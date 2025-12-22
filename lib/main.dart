import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Allow google_fonts to fetch from network if assets aren't bundled
  GoogleFonts.config.allowRuntimeFetching = true;

  if (kDebugMode) {
    print('API_BASE_URL from .env = ${dotenv.env['API_BASE_URL']}');
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, PlayerProfileService>(
      builder: (context, authService, profileService, child) {
        // Not authenticated - show login
        if (!authService.isAuthenticated) {
          return const LoginScreen();
        }
        
        // Profile not loaded yet - show loading
        if (!profileService.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Authenticated but hasn't completed onboarding - show onboarding
        if (!profileService.hasCompletedOnboarding) {
          return const OnboardingScreen();
        }
        
        // Authenticated and onboarding complete - show home
        return const HomeScreen();
      },
    );
  }
}
