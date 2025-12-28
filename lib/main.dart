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
import 'services/streak_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables - only on mobile platforms
  bool dotenvLoaded = false;
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
      dotenvLoaded = true;
    } catch (e) {
      if (kDebugMode) {
        print('Warning: .env file not found, using defaults');
      }
    }
  }

  // Allow google_fonts to fetch from network if assets aren't bundled
  GoogleFonts.config.allowRuntimeFetching = true;

  if (kDebugMode) {
    final apiUrl = dotenvLoaded 
        ? (dotenv.env['API_BASE_URL'] ?? 'https://tennisgpt-production.up.railway.app')
        : 'https://tennisgpt-production.up.railway.app';
    print('API_BASE_URL = $apiUrl');
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
