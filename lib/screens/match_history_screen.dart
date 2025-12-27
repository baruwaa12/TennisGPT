import 'package:flutter/material.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import 'add_match_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
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
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
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
      _loadData(); // Reload data after adding a match
    }
  }

  Future<void> _deleteMatch(String matchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match'),
        content: const Text('Are you sure you want to delete this match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _matchHistoryService.deleteMatch(matchId);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      appBar: AppBar(
        title: const Text('📊 Match History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewMatch,
            tooltip: 'Add New Match',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? _buildEmptyState()
              : _buildMatchHistory(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_tennis,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No matches recorded yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first match to start tracking your progress',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewMatch,
            icon: const Icon(Icons.add),
            label: const Text('Add First Match'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistory() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Performance Summary
            if (_performanceTrends.isNotEmpty) ...[
              _buildPerformanceSummary(),
              const SizedBox(height: 16),
            ],

            // Match List
            ..._matches.map((match) => _buildMatchCard(match)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    final totalMatches = _performanceTrends['totalMatches'] ?? 0;
    final winRate = _performanceTrends['winRate'] ?? 0.0;
    final favoriteSurface = _performanceTrends['favoriteSurface'] ?? 'Unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Matches',
                    totalMatches.toString(),
                    Icons.sports_tennis,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Win Rate',
                    '${(winRate * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    color: winRate > 0.5 ? Colors.green : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Favorite Surface',
                    favoriteSurface,
                    Icons.terrain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMatchCard(MatchPerformance match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              match.result.toLowerCase() == 'win' ? Icons.check_circle : Icons.cancel,
              color: match.result.toLowerCase() == 'win' ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'vs ${match.opponent}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${match.date.toString().split(' ')[0]} • ${match.surface}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${match.setsWon}-${match.setsLost}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${match.result} • ${match.weather}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteMatch(match.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Strengths and Weaknesses
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Strengths:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          ...match.strengths.entries.map((entry) => Text(
                            '• ${entry.key}: ${entry.value}/10',
                            style: TextStyle(
                              color: entry.value >= 7 ? Colors.green : Colors.orange,
                            ),
                          )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weaknesses:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          ...match.weaknesses.entries.map((entry) => Text(
                            '• ${entry.key}: ${entry.value}/10',
                            style: TextStyle(
                              color: entry.value <= 5 ? Colors.red : Colors.orange,
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (match.keyMoments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Key Moments:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...match.keyMoments.map((moment) => Text('• $moment')),
                ],

                if (match.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(match.notes),
                ],

                if (match.tacticalAnalysis.isNotEmpty && match.tacticalAnalysis != 'Analysis pending') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Tactical Analysis:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(match.tacticalAnalysis),
                  ),
                ],

                if (match.recommendedDrills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Recommended Drills:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...match.recommendedDrills.map((drill) => Text('• $drill')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 