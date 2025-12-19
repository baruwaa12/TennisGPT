import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UsageService tracks free tier usage limits.
/// 
/// Free tier limits:
/// - 5 total matches logged
/// - 1 tactical analysis per month
/// - 3 pre-match prep sessions per month
/// - 3 post-match debriefs per month
class UsageService extends ChangeNotifier {
  // FREE TIER LIMITS
  static const int freeMatchesLimit = 5;
  static const int freeTacticalAnalysesPerMonth = 1;
  static const int freePrepSessionsPerMonth = 3;
  static const int freeDebriefsPerMonth = 3;
  
  // Storage keys
  static const String _matchCountKey = 'usage_match_count';
  static const String _tacticalAnalysesKey = 'usage_tactical_analyses';
  static const String _prepSessionsKey = 'usage_prep_sessions';
  static const String _debriefsKey = 'usage_debriefs';
  static const String _lastResetKey = 'usage_last_reset_month';

  int _matchCount = 0;
  int _tacticalAnalysesThisMonth = 0;
  int _prepSessionsThisMonth = 0;
  int _debriefsThisMonth = 0;
  bool _isLoaded = false;

  // Getters
  int get matchCount => _matchCount;
  int get tacticalAnalysesThisMonth => _tacticalAnalysesThisMonth;
  int get prepSessionsThisMonth => _prepSessionsThisMonth;
  int get debriefsThisMonth => _debriefsThisMonth;
  bool get isLoaded => _isLoaded;

  // Limit checkers
  bool get canLogMatch => _matchCount < freeMatchesLimit;
  bool get canUseTacticalAnalysis => _tacticalAnalysesThisMonth < freeTacticalAnalysesPerMonth;
  bool get canUsePrepSession => _prepSessionsThisMonth < freePrepSessionsPerMonth;
  bool get canUseDebrief => _debriefsThisMonth < freeDebriefsPerMonth;

  // Remaining counts
  int get matchesRemaining => (freeMatchesLimit - _matchCount).clamp(0, freeMatchesLimit);
  int get tacticalAnalysesRemaining => (freeTacticalAnalysesPerMonth - _tacticalAnalysesThisMonth).clamp(0, freeTacticalAnalysesPerMonth);
  int get prepSessionsRemaining => (freePrepSessionsPerMonth - _prepSessionsThisMonth).clamp(0, freePrepSessionsPerMonth);
  int get debriefsRemaining => (freeDebriefsPerMonth - _debriefsThisMonth).clamp(0, freeDebriefsPerMonth);

  /// Initialize and load saved usage data
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we need to reset monthly counters
    await _checkMonthlyReset(prefs);
    
    // Load counts
    _matchCount = prefs.getInt(_matchCountKey) ?? 0;
    _tacticalAnalysesThisMonth = prefs.getInt(_tacticalAnalysesKey) ?? 0;
    _prepSessionsThisMonth = prefs.getInt(_prepSessionsKey) ?? 0;
    _debriefsThisMonth = prefs.getInt(_debriefsKey) ?? 0;
    
    _isLoaded = true;
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: Loaded - Matches: $_matchCount, Analyses: $_tacticalAnalysesThisMonth');
    }
  }

  /// Check and reset monthly counters if new month
  Future<void> _checkMonthlyReset(SharedPreferences prefs) async {
    final currentMonth = '${DateTime.now().year}-${DateTime.now().month}';
    final lastReset = prefs.getString(_lastResetKey);
    
    if (lastReset != currentMonth) {
      // New month - reset monthly counters
      await prefs.setInt(_tacticalAnalysesKey, 0);
      await prefs.setInt(_prepSessionsKey, 0);
      await prefs.setInt(_debriefsKey, 0);
      await prefs.setString(_lastResetKey, currentMonth);
      
      _tacticalAnalysesThisMonth = 0;
      _prepSessionsThisMonth = 0;
      _debriefsThisMonth = 0;
      
      if (kDebugMode) {
        print('UsageService: Monthly counters reset');
      }
    }
  }

  /// Record a match logged
  Future<void> recordMatchLogged() async {
    _matchCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_matchCountKey, _matchCount);
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: Match logged - Count: $_matchCount');
    }
  }

  /// Record a tactical analysis used
  Future<void> recordTacticalAnalysis() async {
    _tacticalAnalysesThisMonth++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tacticalAnalysesKey, _tacticalAnalysesThisMonth);
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: Tactical analysis used - Count: $_tacticalAnalysesThisMonth');
    }
  }

  /// Record a prep session used
  Future<void> recordPrepSession() async {
    _prepSessionsThisMonth++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prepSessionsKey, _prepSessionsThisMonth);
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: Prep session used - Count: $_prepSessionsThisMonth');
    }
  }

  /// Record a debrief used
  Future<void> recordDebrief() async {
    _debriefsThisMonth++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_debriefsKey, _debriefsThisMonth);
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: Debrief used - Count: $_debriefsThisMonth');
    }
  }

  /// Get usage summary text
  String getMatchUsageText() {
    return '$_matchCount / $freeMatchesLimit matches';
  }

  String getTacticalUsageText() {
    return '$_tacticalAnalysesThisMonth / $freeTacticalAnalysesPerMonth this month';
  }

  String getPrepUsageText() {
    return '$_prepSessionsThisMonth / $freePrepSessionsPerMonth this month';
  }

  String getDebriefUsageText() {
    return '$_debriefsThisMonth / $freeDebriefsPerMonth this month';
  }

  /// Reset all usage (for testing or premium users)
  Future<void> resetAllUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_matchCountKey);
    await prefs.remove(_tacticalAnalysesKey);
    await prefs.remove(_prepSessionsKey);
    await prefs.remove(_debriefsKey);
    
    _matchCount = 0;
    _tacticalAnalysesThisMonth = 0;
    _prepSessionsThisMonth = 0;
    _debriefsThisMonth = 0;
    
    notifyListeners();
  }
}
