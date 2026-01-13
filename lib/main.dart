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
  bool _hasReinitializedServices = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, PlayerProfileService>(
      builder: (context, authService, profileService, child) {
        // Not authenticated - show login
        if (!authService.isAuthenticated) {
          _hasSyncedOnboarding = false; // Reset sync flag on logout
          _hasReinitializedServices = false; // Reset reinitialization flag
          return const LoginScreen();
        }
        
        // Reinitialize all services after new login (once per login session)
        if (!_hasReinitializedServices) {
          _hasReinitializedServices = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _reinitializeAllServices(context);
          });
        }
        
        // Profile not loaded yet - show loading
        if (!profileService.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Sync onboarding status from backend (once per login)
        if (!_hasSyncedOnboarding && authService.onboardingCompleted) {
          _hasSyncedOnboarding = true;
          // Use addPostFrameCallback to avoid calling setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            profileService.syncFromBackend(authService.onboardingCompleted);
          });
        }
        
        // Authenticated but hasn't completed onboarding - show onboarding
        if (!profileService.hasCompletedOnboarding && !authService.onboardingCompleted) {
          return const OnboardingScreen();
        }
        
        // Authenticated and onboarding complete - show home
        return const HomeScreen();
      },
    );
  }
  
  /// Reinitialize all services that may have been reset during sign out
  void _reinitializeAllServices(BuildContext context) {
    if (kDebugMode) {
      print('AuthWrapper: Reinitializing all services for new user...');
    }
    
    // Reinitialize each service (they will only load fresh data if _isLoaded was reset)
    context.read<PlayerProfileService>().initialize();
    context.read<UsageService>().initialize();
    context.read<StreakService>().initialize();
    context.read<MatchHistoryService>().initialize();
    
    if (kDebugMode) {
      print('AuthWrapper: All services reinitialized');
    }
  }
}
