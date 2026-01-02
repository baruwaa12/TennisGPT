import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import 'add_match_screen.dart';

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
        builder: (context) => const AddMatchScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteMatch(String matchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Text('Delete match?', style: AppTheme.headingMedium),
        content: Text(
          'This action cannot be undone.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: AppTheme.bodyMedium.copyWith(color: AppTheme.loss)),
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
      backgroundColor: AppTheme.surfaceDark,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppTheme.surfaceDark,
            elevation: 0,
            pinned: true,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Match History',
              style: AppTheme.headingSmall.copyWith(color: AppTheme.textSecondary),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
                onPressed: _addNewMatch,
                tooltip: 'Log match',
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
                  Text('Recent matches', style: AppTheme.headingMedium),
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
                color: AppTheme.surfaceCard,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_tennis_rounded,
                size: 48,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Text(
              'No matches yet',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Log your first match to start tracking progress',
              style: AppTheme.bodyMedium,
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
                  'Log first match',
                  style: AppTheme.headingSmall.copyWith(color: Colors.white),
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
        color: AppTheme.loss.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.loss.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.loss, size: 20),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(_errorMessage!, style: AppTheme.bodySmall),
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
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance', style: AppTheme.headingSmall),
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
                color: AppTheme.surfaceBorder,
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
                color: AppTheme.surfaceBorder,
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
        Icon(icon, size: 20, color: AppTheme.textMuted),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          value,
          style: AppTheme.statMedium.copyWith(
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(label, style: AppTheme.label),
      ],
    );
  }

  /// Match row with clear hierarchy:
  /// 1. Score (most prominent)
  /// 2. Opponent name
  /// 3. Date + surface (tertiary)
  Widget _buildMatchRow(MatchPerformance match) {
    final isWin = match.result.toLowerCase() == 'win';
    final opponentName = match.opponent.trim().isNotEmpty 
        ? match.opponent 
        : 'Unknown opponent';
    final dateStr = _formatDate(match.date);
    
    return GestureDetector(
      onTap: () => _showMatchDetails(match),
      child: Container(
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Row(
          children: [
            // Win/Loss indicator
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: isWin ? AppTheme.win : AppTheme.loss,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Opponent name (secondary)
                  Text(
                    opponentName,
                    style: AppTheme.headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  // Date + surface (tertiary)
                  Text(
                    '$dateStr · ${match.surface}',
                    style: AppTheme.label,
                  ),
                ],
              ),
            ),
            
            // Score (most prominent)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceSM,
              ),
              decoration: BoxDecoration(
                color: (isWin ? AppTheme.win : AppTheme.loss).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Text(
                '${match.setsWon}–${match.setsLost}',
                style: AppTheme.scoreDisplay.copyWith(
                  color: isWin ? AppTheme.win : AppTheme.loss,
                ),
              ),
            ),
            
            // Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
              color: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteMatch(match.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: AppTheme.loss, size: 20),
                      const SizedBox(width: AppTheme.spaceSM),
                      Text('Delete', style: AppTheme.bodyMedium.copyWith(color: AppTheme.loss)),
                    ],
                  ),
                ),
              ],
            ),
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
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showMatchDetails(MatchPerformance match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
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
                color: AppTheme.surfaceBorder,
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
                  color: (isWin ? AppTheme.win : AppTheme.loss).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  '${match.setsWon}–${match.setsLost}',
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
                      style: AppTheme.headingMedium,
                    ),
                    Text(
                      '${_formatDate(match.date)} · ${match.surface} · ${match.weather}',
                      style: AppTheme.label,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceLG),
          Divider(color: AppTheme.surfaceBorder),
          const SizedBox(height: AppTheme.spaceLG),
          
          // Strengths & Weaknesses
          if (match.strengths.isNotEmpty || match.weaknesses.isNotEmpty) ...[
            Text('Performance ratings', style: AppTheme.headingSmall),
            const SizedBox(height: AppTheme.spaceMD),
            ...match.strengths.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key, style: AppTheme.bodyMedium),
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
            Text('Key moments', style: AppTheme.headingSmall),
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
                    child: Text(moment, style: AppTheme.bodyMedium),
                  ),
                ],
              ),
            )),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          
          // Notes
          if (match.notes.isNotEmpty) ...[
            Text('Notes', style: AppTheme.headingSmall),
            const SizedBox(height: AppTheme.spaceSM),
            Text(match.notes, style: AppTheme.bodyMedium),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          
          // Tactical Analysis
          if (match.tacticalAnalysis.isNotEmpty && 
              match.tacticalAnalysis != 'Analysis pending') ...[
            Text('Coach feedback', style: AppTheme.headingSmall),
            const SizedBox(height: AppTheme.spaceSM),
            Container(
              padding: AppTheme.cardPadding,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Text(
                match.tacticalAnalysis,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          
          // Recommended Drills
          if (match.recommendedDrills.isNotEmpty) ...[
            Text('Recommended practice', style: AppTheme.headingSmall),
            const SizedBox(height: AppTheme.spaceSM),
            ...match.recommendedDrills.map((drill) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.fitness_center_rounded, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: AppTheme.spaceSM),
                  Expanded(
                    child: Text(drill, style: AppTheme.bodyMedium),
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
              color: AppTheme.surfaceBorder,
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
          style: AppTheme.label.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
