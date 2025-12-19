import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/match_history_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../models/match_performance.dart';
import 'paywall_screen.dart';

class TacticalCoachScreen extends StatefulWidget {
  const TacticalCoachScreen({super.key});

  @override
  State<TacticalCoachScreen> createState() => _TacticalCoachScreenState();
}

class _TacticalCoachScreenState extends State<TacticalCoachScreen> {
  final TextEditingController _queryController = TextEditingController();
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  
  List<MatchPerformance> _recentMatches = [];
  String? _selectedTopic;
  String? _analysisResponse;
  bool _isAnalyzing = false;
  bool _isLoading = true;
  
  // Stats
  double _winRate = 0.0;
  String _topStrength = '';
  String _needsWork = '';

  final List<Map<String, dynamic>> _topics = [
    {
      'id': 'opponent',
      'title': 'Opponent Analysis',
      'emoji': '👤',
      'prompt': 'Analyze my recent opponents and give me patterns to exploit',
      'color': Colors.blue,
    },
    {
      'id': 'patterns',
      'title': 'Pattern Issues',
      'emoji': '🔄',
      'prompt': 'Identify recurring patterns in my losses and how to fix them',
      'color': Colors.orange,
    },
    {
      'id': 'upcoming',
      'title': 'Upcoming Match',
      'emoji': '📅',
      'prompt': 'Help me prepare a tactical game plan for my next match',
      'color': Colors.purple,
    },
    {
      'id': 'drills',
      'title': 'Drill Plan',
      'emoji': '🏋️',
      'prompt': 'Create a practice drill plan based on my weaknesses',
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final matches = await _matchHistoryService.getRecentMatches(10);
      final winRate = await _matchHistoryService.getWinRate();
      
      // Calculate top strength and weakness
      String topStrength = 'Serve';
      String needsWork = 'Backhand';
      
      if (matches.isNotEmpty) {
        final strengthTotals = <String, int>{};
        final weaknessTotals = <String, int>{};
        
        for (final match in matches) {
          match.strengths.forEach((key, value) {
            strengthTotals[key] = (strengthTotals[key] ?? 0) + value;
          });
          match.weaknesses.forEach((key, value) {
            weaknessTotals[key] = (weaknessTotals[key] ?? 0) + value;
          });
        }
        
        if (strengthTotals.isNotEmpty) {
          topStrength = strengthTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
        if (weaknessTotals.isNotEmpty) {
          needsWork = weaknessTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
      }
      
      setState(() {
        _recentMatches = matches;
        _winRate = winRate;
        _topStrength = topStrength;
        _needsWork = needsWork;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAnalysis() async {
    String query = _queryController.text.trim();
    
    if (query.isEmpty && _selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please describe your situation or select a topic',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check usage limits (premium users bypass)
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    
    if (!purchaseService.isPremium && !usageService.canUseTacticalAnalysis) {
      // Show paywall
      HapticFeedback.mediumImpact();
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(
            trigger: PaywallTrigger.tacticalAnalysisLimit,
          ),
        ),
      );
      
      // If they subscribed, continue with analysis
      if (result != true) return;
    }

    // Use topic prompt if selected
    if (_selectedTopic != null && query.isEmpty) {
      final topic = _topics.firstWhere((t) => t['id'] == _selectedTopic);
      query = topic['prompt'];
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResponse = null;
    });
    
    HapticFeedback.mediumImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.tacticalAnalysis(query, _recentMatches);
      
      // Record usage for free users
      if (!purchaseService.isPremium) {
        await usageService.recordTacticalAnalysis();
      }
      
      setState(() {
        _isAnalyzing = false;
        _analysisResponse = response;
      });
      
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '🎯 Tactical Coach',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Recent Form Summary
                  _buildFormSummary(),
                  
                  const SizedBox(height: 20),
                  
                  // Query Input
                  _buildQuerySection(),
                  
                  const SizedBox(height: 20),
                  
                  // Topic Selection
                  _buildTopicSelection(),
                  
                  const SizedBox(height: 24),
                  
                  // Get Analysis Button
                  _buildAnalyzeButton(),
                  
                  // Analysis Response
                  if (_analysisResponse != null) ...[
                    const SizedBox(height: 24),
                    _buildResponseCard(),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildFormSummary() {
    final wins = _recentMatches.where((m) => m.result.toLowerCase() == 'win').length;
    final total = _recentMatches.length;
    final winPercentage = total > 0 ? ((wins / total) * 100).toStringAsFixed(0) : '0';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Your Recent Form',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Last 5 matches visual
          if (_recentMatches.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Last ${_recentMatches.take(5).length}: ',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                ..._recentMatches.take(5).map((match) {
                  final isWin = match.result.toLowerCase() == 'win';
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isWin ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isWin ? 'W' : 'L',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Text(
                  '($winPercentage%)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Strengths & Weaknesses
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    icon: Icons.trending_up,
                    label: 'Strength',
                    value: _topStrength,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatChip(
                    icon: Icons.trending_down,
                    label: 'Needs Work',
                    value: _needsWork,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'Log matches to see your performance trends',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you need help with?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: TextField(
            controller: _queryController,
            style: GoogleFonts.poppins(),
            maxLines: 3,
            onChanged: (_) {
              if (_selectedTopic != null) {
                setState(() => _selectedTopic = null);
              }
            },
            decoration: InputDecoration(
              hintText: 'e.g., "How do I beat a pusher?" or "My serve breaks down under pressure"',
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Or choose a topic:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: _topics.map((topic) {
            final isSelected = _selectedTopic == topic['id'];
            final color = topic['color'] as Color;
            
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedTopic = isSelected ? null : topic['id'];
                  if (_selectedTopic != null) {
                    _queryController.clear();
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? color.withOpacity(0.2) 
                          : Colors.black.withOpacity(0.05),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      topic['emoji'],
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        topic['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? color : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    final hasInput = _queryController.text.isNotEmpty || _selectedTopic != null;
    
    return GestureDetector(
      onTap: _isAnalyzing || !hasInput ? null : _getAnalysis,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasInput
                ? [Colors.green.shade500, Colors.green.shade700]
                : [Colors.grey.shade400, Colors.grey.shade500],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: hasInput
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isAnalyzing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Analyzing...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Get Tactical Analysis 🎯',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResponseCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Tactical Analysis',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _analysisResponse = null;
                    _selectedTopic = null;
                    _queryController.clear();
                  });
                },
                icon: Icon(Icons.refresh, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            _analysisResponse!,
            style: GoogleFonts.poppins(
              fontSize: 15,
              height: 1.7,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
