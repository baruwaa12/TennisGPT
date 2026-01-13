import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StreakService tracks consecutive days of app activity
/// (match logged or tactical analysis used)
class StreakService extends ChangeNotifier {
  static const String _lastActivityKey = 'streak_last_activity';
  static const String _currentStreakKey = 'streak_current';
  static const String _longestStreakKey = 'streak_longest';

  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActivityDate;
  bool _isLoaded = false;

  // Getters
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastActivityDate => _lastActivityDate;
  bool get isLoaded => _isLoaded;
  
  /// Check if user has activity today
  bool get hasActivityToday {
    if (_lastActivityDate == null) return false;
    final now = DateTime.now();
    return _isSameDay(_lastActivityDate!, now);
  }

  /// Initialize and load saved streak data
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    _currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    _longestStreak = prefs.getInt(_longestStreakKey) ?? 0;
    
    final lastActivityStr = prefs.getString(_lastActivityKey);
    if (lastActivityStr != null) {
      _lastActivityDate = DateTime.tryParse(lastActivityStr);
    }
    
    // Check if streak is still valid (not broken)
    _validateStreak();
    
    _isLoaded = true;
    notifyListeners();
    
    if (kDebugMode) {
      print('StreakService: Loaded - Current streak: $_currentStreak days');
    }
  }

  /// Record activity for today (match logged or tactical analysis)
  Future<StreakMilestone?> recordActivity() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Already recorded today
    if (_lastActivityDate != null && _isSameDay(_lastActivityDate!, today)) {
      return null;
    }
    
    StreakMilestone? milestone;
    
    // Check if this continues the streak
    if (_lastActivityDate != null) {
      final yesterday = today.subtract(const Duration(days: 1));
      if (_isSameDay(_lastActivityDate!, yesterday)) {
        // Continuing streak!
        _currentStreak++;
      } else {
        // Streak broken, start fresh
        _currentStreak = 1;
      }
    } else {
      // First activity ever
      _currentStreak = 1;
    }
    
    // Update longest streak
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }
    
    _lastActivityDate = today;
    
    // Check for milestones
    milestone = _checkMilestone(_currentStreak);
    
    // Save to storage
    await _save();
    
    notifyListeners();
    
    if (kDebugMode) {
      print('StreakService: Activity recorded - Streak now $_currentStreak days');
    }
    
    return milestone;
  }

  /// Validate streak hasn't been broken
  void _validateStreak() {
    if (_lastActivityDate == null) {
      _currentStreak = 0;
      return;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    // If last activity was today or yesterday, streak is still valid
    if (_isSameDay(_lastActivityDate!, today) || _isSameDay(_lastActivityDate!, yesterday)) {
      return;
    }
    
    // Streak is broken
    _currentStreak = 0;
  }

  /// Check if a milestone was hit
  StreakMilestone? _checkMilestone(int streak) {
    switch (streak) {
      case 3:
        return StreakMilestone.threeDays;
      case 7:
        return StreakMilestone.oneWeek;
      case 14:
        return StreakMilestone.twoWeeks;
      case 30:
        return StreakMilestone.oneMonth;
      case 60:
        return StreakMilestone.twoMonths;
      case 100:
        return StreakMilestone.hundred;
      default:
        return null;
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Save streak data
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentStreakKey, _currentStreak);
    await prefs.setInt(_longestStreakKey, _longestStreak);
    if (_lastActivityDate != null) {
      await prefs.setString(_lastActivityKey, _lastActivityDate!.toIso8601String());
    }
  }

  /// Reset streak (for user switch - clears in-memory AND forces re-initialization)
  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_longestStreakKey);
    await prefs.remove(_lastActivityKey);
    
    _currentStreak = 0;
    _longestStreak = 0;
    _lastActivityDate = null;
    _isLoaded = false; // CRITICAL: Allow re-initialization for new user
    
    notifyListeners();
    
    if (kDebugMode) {
      print('StreakService: Reset complete - ready for new user');
    }
  }
}

/// Streak milestone achievements
enum StreakMilestone {
  threeDays,
  oneWeek,
  twoWeeks,
  oneMonth,
  twoMonths,
  hundred,
}

extension StreakMilestoneExtension on StreakMilestone {
  String get title {
    switch (this) {
      case StreakMilestone.threeDays:
        return '3-Day Streak!';
      case StreakMilestone.oneWeek:
        return '1 Week Streak!';
      case StreakMilestone.twoWeeks:
        return '2 Week Streak!';
      case StreakMilestone.oneMonth:
        return '1 Month Streak!';
      case StreakMilestone.twoMonths:
        return '2 Month Streak!';
      case StreakMilestone.hundred:
        return '100 Day Streak!';
    }
  }

  String get message {
    switch (this) {
      case StreakMilestone.threeDays:
        return "You're building great habits!";
      case StreakMilestone.oneWeek:
        return 'A full week of dedication!';
      case StreakMilestone.twoWeeks:
        return 'Your consistency is paying off!';
      case StreakMilestone.oneMonth:
        return 'A month of improvement!';
      case StreakMilestone.twoMonths:
        return 'Incredible commitment!';
      case StreakMilestone.hundred:
        return 'You are unstoppable!';
    }
  }

  int get days {
    switch (this) {
      case StreakMilestone.threeDays:
        return 3;
      case StreakMilestone.oneWeek:
        return 7;
      case StreakMilestone.twoWeeks:
        return 14;
      case StreakMilestone.oneMonth:
        return 30;
      case StreakMilestone.twoMonths:
        return 60;
      case StreakMilestone.hundred:
        return 100;
    }
  }
}
