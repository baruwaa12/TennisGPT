import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import 'quick_match_screen.dart';

/// Match History Screen
/// 
/// UX Philosophy: Scannable, personal, premium
/// 
/// Hierarchy:
/// 1. Score - most visually prominent
/// 2. Opponent name - second
/// 3. Date + surface - tertiary
/// 
/// Goal: Scan match list in under 2 seconds
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
      
      setState(() {
        _matches = matches;
        _performanceTrends = trends;
        _isLoading = false;
      });
    } catch (e) {
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
        backgroundColor: AppTheme.elevatedBackground(dialogContext),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Text('Delete match?', style: AppTheme.headingMediumThemed(dialogContext)),
        content: Text(
          'This action cannot be undone.',
          style: AppTheme.bodyMediumThemed(dialogContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: AppTheme.bodyMediumThemed(dialogContext).copyWith(color: AppTheme.textSecondaryColor(dialogContext))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: AppTheme.bodyMediumThemed(dialogContext).copyWith(color: AppTheme.loss)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground(context),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppTheme.scaffoldBackground(context),
            elevation: 0,
            pinned: true,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.textSecondaryColor(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Match History',
              style: AppTheme.headingSmallThemed(context).copyWith(color: AppTheme.textSecondaryColor(context)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
                onPressed: _addNewMatch,
                tooltip: 'Quick Match Log',
              ),
            ],
          ),
          
          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (_matches.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: AppTheme.screenPadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Error message
                  if (_errorMessage != null) ...[
                    _buildErrorCard(),
                    const SizedBox(height: AppTheme.spaceMD),
                  ],
                  
                  // Performance Summary
                  if (_performanceTrends.isNotEmpty) ...[
                    _buildPerformanceSummary(),
                    const SizedBox(height: AppTheme.spaceLG),
                  ],
                  
                  // Section header
                  Text('Recent matches', style: AppTheme.headingMediumThemed(context)),
                  const SizedBox(height: AppTheme.spaceMD),
                  
                  // Match List
                  ..._matches.map((match) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
                    child: _buildMatchRow(match),
                  )),
                  
                  const SizedBox(height: AppTheme.spaceXL),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_tennis_rounded,
                size: 48,
                color: AppTheme.textMutedColor(context),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Text(
              'No matches yet',
              style: AppTheme.headingMediumThemed(context),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Log your first match to start tracking progress',
              style: AppTheme.bodyMediumThemed(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceLG),
            GestureDetector(
              onTap: _addNewMatch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLG,
                  vertical: AppTheme.spaceMD,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Text(
                  'Quick Match Log',
                  style: AppTheme.headingSmallThemed(context).copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.loss.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.loss.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.loss, size: 20),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(_errorMessage!, style: AppTheme.bodySmallThemed(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    final totalMatches = _performanceTrends['totalMatches'] ?? 0;
    final winRate = _performanceTrends['winRate'] ?? 0.0;
    final favoriteSurface = _performanceTrends['favoriteSurface'] ?? 'Unknown';

    return Container(
      padding: AppTheme.cardPaddingLarge,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance', style: AppTheme.headingSmallThemed(context)),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: 'Matches',
                  value: totalMatches.toString(),
                  icon: Icons.sports_tennis_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppTheme.borderColor(context),
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Win rate',
                  value: '${(winRate * 100).toStringAsFixed(0)}%',
                  icon: Icons.trending_up_rounded,
                  valueColor: winRate >= 0.5 ? AppTheme.win : AppTheme.warning,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppTheme.borderColor(context),
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Best surface',
                  value: favoriteSurface,
                  icon: Icons.grid_on_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.textMutedColor(context)),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          value,
          style: AppTheme.statMediumThemed(context).copyWith(
            color: valueColor,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(label, style: AppTheme.labelThemed(context)),
      ],
    );
  }

  /// Match row — compact card with clear hierarchy:
  /// Row 1: Opponent name
  /// Row 2: Date · Surface · Format (tertiary)
  /// Row 3: Score (centered, bold)
  /// Left: win/loss vertical indicator
  Widget _buildMatchRow(MatchPerformance match) {
    final isWin = match.result.toLowerCase() == 'win';
    final opponentName = match.opponent.trim().isNotEmpty 
        ? match.opponent 
        : 'Unknown opponent';
    final dateStr = _formatDate(match.date);
    final scoreDisplay = match.scoreLine.isNotEmpty
        ? match.scoreLine
        : '${match.setsWon}–${match.setsLost}';
    final formatLabel = match.matchFormat.isNotEmpty
        ? match.matchFormat
        : 'BO3';
    
    return GestureDetector(
      onTap: () => _showMatchDetails(match),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Win/Loss vertical indicator
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isWin ? AppTheme.win : AppTheme.loss,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Opponent + menu
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opponentName,
                            style: AppTheme.headingSmallThemed(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.more_vert_rounded, 
                                color: AppTheme.textMutedColor(context), size: 18),
                            color: AppTheme.elevatedBackground(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
                                    Icon(Icons.delete_outline_rounded, color: AppTheme.loss, size: 20),
                                    const SizedBox(width: AppTheme.spaceSM),
                                    Text('Delete', style: AppTheme.bodyMediumThemed(menuContext).copyWith(color: AppTheme.loss)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Row 2: Date · Surface · Format
                    Text(
                      '$dateStr · ${match.surface} · $formatLabel',
                      style: AppTheme.labelThemed(context),
                    ),
                    const SizedBox(height: 8),
                    // Row 3: Score centered
                    Center(
                      child: Text(
                        scoreDisplay,
                        style: AppTheme.headingMediumThemed(context).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: 0.5,
                          color: isWin ? AppTheme.win : AppTheme.loss,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showMatchDetails(MatchPerformance match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _buildMatchDetailSheet(match, scrollController),
      ),
    );
  }

  Widget _buildMatchDetailSheet(MatchPerformance match, ScrollController scrollController) {
    final isWin = match.result.toLowerCase() == 'win';
    final opponentName = match.opponent.trim().isNotEmpty 
        ? match.opponent 
        : 'Unknown opponent';
    final scoreDisplay = match.scoreLine.isNotEmpty
        ? match.scoreLine
        : '${match.setsWon}–${match.setsLost}';
    final formatLabel = match.matchFormat.isNotEmpty
        ? match.matchFormat
        : 'Best of 3 sets';
    
    return SingleChildScrollView(
      controller: scrollController,
      padding: AppTheme.cardPaddingLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMD,
                  vertical: AppTheme.spaceSM,
                ),
                decoration: BoxDecoration(
                  color: (isWin ? AppTheme.win : AppTheme.loss).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  scoreDisplay,
                  style: AppTheme.scoreDisplay.copyWith(
                    color: isWin ? AppTheme.win : AppTheme.loss,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs $opponentName',
                      style: AppTheme.headingMediumThemed(context),
                    ),
                    Text(
                      '${_formatDate(match.date)} · ${match.surface} · ${match.weather} · $formatLabel',
                      style: AppTheme.labelThemed(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceLG),
          Divider(color: AppTheme.borderColor(context)),
          const SizedBox(height: AppTheme.spaceLG),
          
          // Strengths & Weaknesses
          if (match.strengths.isNotEmpty || match.weaknesses.isNotEmpty) ...[
            Text('Performance ratings', style: AppTheme.headingSmallThemed(context)),
            const SizedBox(height: AppTheme.spaceMD),
            ...match.strengths.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key, style: AppTheme.bodyMediumThemed(context)),
                  ),
                  Expanded(
                    flex: 3,
                    child: _buildRatingBar(entry.value, AppTheme.win),
                  ),
                ],
              ),
            )),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          
          // Key Moments
          if (match.keyMoments.isNotEmpty) ...[
            Text('Key moments', style: AppTheme.headingSmallThemed(context)),
            const SizedBox(height: AppTheme.spaceSM),
            ...match.keyMoments.map((moment) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Text(moment, style: AppTheme.bodyMediumThemed(context)),
                  ),
                ],
              ),
            )),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          
          // Notes
          if (match.notes.isNotEmpty) ...[
            Text('Notes', style: AppTheme.headingSmallThemed(context)),
            const SizedBox(height: AppTheme.spaceSM),
            Text(match.notes, style: AppTheme.bodyMediumThemed(context)),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          
          // Match summary
          if (match.matchSummary.isNotEmpty) ...[
            Text('Match summary', style: AppTheme.headingSmallThemed(context)),
            const SizedBox(height: AppTheme.spaceSM),
            Text(match.matchSummary, style: AppTheme.bodyMediumThemed(context)),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          
          // Mental notes
          if (match.mentalNotes.isNotEmpty) ...[
            Text('Mental notes', style: AppTheme.headingSmallThemed(context)),
            const SizedBox(height: AppTheme.spaceSM),
            Text(match.mentalNotes, style: AppTheme.bodyMediumThemed(context)),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          
          // Tactical notes
          if (match.tacticalNotes.isNotEmpty) ...[
            Text('Tactical notes', style: AppTheme.headingSmallThemed(context)),
            const SizedBox(height: AppTheme.spaceSM),
            Text(match.tacticalNotes, style: AppTheme.bodyMediumThemed(context)),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          
          // Tactical Analysis
          if (match.tacticalAnalysis.isNotEmpty && 
              match.tacticalAnalysis != 'Analysis pending') ...[
            Text('Coach feedback', style: AppTheme.headingSmallThemed(context)),
            const SizedBox(height: AppTheme.spaceSM),
            Container(
              padding: AppTheme.cardPadding,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                match.tacticalAnalysis,
                style: AppTheme.bodyMediumThemed(context).copyWith(color: AppTheme.textPrimaryColor(context)),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          
          // Recommended Drills
          if (match.recommendedDrills.isNotEmpty) ...[
            Text('Recommended practice', style: AppTheme.headingSmallThemed(context)),
            const SizedBox(height: AppTheme.spaceSM),
            ...match.recommendedDrills.map((drill) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.fitness_center_rounded, size: 16, color: AppTheme.textMutedColor(context)),
                  const SizedBox(width: AppTheme.spaceSM),
                  Expanded(
                    child: Text(drill, style: AppTheme.bodyMediumThemed(context)),
                  ),
                ],
              ),
            )),
          ],
          
          const SizedBox(height: AppTheme.spaceXXL),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.borderColor(context),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value / 10,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        Text(
          '$value',
          style: AppTheme.labelThemed(context).copyWith(color: AppTheme.textSecondaryColor(context)),
        ),
      ],
    );
  }
}
