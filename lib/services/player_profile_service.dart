import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'token_service.dart';
import 'user_storage_service.dart';

/// PlayerProfileService stores and retrieves player profile data
/// Now uses user-specific storage keys for multi-account support.
class PlayerProfileService extends ChangeNotifier {
  final String _apiBaseUrl = AppConfig.apiBaseUrl;
  final TokenService _tokenService = TokenService();
  
  // Base storage keys (will be prefixed with user ID)
  static const String _baseOnboardingKey = 'has_completed_onboarding';
  static const String _baseLevelKey = 'player_level';
  static const String _baseGoalKey = 'primary_goal';
  static const String _baseNameKey = 'player_name';
  
  // User-specific keys
  String get _hasCompletedOnboardingKey => UserStorageService.getUserKey(_baseOnboardingKey);
  String get _playerLevelKey => UserStorageService.getUserKey(_baseLevelKey);
  String get _primaryGoalKey => UserStorageService.getUserKey(_baseGoalKey);
  String get _playerNameKey => UserStorageService.getUserKey(_baseNameKey);

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

  /// Mark onboarding as complete (locally and on backend)
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
    notifyListeners();
    
    // Sync to backend
    try {
      final token = await _tokenService.getAccessToken();
      if (token != null) {
        await http.post(
          Uri.parse('$_apiBaseUrl/api/auth/onboarding-complete'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (kDebugMode) {
          print('PlayerProfileService: Onboarding synced to backend');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('PlayerProfileService: Failed to sync onboarding to backend - $e');
      }
    }
    
    if (kDebugMode) {
      print('PlayerProfileService: Onboarding completed');
    }
  }
  
  /// Sync onboarding status from backend (called after login)
  Future<void> syncFromBackend(bool backendOnboardingCompleted) async {
    if (backendOnboardingCompleted && !_hasCompletedOnboarding) {
      _hasCompletedOnboarding = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasCompletedOnboardingKey, true);
      notifyListeners();
      
      if (kDebugMode) {
        print('PlayerProfileService: Synced onboarding from backend (completed)');
      }
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
    
    // Add complexity instructions based on level
    String complexityInstructions = '';
    switch (_playerLevel) {
      case 'beginner':
        complexityInstructions = '''
RESPONSE COMPLEXITY: BEGINNER LEVEL
- Use simple, everyday language (avoid tennis jargon or explain it)
- Focus on fundamentals and basic concepts
- Give step-by-step instructions
- Keep recommendations simple and achievable
- Explain "why" in simple terms''';
        break;
      case 'intermediate':
        complexityInstructions = '''
RESPONSE COMPLEXITY: INTERMEDIATE LEVEL
- Use standard tennis terminology
- Include tactical concepts they can apply
- Balance technical detail with practicality
- Assume knowledge of basic strokes and court positions''';
        break;
      case 'advanced':
        complexityInstructions = '''
RESPONSE COMPLEXITY: ADVANCED LEVEL
- Use technical tennis terminology freely
- Include nuanced tactical concepts
- Discuss shot selection and pattern play
- Reference specific situations and adjustments''';
        break;
      case 'competitive':
        complexityInstructions = '''
RESPONSE COMPLEXITY: COMPETITIVE/TOURNAMENT LEVEL
- Use advanced technical language
- Include match strategy and opponent analysis concepts
- Discuss high-pressure situations and mental game
- Reference professional-level tactics and patterns
- Be data-driven and analytical''';
        break;
      default:
        complexityInstructions = '';
    }
    
    return '''Player profile: $levelLabel level, main goal is to ${goalLabel?.toLowerCase()}.

$complexityInstructions''';
  }

  /// Reset in-memory state (for user switch - preserves stored data)
  /// With user-specific keys, switching users automatically uses different data
  Future<void> resetProfile() async {
    _hasCompletedOnboarding = false;
    _playerLevel = '';
    _primaryGoal = '';
    _playerName = '';
    _isLoaded = false; // Allow re-initialization for new user
    
    notifyListeners();
    
    if (kDebugMode) {
      print('PlayerProfileService: Reset in-memory state - ready for new user');
    }
  }
}
