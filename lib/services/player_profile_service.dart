import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PlayerProfileService stores and retrieves player profile data
/// collected during onboarding.
class PlayerProfileService extends ChangeNotifier {
  // Storage keys
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _playerLevelKey = 'player_level';
  static const String _primaryGoalKey = 'primary_goal';
  static const String _playerNameKey = 'player_name';

  bool _hasCompletedOnboarding = false;
  String _playerLevel = '';
  String _primaryGoal = '';
  String _playerName = '';
  bool _isLoaded = false;

  // Player level options
  static const List<Map<String, String>> levelOptions = [
    {'id': 'beginner', 'title': 'Beginner', 'subtitle': 'Learning the basics'},
    {'id': 'intermediate', 'title': 'Intermediate', 'subtitle': 'NTRP 3.0-4.0'},
    {'id': 'advanced', 'title': 'Advanced', 'subtitle': 'NTRP 4.0-5.0'},
    {'id': 'competitive', 'title': 'Competitive', 'subtitle': 'Tournament player'},
  ];

  // Goal options
  static const List<Map<String, String>> goalOptions = [
    {'id': 'win_more', 'title': 'Win more matches', 'emoji': '🏆'},
    {'id': 'beat_opponents', 'title': 'Beat specific opponents', 'emoji': '🎯'},
    {'id': 'consistency', 'title': 'Improve consistency', 'emoji': '📈'},
    {'id': 'track_progress', 'title': 'Track my progress', 'emoji': '📊'},
  ];

  // Getters
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String get playerLevel => _playerLevel;
  String get primaryGoal => _primaryGoal;
  String get playerName => _playerName;
  bool get isLoaded => _isLoaded;

  /// Initialize and load saved profile data
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    _hasCompletedOnboarding = prefs.getBool(_hasCompletedOnboardingKey) ?? false;
    _playerLevel = prefs.getString(_playerLevelKey) ?? '';
    _primaryGoal = prefs.getString(_primaryGoalKey) ?? '';
    _playerName = prefs.getString(_playerNameKey) ?? '';
    
    _isLoaded = true;
    notifyListeners();
    
    if (kDebugMode) {
      print('PlayerProfileService: Loaded - Onboarding complete: $_hasCompletedOnboarding');
    }
  }

  /// Save player level
  Future<void> setPlayerLevel(String level) async {
    _playerLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerLevelKey, level);
    notifyListeners();
  }

  /// Save primary goal
  Future<void> setPrimaryGoal(String goal) async {
    _primaryGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_primaryGoalKey, goal);
    notifyListeners();
  }

  /// Save player name
  Future<void> setPlayerName(String name) async {
    _playerName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerNameKey, name);
    notifyListeners();
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
    notifyListeners();
    
    if (kDebugMode) {
      print('PlayerProfileService: Onboarding completed');
    }
  }

  /// Get player context for AI prompts
  String getPlayerContext() {
    if (_playerLevel.isEmpty && _primaryGoal.isEmpty) {
      return '';
    }
    
    final levelLabel = levelOptions.firstWhere(
      (l) => l['id'] == _playerLevel,
      orElse: () => {'title': 'Tennis player'},
    )['title'];
    
    final goalLabel = goalOptions.firstWhere(
      (g) => g['id'] == _primaryGoal,
      orElse: () => {'title': 'improve'},
    )['title'];
    
    return 'Player profile: $levelLabel level, main goal is to ${goalLabel?.toLowerCase()}.';
  }

  /// Reset profile (for testing)
  Future<void> resetProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasCompletedOnboardingKey);
    await prefs.remove(_playerLevelKey);
    await prefs.remove(_primaryGoalKey);
    await prefs.remove(_playerNameKey);
    
    _hasCompletedOnboarding = false;
    _playerLevel = '';
    _primaryGoal = '';
    _playerName = '';
    
    notifyListeners();
  }
}
