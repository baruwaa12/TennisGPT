import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../services/auth_service.dart';
import '../services/player_profile_service.dart';
import '../theme/app_theme.dart';
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

  Future<void> _signInWithApple() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithApple();

      if (!mounted) return;

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

  // ============ Consistent button dimensions ============
  static const double _authButtonHeight = 56.0;
  static const double _authButtonRadius = 12.0;
  static const double _authButtonFontSize = 16.0;
  static const EdgeInsets _authButtonPadding =
      EdgeInsets.symmetric(horizontal: 24);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoading = authService.isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.grey[800]!;
    final subtitleColor = isDark ? AppTheme.primaryLight : AppTheme.primaryDark;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [AppTheme.surfaceSecondary, AppTheme.surfaceDark]
                  : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceCard : Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary
                                .withOpacity(isDark ? 0.3 : 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sports_tennis,
                        size: 60,
                        color: AppTheme.primaryLight,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App Title
                    Text(
                      'Composure',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.primaryDark,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Updated Subtitle — elite positioning
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Structured Tactical Intelligence for Competitive Players',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ============ Auth Buttons (consistent) ============

                    // Google Sign In — consistent dimensions
                    SizedBox(
                      width: double.infinity,
                      height: _authButtonHeight,
                      child: Material(
                        color: isDark
                            ? AppTheme.surfaceCard
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(_authButtonRadius),
                        elevation: isDark ? 0 : 2,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(_authButtonRadius),
                          onTap: isLoading ? null : _signInWithGoogle,
                          child: Padding(
                            padding: _authButtonPadding,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLoading)
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryLight,
                                      ),
                                    ),
                                  )
                                else
                                  // Google "G" — no white box, transparent
                                  Text(
                                    'G',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF4285F4),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Text(
                                  isLoading
                                      ? 'Signing in...'
                                      : 'Continue with Google',
                                  style: GoogleFonts.poppins(
                                    fontSize: _authButtonFontSize,
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

                    // Apple Sign In (iOS only) — matching dimensions
                    if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                      const SizedBox(height: 12),
                      FutureBuilder<bool>(
                        future: SignInWithApple.isAvailable(),
                        builder: (context, snapshot) {
                          if (snapshot.data != true) {
                            return const SizedBox.shrink();
                          }
                          return SizedBox(
                            width: double.infinity,
                            height: _authButtonHeight,
                            child: Material(
                              color: isDark
                                  ? Colors.white
                                  : Colors.black,
                              borderRadius: BorderRadius.circular(
                                  _authButtonRadius),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                    _authButtonRadius),
                                onTap: isLoading
                                    ? null
                                    : _signInWithApple,
                                child: Padding(
                                  padding: _authButtonPadding,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.apple,
                                        size: 24,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Apple',
                                        style: GoogleFonts.poppins(
                                          fontSize: _authButtonFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Updated Feature bullets — analytical positioning
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.surfaceCard : Colors.white)
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureItem(
                            icon: Icons.analytics_outlined,
                            title: 'Tactical Analysis',
                            subtitle:
                                'Structured insights from match data',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(
                            icon: Icons.pattern_rounded,
                            title: 'Match Pattern Tracking',
                            subtitle:
                                'Identify recurring trends across matches',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(
                            icon: Icons.psychology_outlined,
                            title: 'Mental Stability Insights',
                            subtitle:
                                'Data-driven readiness assessment',
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

    final titleColor = isDark ? Colors.white : Colors.grey[800]!;
    final subtitleColor = isDark ? Colors.grey[400]! : AppTheme.primaryDark;
    final iconBgColor = isDark
        ? AppTheme.primary.withOpacity(0.15)
        : AppTheme.primary.withOpacity(0.1);

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
            color: AppTheme.primaryLight,
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
