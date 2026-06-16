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
  List<MatchPerformance> _allMatches = [];
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
      final all = await _matchHistoryService.getAllMatches();
      final matches = all.take(10).toList();
      final winRate = await _matchHistoryService.getWinRate();
      final total = all.length;
      final streak = _calculateStreak(matches);

      if (!mounted) return;
      setState(() {
        _allMatches = all;
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
    final style = context.watch<UiStyleService>().style;
    final vibrant = style == UiStyle.vibrant;
    final authored = style == UiStyle.authored;
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
                  SliverToBoxAdapter(
                    child: authored
                        ? _buildAuthoredHeader(firstName)
                        : _buildHeader(firstName, vibrant),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceLG),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        authored
                            ? _buildAuthoredBody(streakService, showSkeleton)
                            : vibrant
                                ? _buildVibrantBody(streakService, showSkeleton)
                                : _buildMinimalBody(streakService, showSkeleton),
                      ),
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

  Widget _buildHeader(String firstName, bool vibrant) {
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
          if (vibrant) ...[
            CircleAvatar(
              radius: 22,
              backgroundColor: AppAccents.tint(AppTheme.primary, alpha: 0.18),
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
                style: AppTheme.headingSmallThemed(context)
                    .copyWith(color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
          ],
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
                  vibrant ? '$firstName 👋' : firstName,
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

  // ====================================================================
  //  VIBRANT — energetic (Strava / Nike / Duolingo):
  //  gradient ring hero, colour stat grid, bold cards, punchy feature card.
  // ====================================================================

  List<Widget> _buildVibrantBody(
      StreakService streakService, bool showSkeleton) {
    return [
      if (showSkeleton)
        const SkeletonBox(height: 168, radius: AppTheme.radiusXL)
      else if (_totalMatches == 0)
        _buildFirstMatchCard(true)
      else ...[
        _buildVibrantHero(streakService),
        const SizedBox(height: AppTheme.spaceMD),
        _buildVibrantStatGrid(streakService),
      ],
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
        SectionHeader(
          title: 'Recent matches',
          actionLabel: 'View all',
          onAction: _openMatchHistory,
        ),
        const SizedBox(height: AppTheme.spaceMD),
        ..._recentMatches.take(3).map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
                child: _buildVibrantMatchCard(m),
              ),
            ),
        const SizedBox(height: AppTheme.spaceXXL),
      ],
      _buildVibrantCoachCard(),
      const SizedBox(height: AppTheme.spaceXXL),
    ];
  }

  Widget _buildVibrantHero(StreakService streakService) {
    final winPct = (_winRate * 100).round();
    final hasStreak = _currentStreak != 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppAccents.heroGradient(context),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.34),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          StatRing(progress: _winRate, value: '$winPct', label: 'WIN %', size: 116),
          const SizedBox(width: AppTheme.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasStreak)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentStreak > 0
                              ? Icons.local_fire_department_rounded
                              : Icons.refresh_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _currentStreak > 0
                              ? '${_currentStreak.abs()} win streak'
                              : '${_currentStreak.abs()} to bounce back',
                          style: AppTheme.label.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  '$_totalMatches matches played',
                  style: AppTheme.headingSmall
                      .copyWith(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Row(
                  children: _recentMatches.take(5).map((match) {
                    final isWin = match.result.toLowerCase() == 'win';
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isWin ? Colors.white : Colors.transparent,
                        border:
                            Border.all(color: Colors.white70, width: 1.4),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibrantStatGrid(StreakService streakService) {
    final last5Wins = _recentMatches
        .take(5)
        .where((m) => m.result.toLowerCase() == 'win')
        .length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.sports_tennis_rounded,
                value: '$_totalMatches',
                label: 'Matches',
                color: AppAccents.blue,
                onTap: _openMatchHistory,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: StatTile(
                icon: _currentStreak >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                value: '${_currentStreak.abs()}',
                label: _currentStreak >= 0 ? 'Win streak' : 'Skid',
                color: _currentStreak >= 0 ? AppAccents.green : AppAccents.coral,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMD),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.local_fire_department_rounded,
                value: '${streakService.currentStreak}',
                label: 'Day streak',
                color: AppAccents.amber,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: StatTile(
                icon: Icons.bolt_rounded,
                value: '$last5Wins/5',
                label: 'Last 5 form',
                color: AppAccents.violet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVibrantMatchCard(MatchPerformance match) {
    final isWin = match.result.toLowerCase() == 'win';
    final color = isWin ? AppAccents.green : AppAccents.coral;

    return PressableCard(
      onTap: _openMatchHistory,
      accent: color,
      semanticLabel: '${match.result} versus ${match.opponent}',
      child: Row(
        children: [
          Container(
            width: 6,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.opponent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingSmallThemed(context)
                      .copyWith(fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDate(match.date)} · ${match.surface}',
                  style: AppTheme.bodySmallThemed(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TonalChip(label: isWin ? 'Win' : 'Loss', color: color),
              const SizedBox(height: 4),
              Text(
                match.scoreLine.isNotEmpty
                    ? match.scoreLine
                    : '${match.setsWon}-${match.setsLost}',
                style: AppTheme.bodySmallThemed(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVibrantCoachCard() {
    final radius = BorderRadius.circular(AppTheme.radiusXL);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          HapticFeedback.lightImpact();
          _openCoach();
        },
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppAccents.violet, AppAccents.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: AppAccents.violet.withValues(alpha: 0.34),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask your Tactical Coach',
                      style: AppTheme.headingSmall
                          .copyWith(color: Colors.white, fontSize: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'AI-spotted patterns and your next-match focus.',
                      style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  // ====================================================================
  //  MINIMAL — editorial (Oura / Whoop / Linear):
  //  giant type, thin form bar, hairline-divided lists, quiet rows.
  // ====================================================================

  List<Widget> _buildMinimalBody(
      StreakService streakService, bool showSkeleton) {
    return [
      if (showSkeleton)
        const SkeletonBox(height: 150, radius: AppTheme.radiusXL)
      else if (_totalMatches == 0)
        _buildFirstMatchCard(false)
      else
        _buildMinimalHero(streakService),
      const SizedBox(height: AppTheme.spaceXL),
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
        _buildMinimalRecentList(),
        const SizedBox(height: AppTheme.spaceXXL),
      ],
      _buildMinimalCoachRow(),
      const SizedBox(height: AppTheme.spaceXXL),
    ];
  }

  Widget _buildMinimalHero(StreakService streakService) {
    final winPct = (_winRate * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WIN RATE',
            style: AppTheme.labelThemed(context).copyWith(letterSpacing: 1.6)),
        const SizedBox(height: AppTheme.spaceXS),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$winPct',
              style: AppTheme.statLargeThemed(context).copyWith(
                fontSize: 92,
                height: 0.9,
                letterSpacing: -3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 2),
              child: Text('%',
                  style: AppTheme.statMediumThemed(context)
                      .copyWith(color: AppTheme.textMutedColor(context))),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLG),
        _buildFormBar(),
        const SizedBox(height: AppTheme.spaceLG),
        IntrinsicHeight(
          child: Row(
            children: [
              _miniStat('$_totalMatches', 'Matches'),
              _vDivider(),
              _miniStat(
                '${_currentStreak.abs()}',
                _currentStreak >= 0 ? 'Win streak' : 'Skid',
              ),
              _vDivider(),
              _miniStat('${streakService.currentStreak}', 'Day streak'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormBar() {
    final items = _recentMatches.take(8).toList().reversed.toList();
    return Row(
      children: items.map((match) {
        final isWin = match.result.toLowerCase() == 'win';
        return Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: isWin
                  ? AppTheme.textPrimaryColor(context)
                  : AppTheme.borderColor(context),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.statMediumThemed(context)
                .copyWith(fontSize: 24, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.labelThemed(context)),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      color: AppTheme.borderColor(context),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
    );
  }

  Widget _buildMinimalRecentList() {
    final items = _recentMatches.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent',
          actionLabel: 'View all',
          onAction: _openMatchHistory,
        ),
        const SizedBox(height: AppTheme.spaceXS),
        for (int i = 0; i < items.length; i++) ...[
          _buildMinimalMatchRow(items[i]),
          if (i != items.length - 1)
            Divider(height: 1, color: AppTheme.borderColor(context)),
        ],
      ],
    );
  }

  Widget _buildMinimalMatchRow(MatchPerformance match) {
    final isWin = match.result.toLowerCase() == 'win';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _openMatchHistory();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.opponent,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.headingSmallThemed(context)
                        .copyWith(fontSize: 17, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatDate(match.date)} · ${match.surface}',
                    style: AppTheme.bodySmallThemed(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isWin ? 'Win' : 'Loss',
                  style: AppTheme.headingSmallThemed(context).copyWith(
                    fontSize: 15,
                    color: isWin
                        ? AppTheme.textPrimaryColor(context)
                        : AppTheme.textMutedColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  match.scoreLine.isNotEmpty
                      ? match.scoreLine
                      : '${match.setsWon}-${match.setsLost}',
                  style: AppTheme.bodySmallThemed(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalCoachRow() {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _openCoach();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.borderColor(context)),
            bottom: BorderSide(color: AppTheme.borderColor(context)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.insights_rounded,
                color: AppTheme.textSecondaryColor(context), size: 22),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tactical Coach',
                      style: AppTheme.headingSmallThemed(context)
                          .copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('AI insight from your matches',
                      style: AppTheme.bodySmallThemed(context)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMutedColor(context)),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  //  AUTHORED — deliberately de-genericized.
  //  Leads with the SCORELINE (mono), rivalries instead of a stat grid,
  //  court-surface accents, a net-tick baseline, and demoted chrome.
  //  Hand-composed spacing on the hero (off the 4px grid on purpose).
  // ====================================================================

  Widget _buildAuthoredHeader(String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLG, AppTheme.spaceLG, AppTheme.spaceMD, AppTheme.spaceSM),
      child: Row(
        children: [
          Expanded(
            child: Text(
              firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLargeThemed(context).copyWith(
                color: AppTheme.textSecondaryColor(context),
                fontWeight: FontWeight.w600,
              ),
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
              foregroundColor: AppTheme.textMutedColor(context),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAuthoredBody(
      StreakService streakService, bool showSkeleton) {
    if (showSkeleton) {
      return const [
        SkeletonBox(height: 196, radius: AppTheme.radiusLG),
        SizedBox(height: 28),
        SkeletonBox(height: 70),
        SizedBox(height: AppTheme.spaceXXL),
      ];
    }

    if (_totalMatches == 0) {
      return [
        _buildFirstMatchCard(false),
        const SizedBox(height: AppTheme.spaceXXL),
      ];
    }

    final rivalries = _rivalries();

    return [
      _buildLastMatchHero(_recentMatches.first),
      const SizedBox(height: 18),
      _buildAuthoredFormLine(),
      const SizedBox(height: 34),
      _authoredTextAction(
        icon: Icons.add_rounded,
        label: 'Log a match',
        onTap: _openQuickMatch,
      ),
      const SizedBox(height: 36),
      if (rivalries.isNotEmpty) ...[
        _buildRivalryStrip(rivalries),
        const SizedBox(height: 36),
      ],
      if (_recentMatches.length > 1) ...[
        _buildAuthoredRecentList(),
        const SizedBox(height: 30),
      ],
      _buildAuthoredCoachAction(),
      const SizedBox(height: AppTheme.spaceXXL),
    ];
  }

  /// The hero is the match, not a metric. The biggest object on screen is the
  /// actual scoreline of the last match — lost sets dimmed — set in mono.
  Widget _buildLastMatchHero(MatchPerformance m) {
    final isWin = m.result.toLowerCase() == 'win';
    final accent = AppTheme.surfaceAccent(m.surface);
    final score = m.scoreLine.isNotEmpty
        ? m.scoreLine
        : '${m.setsWon}-${m.setsLost}';

    return Padding(
      // Hand-composed, off the spacing scale, no card chrome.
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LAST MATCH',
                style: AppTheme.labelThemed(context).copyWith(letterSpacing: 2),
              ),
              const Spacer(),
              _surfaceTag(m.surface, accent),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isWin ? 'Beat' : 'Lost to',
                style: AppTheme.bodyMediumThemed(context)
                    .copyWith(color: AppTheme.textMutedColor(context)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  m.opponent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingMediumThemed(context)
                      .copyWith(letterSpacing: -0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScoreline(score, size: 46),
          const SizedBox(height: 22),
          _courtBaseline(),
        ],
      ),
    );
  }

  /// The scoreline lockup — mono, large, lost sets dimmed. Pure typography
  /// doing identity work: instantly, unmistakably tennis.
  Widget _buildScoreline(String raw, {double size = 30}) {
    final sets = raw.trim().isEmpty
        ? const <String>[]
        : raw.trim().split(RegExp(r'\s+'));
    if (sets.isEmpty) {
      return Text('—', style: AppTheme.scorelineThemed(context, size: size));
    }
    final won = AppTheme.textPrimaryColor(context);
    final lost = AppTheme.textMutedColor(context).withValues(alpha: 0.5);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final s in sets)
          Padding(
            padding: EdgeInsets.only(right: size * 0.32),
            child: Text(
              s,
              style: AppTheme.scorelineThemed(
                context,
                size: size,
                color: _playerWonSet(s) ? won : lost,
              ),
            ),
          ),
      ],
    );
  }

  bool _playerWonSet(String token) {
    final clean = token.replaceAll(RegExp(r'\(.*?\)'), '');
    final parts = clean.split('-');
    if (parts.length < 2) return true;
    final me = int.tryParse(parts[0].trim()) ?? 0;
    final opp = int.tryParse(parts[1].trim()) ?? 0;
    return me >= opp;
  }

  /// Court-colour language: a small accent dot + surface name. Not a theme.
  Widget _surfaceTag(String surface, Color accent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          surface.toUpperCase(),
          style: AppTheme.labelThemed(context)
              .copyWith(color: accent, letterSpacing: 1.2),
        ),
      ],
    );
  }

  /// The only "decoration" — a thin rule with a center net tick, borrowed from
  /// the court, not from a design library.
  Widget _courtBaseline() {
    final line = AppTheme.borderColor(context);
    return SizedBox(
      height: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Container(height: 1, color: line)),
          Container(width: 1, height: 8, color: line),
          Expanded(child: Container(height: 1, color: line)),
        ],
      ),
    );
  }

  /// Win rate demoted: a quiet W L W L row instead of a hero ring.
  Widget _buildAuthoredFormLine() {
    final items = _recentMatches.take(8).toList().reversed.toList();
    final winPct = (_winRate * 100).round();
    final secondary = AppTheme.textSecondaryColor(context);
    final muted = AppTheme.textMutedColor(context).withValues(alpha: 0.45);

    return Row(
      children: [
        for (final m in items)
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: Text(
              m.result.toLowerCase() == 'win' ? 'W' : 'L',
              style: AppTheme.scorelineThemed(
                context,
                size: 13,
                color: m.result.toLowerCase() == 'win' ? secondary : muted,
              ),
            ),
          ),
        const Spacer(),
        Text('$winPct% win rate', style: AppTheme.bodySmallThemed(context)),
      ],
    );
  }

  Widget _authoredTextAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.headingSmallThemed(context)
                  .copyWith(fontSize: 16, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  /// Rivalries replaced the stat grid. A head-to-head strip can only exist in
  /// a tennis app — structure that can't be ported is structure with identity.
  Widget _buildRivalryStrip(List<_Rivalry> rivalries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RIVALRIES',
          style: AppTheme.labelThemed(context).copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < rivalries.length; i++) ...[
          _buildRivalryRow(rivalries[i]),
          if (i != rivalries.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildRivalryRow(_Rivalry r) {
    final leading = r.wins >= r.losses;
    final primary = AppTheme.textPrimaryColor(context);
    final muted = AppTheme.textMutedColor(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _openMatchHistory();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                r.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.headingSmallThemed(context)
                    .copyWith(fontSize: 17, letterSpacing: -0.2),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                Text('${r.wins}',
                    style: AppTheme.scorelineThemed(context,
                        size: 18, color: leading ? primary : muted)),
                Text('–',
                    style: AppTheme.scorelineThemed(context,
                        size: 18, color: muted)),
                Text('${r.losses}',
                    style: AppTheme.scorelineThemed(context,
                        size: 18, color: leading ? muted : primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_Rivalry> _rivalries() {
    final Map<String, _Rivalry> map = {};
    for (final m in _allMatches) {
      final name = m.opponent.trim();
      if (name.isEmpty || name.toLowerCase() == 'unknown') continue;
      final key = name.toLowerCase();
      final r = map[key] ?? _Rivalry(name);
      if (m.result.toLowerCase() == 'win') {
        r.wins++;
      } else {
        r.losses++;
      }
      map[key] = r;
    }
    final list = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list.take(3).toList();
  }

  Widget _buildAuthoredRecentList() {
    final items = _recentMatches.skip(1).take(4).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Earlier',
          actionLabel: 'View all',
          onAction: _openMatchHistory,
        ),
        const SizedBox(height: 6),
        for (final m in items) _buildAuthoredMatchRow(m),
      ],
    );
  }

  Widget _buildAuthoredMatchRow(MatchPerformance m) {
    final isWin = m.result.toLowerCase() == 'win';
    final accent = AppTheme.surfaceAccent(m.surface);
    final score = m.scoreLine.isNotEmpty
        ? m.scoreLine
        : '${m.setsWon}-${m.setsLost}';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _openMatchHistory();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isWin ? 'Beat' : 'Lost to'} ${m.opponent}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyMediumThemed(context)
                        .copyWith(color: AppTheme.textPrimaryColor(context)),
                  ),
                  const SizedBox(height: 2),
                  Text('${_formatDate(m.date)} · ${m.surface}',
                      style: AppTheme.bodySmallThemed(context)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildScoreline(score, size: 17),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthoredCoachAction() {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _openCoach();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ask your Tactical Coach',
                      style: AppTheme.headingSmallThemed(context)
                          .copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('Patterns from your matches, your next-match focus',
                      style: AppTheme.bodySmallThemed(context)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded,
                size: 18, color: AppTheme.primary),
          ],
        ),
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

/// Aggregated head-to-head record against one opponent (Authored style).
class _Rivalry {
  _Rivalry(this.name);

  final String name;
  int wins = 0;
  int losses = 0;

  int get total => wins + losses;
}
