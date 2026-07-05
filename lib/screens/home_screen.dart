import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/broadcast_theme.dart';
import '../widgets/broadcast_kit.dart';
import '../widgets/ui_kit.dart';
import '../services/auth_service.dart';
import '../services/match_history_service.dart';
import '../models/match_performance.dart';
import 'tactical_coach_screen.dart';
import 'match_history_screen.dart';
import 'quick_match_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Home Screen — Broadcast.
/// A sports "match centre" rendered on a dark TV-graphics canvas: high-contrast
/// scoreboard hero, tabular numbers, electric-lime accent rules, uppercase
/// labels, and fixtures-style result lists.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MatchHistoryService _matchHistoryService = MatchHistoryService();

  List<MatchPerformance> _recentMatches = [];
  double _winRate = 0.0;
  int _totalMatches = 0;
  bool _isLoading = true;
  bool _hasLoadedOnce = false;

  late BroadcastTheme _bc;

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

      if (!mounted) return;
      setState(() {
        _recentMatches = matches;
        _winRate = winRate;
        _totalMatches = all.length;
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
    _bc = BroadcastTheme.of(context);

    final authService = Provider.of<AuthService>(context);
    final firstName = authService.isGuest
        ? 'Player'
        : (authService.userDisplayName?.split(' ').first ?? 'Player');
    final showSkeleton = _isLoading && !_hasLoadedOnce;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _bc.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: _bc.dark ? Brightness.dark : Brightness.light,
      ),
      child: Theme(
        data: _bc.themeData,
        child: Scaffold(
          backgroundColor: _bc.bg,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              color: _bc.accentInk,
              backgroundColor: _bc.panel,
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
                                SkeletonBox(
                                    height: 150, radius: AppTheme.radiusSM),
                                SizedBox(height: AppTheme.spaceMD),
                                SkeletonBox(
                                    height: 84, radius: AppTheme.radiusSM),
                              ]
                            : _totalMatches == 0
                                ? [_broadcastEmpty()]
                                : _broadcastBody(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          Container(width: 4, height: 36, color: _bc.accentInk),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATCH CENTRE',
                  style: AppTheme.labelThemed(context)
                      .copyWith(color: _bc.accentInk, letterSpacing: 2.5),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingMediumThemed(context).copyWith(
                      letterSpacing: -0.4,
                      fontWeight: FontWeight.w700,
                      color: _bc.textPrimary),
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
              foregroundColor: _bc.textMuted,
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  List<Widget> _broadcastBody() {
    return [
      _broadcastHero(),
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

  /// Form delta: win rate over the last 5 matches vs overall win rate.
  /// Positive means the player is trending above their baseline.
  /// Returns null when there isn't enough history for it to mean anything.
  int? _formDeltaPct() {
    if (_totalMatches < 6 || _recentMatches.isEmpty) return null;
    final window = _recentMatches.take(5).toList();
    final windowRate = window.where(_isWin).length / window.length;
    return ((windowRate - _winRate) * 100).round();
  }

  Widget _broadcastHero() {
    final winPct = (_winRate * 100).round();
    final wins = (_winRate * _totalMatches).round();
    final losses = _totalMatches - wins;
    final formDelta = _formDeltaPct();

    final semantics = StringBuffer(
        'Win rate $winPct percent, record $wins and $losses');
    if (formDelta != null) {
      semantics.write(
          ', form ${formDelta >= 0 ? "up" : "down"} ${formDelta.abs()} percent');
    }

    return BroadcastPanel(
      bc: _bc,
      accentRule: true,
      semanticLabel: semantics.toString(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('WIN %',
                  style: AppTheme.labelThemed(context)
                      .copyWith(color: _bc.accentInk, letterSpacing: 2)),
              const SizedBox(height: 2),
              Text(
                '$winPct',
                style: AppTheme.scorelineThemed(context, size: 68)
                    .copyWith(height: 0.95, color: _bc.textPrimary),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spaceLG),
          Container(width: 1, height: 92, color: _bc.border),
          const SizedBox(width: AppTheme.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _broadcastHeroLine('RECORD', '$wins–$losses'),
                if (formDelta != null) ...[
                  const SizedBox(height: 12),
                  _broadcastFormLine(formDelta),
                ],
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
            style: AppTheme.labelThemed(context)
                .copyWith(letterSpacing: 1.5, color: _bc.textMuted)),
        Text(value,
            style: AppTheme.scorelineThemed(context, size: 18)
                .copyWith(color: _bc.textPrimary)),
      ],
    );
  }

  Widget _broadcastFormLine(int delta) {
    final Color color;
    final IconData arrow;
    if (delta > 0) {
      color = _bc.win;
      arrow = Icons.arrow_upward_rounded;
    } else if (delta < 0) {
      color = _bc.loss;
      arrow = Icons.arrow_downward_rounded;
    } else {
      color = _bc.textMuted;
      arrow = Icons.arrow_forward_rounded;
    }
    final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('FORM',
            style: AppTheme.labelThemed(context)
                .copyWith(letterSpacing: 1.5, color: _bc.textMuted)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(arrow, size: 15, color: color),
            const SizedBox(width: 3),
            Text('$sign${delta.abs()}%',
                style: AppTheme.scorelineThemed(context, size: 18)
                    .copyWith(color: color)),
          ],
        ),
      ],
    );
  }

  Widget _broadcastCta() {
    return BroadcastCta(
      label: 'LOG A MATCH',
      icon: Icons.add_rounded,
      onPressed: _openQuickMatch,
    );
  }

  Widget _broadcastRecent() {
    final items = _recentMatches.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BroadcastSectionHeader(
          bc: _bc,
          title: 'Recent results',
          actionLabel: 'View all',
          onAction: _openMatchHistory,
        ),
        const SizedBox(height: AppTheme.spaceXS),
        BroadcastPanel(
          bc: _bc,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _broadcastMatchRow(items[i]),
                if (i != items.length - 1)
                  Divider(height: 1, color: _bc.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _broadcastMatchRow(MatchPerformance m) {
    final isWin = _isWin(m);
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
            BroadcastResultBadge(bc: _bc, isWin: isWin),
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
                        .copyWith(fontSize: 16, color: _bc.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text('${_formatDate(m.date)} · ${m.surface.toUpperCase()}',
                      style: AppTheme.labelThemed(context)
                          .copyWith(color: _bc.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            BroadcastScoreline(bc: _bc, raw: score),
          ],
        ),
      ),
    );
  }

  Widget _broadcastCoachCard() {
    return BroadcastPanel(
      bc: _bc,
      raised: true,
      onTap: _openCoach,
      semanticLabel: 'Open tactical coach',
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: _bc.accentInk, size: 26),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TACTICAL COACH',
                    style: AppTheme.labelThemed(context).copyWith(
                        letterSpacing: 2,
                        color: _bc.textPrimary,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text('AI breakdown of your match patterns',
                    style: AppTheme.bodySmallThemed(context)
                        .copyWith(color: _bc.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: _bc.accentInk, size: 20),
        ],
      ),
    );
  }

  Widget _broadcastEmpty() {
    return BroadcastPanel(
      bc: _bc,
      semanticLabel: 'No matches yet. Log your first match.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NO MATCHES YET',
              style: AppTheme.labelThemed(context)
                  .copyWith(color: _bc.accentInk, letterSpacing: 2)),
          const SizedBox(height: AppTheme.spaceSM),
          Text('Log your first match',
              style: AppTheme.headingMediumThemed(context)
                  .copyWith(color: _bc.textPrimary)),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            'Your win rate, form and AI coaching all unlock from here.',
            style: AppTheme.bodyMediumThemed(context)
                .copyWith(color: _bc.textSecondary),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          _broadcastCta(),
        ],
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
