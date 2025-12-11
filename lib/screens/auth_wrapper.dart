import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // While checking auth state
    if (authService.isLoading && !authService.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If user is signed in -> go to home
    if (authService.isAuthenticated) {
      return const HomeScreen(); // your real home screen
    }

    // Otherwise -> show login
    return const LoginScreen();
  }
}
