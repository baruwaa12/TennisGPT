import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/player_profile_service.dart';
import '../services/usage_service.dart';
import '../services/streak_service.dart';
import '../services/match_history_service.dart';
import '../services/purchase_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'onboarding/onboarding_screen.dart';

/// AuthWrapper handles authentication state and service initialization.
/// 
/// This is a StatefulWidget that:
/// 1. Listens to AuthService for login/logout events
/// 2. Re-initializes all user services when a user logs in
/// 3. Shows appropriate screen based on auth + onboarding state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializingServices = false;
  String? _lastInitializedEmail;
  
  @override
  void initState() {
    super.initState();
    // Start listening to auth changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      authService.addListener(_onAuthStateChanged);
      
      // Initial check
      _onAuthStateChanged();
    });
  }
  
  @override
  void dispose() {
    try {
      context.read<AuthService>().removeListener(_onAuthStateChanged);
    } catch (_) {}
    super.dispose();
  }
  
  void _onAuthStateChanged() {
    if (!mounted) return;
    
    final authService = context.read<AuthService>();
    
    if (kDebugMode) {
      print('AuthWrapper._onAuthStateChanged: isAuthenticated=${authService.isAuthenticated}, email=${authService.userEmail}');
    }
    
    // If user just logged in and we haven't initialized services for this user yet
    if (authService.isAuthenticated && 
        authService.userEmail != null &&
        authService.userEmail != _lastInitializedEmail &&
        !_isInitializingServices) {
      _initializeServicesForUser(authService.userEmail!);
    }
    
    // If user logged out, reset tracking
    if (!authService.isAuthenticated) {
      _lastInitializedEmail = null;
    }
    
    // Trigger rebuild
    setState(() {});
  }
  
  Future<void> _initializeServicesForUser(String userEmail) async {
    if (_isInitializingServices) return;
    
    if (kDebugMode) {
      print('AuthWrapper: Initializing services for user: $userEmail');
    }
    
    setState(() {
      _isInitializingServices = true;
    });
    
    try {
      // Get all services
      final profileService = context.read<PlayerProfileService>();
      final usageService = context.read<UsageService>();
      final streakService = context.read<StreakService>();
      final matchService = context.read<MatchHistoryService>();
      final purchaseService = context.read<PurchaseService>();
      
      // Reset in-memory state (this clears cached data from previous user)
      await profileService.resetProfile();
      await usageService.resetAllUsage();
      await streakService.resetStreak();
      await matchService.resetAllMatches();
      
      // Now re-initialize each service to load data for the new user
      // UserStorageService already has the new user's email set by AuthService
      await profileService.initialize();
      await usageService.initialize();
      await streakService.initialize();
      await matchService.initialize();
      
      // Identify user with RevenueCat
      await purchaseService.identifyUser(userEmail);
      
      _lastInitializedEmail = userEmail;
      
      if (kDebugMode) {
        print('AuthWrapper: Services initialized for $userEmail');
        print('AuthWrapper: Profile loaded=${profileService.isLoaded}, onboarding=${profileService.hasCompletedOnboarding}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthWrapper: Error initializing services - $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingServices = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final profileService = context.watch<PlayerProfileService>();

    if (kDebugMode) {
      print('AuthWrapper.build: isLoading=${authService.isLoading}, isAuthenticated=${authService.isAuthenticated}, isInitializingServices=$_isInitializingServices');
    }

    // Show loading during initial auth check
    if (authService.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Signing in...'),
            ],
          ),
        ),
      );
    }

    // Not authenticated -> show login
    if (!authService.isAuthenticated) {
      return const LoginScreen();
    }

    // Authenticated but services are being initialized for this user
    if (_isInitializingServices) {
      return const Scaffold(
        body: Center(
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

    // Authenticated but haven't initialized services yet (shouldn't happen, but safety check)
    if (_lastInitializedEmail != authService.userEmail) {
      // Trigger initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (authService.userEmail != null) {
          _initializeServicesForUser(authService.userEmail!);
        }
      });
      
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing your account...'),
            ],
          ),
        ),
      );
    }

    // Check onboarding status from BOTH backend and local
    final hasCompletedOnboarding = 
        authService.onboardingCompleted || profileService.hasCompletedOnboarding;

    if (kDebugMode) {
      print('AuthWrapper: Ready! onboardingCompleted=$hasCompletedOnboarding (backend=${authService.onboardingCompleted}, local=${profileService.hasCompletedOnboarding})');
    }

    // Need to complete onboarding
    if (!hasCompletedOnboarding) {
      return const OnboardingScreen();
    }

    // All good - show home screen
    return const HomeScreen();
  }
}
