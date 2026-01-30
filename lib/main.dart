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
  String? _lastInitializedForEmail;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final profileService = context.watch<PlayerProfileService>();
    
    if (kDebugMode) {
      print('AuthWrapper: authenticated=${authService.isAuthenticated}, email=${authService.userEmail}, profileLoaded=${profileService.isLoaded}');
    }
    
    // Not authenticated - show login
    if (!authService.isAuthenticated) {
      _lastInitializedForEmail = null;
      return const LoginScreen();
    }
    
    // Authenticated - check if we need to initialize services for this user
    final currentEmail = authService.userEmail;
    
    // If profile isn't loaded OR we're logged in as a different user, initialize services
    if (!profileService.isLoaded || _lastInitializedForEmail != currentEmail) {
      // Trigger initialization asynchronously but don't block
      _initializeServicesForUser(currentEmail);
      
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your data...'),
            ],
          ),
        ),
      );
    }
    
    // Profile is loaded - check onboarding
    final hasCompletedOnboarding = profileService.hasCompletedOnboarding || authService.onboardingCompleted;
    
    if (kDebugMode) {
      print('AuthWrapper: Onboarding check - local=${profileService.hasCompletedOnboarding}, backend=${authService.onboardingCompleted}');
    }
    
    if (!hasCompletedOnboarding) {
      return const OnboardingScreen();
    }
    
    // Authenticated and onboarding complete - show home
    return const HomeScreen();
  }

  /// Initialize all services for the current user
  Future<void> _initializeServicesForUser(String? email) async {
    if (kDebugMode) {
      print('AuthWrapper: Initializing services for user: $email');
    }
    
    try {
      final profileService = context.read<PlayerProfileService>();
      final usageService = context.read<UsageService>();
      final streakService = context.read<StreakService>();
      final matchHistoryService = context.read<MatchHistoryService>();
      final authService = context.read<AuthService>();
      
      // Force re-initialization by resetting loaded state first
      // This ensures we load data for the new user
      if (_lastInitializedForEmail != email) {
        await profileService.resetProfile();
        await usageService.resetAllUsage();
        await streakService.resetStreak();
        await matchHistoryService.resetAllMatches();
      }
      
      // Now initialize (this will load data from storage with user-specific keys)
      await profileService.initialize();
      await usageService.initialize();
      await streakService.initialize();
      await matchHistoryService.initialize();
      
      // Sync onboarding from backend
      if (authService.onboardingCompleted) {
        await profileService.syncFromBackend(authService.onboardingCompleted);
      }
      
      _lastInitializedForEmail = email;
      
      if (kDebugMode) {
        print('AuthWrapper: Services initialized for $email');
      }
      
      // Trigger rebuild
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthWrapper: Error initializing services - $e');
      }
    }
  }
}
