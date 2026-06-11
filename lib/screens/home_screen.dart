import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import '../services/auth_service.dart';
import '../services/match_history_service.dart';
import '../services/streak_service.dart';
import '../services/court_service.dart';
import '../models/match_performance.dart';
import 'tactical_coach_screen.dart';
import 'match_history_screen.dart';
import 'quick_match_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Home Screen — Performance Dashboard
/// Direction: modern, youthful, colourful-but-sleek. One gradient hero as the
/// single colour moment; neutral surfaces and tonal accents carry the rest.
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
  bool _hasLoadedOnce = false;

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

      if (!mounted) return;
      setState(() {
        _recentMatches = matches;
        _winRate = winRate;
        _totalMatches = total;
        _currentStreak = streak;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasLoadedOnce = true;
      });
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
            onPressed: () => Navigator.pop(ctx, true),
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

  void _openQuickMatch() {
    if (_isGuest) {
      _requireSignIn();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuickMatchScreen()),
    ).then((_) => _loadStats());
  }

  void _openMatchHistory() {
    if (_isGuest) {
      _requireSignIn();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MatchHistoryScreen()),
    ).then((_) => _loadStats());
  }

  void _openCoach() {
    if (_isGuest) {
      _requireSignIn();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TacticalCoachScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final streakService = Provider.of<StreakService>(context);
    final court = context.watch<CourtService>();
    final firstName = authService.isGuest
        ? 'Player'
        : (authService.userDisplayName?.split(' ').first ?? 'Player');

    final showSkeleton = _isLoading && !_hasLoadedOnce;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: Stack(
        children: [
          AmbientBackground(color: court.buttonColorLight),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              color: AppTheme.primary,
              backgroundColor: AppTheme.cardBackground(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(firstName)),
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (showSkeleton)
                          _buildHeroSkeleton()
                        else if (_totalMatches == 0)
                          _buildFirstMatchCard()
                        else
                          _buildHeroCard(streakService),
                        const SizedBox(height: AppTheme.spaceMD),
                        PrimaryActionButton(
                          label: 'Log a match',
                          icon: Icons.add_rounded,
                          gradientColors: [
                            court.buttonColorLight,
                            court.buttonColorDark,
                          ],
                          onPressed: _openQuickMatch,
                        ),
                        const SizedBox(height: AppTheme.spaceXL),
                        if (showSkeleton) ...[
                          _buildListSkeleton(),
                          const SizedBox(height: AppTheme.spaceXL),
                        ] else if (_recentMatches.isNotEmpty) ...[
                          _buildRecentActivity(),
                          const SizedBox(height: AppTheme.spaceXL),
                        ],
                        _buildCoachCard(),
                        const SizedBox(height: AppTheme.spaceXXL),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ============ Header ============

  Widget _buildHeader(String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMD,
        AppTheme.spaceMD,
        AppTheme.spaceSM,
        AppTheme.spaceMD,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTheme.labelThemed(context)
                      .copyWith(color: AppAccents.teal),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  style: AppTheme.headingLargeThemed(context)
                      .copyWith(height: 1.0),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
            iconSize: 22,
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              backgroundColor:
                  AppTheme.cardBackground(context).withValues(alpha: 0.85),
              foregroundColor: AppTheme.textSecondaryColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                side: BorderSide(color: AppTheme.borderColor(context)),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  // ============ Hero KPI card (the colour moment) ============

  Widget _buildHeroCard(StreakService streakService) {
    final winPercentage = (_winRate * 100).round();
    final streakLabel = _currentStreak > 0
        ? 'On a roll'
        : _currentStreak < 0
            ? 'Bounce-back mode'
            : 'Fresh start';
    final streakIcon = _currentStreak > 0
        ? Icons.bolt_rounded
        : _currentStreak < 0
            ? Icons.replay_rounded
            : Icons.spa_rounded;

    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppAccents.heroGradient(context),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This season',
                style: AppTheme.label.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(streakIcon, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      streakLabel,
                      style: AppTheme.label.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$winPercentage',
                style: AppTheme.statLarge.copyWith(
                  color: Colors.white,
                  fontSize: 64,
                  height: 0.95,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 2),
                child: Text(
                  '%',
                  style: AppTheme.statMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'win rate',
                  style: AppTheme.bodySmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
          if (_recentMatches.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSM),
            Row(
              children: [
                Text(
                  'Recent form',
                  style: AppTheme.label
                      .copyWith(color: Colors.white.withValues(alpha: 0.75)),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                ..._recentMatches.take(5).map((match) {
                  final isWin = match.result.toLowerCase() == 'win';
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isWin
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.spaceMD),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              _buildHeroStat('$_totalMatches', 'matches'),
              if (_currentStreak != 0)
                _buildHeroStat(
                  '${_currentStreak.abs()}',
                  _currentStreak > 0 ? 'win streak' : 'to bounce back',
                ),
              if (streakService.currentStreak > 0)
                _buildHeroStat('${streakService.currentStreak}', 'day streak'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.statMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.label
                .copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  // ============ Empty state (new user) ============

  Widget _buildFirstMatchCard() {
    return PressableCard(
      onTap: _openQuickMatch,
      padding: AppTheme.cardPaddingLarge,
      accent: AppTheme.primary,
      semanticLabel: 'Log your first match',
      child: Row(
        children: [
          const TonalIconBadge(
            icon: Icons.sports_tennis_rounded,
            color: AppAccents.teal,
            size: 52,
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log your first match',
                  style: AppTheme.headingSmallThemed(context),
                ),
                const SizedBox(height: 4),
                Text(
                  'Takes 30 seconds. Your win rate, form and coaching unlock from here.',
                  style: AppTheme.bodySmallThemed(context),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppTheme.textMutedColor(context)),
        ],
      ),
    );
  }

  // ============ Recent activity ============

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent matches',
          actionLabel: 'View all',
          onAction: _openMatchHistory,
        ),
        const SizedBox(height: AppTheme.spaceSM),
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

  Widget _buildMatchItem(MatchPerformance match) {
    final isWin = match.result.toLowerCase() == 'win';
    final accent = isWin ? AppAccents.green : AppAccents.coral;

    return PressableCard(
      onTap: _openMatchHistory,
      semanticLabel: '${match.result} versus ${match.opponent}',
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        match.opponent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.headingSmallThemed(context)
                            .copyWith(fontSize: 17),
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
                const SizedBox(height: 3),
                Text(
                  '${_formatDate(match.date)} · ${match.surface} · ${match.matchFormat}',
                  style: AppTheme.bodySmallThemed(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          TonalChip(
            label: isWin ? 'Win' : 'Loss',
            color: accent,
          ),
        ],
      ),
    );
  }

  // ============ Coaching feature card ============

  Widget _buildCoachCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Coaching'),
        const SizedBox(height: AppTheme.spaceSM),
        PressableCard(
          onTap: _openCoach,
          padding: AppTheme.cardPaddingLarge,
          accent: AppAccents.violet,
          semanticLabel: 'Open Tactical Coach',
          child: Row(
            children: [
              const TonalIconBadge(
                icon: Icons.insights_rounded,
                color: AppAccents.violet,
                size: 52,
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Tactical Coach',
                          style: AppTheme.headingSmallThemed(context),
                        ),
                        const SizedBox(width: AppTheme.spaceSM),
                        const TonalChip(label: 'AI', color: AppAccents.violet),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patterns, what wins you points, and your next-match focus.',
                      style: AppTheme.bodySmallThemed(context),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMutedColor(context)),
            ],
          ),
        ),
      ],
    );
  }

  // ============ Skeletons ============

  Widget _buildHeroSkeleton() {
    return const SkeletonBox(height: 196, radius: AppTheme.radiusXL);
  }

  Widget _buildListSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 18, width: 140, radius: AppTheme.radiusSM),
        SizedBox(height: AppTheme.spaceMD),
        SkeletonBox(height: 68),
        SizedBox(height: AppTheme.spaceSM),
        SkeletonBox(height: 68),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
