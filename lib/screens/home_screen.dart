import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/streak_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/home/home_header.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/common/quick_action_button.dart';
import '../widgets/common/action_card.dart';
import '../widgets/common/loading_indicator.dart';
import 'emotional_reset_screen.dart';
import 'mental_check_in_screen.dart';
import 'tactical_coach_screen.dart';
import 'match_history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StreakService _streakService = StreakService();

  StreakData? _streakData;
  WeeklyStats? _weeklyStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final streakData = await _streakService.getStreakData();
      final weeklyStats = await _streakService.getWeeklyStats();

      if (mounted) {
        setState(() {
          _streakData = streakData;
          _weeklyStats = weeklyStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateDaysSinceLastMatch() {
    // For now, return 0 if we have matches this week, otherwise 7
    if (_weeklyStats?.matchesPlayed != null && _weeklyStats!.matchesPlayed > 0) {
      return 0;
    }
    return 7;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.userDisplayName?.split(' ')[0];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_tennis,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'TennisGPT',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'signout') {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Sign Out'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: authService.userPhotoURL != null
                    ? NetworkImage(authService.userPhotoURL!)
                    : null,
                child: authService.userPhotoURL == null
                    ? Text(
                        authService.userDisplayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(
                child: TennisLoadingIndicator(message: 'Loading...'),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with greeting and streak
                    HomeHeader(
                      userName: userName,
                      streakCount: _streakData?.displayStreak ?? 0,
                      streakType: _streakData?.streakType ?? 'day',
                      hasCheckedInToday: _streakData?.hasCheckedInToday ?? false,
                    ).animate().fadeIn().slideY(begin: -0.2, end: 0),

                    const SizedBox(height: AppSpacing.lg),

                    // Primary Focus Card
                    PrimaryFocusCard(
                      hasCheckedInToday: _streakData?.hasCheckedInToday ?? false,
                      daysSinceLastMatch: _calculateDaysSinceLastMatch(),
                      lastMoodRating: _streakData?.recentMood,
                      onCheckIn: () => _navigateToScreen(const MentalCheckInScreen()),
                      onLogMatch: () => _navigateToScreen(const MatchHistoryScreen()),
                      onEmotionalReset: () => _navigateToScreen(const EmotionalResetScreen()),
                      onTacticalTip: () => _navigateToScreen(const TacticalCoachScreen()),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: AppSpacing.lg),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: AppSpacing.sm),
                    QuickActionsRow(
                      actions: [
                        QuickActionItem(
                          label: 'Check-In',
                          icon: Icons.psychology_outlined,
                          onTap: () => _navigateToScreen(const MentalCheckInScreen()),
                          showBadge: !(_streakData?.hasCheckedInToday ?? false),
                        ),
                        QuickActionItem(
                          label: 'Quick Tip',
                          icon: Icons.lightbulb_outline,
                          onTap: () => _navigateToScreen(const TacticalCoachScreen()),
                        ),
                        QuickActionItem(
                          label: 'Log Match',
                          icon: Icons.add_circle_outline,
                          onTap: () => _navigateToScreen(const MatchHistoryScreen()),
                        ),
                        QuickActionItem(
                          label: 'Reset',
                          icon: Icons.spa_outlined,
                          onTap: () => _navigateToScreen(const EmotionalResetScreen()),
                        ),
                      ],
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // Weekly Stats
                    Text(
                      'This Week',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: AppSpacing.sm),
                    _buildWeeklyStats().animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // Features Grid
                    Text(
                      'Features',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFeaturesGrid().animate().fadeIn(delay: 450.ms),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWeeklyStats() {
    final stats = _weeklyStats;

    return StatRow(
      stats: [
        StatItem(
          label: 'Matches',
          value: '${stats?.matchesPlayed ?? 0}',
          subtitle: 'played',
        ),
        StatItem(
          label: 'Win Rate',
          value: stats?.hasMatches == true
              ? '${stats!.winRate.toStringAsFixed(0)}%'
              : '--',
          subtitle: stats?.hasMatches == true
              ? (stats!.isWinRateUp ? '+${stats.winRateChange.abs().toStringAsFixed(0)}%' : '${stats.winRateChange.toStringAsFixed(0)}%')
              : 'no matches',
          subtitleColor: stats?.isWinRateUp == true ? AppColors.success : AppColors.textMuted,
        ),
        StatItem(
          label: 'Check-Ins',
          value: '${stats?.checkInsCompleted ?? 0}',
          subtitle: stats?.averageMood != null
              ? 'avg ${stats!.averageMood!.toStringAsFixed(1)}'
              : 'this week',
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.3,
      children: [
        FeatureCard(
          title: 'Mental Check-In',
          subtitle: 'Track your mindset',
          icon: Icons.psychology_outlined,
          iconColor: AppColors.info,
          onTap: () => _navigateToScreen(const MentalCheckInScreen()),
        ),
        FeatureCard(
          title: 'Tactical Coach',
          subtitle: 'AI-powered advice',
          icon: Icons.sports_tennis,
          iconColor: AppColors.primary,
          onTap: () => _navigateToScreen(const TacticalCoachScreen()),
        ),
        FeatureCard(
          title: 'Emotional Reset',
          subtitle: 'Process emotions',
          icon: Icons.spa_outlined,
          iconColor: AppColors.warning,
          onTap: () => _navigateToScreen(const EmotionalResetScreen()),
        ),
        FeatureCard(
          title: 'Match History',
          subtitle: 'View your progress',
          icon: Icons.analytics_outlined,
          iconColor: Colors.purpleAccent,
          onTap: () => _navigateToScreen(const MatchHistoryScreen()),
        ),
      ],
    );
  }

  void _navigateToScreen(Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      // Refresh data when returning from any screen
      _loadData();
    });
  }
}
