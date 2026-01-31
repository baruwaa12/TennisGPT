import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/player_profile_service.dart';
import 'home_screen.dart';
import 'onboarding/onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to auth service errors
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Show errors from AuthService as snackbars
    if (authService.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.error!),
          backgroundColor: Colors.red,
        ),
      );
      authService.clearError();
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();

      if (!mounted) return;

      // Fallback navigation if the AuthWrapper doesn't rebuild immediately.
      if (authService.isAuthenticated) {
        final profileService = context.read<PlayerProfileService>();
        await profileService.initialize();
        final hasCompletedOnboarding =
            authService.onboardingCompleted || profileService.hasCompletedOnboarding;

        final nextScreen = hasCompletedOnboarding
            ? const HomeScreen()
            : const OnboardingScreen();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoading = authService.isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Theme-aware colors
    final backgroundColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey[800]!;
    final subtitleColor = isDark ? Colors.green.shade300 : Colors.green.shade600;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark 
                ? [const Color(0xFF1A1A1A), const Color(0xFF0D0D0D)]
                : [Colors.green.shade50, Colors.green.shade100],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// App Logo/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(isDark ? 0.2 : 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sports_tennis,
                        size: 60,
                        color: Colors.green.shade400,
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// App Title
                    Text(
                      'Composure',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.green.shade800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// Subtitle
                    Text(
                      'Your AI Tennis Strategist',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 60),

                    /// Google Sign In Button - fully theme-aware
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: isLoading ? null : _signInWithGoogle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLoading)
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green.shade400,
                                      ),
                                    ),
                                  )
                                else
                                  Image.network(
                                    'https://developers.google.com/identity/images/g-logo.png',
                                    height: 24,
                                    width: 24,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback to icon if network image fails
                                      return Icon(
                                        Icons.g_mobiledata,
                                        size: 24,
                                        color: Colors.blue.shade700,
                                      );
                                    },
                                  ),
                                const SizedBox(width: 12),
                                Text(
                                  isLoading
                                      ? 'Signing in...'
                                      : 'Continue with Google',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// Features list
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureItem(
                            icon: Icons.psychology,
                            title: 'AI-Powered Analysis',
                            subtitle: 'Get personalized coaching insights',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(
                            icon: Icons.track_changes,
                            title: 'Match Tracking',
                            subtitle: 'Track your performance over time',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(
                            icon: Icons.fitness_center,
                            title: 'Mental Training',
                            subtitle: 'Build mental resilience and focus',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Consistent theme-aware colors
    final titleColor = isDark ? Colors.white : Colors.grey[800]!;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.green.shade600;
    final iconBgColor = isDark ? Colors.green.shade900 : Colors.green.shade100;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.green.shade400,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
