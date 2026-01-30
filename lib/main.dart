import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/purchase_service.dart';
import 'services/usage_service.dart';
import 'services/player_profile_service.dart';
import 'services/theme_service.dart';
import 'services/streak_service.dart';
import 'services/match_history_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow google_fonts to fetch from network if assets aren't bundled
  GoogleFonts.config.allowRuntimeFetching = true;

  if (kDebugMode) {
    print('API_BASE_URL = https://tennisgpt-production.up.railway.app');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ApiService()),
        ChangeNotifierProvider(
          create: (context) => AuthService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => PurchaseService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => UsageService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => PlayerProfileService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeService()..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => StreakService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => MatchHistoryService()..initialize(),
        ),
        // Wire up sign out callback to clear ALL local data for ALL services
        ProxyProvider6<AuthService, PlayerProfileService, UsageService, StreakService, MatchHistoryService, PurchaseService, void>(
          update: (context, authService, profileService, usageService, streakService, matchHistoryService, purchaseService, _) {
            authService.onSignOut = () async {
              if (kDebugMode) {
                print('main.dart: Clearing ALL user data from ALL services...');
              }
              
              // Reset ALL services that store user-specific data
              await profileService.resetProfile();
              await usageService.resetAllUsage();
              await streakService.resetStreak();
              await matchHistoryService.resetAllMatches();
              
              // Log out from RevenueCat (important for subscription state)
              await purchaseService.logOut();
              
              if (kDebugMode) {
                print('main.dart: All user data cleared - ready for new user');
              }
            };
          },
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Composure',
            debugShowCheckedModeBanner: false,
            theme: ThemeService.lightTheme,
            darkTheme: ThemeService.darkTheme,
            themeMode: themeService.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasSyncedOnboarding = false;
  String? _lastAuthenticatedEmail;
  bool _isReInitializing = false;

  @override
  void initState() {
    super.initState();
    // Listen to auth changes directly for more reliable updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      authService.addListener(_onAuthChanged);
    });
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    try {
      final authService = context.read<AuthService>();
      authService.removeListener(_onAuthChanged);
    } catch (_) {
      // Context might not be available during dispose
    }
    super.dispose();
  }

  void _onAuthChanged() {
    // Force rebuild when auth state changes
    if (mounted) {
      setState(() {});
    }
  }

  /// Re-initialize all services after login
  Future<void> _reInitializeServicesForUser() async {
    if (_isReInitializing) return;
    _isReInitializing = true;
    
    if (kDebugMode) {
      print('AuthWrapper: Re-initializing services for new login...');
    }
    
    try {
      final profileService = context.read<PlayerProfileService>();
      final usageService = context.read<UsageService>();
      final streakService = context.read<StreakService>();
      final matchHistoryService = context.read<MatchHistoryService>();
      
      // Re-initialize all services (they check _isLoaded internally)
      await profileService.initialize();
      await usageService.initialize();
      await streakService.initialize();
      await matchHistoryService.initialize();
      
      if (kDebugMode) {
        print('AuthWrapper: Services re-initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthWrapper: Error re-initializing services - $e');
      }
    } finally {
      _isReInitializing = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final profileService = context.watch<PlayerProfileService>();
    
    if (kDebugMode) {
      print('AuthWrapper: Building - authenticated=${authService.isAuthenticated}, email=${authService.userEmail}, profileLoaded=${profileService.isLoaded}, onboarding=${profileService.hasCompletedOnboarding || authService.onboardingCompleted}');
    }
    
    // Not authenticated - show login
    if (!authService.isAuthenticated) {
      _hasSyncedOnboarding = false;
      _lastAuthenticatedEmail = null;
      return const LoginScreen();
    }
    
    // Check if this is a new login session (different email or first login)
    final currentEmail = authService.userEmail;
    if (_lastAuthenticatedEmail != currentEmail) {
      _lastAuthenticatedEmail = currentEmail;
      _hasSyncedOnboarding = false;
      
      // Re-initialize services for the new user (they may have been reset during logout)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _reInitializeServicesForUser();
        
        // Sync onboarding from backend for this user
        if (authService.onboardingCompleted && mounted) {
          profileService.syncFromBackend(authService.onboardingCompleted);
          _hasSyncedOnboarding = true;
        }
      });
    }
    
    // Profile not loaded yet - show loading
    if (!profileService.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Authenticated but hasn't completed onboarding - show onboarding
    // Check BOTH local and backend status
    final hasCompletedOnboarding = profileService.hasCompletedOnboarding || authService.onboardingCompleted;
    if (!hasCompletedOnboarding) {
      return const OnboardingScreen();
    }
    
    // Authenticated and onboarding complete - show home
    return const HomeScreen();
  }
}
