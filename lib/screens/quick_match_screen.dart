import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import '../services/api_service.dart';
import 'add_match_screen.dart';

class QuickMatchScreen extends StatefulWidget {
  const QuickMatchScreen({super.key});

  @override
  State<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends State<QuickMatchScreen>
    with SingleTickerProviderStateMixin {
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  String? _result;
  int _setsWon = 2;
  int _setsLost = 0;
  bool _isSaving = false;
  bool _showSuccess = false;
  String? _aiInsight;
  
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _noteController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _saveMatch() async {
    if (_result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select WIN or LOSS',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final matchId = DateTime.now().millisecondsSinceEpoch.toString();
      final opponent = _opponentController.text.trim().isEmpty 
          ? 'Opponent' 
          : _opponentController.text.trim();
      
      // Create quick match description for AI
      final matchDescription = '''
Match Result: $_result ($_setsWon-$_setsLost)
Opponent: $opponent
${_noteController.text.isNotEmpty ? 'Notes: ${_noteController.text}' : ''}
      '''.trim();

      // Get AI analysis
      final apiService = Provider.of<ApiService>(context, listen: false);
      final recentMatches = await _matchHistoryService.getRecentMatches(3);
      final analysis = await apiService.tacticalAnalysis(matchDescription, recentMatches);

      // Create match with minimal data
      final match = MatchPerformance(
        id: matchId,
        date: DateTime.now(),
        opponent: opponent,
        result: _result!,
        setsWon: _setsWon,
        setsLost: _setsLost,
        surface: 'Hard',
        weather: 'Sunny',
        notes: _noteController.text,
        strengths: {},
        weaknesses: {},
        keyMoments: [],
        tacticalAnalysis: analysis ?? 'Analysis pending',
        recommendedDrills: [],
      );

      await _matchHistoryService.saveMatch(match);

      setState(() {
        _isSaving = false;
        _showSuccess = true;
        _aiInsight = analysis;
      });
      
      _celebrationController.forward();
      HapticFeedback.heavyImpact();

    } catch (e) {
      setState(() => _isSaving = false);
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

  void _goBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, _showSuccess);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return _buildSuccessView();
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '⚡ Quick Match Log',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AddMatchScreen()),
              );
            },
            child: Text(
              'Detailed',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Log your match in 30 seconds',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Result',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildResultButton(
                    label: 'WIN',
                    emoji: '🏆',
                    isSelected: _result == 'Win',
                    color: Colors.green,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _result = 'Win';
                        _setsWon = 2;
                        _setsLost = 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResultButton(
                    label: 'LOSS',
                    emoji: '😤',
                    isSelected: _result == 'Loss',
                    color: Colors.red,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _result = 'Loss';
                        _setsWon = 0;
                        _setsLost = 2;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Score',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildScoreSelector(
                    value: _setsWon,
                    label: 'You',
                    isWinner: _result == 'Win',
                    onChanged: (val) => setState(() => _setsWon = val),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '-',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  _buildScoreSelector(
                    value: _setsLost,
                    label: 'Opp',
                    isWinner: _result == 'Loss',
                    onChanged: (val) => setState(() => _setsLost = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Opponent (optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _opponentController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'Who did you play?',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick note (optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _noteController,
                style: GoogleFonts.poppins(),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g., "Backhand broke down in 3rd set"',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _isSaving ? null : _saveMatch,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _result == null
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : _result == 'Win'
                            ? [Colors.green.shade500, Colors.green.shade700]
                            : [Colors.blue.shade500, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _result != null
                      ? [
                          BoxShadow(
                            color: (_result == 'Win' ? Colors.green : Colors.blue)
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save & Get AI Analysis 🎯',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AddMatchScreen()),
                  );
                },
                child: Text(
                  '+ Add detailed stats instead',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultButton({
    required String label,
    required String emoji,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSelector({
    required int value,
    required String label,
    required bool isWinner,
    required Function(int) onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: value > 0
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(value - 1);
                    }
                  : null,
              icon: Icon(
                Icons.remove_circle_outline,
                color: value > 0 ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isWinner ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isWinner ? Colors.green.shade200 : Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isWinner ? Colors.green.shade700 : Colors.grey[700],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: value < 3
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(value + 1);
                    }
                  : null,
              icon: Icon(
                Icons.add_circle_outline,
                color: value < 3 ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    final isWin = _result == 'Win';
    
    return Scaffold(
      backgroundColor: isWin ? Colors.green.shade50 : Colors.blue.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    Text(
                      isWin ? '🏆' : '💪',
                      style: const TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isWin ? 'Nice Win!' : 'Match Logged!',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isWin ? Colors.green.shade700 : Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_setsWon - $_setsLost vs ${_opponentController.text.isEmpty ? "Opponent" : _opponentController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_aiInsight != null)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'AI Analysis',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _aiInsight!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _goBack,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isWin
                          ? [Colors.green.shade500, Colors.green.shade700]
                          : [Colors.blue.shade500, Colors.blue.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isWin ? Colors.green : Colors.blue).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
