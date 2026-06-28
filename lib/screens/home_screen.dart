import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import '../services/auth_service.dart';
import '../services/match_history_service.dart';
import '../services/streak_service.dart';
import '../models/match_performance.dart';
import 'tactical_coach_screen.dart';
import 'match_history_screen.dart';
import 'quick_match_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Home Screen — Broadcast.
/// A sports "match centre": high-contrast scoreboard hero, tabular numbers,
/// accent rules, uppercase labels, and fixtures-style result lists.
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
      final all = await _matchHistoryService.getAllMatches();
      final matches = all.take(10).toList();
      final winRate = await _matchHistoryService.getWinRate();
      final streak = _calculateStreak(matches);

      if (!mounted) return;
      setState(() {
        _recentMatches = matches;
        _winRate = winRate;
        _totalMatches = all.length;
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

  void _openSettings() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  bool _isWin(MatchPerformance m) => m.result.toLowerCase() == 'win';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final streakService = Provider.of<StreakService>(context);
    final firstName = authService.isGuest
        ? 'Player'
        : (authService.userDisplayName?.split(' ').first ?? 'Player');
    final showSkeleton = _isLoading && !_hasLoadedOnce;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: AppTheme.primary,
          backgroundColor: AppTheme.cardBackground(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _broadcastHeader(firstName)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG, 0,
                    AppTheme.spaceLG, AppTheme.spaceXXL),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    showSkeleton
                        ? const [
                            SkeletonBox(height: 150, radius: AppTheme.radiusSM),
                            SizedBox(height: AppTheme.spaceMD),
                            SkeletonBox(height: 84, radius: AppTheme.radiusSM),
                          ]
                        : _totalMatches == 0
                            ? [_broadcastEmpty()]
                            : _broadcastBody(streakService),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _broadcastHeader(String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG, AppTheme.spaceLG,
          AppTheme.spaceMD, AppTheme.spaceMD),
      child: Row(
        children: [
          Container(width: 4, height: 36, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATCH CENTRE',
                  style: AppTheme.labelThemed(context)
                      .copyWith(color: AppTheme.primary, letterSpacing: 2.5),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingMediumThemed(context).copyWith(
                      letterSpacing: -0.4, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openSettings,
            tooltip: 'Settings',
            iconSize: 22,
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: AppTheme.textSecondaryColor(context),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  List<Widget> _broadcastBody(StreakService streakService) {
    return [
      _broadcastHero(streakService),
      const SizedBox(height: AppTheme.spaceMD),
      _broadcastStatStrip(streakService),
      const SizedBox(height: AppTheme.spaceLG),
      _broadcastCta(),
      const SizedBox(height: AppTheme.spaceXL),
      if (_recentMatches.isNotEmpty) ...[
        _broadcastRecent(),
        const SizedBox(height: AppTheme.spaceXL),
      ],
      _broadcastCoachCard(),
    ];
  }

  Widget _broadcastHero(StreakService streakService) {
    final winPct = (_winRate * 100).round();
    final wins = (_winRate * _totalMatches).round();
    final losses = _totalMatches - wins;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border(
          left: BorderSide(color: AppTheme.primary, width: 3),
          top: BorderSide(color: AppTheme.borderColor(context)),
          right: BorderSide(color: AppTheme.borderColor(context)),
          bottom: BorderSide(color: AppTheme.borderColor(context)),
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('WIN %',
                  style: AppTheme.labelThemed(context)
                      .copyWith(color: AppTheme.primary, letterSpacing: 2)),
              const SizedBox(height: 2),
              Text(
                '$winPct',
                style: AppTheme.scorelineThemed(context, size: 68)
                    .copyWith(height: 0.95),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spaceLG),
          Container(
            width: 1,
            height: 92,
            color: AppTheme.borderColor(context),
          ),
          const SizedBox(width: AppTheme.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _broadcastHeroLine('RECORD', '$wins–$losses'),
                const SizedBox(height: 10),
                _broadcastHeroLine(
                    'DAY STREAK', '${streakService.currentStreak}'),
                const SizedBox(height: 14),
                _broadcastFormSquares(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _broadcastHeroLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTheme.labelThemed(context).copyWith(letterSpacing: 1.5)),
        Text(value, style: AppTheme.scorelineThemed(context, size: 18)),
      ],
    );
  }

  Widget _broadcastFormSquares() {
    final items = _recentMatches.take(8).toList().reversed.toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      children: items.map((m) {
        final isWin = _isWin(m);
        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            color: isWin ? AppTheme.win : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isWin ? AppTheme.win : AppTheme.loss,
              width: 1.6,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _broadcastStatStrip(StreakService streakService) {
    final last5Wins = _recentMatches.take(5).where(_isWin).length;
    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            _broadcastStatCell('MATCHES', '$_totalMatches'),
            _broadcastStripDivider(),
            _broadcastStatCell(
              _currentStreak >= 0 ? 'WIN RUN' : 'SKID',
              '${_currentStreak.abs()}',
            ),
            _broadcastStripDivider(),
            _broadcastStatCell('LAST 5', '$last5Wins/5'),
          ],
        ),
      ),
    );
  }

  Widget _broadcastStripDivider() =>
      Container(width: 1, color: AppTheme.borderColor(context));

  Widget _broadcastStatCell(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        child: Column(
          children: [
            Text(value, style: AppTheme.scorelineThemed(context, size: 26)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    AppTheme.labelThemed(context).copyWith(letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _broadcastCta() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _openQuickMatch();
      },
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppTheme.spaceSM),
            Text(
              'LOG A MATCH',
              style: AppTheme.headingSmall.copyWith(
                  color: Colors.white, fontSize: 16, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _broadcastRecent() {
    final items = _recentMatches.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECENT RESULTS',
                style: AppTheme.labelThemed(context).copyWith(
                    letterSpacing: 2,
                    color: AppTheme.textSecondaryColor(context))),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _openMatchHistory();
              },
              child: Text('VIEW ALL',
                  style: AppTheme.labelThemed(context)
                      .copyWith(color: AppTheme.primary, letterSpacing: 1.5)),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _broadcastMatchRow(items[i]),
                if (i != items.length - 1)
                  Divider(height: 1, color: AppTheme.borderColor(context)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _broadcastMatchRow(MatchPerformance m) {
    final isWin = _isWin(m);
    final color = isWin ? AppTheme.win : AppTheme.loss;
    final score =
        m.scoreLine.isNotEmpty ? m.scoreLine : '${m.setsWon}-${m.setsLost}';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _openMatchHistory();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceMD),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isWin ? 'W' : 'L',
                style: AppTheme.label
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.opponent,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.headingSmallThemed(context)
                        .copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text('${_formatDate(m.date)} · ${m.surface.toUpperCase()}',
                      style: AppTheme.labelThemed(context)),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Text(score, style: AppTheme.scorelineThemed(context, size: 17)),
          ],
        ),
      ),
    );
  }

  Widget _broadcastCoachCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openCoach();
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: AppTheme.elevatedBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border(
            left: BorderSide(color: AppTheme.primary, width: 3),
            top: BorderSide(color: AppTheme.borderColor(context)),
            right: BorderSide(color: AppTheme.borderColor(context)),
            bottom: BorderSide(color: AppTheme.borderColor(context)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.insights_rounded, color: AppTheme.primary, size: 26),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TACTICAL COACH',
                      style: AppTheme.labelThemed(context).copyWith(
                          letterSpacing: 2,
                          color: AppTheme.textPrimaryColor(context),
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('AI breakdown of your match patterns',
                      style: AppTheme.bodySmallThemed(context)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded,
                color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _broadcastEmpty() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _openQuickMatch();
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border(
            left: BorderSide(color: AppTheme.primary, width: 3),
            top: BorderSide(color: AppTheme.borderColor(context)),
            right: BorderSide(color: AppTheme.borderColor(context)),
            bottom: BorderSide(color: AppTheme.borderColor(context)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NO MATCHES YET',
                style: AppTheme.labelThemed(context)
                    .copyWith(color: AppTheme.primary, letterSpacing: 2)),
            const SizedBox(height: AppTheme.spaceSM),
            Text('Log your first match',
                style: AppTheme.headingMediumThemed(context)),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Your win rate, form and AI coaching all unlock from here.',
              style: AppTheme.bodyMediumThemed(context),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            _broadcastCta(),
          ],
        ),
      ),
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
