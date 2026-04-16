import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/auth_wrapper.dart';
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

  // Keep font loading local-only for predictable offline behavior.
  GoogleFonts.config.allowRuntimeFetching = false;

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
            final apiService = Provider.of<ApiService>(context, listen: false);
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
            
            // Sync onboarding status from backend to local profile service
            authService.onOnboardingStatusReceived = (completed) async {
              await profileService.syncFromBackend(completed);
            };
            
            // Reinitialize user-scoped services after login/session restore
            authService.onUserChanged = () async {
              await profileService.resetProfile();
              await usageService.resetAllUsage();
              await streakService.resetStreak();
              await matchHistoryService.resetAllMatches();
              
              await profileService.initialize();
              await usageService.initialize();
              await streakService.initialize();
              await matchHistoryService.initialize();
              
              // Identify user with RevenueCat for subscription tracking
              final email = authService.userEmail;
              if (email != null) {
                await purchaseService.identifyUser(email);
                if (kDebugMode) {
                  print('main.dart: Identified user with RevenueCat: $email');
                }
                await apiService.syncSubscriptionWithBackend();
                await authService.refreshProfile();
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

