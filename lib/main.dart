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
            title: 'TennisGPT',
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
      
      // Sync onboarding from backend for this user
      if (authService.onboardingCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          profileService.syncFromBackend(authService.onboardingCompleted);
        });
        _hasSyncedOnboarding = true;
      }
    }
    
    // Profile not loaded yet - show loading (but this should rarely happen now)
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
