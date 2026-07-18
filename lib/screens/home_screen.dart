import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import '../widgets/composure_kit.dart';
import '../services/auth_service.dart';
import '../services/match_history_service.dart';
import '../models/match_performance.dart';
import 'tactical_coach_screen.dart';
import 'match_history_screen.dart';
import 'quick_match_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Home Screen — ComposureDesign1.
/// The "match centre": a win-rate hero, quick actions, recent results and the
/// tactical coach entry, styled with the ComposureDesign1 token system.
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
    final dark = AppTheme.isDark(context);
    final authService = Provider.of<AuthService>(context);
    final firstName = authService.isGuest
        ? 'Player'
        : (authService.userDisplayName?.split(' ').first ?? 'Player');
    final showSkeleton = _isLoading && !_hasLoadedOnce;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground(context),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadStats,
            color: AppTheme.primary,
            backgroundColor: AppTheme.cardBackground(context),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header(firstName)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG, 0,
                      AppTheme.spaceLG, AppTheme.spaceXXL),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      showSkeleton
                          ? const [
                              SkeletonBox(
                                  height: 150, radius: AppTheme.radiusLG),
                              SizedBox(height: AppTheme.spaceMD),
                              SkeletonBox(
                                  height: 84, radius: AppTheme.radiusLG),
                            ]
                          : _totalMatches == 0
                              ? [_emptyState()]
                              : _body(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG, AppTheme.spaceLG,
          AppTheme.spaceMD, AppTheme.spaceMD),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CEyebrow('Match Centre'),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingLargeThemed(context)
                      .copyWith(fontSize: 30),
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
              foregroundColor: AppTheme.textMutedColor(context),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  List<Widget> _body() {
    return [
      _hero(),
      const SizedBox(height: AppTheme.spaceLG),
      CPrimaryButton(
        label: 'Log a match',
        icon: Icons.add_rounded,
        onPressed: _openQuickMatch,
      ),
      const SizedBox(height: AppTheme.spaceXL),
      if (_recentMatches.isNotEmpty) ...[
        _recent(),
        const SizedBox(height: AppTheme.spaceXL),
      ],
      _coachCard(),
    ];
  }

  /// Form delta: win rate over the last 5 matches vs overall win rate.
  int? _formDeltaPct() {
    if (_totalMatches < 6 || _recentMatches.isEmpty) return null;
    final window = _recentMatches.take(5).toList();
    final windowRate = window.where(_isWin).length / window.length;
    return ((windowRate - _winRate) * 100).round();
  }

  Widget _hero() {
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

    return Semantics(
      label: semantics.toString(),
      child: TGCard(
        padding: AppTheme.cardPaddingLarge,
        elevated: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const CEyebrow('Win %'),
                const SizedBox(height: 2),
                Text(
                  '$winPct',
                  style: AppTheme.scorelineThemed(context, size: 64)
                      .copyWith(height: 0.95),
                ),
              ],
            ),
            const SizedBox(width: AppTheme.spaceLG),
            Container(
                width: 1, height: 92, color: AppTheme.borderColor(context)),
            const SizedBox(width: AppTheme.spaceLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _heroLine('Record', '$wins–$losses'),
                  if (formDelta != null) ...[
                    const SizedBox(height: 12),
                    _formLine(formDelta),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label.toUpperCase(),
            style: AppTheme.labelThemed(context).copyWith(
                letterSpacing: 1.4, color: AppTheme.textMutedColor(context))),
        Text(value,
            style: AppTheme.scorelineThemed(context, size: 18)),
      ],
    );
  }

  Widget _formLine(int delta) {
    final Color color;
    final IconData arrow;
    if (delta > 0) {
      color = AppTheme.win;
      arrow = Icons.arrow_upward_rounded;
    } else if (delta < 0) {
      color = AppTheme.loss;
      arrow = Icons.arrow_downward_rounded;
    } else {
      color = AppTheme.textMutedColor(context);
      arrow = Icons.arrow_forward_rounded;
    }
    final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('FORM',
            style: AppTheme.labelThemed(context).copyWith(
                letterSpacing: 1.4, color: AppTheme.textMutedColor(context))),
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

  Widget _recent() {
    final items = _recentMatches.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CSectionHeader(
          title: 'Recent results',
          actionLabel: 'View all',
          onAction: _openMatchHistory,
        ),
        const SizedBox(height: AppTheme.spaceXS),
        TGCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _matchRow(items[i]),
                if (i != items.length - 1)
                  Divider(height: 1, color: AppTheme.borderColor(context)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _matchRow(MatchPerformance m) {
    final isWin = _isWin(m);
    final score =
        m.scoreLine.isNotEmpty ? m.scoreLine : '${m.setsWon}-${m.setsLost}';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _openMatchHistory();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceMD),
        child: Row(
          children: [
            CResultBadge(isWin: isWin),
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
                      style: AppTheme.labelThemed(context).copyWith(
                          color: AppTheme.textMutedColor(context))),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            _scoreline(score),
          ],
        ),
      ),
    );
  }

  /// Monospace scoreline with lost sets dimmed so the eye lands on sets won.
  Widget _scoreline(String raw, {double size = 17}) {
    final sets = raw.trim().isEmpty
        ? const <String>[]
        : raw.trim().split(RegExp(r'\s+'));
    if (sets.isEmpty) {
      return Text('—', style: AppTheme.scorelineThemed(context, size: size));
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < sets.length; i++)
          Padding(
            padding:
                EdgeInsets.only(right: i == sets.length - 1 ? 0 : size * 0.32),
            child: Text(
              sets[i],
              style: AppTheme.scorelineThemed(context, size: size).copyWith(
                color: _wonSet(sets[i])
                    ? AppTheme.textPrimaryColor(context)
                    : AppTheme.textMutedColor(context).withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }

  bool _wonSet(String token) {
    final clean = token.replaceAll(RegExp(r'\(.*?\)'), '');
    final parts = clean.split('-');
    if (parts.length < 2) return true;
    final me = int.tryParse(parts[0].trim()) ?? 0;
    final opp = int.tryParse(parts[1].trim()) ?? 0;
    return me >= opp;
  }

  Widget _coachCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openCoach();
      },
      child: Semantics(
        button: true,
        label: 'Open tactical coach',
        child: Container(
          decoration: AppTheme.elevatedCardDecorationThemed(context),
          padding: AppTheme.cardPaddingLarge,
          child: Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: AppTheme.primary, size: 26),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tactical Coach',
                        style: AppTheme.headingSmallThemed(context)
                            .copyWith(fontSize: 16)),
                    const SizedBox(height: 3),
                    Text('AI breakdown of your match patterns',
                        style: AppTheme.bodySmallThemed(context)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppTheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return CEmptyState(
      eyebrow: 'No matches yet',
      title: 'Log your first match',
      message: 'Your win rate, form and AI coaching all unlock from here.',
      action: CPrimaryButton(
        label: 'Log a match',
        icon: Icons.add_rounded,
        onPressed: _openQuickMatch,
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
