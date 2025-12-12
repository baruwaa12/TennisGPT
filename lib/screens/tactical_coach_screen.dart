import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/match_history_service.dart';
import '../models/match_performance.dart';

class TacticalCoachScreen extends StatefulWidget {
  const TacticalCoachScreen({super.key});

  @override
  State<TacticalCoachScreen> createState() => _TacticalCoachScreenState();
}

class _TacticalCoachScreenState extends State<TacticalCoachScreen>
    with TickerProviderStateMixin {
  final TextEditingController _matchDescriptionController = TextEditingController();
  final TextEditingController _quickTipController = TextEditingController();
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  
  String? _analysisResponse;
  String? _drillsResponse;
  String? _quickTipResponse;
  List<MatchPerformance> _recentMatches = [];
  bool _isAnalyzing = false;
  bool _isGeneratingDrills = false;
  bool _isGettingTip = false;

  @override
  void initState() {
    super.initState();
    _loadRecentMatches();
  }

  @override
  void dispose() {
    _matchDescriptionController.dispose();
    _quickTipController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentMatches() async {
    final matches = await _matchHistoryService.getRecentMatches(5);
    setState(() {
      _recentMatches = matches;
    });
  }

  Future<void> _analyzeMatch() async {
    if (_matchDescriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your match first')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResponse = null;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final response = await apiService.tacticalAnalysis(
      _matchDescriptionController.text.trim(),
      _recentMatches,
    );

    setState(() {
      _isAnalyzing = false;
      _analysisResponse = response;
    });
  }

  Future<void> _generateDrillsFromHistory() async {
    setState(() {
      _isGeneratingDrills = true;
      _drillsResponse = null;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final response = await apiService.generateDrillsFromHistory(_recentMatches);

    setState(() {
      _isGeneratingDrills = false;
      _drillsResponse = response;
    });
  }

  Future<void> _getQuickTacticalTip() async {
    if (_quickTipController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your situation first')),
      );
      return;
    }

    setState(() {
      _isGettingTip = true;
      _quickTipResponse = null;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final response = await apiService.quickTacticalTip(_quickTipController.text.trim());

    setState(() {
      _isGettingTip = false;
      _quickTipResponse = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎾 Tactical Coach'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Match History Summary
            if (_recentMatches.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Recent Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last ${_recentMatches.length} matches analyzed',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._recentMatches.take(3).map((match) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              match.result.toLowerCase() == 'win' 
                                ? Icons.check_circle 
                                : Icons.cancel,
                              color: match.result.toLowerCase() == 'win' 
                                ? Colors.green 
                                : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${match.date.toString().split(' ')[0]}: ${match.result} vs ${match.opponent}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Match Analysis Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔍 Match Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _matchDescriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe your match: opponent, score, what went well/poorly, key moments...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeMatch,
                        icon: _isAnalyzing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.analytics),
                        label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Match'),
                      ),
                    ),
                    if (_analysisResponse != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          _analysisResponse!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Drill Recommendations Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏋️ Drill Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _recentMatches.isEmpty 
                        ? 'Get foundational drills to build your game'
                        : 'Based on your match history',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingDrills ? null : _generateDrillsFromHistory,
                        icon: _isGeneratingDrills 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fitness_center),
                        label: Text(_isGeneratingDrills ? 'Generating...' : 'Get Drills'),
                      ),
                    ),
                    if (_drillsResponse != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          _drillsResponse!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Tactical Tip Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Quick Tactical Tip',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quickTipController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Describe a specific situation you need help with...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGettingTip ? null : _getQuickTacticalTip,
                        icon: _isGettingTip 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lightbulb),
                        label: Text(_isGettingTip ? 'Getting Tip...' : 'Get Quick Tip'),
                      ),
                    ),
                    if (_quickTipResponse != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          _quickTipResponse!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
} 