import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
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
  AuthService? _authService;
  bool _authListenerAttached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_authListenerAttached) {
      _authService = context.read<AuthService>();
      _authService!.addListener(_onAuthStateChanged);
      _authListenerAttached = true;
    }
  }

  @override
  void dispose() {
    _authService?.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.error!),
          backgroundColor: AppTheme.loss,
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
        // Use backend-auth onboarding state as the source of truth for
        // first-login routing to avoid local-state race conditions.
        final hasCompletedOnboarding = authService.onboardingCompleted;

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
            backgroundColor: AppTheme.loss,
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
        // Use backend-auth onboarding state as the source of truth for
        // first-login routing to avoid local-state race conditions.
        final hasCompletedOnboarding = authService.onboardingCompleted;

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
            backgroundColor: AppTheme.loss,
          ),
        );
      }
    }
  }

  // ============ Consistent button dimensions ============
  static const double _authButtonHeight = 56.0;
  static const double _authButtonRadius = AppTheme.radiusLG;
  static const double _authButtonFontSize = 16.0;
  static const EdgeInsets _authButtonPadding =
      EdgeInsets.symmetric(horizontal: AppTheme.spaceLG);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoading = authService.isLoading;
    final isDark = AppTheme.isDark(context);

    final textColor = AppTheme.textPrimaryColor(context);
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
                  : [AppTheme.brandSofter, AppTheme.brandSoft],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground(context),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary
                                .withValues(alpha: isDark ? 0.3 : 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_tennis,
                        size: 60,
                        color: AppTheme.primaryLight,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App Title
                    Text(
                      'Composure',
                      style: AppTheme.headingLargeThemed(context).copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppTheme.textPrimary : AppTheme.primaryDark,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceSM),

                    // Updated Subtitle — elite positioning
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Structured Tactical Intelligence for Competitive Players',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMediumThemed(context).copyWith(
                          fontSize: 14,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceXXL),

                    // ============ Auth Buttons (consistent) ============

                    // Google Sign In — consistent dimensions
                    SizedBox(
                      width: double.infinity,
                      height: _authButtonHeight,
                      child: Material(
                        color: AppTheme.cardBackground(context),
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
                                  const SizedBox(
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
                                  const Text(
                                    'G',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontVariations:
                                          AppTheme.fontVariationsSemiExpanded,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      // Google brand blue — intentionally kept.
                                      color: Color(0xFF4285F4),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Text(
                                  isLoading
                                      ? 'Signing in...'
                                      : 'Continue with Google',
                                  style: AppTheme.bodyMediumThemed(context)
                                      .copyWith(
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
                              // Apple sign-in brand surface (black / white).
                              color: isDark ? Colors.white : Colors.black,
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
                                        style: AppTheme.bodyMediumThemed(context)
                                            .copyWith(
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

                    const SizedBox(height: AppTheme.spaceLG),

                    // Continue without signing in
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              authService.enterGuestMode();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => const HomeScreen()),
                              );
                            },
                      child: Text(
                        'Continue without signing in',
                        style: AppTheme.bodyMediumThemed(context).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor.withValues(alpha: 0.7),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceLG),

                    // Updated Feature bullets — analytical positioning
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceLG),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground(context)
                            .withValues(alpha: 0.9),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLG),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureItem(
                            icon: Icons.analytics_outlined,
                            title: 'Tactical Analysis',
                            subtitle:
                                'Structured insights from match data',
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          _buildFeatureItem(
                            icon: Icons.pattern_rounded,
                            title: 'Match Pattern Tracking',
                            subtitle:
                                'Identify recurring trends across matches',
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
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
    final isDark = AppTheme.isDark(context);

    final titleColor = AppTheme.textPrimaryColor(context);
    final subtitleColor =
        isDark ? AppTheme.textMutedColor(context) : AppTheme.primaryDark;
    final iconBgColor = isDark
        ? AppTheme.primary.withValues(alpha: 0.15)
        : AppTheme.primary.withValues(alpha: 0.1);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSM),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
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
                style: AppTheme.bodyMediumThemed(context).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              Text(
                subtitle,
                style: AppTheme.bodySmallThemed(context).copyWith(
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
