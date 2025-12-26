import '../models/check_in_entry.dart';
import 'storage_service.dart';
import 'match_history_service.dart';

/// Service for calculating and tracking user streaks
class StreakService {
  final MatchHistoryService _matchHistoryService = MatchHistoryService();

  /// Get comprehensive streak data for the user
  Future<StreakData> getStreakData() async {
    final checkInStreak = await getCheckInStreak();
    final winStreak = await getWinStreak();
    final hasCheckedInToday = await _hasCheckedInToday();
    final lastCheckIn = await _getLastCheckIn();
    final recentMatches = await _matchHistoryService.getRecentMatches(5);

    return StreakData(
      currentCheckInStreak: checkInStreak.current,
      longestCheckInStreak: checkInStreak.longest,
      currentWinStreak: winStreak.current,
      longestWinStreak: winStreak.longest,
      hasCheckedInToday: hasCheckedInToday,
      lastCheckInDate: lastCheckIn != null
          ? DateTime.fromMillisecondsSinceEpoch(lastCheckIn.timestamp)
          : null,
      totalCheckIns: (await StorageService.getCheckIns()).length,
      totalMatches: recentMatches.length,
      recentMood: lastCheckIn?.rating,
    );
  }

  /// Calculate the current check-in streak
  Future<StreakResult> getCheckInStreak() async {
    final checkIns = await StorageService.getCheckIns();
    if (checkIns.isEmpty) {
      return StreakResult(current: 0, longest: 0);
    }

    // Sort by timestamp descending (most recent first)
    checkIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Get unique dates
    final Set<String> uniqueDates = {};
    for (final checkIn in checkIns) {
      final date = DateTime.fromMillisecondsSinceEpoch(checkIn.timestamp);
      uniqueDates.add(_dateToString(date));
    }

    final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));

    // Calculate current streak
    int currentStreak = 0;
    final today = _dateToString(DateTime.now());
    final yesterday = _dateToString(DateTime.now().subtract(const Duration(days: 1)));

    // Check if streak is still active (checked in today or yesterday)
    if (sortedDates.isNotEmpty) {
      final mostRecent = sortedDates.first;
      if (mostRecent == today || mostRecent == yesterday) {
        currentStreak = _calculateConsecutiveDays(sortedDates);
      }
    }

    // Calculate longest streak
    int longestStreak = _calculateLongestStreak(sortedDates);

    return StreakResult(
      current: currentStreak,
      longest: longestStreak > currentStreak ? longestStreak : currentStreak,
    );
  }

  /// Calculate the current win streak from match history
  Future<StreakResult> getWinStreak() async {
    final matches = await _matchHistoryService.getAllMatches();
    if (matches.isEmpty) {
      return StreakResult(current: 0, longest: 0);
    }

    // Sort by date descending (most recent first)
    matches.sort((a, b) => b.date.compareTo(a.date));

    // Calculate current win streak
    int currentStreak = 0;
    for (final match in matches) {
      if (match.result.toLowerCase() == 'win') {
        currentStreak++;
      } else {
        break;
      }
    }

    // Calculate longest win streak
    int longestStreak = 0;
    int tempStreak = 0;
    for (final match in matches.reversed) {
      if (match.result.toLowerCase() == 'win') {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    return StreakResult(
      current: currentStreak,
      longest: longestStreak > currentStreak ? longestStreak : currentStreak,
    );
  }

  /// Check if user has checked in today
  Future<bool> _hasCheckedInToday() async {
    final checkIns = await StorageService.getCheckIns();
    if (checkIns.isEmpty) return false;

    final today = _dateToString(DateTime.now());
    return checkIns.any((checkIn) {
      final date = DateTime.fromMillisecondsSinceEpoch(checkIn.timestamp);
      return _dateToString(date) == today;
    });
  }

  /// Get the most recent check-in
  Future<CheckInEntry?> _getLastCheckIn() async {
    final checkIns = await StorageService.getCheckIns();
    if (checkIns.isEmpty) return null;

    checkIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return checkIns.first;
  }

  /// Calculate consecutive days from a sorted list of date strings
  int _calculateConsecutiveDays(List<String> sortedDates) {
    if (sortedDates.isEmpty) return 0;

    int streak = 1;
    DateTime previousDate = DateTime.parse(sortedDates.first);

    for (int i = 1; i < sortedDates.length; i++) {
      final currentDate = DateTime.parse(sortedDates[i]);
      final difference = previousDate.difference(currentDate).inDays;

      if (difference == 1) {
        streak++;
        previousDate = currentDate;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate the longest streak from date strings
  int _calculateLongestStreak(List<String> sortedDates) {
    if (sortedDates.isEmpty) return 0;

    // Sort ascending for this calculation
    final ascendingDates = sortedDates.toList()..sort();

    int longest = 1;
    int current = 1;
    DateTime previousDate = DateTime.parse(ascendingDates.first);

    for (int i = 1; i < ascendingDates.length; i++) {
      final currentDate = DateTime.parse(ascendingDates[i]);
      final difference = currentDate.difference(previousDate).inDays;

      if (difference == 1) {
        current++;
        if (current > longest) {
          longest = current;
        }
      } else if (difference > 1) {
        current = 1;
      }
      previousDate = currentDate;
    }

    return longest;
  }

  /// Convert DateTime to date string (YYYY-MM-DD)
  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get weekly stats for home screen display
  Future<WeeklyStats> getWeeklyStats() async {
    final matches = await _matchHistoryService.getAllMatches();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weeklyMatches = matches.where((m) => m.date.isAfter(weekAgo)).toList();
    final weeklyWins = weeklyMatches.where((m) => m.result.toLowerCase() == 'win').length;

    // Calculate win rate change
    final previousWeekStart = weekAgo.subtract(const Duration(days: 7));
    final previousWeekMatches = matches.where(
      (m) => m.date.isAfter(previousWeekStart) && m.date.isBefore(weekAgo),
    ).toList();

    double winRateChange = 0;
    if (previousWeekMatches.isNotEmpty && weeklyMatches.isNotEmpty) {
      final previousWinRate = previousWeekMatches
              .where((m) => m.result.toLowerCase() == 'win')
              .length /
          previousWeekMatches.length;
      final currentWinRate = weeklyWins / weeklyMatches.length;
      winRateChange = (currentWinRate - previousWinRate) * 100;
    }

    // Get check-ins this week
    final checkIns = await StorageService.getCheckIns();
    final weeklyCheckIns = checkIns.where((c) {
      final date = DateTime.fromMillisecondsSinceEpoch(c.timestamp);
      return date.isAfter(weekAgo);
    }).length;

    // Calculate average mood this week
    final weeklyMoods = checkIns.where((c) {
      final date = DateTime.fromMillisecondsSinceEpoch(c.timestamp);
      return date.isAfter(weekAgo);
    }).map((c) => c.rating);

    double? averageMood;
    if (weeklyMoods.isNotEmpty) {
      averageMood = weeklyMoods.reduce((a, b) => a + b) / weeklyMoods.length;
    }

    return WeeklyStats(
      matchesPlayed: weeklyMatches.length,
      matchesWon: weeklyWins,
      winRate: weeklyMatches.isNotEmpty ? (weeklyWins / weeklyMatches.length) * 100 : 0,
      winRateChange: winRateChange,
      checkInsCompleted: weeklyCheckIns,
      averageMood: averageMood,
    );
  }
}

/// Represents streak data
class StreakResult {
  final int current;
  final int longest;

  StreakResult({required this.current, required this.longest});
}

/// Comprehensive streak data for display
class StreakData {
  final int currentCheckInStreak;
  final int longestCheckInStreak;
  final int currentWinStreak;
  final int longestWinStreak;
  final bool hasCheckedInToday;
  final DateTime? lastCheckInDate;
  final int totalCheckIns;
  final int totalMatches;
  final int? recentMood;

  StreakData({
    required this.currentCheckInStreak,
    required this.longestCheckInStreak,
    required this.currentWinStreak,
    required this.longestWinStreak,
    required this.hasCheckedInToday,
    this.lastCheckInDate,
    required this.totalCheckIns,
    required this.totalMatches,
    this.recentMood,
  });

  /// Get the primary streak to display (check-in streak takes priority)
  int get displayStreak => currentCheckInStreak > 0 ? currentCheckInStreak : currentWinStreak;

  /// Get streak type for display
  String get streakType => currentCheckInStreak > 0 ? 'day' : 'win';
}

/// Weekly statistics for home screen
class WeeklyStats {
  final int matchesPlayed;
  final int matchesWon;
  final double winRate;
  final double winRateChange;
  final int checkInsCompleted;
  final double? averageMood;

  WeeklyStats({
    required this.matchesPlayed,
    required this.matchesWon,
    required this.winRate,
    required this.winRateChange,
    required this.checkInsCompleted,
    this.averageMood,
  });

  bool get hasMatches => matchesPlayed > 0;
  bool get isWinRateUp => winRateChange > 0;
}
