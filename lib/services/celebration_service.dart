import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// CelebrationService handles displaying subtle achievement notifications
/// for user milestones - no confetti, just clean professional feedback.
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
      showAchievement(
        context,
        type: CelebrationType.firstMatch,
        title: "You're on your way!",
        message: "First match logged. Keep tracking to unlock insights.",
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
      showAchievement(
        context,
        type: CelebrationType.firstAnalysis,
        title: "Your journey begins",
        message: "First tactical analysis complete.",
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
      showAchievement(
        context,
        type: CelebrationType.firstWin,
        title: "Victory logged",
        message: "First win recorded. Keep the momentum going.",
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
      showAchievement(
        context,
        type: CelebrationType.tenMatches,
        title: "10 Matches",
        message: "Your data is building real insights.",
      );
    }
    return true;
  }

  /// Show streak achievement
  static void showStreakAchievement(BuildContext context, int streak) {
    if (streak == 3) {
      showAchievement(
        context,
        type: CelebrationType.threeStreak,
        title: "3-Day Streak",
        message: "You're building great habits.",
      );
    } else if (streak == 7) {
      showAchievement(
        context,
        type: CelebrationType.sevenStreak,
        title: "7-Day Streak",
        message: "A week of dedication.",
      );
    }
  }

  /// Show a subtle achievement toast/snackbar
  static void showAchievement(
    BuildContext context, {
    required CelebrationType type,
    required String title,
    required String message,
  }) {
    HapticFeedback.mediumImpact();
    
    final color = _getColor(type);
    final icon = _getIcon(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static Color _getColor(CelebrationType type) {
    switch (type) {
      case CelebrationType.firstMatch:
        return Colors.green.shade600;
      case CelebrationType.firstAnalysis:
        return Colors.blue.shade600;
      case CelebrationType.threeStreak:
        return Colors.orange.shade600;
      case CelebrationType.sevenStreak:
        return Colors.amber.shade700;
      case CelebrationType.tenMatches:
        return Colors.purple.shade600;
      case CelebrationType.firstWin:
        return Colors.green.shade600;
      case CelebrationType.milestone:
        return Colors.indigo.shade600;
    }
  }

  static IconData _getIcon(CelebrationType type) {
    switch (type) {
      case CelebrationType.firstMatch:
        return Icons.sports_tennis;
      case CelebrationType.firstAnalysis:
        return Icons.psychology;
      case CelebrationType.threeStreak:
        return Icons.local_fire_department;
      case CelebrationType.sevenStreak:
        return Icons.emoji_events;
      case CelebrationType.tenMatches:
        return Icons.military_tech;
      case CelebrationType.firstWin:
        return Icons.emoji_events;
      case CelebrationType.milestone:
        return Icons.star;
    }
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
