import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import '../services/ui_style_service.dart';
import '../services/auth_service.dart';
import '../services/match_history_service.dart';
import '../services/streak_service.dart';
import '../models/match_performance.dart';
import 'tactical_coach_screen.dart';
import 'match_history_screen.dart';
import 'quick_match_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Home Screen — Apple-level minimal performance dashboard.
/// Near-monochrome, big type, generous space. Cards light up on press.
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

  Future<bool> _requireSignIn() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Text('Sign in to continue',
            style: AppTheme.headingSmallThemed(context)),
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
    final vibrant =
        context.watch<UiStyleService>().style == UiStyle.vibrant;
    final firstName = authService.isGuest
        ? 'Player'
        : (authService.userDisplayName?.split(' ').first ?? 'Player');

    final showSkeleton = _isLoading && !_hasLoadedOnce;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: Stack(
        children: [
          AmbientBackground(color: vibrant ? AppTheme.primary : null),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceLG),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (showSkeleton)
                          const SkeletonBox(
                              height: 188, radius: AppTheme.radiusXL)
                        else if (_totalMatches == 0)
                          _buildFirstMatchCard(vibrant)
                        else
                          _buildHeroCard(streakService, vibrant),
                        const SizedBox(height: AppTheme.spaceMD),
                        PrimaryActionButton(
                          label: 'Log a match',
                          icon: Icons.add_rounded,
                          onPressed: _openQuickMatch,
                        ),
                        const SizedBox(height: AppTheme.spaceXXL),
                        if (showSkeleton) ...[
                          _buildListSkeleton(),
                          const SizedBox(height: AppTheme.spaceXXL),
                        ] else if (_recentMatches.isNotEmpty) ...[
                          _buildRecentActivity(vibrant),
                          const SizedBox(height: AppTheme.spaceXXL),
                        ],
                        _buildCoachCard(vibrant),
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
        AppTheme.spaceLG,
        AppTheme.spaceLG,
        AppTheme.spaceMD,
        AppTheme.spaceLG,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting().toUpperCase(),
                  style: AppTheme.labelThemed(context)
                      .copyWith(letterSpacing: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  firstName,
                  style: AppTheme.headingLargeThemed(context)
                      .copyWith(height: 1.0, letterSpacing: -0.8),
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
                  AppTheme.cardBackground(context).withValues(alpha: 0.9),
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

  // ============ Hero KPI card (calm, monochrome, big type) ============

  Widget _buildHeroCard(StreakService streakService, bool vibrant) {
    final winPercentage = (_winRate * 100).round();
    final streakLabel = _currentStreak > 0
        ? 'On a roll'
        : _currentStreak < 0
            ? 'Bounce-back mode'
            : 'Fresh start';

    // Colour treatment differs by style; layout is shared.
    final onCard = vibrant ? Colors.white : AppTheme.textPrimaryColor(context);
    final onCardMuted =
        vibrant ? Colors.white70 : AppTheme.textMutedColor(context);
    final divider = vibrant
        ? Colors.white.withValues(alpha: 0.25)
        : AppTheme.borderColor(context);

    final decoration = vibrant
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: AppAccents.heroGradient(context),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          )
        : BoxDecoration(
            color: AppTheme.cardBackground(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: AppTheme.isDark(context) ? 0.22 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WIN RATE',
                  style: AppTheme.labelThemed(context)
                      .copyWith(letterSpacing: 1.4, color: onCardMuted)),
              Text(streakLabel,
                  style: AppTheme.bodySmallThemed(context)
                      .copyWith(color: onCardMuted)),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$winPercentage',
                style: AppTheme.statLargeThemed(context).copyWith(
                  fontSize: 76,
                  height: 0.95,
                  letterSpacing: -2.5,
                  color: onCard,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14, left: 2),
                child: Text('%',
                    style: AppTheme.statMediumThemed(context)
                        .copyWith(color: onCardMuted)),
              ),
              const Spacer(),
              if (_recentMatches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: _recentMatches.take(5).map((match) {
                      final isWin = match.result.toLowerCase() == 'win';
                      final Color dotColor;
                      final Color dotBorder;
                      if (vibrant) {
                        dotColor =
                            isWin ? AppAccents.green : Colors.transparent;
                        dotBorder = isWin ? AppAccents.green : Colors.white70;
                      } else {
                        dotColor = isWin ? onCard : Colors.transparent;
                        dotBorder = isWin ? onCard : onCardMuted;
                      }
                      return Container(
                        margin: const EdgeInsets.only(left: 6),
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                          border: Border.all(color: dotBorder, width: 1.4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Container(height: 1, color: divider),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              _buildHeroStat('$_totalMatches', 'Matches', onCard, onCardMuted),
              if (_currentStreak != 0)
                _buildHeroStat(
                  '${_currentStreak.abs()}',
                  _currentStreak > 0 ? 'Win streak' : 'To bounce back',
                  onCard,
                  onCardMuted,
                ),
              if (streakService.currentStreak > 0)
                _buildHeroStat('${streakService.currentStreak}', 'Day streak',
                    onCard, onCardMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(
      String value, String label, Color onCard, Color onCardMuted) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.statMediumThemed(context)
                .copyWith(fontSize: 24, letterSpacing: -0.5, color: onCard),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTheme.labelThemed(context).copyWith(color: onCardMuted)),
        ],
      ),
    );
  }

  // ============ Empty state (new user) ============

  Widget _buildFirstMatchCard(bool vibrant) {
    return PressableCard(
      onTap: _openQuickMatch,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      semanticLabel: 'Log your first match',
      accent: vibrant ? AppAccents.teal : null,
      child: Row(
        children: [
          TonalIconBadge(
              icon: Icons.sports_tennis_rounded,
              size: 52,
              color: vibrant ? AppAccents.teal : null),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Log your first match',
                    style: AppTheme.headingSmallThemed(context)),
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

  Widget _buildRecentActivity(bool vibrant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent matches',
          actionLabel: 'View all',
          onAction: _openMatchHistory,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        ...List.generate(
          _recentMatches.take(3).length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
            child: _buildMatchItem(_recentMatches[index], vibrant),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchItem(MatchPerformance match, bool vibrant) {
    final isWin = match.result.toLowerCase() == 'win';
    final winColor = vibrant ? AppAccents.green : AppTheme.textPrimaryColor(context);
    final lossColor = vibrant ? AppAccents.coral : AppTheme.textMutedColor(context);

    return PressableCard(
      onTap: _openMatchHistory,
      semanticLabel: '${match.result} versus ${match.opponent}',
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: isWin
                  ? winColor
                  : lossColor.withValues(alpha: 0.5),
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
                            .copyWith(fontSize: 17, letterSpacing: -0.2),
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
            filled: isWin,
            color: isWin ? winColor : lossColor,
          ),
        ],
      ),
    );
  }

  // ============ Coaching feature card ============

  Widget _buildCoachCard(bool vibrant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Coaching'),
        const SizedBox(height: AppTheme.spaceMD),
        PressableCard(
          onTap: _openCoach,
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          semanticLabel: 'Open Tactical Coach',
          accent: vibrant ? AppAccents.violet : null,
          child: Row(
            children: [
              TonalIconBadge(
                  icon: Icons.insights_rounded,
                  size: 52,
                  color: vibrant ? AppAccents.violet : null),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Tactical Coach',
                            style: AppTheme.headingSmallThemed(context)),
                        const SizedBox(width: AppTheme.spaceSM),
                        TonalChip(
                          label: 'AI',
                          filled: true,
                          color: AppTheme.primary,
                        ),
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

  Widget _buildListSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 18, width: 140, radius: AppTheme.radiusSM),
        SizedBox(height: AppTheme.spaceMD),
        SkeletonBox(height: 70),
        SizedBox(height: AppTheme.spaceSM),
        SkeletonBox(height: 70),
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
