import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_storage_service.dart';

/// UsageService tracks free tier usage limits (client-side gate).
/// Backend is the real source of truth — this is a UX-level pre-check.
///
/// Free tier limits:
/// - 5 total matches logged (lifetime)
/// - 10 AI calls per day (resets daily UTC)
///
/// Premium users: unlimited (bypass all checks)
class UsageService extends ChangeNotifier {
  // FREE TIER LIMITS
  static const int freeMatchesLimit = 5;
  static const int freeDailyAILimit = 10;
  
  // Base storage keys (will be prefixed with user ID)
  static const String _baseMatchCountKey = 'usage_match_count';
  static const String _baseDailyAICountKey = 'usage_daily_ai_count';
  static const String _baseDailyAIDateKey = 'usage_daily_ai_date';
  
  // Legacy keys (for cleanup)
  static const String _legacyTacticalKey = 'usage_tactical_analyses';
  static const String _legacyPrepKey = 'usage_prep_sessions';
  static const String _legacyDebriefKey = 'usage_debriefs';
  static const String _legacyLifetimeKey = 'usage_ai_analyses_lifetime';

  int _matchCount = 0;
  int _dailyAIUsed = 0;
  String _dailyAIDate = '';
  bool _isLoaded = false;
  
  // User-specific keys
  String get _matchCountKey => UserStorageService.getUserKey(_baseMatchCountKey);
  String get _dailyAICountKey => UserStorageService.getUserKey(_baseDailyAICountKey);
  String get _dailyAIDateKey => UserStorageService.getUserKey(_baseDailyAIDateKey);

  // Getters
  int get matchCount => _matchCount;
  int get dailyAIUsed => _dailyAIUsed;
  bool get isLoaded => _isLoaded;

  // Today's date as UTC string for comparison
  static String _todayUTC() => DateTime.now().toUtc().toIso8601String().substring(0, 10);

  // Limit checkers
  bool get canLogMatch => _matchCount < freeMatchesLimit;
  bool get canUseTacticalAnalysis => _isToday() ? _dailyAIUsed < freeDailyAILimit : true;
  bool get canUsePrepSession => canUseTacticalAnalysis;
  bool get canUseDebrief => canUseTacticalAnalysis;

  bool _isToday() => _dailyAIDate == _todayUTC();

  // Remaining counts
  int get matchesRemaining => (freeMatchesLimit - _matchCount).clamp(0, freeMatchesLimit);
  int get aiAnalysesRemaining {
    if (!_isToday()) return freeDailyAILimit;
    return (freeDailyAILimit - _dailyAIUsed).clamp(0, freeDailyAILimit);
  }

  /// Initialize and load saved usage data
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Clean up legacy keys
    await _cleanupLegacy(prefs);
    
    // Load counts
    _matchCount = prefs.getInt(_matchCountKey) ?? 0;
    _dailyAIUsed = prefs.getInt(_dailyAICountKey) ?? 0;
    _dailyAIDate = prefs.getString(_dailyAIDateKey) ?? '';
    
    // Auto-reset if it's a new day
    if (!_isToday()) {
      _dailyAIUsed = 0;
      _dailyAIDate = _todayUTC();
      await prefs.setInt(_dailyAICountKey, 0);
      await prefs.setString(_dailyAIDateKey, _dailyAIDate);
    }
    
    _isLoaded = true;
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: Loaded - Matches: $_matchCount, AI today: $_dailyAIUsed/$freeDailyAILimit');
    }
  }

  /// Clean up legacy storage keys from old quota system
  Future<void> _cleanupLegacy(SharedPreferences prefs) async {
    await prefs.remove(UserStorageService.getUserKey(_legacyTacticalKey));
    await prefs.remove(UserStorageService.getUserKey(_legacyPrepKey));
    await prefs.remove(UserStorageService.getUserKey(_legacyDebriefKey));
    await prefs.remove(UserStorageService.getUserKey(_legacyLifetimeKey));
    await prefs.remove('usage_last_reset_month');
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

  /// Record an AI analysis used (daily pool)
  Future<void> _recordAIAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayUTC();
    
    // Reset if new day
    if (_dailyAIDate != today) {
      _dailyAIUsed = 0;
      _dailyAIDate = today;
    }
    
    _dailyAIUsed++;
    await prefs.setInt(_dailyAICountKey, _dailyAIUsed);
    await prefs.setString(_dailyAIDateKey, _dailyAIDate);
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: AI used today - Count: $_dailyAIUsed/$freeDailyAILimit');
    }
  }

  /// Record a tactical analysis used
  Future<void> recordTacticalAnalysis() async => _recordAIAnalysis();

  /// Record a prep session used
  Future<void> recordPrepSession() async => _recordAIAnalysis();

  /// Record a debrief used
  Future<void> recordDebrief() async => _recordAIAnalysis();

  /// Get usage summary text
  String getMatchUsageText() {
    return '$_matchCount / $freeMatchesLimit matches';
  }

  String getAIUsageText() {
    final remaining = aiAnalysesRemaining;
    return '$remaining / $freeDailyAILimit AI calls left today';
  }

  /// Reset in-memory state (for user switch)
  Future<void> resetAllUsage() async {
    _matchCount = 0;
    _dailyAIUsed = 0;
    _dailyAIDate = '';
    _isLoaded = false;
    
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: Reset in-memory state - ready for new user');
    }
  }
  
  /// Actually delete usage data (for dev tools reset)
  Future<void> deleteUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_matchCountKey);
    await prefs.remove(_dailyAICountKey);
    await prefs.remove(_dailyAIDateKey);
    
    _matchCount = 0;
    _dailyAIUsed = 0;
    _dailyAIDate = '';
    
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: Deleted usage data for current user');
    }
  }
}
