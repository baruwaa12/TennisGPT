import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/composure_kit.dart';
import '../widgets/ui_kit.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import 'quick_match_screen.dart';

/// Match History — ComposureDesign1.
/// Fixtures-style results list on the app canvas: a summary card up top, W/L
/// badges, mono scorelines with lost sets dimmed, skeleton loading.
///
/// Hierarchy: score first, opponent second, date + surface tertiary.
/// Goal: scan the list in under 2 seconds.
class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  List<MatchPerformance> _matches = [];
  Map<String, dynamic> _performanceTrends = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final matches = await _matchHistoryService.getAllMatches();
      final trends = await _matchHistoryService.getPerformanceTrends();

      if (!mounted) return;
      setState(() {
        _matches = matches;
        _performanceTrends = trends;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Couldn\'t load your matches. Pull to refresh.';
      });
    }
  }

  Future<void> _addNewMatch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuickMatchScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteMatch(String matchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBackground(dialogContext),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          side: BorderSide(color: AppTheme.borderColor(dialogContext)),
        ),
        title: Text('Delete match?',
            style: AppTheme.headingSmallThemed(dialogContext)),
        content: Text(
          'This action cannot be undone.',
          style: AppTheme.bodyMediumThemed(dialogContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: Text('Cancel',
                style: AppTheme.bodyMediumThemed(dialogContext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: Text('Delete',
                style: AppTheme.bodyMediumThemed(dialogContext)
                    .copyWith(color: AppTheme.loss, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _matchHistoryService.deleteMatch(matchId);
      HapticFeedback.lightImpact();
      _loadData();
    }
  }

  bool _isWin(MatchPerformance m) => m.result.toLowerCase() == 'win';

  String _score(MatchPerformance m) =>
      m.scoreLine.isNotEmpty ? m.scoreLine : '${m.setsWon}-${m.setsLost}';

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

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);

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
            onRefresh: _loadData,
            color: AppTheme.primary,
            backgroundColor: AppTheme.cardBackground(context),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _topBar()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.spaceLG, 0,
                      AppTheme.spaceLG, AppTheme.spaceXXL),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _isLoading
                          ? _skeleton()
                          : _matches.isEmpty
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

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceSM, AppTheme.spaceSM,
          AppTheme.spaceMD, AppTheme.spaceMD),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
            iconSize: 22,
            style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
            color: AppTheme.textSecondaryColor(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppTheme.spaceXS),
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('MATCH HISTORY',
                style: AppTheme.labelThemed(context).copyWith(
                    fontSize: 16,
                    letterSpacing: 2,
                    color: AppTheme.textPrimaryColor(context))),
          ),
          IconButton(
            onPressed: _addNewMatch,
            tooltip: 'Log a match',
            iconSize: 24,
            style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
            color: AppTheme.primary,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  List<Widget> _skeleton() {
    return const [
      SkeletonBox(height: 108, radius: AppTheme.radiusLG),
      SizedBox(height: AppTheme.spaceLG),
      SkeletonBox(height: 14, width: 140, radius: AppTheme.radiusSM),
      SizedBox(height: AppTheme.spaceSM),
      SkeletonBox(height: 72, radius: AppTheme.radiusLG),
      SizedBox(height: AppTheme.spaceSM),
      SkeletonBox(height: 72, radius: AppTheme.radiusLG),
      SizedBox(height: AppTheme.spaceSM),
      SkeletonBox(height: 72, radius: AppTheme.radiusLG),
    ];
  }

  List<Widget> _body() {
    return [
      if (_errorMessage != null) ...[
        _errorCard(),
        const SizedBox(height: AppTheme.spaceMD),
      ],
      if (_performanceTrends.isNotEmpty) ...[
        _summaryStrip(),
        const SizedBox(height: AppTheme.spaceLG),
      ],
      const CSectionHeader(title: 'All results'),
      const SizedBox(height: AppTheme.spaceXS),
      _fixturesList(),
    ];
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.loss.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.loss, size: 20),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(_errorMessage!,
                style: AppTheme.bodySmallThemed(context)
                    .copyWith(color: AppTheme.textSecondaryColor(context))),
          ),
        ],
      ),
    );
  }

  Widget _summaryStrip() {
    final totalMatches = _performanceTrends['totalMatches'] ?? 0;
    final winRate = (_performanceTrends['winRate'] ?? 0.0) as double;
    final favoriteSurface =
        (_performanceTrends['favoriteSurface'] ?? '—') as String;

    return IntrinsicHeight(
      child: TGCard(
        elevated: true,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _summaryCell('MATCHES', '$totalMatches'),
            _stripDivider(),
            _summaryCell('WIN %', '${(winRate * 100).round()}'),
            _stripDivider(),
            _summaryCell('BEST SURFACE', favoriteSurface.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _stripDivider() =>
      Container(width: 1, color: AppTheme.borderColor(context));

  Widget _summaryCell(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        child: Column(
          children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.scorelineThemed(context, size: 24)),
            const SizedBox(height: 4),
            Text(label,
                style: AppTheme.labelThemed(context).copyWith(
                    letterSpacing: 1.2,
                    color: AppTheme.textMutedColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _fixturesList() {
    return TGCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < _matches.length; i++) ...[
            _matchRow(_matches[i]),
            if (i != _matches.length - 1)
              Divider(height: 1, color: AppTheme.borderColor(context)),
          ],
        ],
      ),
    );
  }

  Widget _matchRow(MatchPerformance match) {
    final isWin = _isWin(match);
    final opponentName =
        match.opponent.trim().isNotEmpty ? match.opponent : 'Unknown opponent';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showMatchDetails(match);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMD, AppTheme.spaceMD, AppTheme.spaceXS,
            AppTheme.spaceMD),
        child: Row(
          children: [
            CResultBadge(isWin: isWin),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opponentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.headingSmallThemed(context)
                        .copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatDate(match.date)} · ${match.surface.toUpperCase()}',
                    style: AppTheme.labelThemed(context)
                        .copyWith(color: AppTheme.textMutedColor(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            _scoreline(_score(match)),
            SizedBox(
              width: 40,
              height: 44,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                tooltip: 'Match options',
                icon: Icon(Icons.more_vert_rounded,
                    color: AppTheme.textMutedColor(context), size: 18),
                color: AppTheme.elevatedBackground(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  side: BorderSide(color: AppTheme.borderColor(context)),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteMatch(match.id);
                  }
                },
                itemBuilder: (menuContext) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.loss, size: 20),
                        const SizedBox(width: AppTheme.spaceSM),
                        Text('Delete',
                            style: AppTheme.bodyMediumThemed(menuContext)
                                .copyWith(color: AppTheme.loss)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceXL),
      child: Semantics(
        label: 'No matches yet. Log your first match.',
        child: CEmptyState(
          eyebrow: 'No matches yet',
          title: 'Log your first match',
          message:
              'Every result you log builds your win rate, form and coaching.',
          action: CPrimaryButton(
            label: 'Log a match',
            icon: Icons.add_rounded,
            onPressed: _addNewMatch,
          ),
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

  void _showMatchDetails(MatchPerformance match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground(context),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLG)),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) =>
            _buildMatchDetailSheet(match, scrollController),
      ),
    );
  }

  Widget _buildMatchDetailSheet(
      MatchPerformance match, ScrollController scrollController) {
    final isWin = _isWin(match);
    final opponentName =
        match.opponent.trim().isNotEmpty ? match.opponent : 'Unknown opponent';
    final formatLabel =
        match.matchFormat.isNotEmpty ? match.matchFormat : 'Best of 3 sets';

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            children: [
              CResultBadge(isWin: isWin),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                isWin ? 'WIN' : 'LOSS',
                style: AppTheme.labelThemed(context).copyWith(
                  letterSpacing: 2,
                  color: isWin ? AppTheme.win : AppTheme.loss,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatDate(match.date)} · ${match.surface.toUpperCase()}',
                style: AppTheme.labelThemed(context)
                    .copyWith(color: AppTheme.textMutedColor(context)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'vs $opponentName',
            style: AppTheme.headingMediumThemed(context),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          _scoreline(_score(match), size: 36),
          const SizedBox(height: AppTheme.spaceXS),
          Text(formatLabel,
              style: AppTheme.labelThemed(context)
                  .copyWith(color: AppTheme.textMutedColor(context))),
          const SizedBox(height: AppTheme.spaceLG),
          Divider(color: AppTheme.borderColor(context)),
          const SizedBox(height: AppTheme.spaceLG),
          if (match.matchSummary.isNotEmpty) ...[
            Text('MATCH SUMMARY',
                style: AppTheme.labelThemed(context).copyWith(
                    letterSpacing: 2, color: AppTheme.textMutedColor(context))),
            const SizedBox(height: AppTheme.spaceSM),
            Text(match.matchSummary,
                style: AppTheme.bodyMediumThemed(context).copyWith(
                    color: AppTheme.textSecondaryColor(context), height: 1.55)),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          if (match.notes.isNotEmpty) ...[
            Text('NOTES',
                style: AppTheme.labelThemed(context).copyWith(
                    letterSpacing: 2, color: AppTheme.textMutedColor(context))),
            const SizedBox(height: AppTheme.spaceSM),
            Text(match.notes,
                style: AppTheme.bodyMediumThemed(context).copyWith(
                    color: AppTheme.textSecondaryColor(context), height: 1.55)),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          const SizedBox(height: AppTheme.spaceXXL),
        ],
      ),
    );
  }
}
