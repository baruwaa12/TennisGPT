import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CelebrationType {
  firstMatch,
  firstAnalysis,
  threeStreak,
  sevenStreak,
  tenMatches,
  firstWin,
  milestone,
}

/// CelebrationService handles displaying celebratory animations
/// for user achievements and milestones.
class CelebrationService {
  static const String _firstMatchKey = 'celebration_first_match';
  static const String _firstAnalysisKey = 'celebration_first_analysis';
  static const String _firstWinKey = 'celebration_first_win';
  static const String _tenMatchesKey = 'celebration_ten_matches';

  /// Check and show celebration for first match
  static Future<bool> checkFirstMatch(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_firstMatchKey) == true) return false;
    
    await prefs.setBool(_firstMatchKey, true);
    if (context.mounted) {
      showCelebration(
        context,
        type: CelebrationType.firstMatch,
        title: "You're on your way! 🎾",
        message: "First match logged! Keep tracking to unlock powerful insights.",
      );
    }
    return true;
  }

  /// Check and show celebration for first analysis
  static Future<bool> checkFirstAnalysis(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_firstAnalysisKey) == true) return false;
    
    await prefs.setBool(_firstAnalysisKey, true);
    if (context.mounted) {
      showCelebration(
        context,
        type: CelebrationType.firstAnalysis,
        title: "Your journey begins! 🎯",
        message: "First tactical analysis complete. Welcome to AI-powered tennis.",
      );
    }
    return true;
  }

  /// Check and show celebration for first win
  static Future<bool> checkFirstWin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_firstWinKey) == true) return false;
    
    await prefs.setBool(_firstWinKey, true);
    if (context.mounted) {
      showCelebration(
        context,
        type: CelebrationType.firstWin,
        title: "Victory! 🏆",
        message: "First win logged! Let's keep the momentum going.",
      );
    }
    return true;
  }

  /// Check and show celebration for 10 matches milestone
  static Future<bool> checkTenMatches(BuildContext context, int matchCount) async {
    if (matchCount != 10) return false;
    
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_tenMatchesKey) == true) return false;
    
    await prefs.setBool(_tenMatchesKey, true);
    if (context.mounted) {
      showCelebration(
        context,
        type: CelebrationType.tenMatches,
        title: "10 Matches! 🎖️",
        message: "You've logged 10 matches. Your data is building real insights.",
      );
    }
    return true;
  }

  /// Show streak celebration
  static void showStreakCelebration(BuildContext context, int streak) {
    if (streak == 3) {
      showCelebration(
        context,
        type: CelebrationType.threeStreak,
        title: "3-Day Streak! 🔥",
        message: "You're building great habits. Keep it up!",
      );
    } else if (streak == 7) {
      showCelebration(
        context,
        type: CelebrationType.sevenStreak,
        title: "7-Day Streak! 🏆",
        message: "A week of dedication! You're becoming unstoppable.",
      );
    }
  }

  /// Main celebration display method
  static void showCelebration(
    BuildContext context, {
    required CelebrationType type,
    required String title,
    required String message,
  }) {
    HapticFeedback.heavyImpact();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Celebration',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _CelebrationOverlay(
          type: type,
          title: title,
          message: message,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: child,
        );
      },
    );
  }

  /// Reset all celebration flags (for testing)
  static Future<void> resetCelebrations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstMatchKey);
    await prefs.remove(_firstAnalysisKey);
    await prefs.remove(_firstWinKey);
    await prefs.remove(_tenMatchesKey);
  }
}

class _CelebrationOverlay extends StatefulWidget {
  final CelebrationType type;
  final String title;
  final String message;

  const _CelebrationOverlay({
    required this.type,
    required this.title,
    required this.message,
  });

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Start confetti after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String get _emoji {
    switch (widget.type) {
      case CelebrationType.firstMatch:
        return '🎾';
      case CelebrationType.firstAnalysis:
        return '🎯';
      case CelebrationType.threeStreak:
        return '🔥';
      case CelebrationType.sevenStreak:
        return '🏆';
      case CelebrationType.tenMatches:
        return '🎖️';
      case CelebrationType.firstWin:
        return '🏆';
      case CelebrationType.milestone:
        return '⭐';
    }
  }

  Color get _color {
    switch (widget.type) {
      case CelebrationType.firstMatch:
        return Colors.green;
      case CelebrationType.firstAnalysis:
        return Colors.blue;
      case CelebrationType.threeStreak:
        return Colors.orange;
      case CelebrationType.sevenStreak:
        return Colors.amber;
      case CelebrationType.tenMatches:
        return Colors.purple;
      case CelebrationType.firstWin:
        return Colors.green;
      case CelebrationType.milestone:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti from top
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [
              Colors.green,
              Colors.blue,
              Colors.orange,
              Colors.purple,
              Colors.pink,
              Colors.yellow,
            ],
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 10,
            emissionFrequency: 0.05,
            gravity: 0.1,
          ),
        ),
        
        // Celebration Card
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _color.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emoji with glow
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Message
                    Text(
                      widget.message,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Dismiss button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_color, _color.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Awesome! 🙌',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
