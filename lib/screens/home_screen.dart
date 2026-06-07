import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/match_history_service.dart';
import '../services/streak_service.dart';
import '../models/match_performance.dart';
import 'tactical_coach_screen.dart';
import 'match_history_screen.dart';
import 'quick_match_screen.dart';
import 'mental_check_in_screen.dart';
import 'emotional_reset_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Home Screen - Performance Dashboard
/// Direction: calm tactical intelligence.
/// Behavior is unchanged; only UI presentation is refined.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MatchHistoryService _matchHistoryService = MatchHistoryService();

  List<MatchPerformance> _recentMatches = [];
  double _winRate = 0.0;
  int _currentStreak = 0;
  int _totalMatches = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final matches = await _matchHistoryService.getRecentMatches(10);
      final winRate = await _matchHistoryService.getWinRate();
      final total = await _matchHistoryService.getTotalMatches();
      final streak = _calculateStreak(matches);

      setState(() {
        _recentMatches = matches;
        _winRate = winRate;
        _totalMatches = total;
        _currentStreak = streak;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int _calculateStreak(List<MatchPerformance> matches) {
    if (matches.isEmpty) return 0;

    int streak = 0;
    final bool isWinStreak = matches.first.result.toLowerCase() == 'win';

    for (final match in matches) {
      if ((match.result.toLowerCase() == 'win') == isWinStreak) {
        streak++;
      } else {
        break;
      }
    }

    return isWinStreak ? streak : -streak;
  }

  bool get _isGuest => Provider.of<AuthService>(context, listen: false).isGuest;

  /// Shows a sign-in prompt when a guest taps a feature that requires auth.
  /// Returns true if the user signed in, false if they cancelled.
  Future<bool> _requireSignIn() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Text(
          'Sign in to continue',
          style: AppTheme.headingSmallThemed(context),
        ),
        content: Text(
          'Create a free account to log matches, get AI coaching, and track your progress.',
          style: AppTheme.bodyMediumThemed(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Not now', style: AppTheme.bodyMediumThemed(context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            child: Text(
              'Sign in',
              style: AppTheme.bodyMediumThemed(context).copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.exitGuestMode();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final streakService = Provider.of<StreakService>(context);
    final firstName = authService.isGuest
        ? 'Player'
        : (authService.userDisplayName?.split(' ').first ?? 'Player');

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: Stack(
        children: [
          _buildAtmosphericBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              color: AppTheme.primary,
              backgroundColor: AppTheme.cardBackground(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(context, authService, firstName),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMD),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildPerformanceCard(streakService),
                        const SizedBox(height: AppTheme.spaceLG),
                        _buildPrimaryAction(),
                        const SizedBox(height: AppTheme.spaceXL),
                        if (_recentMatches.isNotEmpty) ...[
                          _buildRecentActivity(),
                          const SizedBox(height: AppTheme.spaceXL),
                        ],
                        _buildToolsSection(),
                        const SizedBox(height: AppTheme.spaceXXL),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned(
              top: 18,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSM,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppTheme.borderColor(context)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Refreshing', style: AppTheme.labelThemed(context)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Get time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Widget _buildAtmosphericBackground() {
    final screenWidth = MediaQuery.of(context).size.width;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppTheme.scaffoldBackground(context),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/images/menu_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // Readability scrim: darkens top/bottom so text and cards stay legible
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.scaffoldBackground(context).withValues(alpha: 0.55),
                    AppTheme.scaffoldBackground(context).withValues(alpha: 0.30),
                    AppTheme.scaffoldBackground(context).withValues(alpha: 0.65),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Tennis ball peeking from the top-right corner.
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            right: -18,
            child: Image.asset(
              'assets/images/tennis_ball.png',
              width: 86,
              height: 86,
              fit: BoxFit.contain,
            ),
          ),
          // Racket head emerging from the bottom-left corner.
          Positioned(
            left: -screenWidth * 0.18,
            bottom: -screenWidth * 0.14,
            child: Image.asset(
              'assets/images/tennis_racket.png',
              width: screenWidth * 0.85,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  /// Header with timed greeting + elite positioning tagline
  Widget _buildHeader(
      BuildContext context, AuthService authService, String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMD,
        AppTheme.spaceMD,
        AppTheme.spaceMD,
        AppTheme.spaceSM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTheme.labelThemed(context).copyWith(
                    color: AppTheme.neutral.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  firstName,
                  style: AppTheme.headingLargeThemed(context).copyWith(
                    height: 1.0,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: Text(
                    'TACTICAL INTELLIGENCE BOARD',
                    style: AppTheme.labelThemed(context).copyWith(
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.tune_rounded,
                color: AppTheme.textSecondaryColor(context),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Performance Card - The visual anchor
  /// Hierarchy: Primary stat → Secondary stats → Tertiary indicators
  Widget _buildPerformanceCard(StreakService streakService) {
    final winPercentage = (_winRate * 100).toStringAsFixed(0);

    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        color: AppTheme.elevatedBackground(context).withValues(alpha: 0.96),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Season Pulse',
                    style: AppTheme.labelThemed(context).copyWith(
                      color: AppTheme.neutral,
                    ),
                  ),
                  Text(
                    '$winPercentage%',
                    style: AppTheme.statLargeThemed(context).copyWith(
                      fontSize: 56,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                ],
              ),
              Transform.rotate(
                angle: -0.08,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.55)),
                  ),
                  child: Text(
                    _currentStreak == 0
                        ? 'RESET'
                        : _currentStreak > 0
                            ? 'ON FIRE'
                            : 'REBUILD',
                    style: AppTheme.labelThemed(context).copyWith(
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Container(height: 1, color: AppTheme.borderColor(context)),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryStatItem(
                  value: '$_totalMatches',
                  label: 'matches logged',
                ),
              ),
              if (_currentStreak != 0)
                Expanded(
                  child: _buildSecondaryStatItem(
                    value: '${_currentStreak.abs()}',
                    label: _currentStreak > 0 ? 'match streak' : 'bounce back',
                    valueColor: _currentStreak > 0 ? AppTheme.win : null,
                  ),
                ),
              if (streakService.currentStreak > 0)
                Expanded(
                  child: _buildSecondaryStatItem(
                    value: '${streakService.currentStreak}',
                    label: 'day streak',
                  ),
                ),
            ],
          ),
          if (_recentMatches.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMD),
            Container(height: 1, color: AppTheme.borderColor(context)),
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              children: [
                Text('Recent form', style: AppTheme.labelThemed(context)),
                const SizedBox(width: AppTheme.spaceMD),
                ...List.generate(
                  _recentMatches.take(5).length,
                  (index) {
                    final isWin =
                        _recentMatches[index].result.toLowerCase() == 'win';
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isWin
                            ? AppTheme.win
                            : AppTheme.loss.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryStatItem({
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTheme.statMediumThemed(context).copyWith(
            color: valueColor ?? AppTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.labelThemed(context)),
      ],
    );
  }

  /// Primary Action - Clear but not overpowering
  Widget _buildPrimaryAction() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (_isGuest) {
          _requireSignIn();
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuickMatchScreen()),
        ).then((_) => _loadStats());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLG,
          vertical: AppTheme.spaceLG,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryLight, AppTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD + 2),
          boxShadow: AppTheme.ctaGlowThemed(context),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_tennis_rounded,
              color: AppTheme.surfaceDark,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Text(
              'Quick Match Log',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.surfaceDark,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Recent Activity - lightweight match records
  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Recent matches'),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (_isGuest) {
                  _requireSignIn();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MatchHistoryScreen()),
                );
              },
              child: Text(
                'View all',
                style: AppTheme.labelThemed(context)
                    .copyWith(color: AppTheme.primary),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spaceMD),

        // Match list
        ...List.generate(
          _recentMatches.take(3).length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
            child: _buildMatchItem(_recentMatches[index]),
          ),
        ),
      ],
    );
  }

  /// Match item - clean match record
  Widget _buildMatchItem(MatchPerformance match) {
    final isWin = match.result.toLowerCase() == 'win';
    final resultLabel = isWin ? 'Win' : 'Loss';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MatchHistoryScreen()),
        );
      },
      child: Container(
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            // Result indicator - subtle
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isWin ? AppTheme.win : AppTheme.loss.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(width: AppTheme.spaceMD),

            // Match info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        match.opponent,
                        style: AppTheme.headingSmallThemed(context).copyWith(
                          color: AppTheme.textPrimaryColor(context),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Text(
                        match.scoreLine.isNotEmpty
                            ? match.scoreLine
                            : '${match.setsWon}-${match.setsLost}',
                        style: AppTheme.bodySmallThemed(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$resultLabel - ${_formatDate(match.date)} - ${match.surface} - ${match.matchFormat}',
                    style: AppTheme.bodySmallThemed(context),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: AppTheme.textMutedColor(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Tools Section - Analytical positioning
  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Coach tools'),
        const SizedBox(height: AppTheme.spaceMD),
        Row(
          children: [
            Expanded(
                child: _buildToolItem(
              icon: Icons.analytics_outlined,
              label: 'Tactical\nCoach',
              onTap: () {
                if (_isGuest) {
                  _requireSignIn();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TacticalCoachScreen()),
                );
              },
            )),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
                child: _buildToolItem(
              icon: Icons.flag_outlined,
              label: 'Pre-Match\nPrep',
              onTap: () {
                if (_isGuest) {
                  _requireSignIn();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MentalCheckInScreen()),
                );
              },
            )),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
                child: _buildToolItem(
              icon: Icons.edit_note_outlined,
              label: 'Post-Match\nDebrief',
              onTap: () {
                if (_isGuest) {
                  _requireSignIn();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EmotionalResetScreen()),
                );
              },
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSM,
          vertical: AppTheme.spaceLG,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 23, color: AppTheme.neutral),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              label,
              style: AppTheme.labelThemed(context).copyWith(
                color: AppTheme.textSecondaryColor(context),
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(title, style: AppTheme.headingSmallThemed(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.borderColor(context),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
