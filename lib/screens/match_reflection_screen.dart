import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/player_profile_service.dart';
import '../models/match_performance.dart';

/// Quick post-match reflection screen with guided options
class MatchReflectionScreen extends StatefulWidget {
  final MatchPerformance match;
  
  const MatchReflectionScreen({
    super.key,
    required this.match,
  });

  @override
  State<MatchReflectionScreen> createState() => _MatchReflectionScreenState();
}

class _MatchReflectionScreenState extends State<MatchReflectionScreen> {
  // What went well
  final Set<String> _selectedStrengths = {};
  String _otherStrength = '';
  
  // What needs work
  final Set<String> _selectedWeaknesses = {};
  String _otherWeakness = '';
  
  bool _isGettingAdvice = false;
  String? _tacticalAdvice;

  static const List<Map<String, String>> strengthOptions = [
    {'id': 'serve', 'label': 'Serve was on', 'emoji': '🎯'},
    {'id': 'movement', 'label': 'Movement was good', 'emoji': '🏃'},
    {'id': 'shot_selection', 'label': 'Made smart shot selections', 'emoji': '🧠'},
    {'id': 'focus', 'label': 'Stayed focused throughout', 'emoji': '👁️'},
    {'id': 'returns', 'label': 'Returns were solid', 'emoji': '↩️'},
    {'id': 'net_play', 'label': 'Net play was effective', 'emoji': '🏐'},
  ];

  static const List<Map<String, String>> weaknessOptions = [
    {'id': 'errors', 'label': 'Too many unforced errors', 'emoji': '❌'},
    {'id': 'backhand', 'label': 'Backhand broke down', 'emoji': '🔙'},
    {'id': 'focus', 'label': 'Lost focus in key moments', 'emoji': '😵'},
    {'id': 'fitness', 'label': 'Fitness/stamina issues', 'emoji': '😮‍💨'},
    {'id': 'serve', 'label': 'Serve was inconsistent', 'emoji': '🎾'},
    {'id': 'nerves', 'label': 'Nerves affected play', 'emoji': '😰'},
  ];

  Future<void> _getTacticalAdvice() async {
    if (_selectedStrengths.isEmpty && _selectedWeaknesses.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select at least one item to get advice',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGettingAdvice = true);
    HapticFeedback.mediumImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profileService = Provider.of<PlayerProfileService>(context, listen: false);
      
      // Build context for AI
      final strengths = _selectedStrengths.map((id) {
        final option = strengthOptions.firstWhere((o) => o['id'] == id, orElse: () => {'label': id});
        return option['label'] ?? id;
      }).toList();
      if (_otherStrength.isNotEmpty) strengths.add(_otherStrength);
      
      final weaknesses = _selectedWeaknesses.map((id) {
        final option = weaknessOptions.firstWhere((o) => o['id'] == id, orElse: () => {'label': id});
        return option['label'] ?? id;
      }).toList();
      if (_otherWeakness.isNotEmpty) weaknesses.add(_otherWeakness);

      final playerContext = profileService.getPlayerContext();
      final matchContext = '''
$playerContext

Match Result: ${widget.match.result} vs ${widget.match.opponent}
Score: ${widget.match.setsWon}-${widget.match.setsLost}

What went well: ${strengths.join(', ')}
What needs work: ${weaknesses.join(', ')}

Based on this post-match reflection, provide specific tactical advice for improvement.
''';

      final response = await apiService.tacticalAnalysis(matchContext, null);
      
      setState(() {
        _isGettingAdvice = false;
        _tacticalAdvice = response;
      });
      
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isGettingAdvice = false);
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

  void _skip() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  void _done() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, {
      'strengths': _selectedStrengths.toList(),
      'weaknesses': _selectedWeaknesses.toList(),
      'otherStrength': _otherStrength,
      'otherWeakness': _otherWeakness,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWin = widget.match.result.toLowerCase() == 'win';

    if (_tacticalAdvice != null) {
      return _buildAdviceView(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '📝 Match Reflection',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              'Skip',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isWin 
                    ? (isDark ? Colors.green.shade900 : Colors.green.shade50)
                    : (isDark ? Colors.blue.shade900 : Colors.blue.shade50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    isWin ? '🏆' : '💪',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.match.result} vs ${widget.match.opponent}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        Text(
                          '${widget.match.setsWon}-${widget.match.setsLost}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // What went well
            Text(
              'What went well? ✅',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildOptionGrid(
              options: strengthOptions,
              selected: _selectedStrengths,
              isDark: isDark,
              accentColor: Colors.green,
            ),
            const SizedBox(height: 8),
            _buildOtherInput(
              hint: 'Other strength...',
              value: _otherStrength,
              onChanged: (v) => setState(() => _otherStrength = v),
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            // What needs work
            Text(
              'What needs work? 🔧',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildOptionGrid(
              options: weaknessOptions,
              selected: _selectedWeaknesses,
              isDark: isDark,
              accentColor: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildOtherInput(
              hint: 'Other area to improve...',
              value: _otherWeakness,
              onChanged: (v) => setState(() => _otherWeakness = v),
              isDark: isDark,
            ),
            
            const SizedBox(height: 32),
            
            // Get tactical advice button
            GestureDetector(
              onTap: _isGettingAdvice ? null : _getTacticalAdvice,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isGettingAdvice
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                          'Get Tactical Advice 🎯',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Skip for now
            Center(
              child: TextButton(
                onPressed: _done,
                child: Text(
                  'Save without advice',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceView(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '🎯 Tactical Advice',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
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
                        'Based on Your Reflection',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    _tacticalAdvice!,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      height: 1.7,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            GestureDetector(
              onTap: _done,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade500, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Done ✓',
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
    );
  }

  Widget _buildOptionGrid({
    required List<Map<String, String>> options,
    required Set<String> selected,
    required bool isDark,
    required Color accentColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option['id']);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isSelected) {
                selected.remove(option['id']);
              } else {
                selected.add(option['id']!);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(isDark ? 0.3 : 0.15)
                  : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? accentColor 
                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option['emoji'] ?? '', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  option['label'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected 
                        ? accentColor 
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOtherInput({
    required String hint,
    required String value,
    required Function(String) onChanged,
    required bool isDark,
  }) {
    return TextField(
      onChanged: onChanged,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: isDark ? Colors.white : Colors.grey[800],
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
