import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/player_profile_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'onboarding/onboarding_screen.dart';

/// Simple AuthWrapper that handles authentication state.
/// 
/// Flow:
/// 1. Not authenticated -> LoginScreen
/// 2. Authenticated, onboarding not done -> OnboardingScreen
/// 3. Authenticated, onboarding done -> HomeScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final profileService = context.watch<PlayerProfileService>();

    if (kDebugMode) {
      print('AuthWrapper: isLoading=${authService.isLoading}, isAuthenticated=${authService.isAuthenticated}');
    }

    // While checking auth state (initial load)
    if (authService.isLoading && !authService.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Not authenticated -> show login
    if (!authService.isAuthenticated) {
      return const LoginScreen();
    }

    // Authenticated! Check onboarding status
    // Use backend status (authService) OR local status (profileService)
    final hasCompletedOnboarding = 
        authService.onboardingCompleted || profileService.hasCompletedOnboarding;

    if (kDebugMode) {
      print('AuthWrapper: Authenticated! onboardingCompleted=$hasCompletedOnboarding');
    }

    if (!hasCompletedOnboarding) {
      return const OnboardingScreen();
    }

    // Authenticated and onboarding complete -> show home
    return const HomeScreen();
  }
}
