import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UsageService tracks free tier usage limits.
/// 
/// Free tier limits (LIFETIME, not monthly):
/// - 5 total matches logged
/// - 4 AI analyses total (shared across Tactical/Prep/Debrief)
class UsageService extends ChangeNotifier {
  // FREE TIER LIMITS
  static const int freeMatchesLimit = 5;
  static const int freeAIAnalysesLimit = 4; // 4 lifetime total across all AI features
  
  // Storage keys
  static const String _matchCountKey = 'usage_match_count';
  static const String _aiAnalysesKey = 'usage_ai_analyses_lifetime'; // Lifetime counter
  
  // Legacy keys (for migration)
  static const String _legacyTacticalKey = 'usage_tactical_analyses';
  static const String _legacyPrepKey = 'usage_prep_sessions';
  static const String _legacyDebriefKey = 'usage_debriefs';

  int _matchCount = 0;
  int _aiAnalysesUsed = 0;
  bool _isLoaded = false;

  // Getters
  int get matchCount => _matchCount;
  int get aiAnalysesUsed => _aiAnalysesUsed;
  bool get isLoaded => _isLoaded;

  // Limit checkers (all AI features share the same pool)
  bool get canLogMatch => _matchCount < freeMatchesLimit;
  bool get canUseTacticalAnalysis => _aiAnalysesUsed < freeAIAnalysesLimit;
  bool get canUsePrepSession => _aiAnalysesUsed < freeAIAnalysesLimit;
  bool get canUseDebrief => _aiAnalysesUsed < freeAIAnalysesLimit;

  // Remaining counts
  int get matchesRemaining => (freeMatchesLimit - _matchCount).clamp(0, freeMatchesLimit);
  int get aiAnalysesRemaining => (freeAIAnalysesLimit - _aiAnalysesUsed).clamp(0, freeAIAnalysesLimit);

  /// Initialize and load saved usage data
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Migrate from legacy monthly counters if needed
    await _migrateFromLegacy(prefs);
    
    // Load counts
    _matchCount = prefs.getInt(_matchCountKey) ?? 0;
    _aiAnalysesUsed = prefs.getInt(_aiAnalysesKey) ?? 0;
    
    _isLoaded = true;
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: Loaded - Matches: $_matchCount, AI Analyses: $_aiAnalysesUsed/$freeAIAnalysesLimit');
    }
  }

  /// Migrate from legacy monthly counters to new lifetime counter
  Future<void> _migrateFromLegacy(SharedPreferences prefs) async {
    // Check if we already have the new key
    if (prefs.containsKey(_aiAnalysesKey)) return;
    
    // Sum up all legacy usage
    final legacyTactical = prefs.getInt(_legacyTacticalKey) ?? 0;
    final legacyPrep = prefs.getInt(_legacyPrepKey) ?? 0;
    final legacyDebrief = prefs.getInt(_legacyDebriefKey) ?? 0;
    final totalLegacy = legacyTactical + legacyPrep + legacyDebrief;
    
    if (totalLegacy > 0) {
      // Migrate: give them credit for what they've used, but cap at new limit
      await prefs.setInt(_aiAnalysesKey, totalLegacy.clamp(0, freeAIAnalysesLimit));
      
      if (kDebugMode) {
        print('UsageService: Migrated $totalLegacy legacy uses to lifetime counter');
      }
    }
    
    // Clean up legacy keys
    await prefs.remove(_legacyTacticalKey);
    await prefs.remove(_legacyPrepKey);
    await prefs.remove(_legacyDebriefKey);
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

  /// Record an AI analysis used (shared pool)
  Future<void> _recordAIAnalysis() async {
    _aiAnalysesUsed++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_aiAnalysesKey, _aiAnalysesUsed);
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: AI analysis used - Count: $_aiAnalysesUsed/$freeAIAnalysesLimit');
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
    return '$_aiAnalysesUsed / $freeAIAnalysesLimit free analyses used';
  }

  /// Reset all usage (for user switch - clears in-memory AND forces re-initialization)
  Future<void> resetAllUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_matchCountKey);
    await prefs.remove(_aiAnalysesKey);
    
    _matchCount = 0;
    _aiAnalysesUsed = 0;
    _isLoaded = false; // CRITICAL: Allow re-initialization for new user
    
    notifyListeners();
    
    if (kDebugMode) {
      print('UsageService: Reset complete - ready for new user');
    }
  }
}
