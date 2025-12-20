/// TennisValidator checks if user input is tennis-related.
/// Returns validation result with helpful message if not tennis-related.
class TennisValidator {
  // Tennis-related keywords (case-insensitive matching)
  static const List<String> _tennisKeywords = [
    // Strokes & Techniques
    'serve', 'forehand', 'backhand', 'volley', 'overhead', 'smash', 'lob',
    'slice', 'topspin', 'drop shot', 'approach', 'return', 'groundstroke',
    'kick serve', 'flat serve', 'first serve', 'second serve', 'ace',
    
    // Court & Equipment
    'court', 'baseline', 'net', 'racket', 'racquet', 'ball', 'strings',
    'grip', 'tennis', 'clay', 'hard court', 'grass', 'deuce', 'ad court',
    
    // Game Terms
    'match', 'set', 'game', 'point', 'tiebreak', 'tie-break', 'break point',
    'match point', 'set point', 'deuce', 'advantage', 'love', 'rally',
    'winner', 'unforced error', 'double fault', 'let', 'fault',
    
    // Tactics & Strategy
    'opponent', 'play', 'strategy', 'tactic', 'pattern', 'movement',
    'footwork', 'positioning', 'attack', 'defend', 'aggressive', 'defensive',
    'pusher', 'baseliner', 'serve and volley', 'counterpuncher',
    
    // Training & Improvement
    'drill', 'practice', 'training', 'warm up', 'warmup', 'fitness',
    'consistency', 'accuracy', 'power', 'spin', 'placement', 'timing',
    
    // Match Situations
    'win', 'loss', 'lost', 'won', 'beat', 'choke', 'choked', 'pressure',
    'nerves', 'nervous', 'focus', 'concentration', 'mental', 'confidence',
    'momentum', 'comeback', 'lead', 'behind', 'crunch time', 'close match',
    
    // Common phrases
    'playing', 'played', 'hitting', 'shot', 'shots', 'points', 'games',
    'sets', 'level', 'rating', 'ntrp', 'utr', 'ranking', 'tournament',
    'league', 'doubles', 'singles', 'partner', 'team',
  ];

  // Non-tennis indicators (if these appear WITHOUT tennis keywords, likely off-topic)
  static const List<String> _offTopicIndicators = [
    'recipe', 'cook', 'weather forecast', 'stock market', 'cryptocurrency',
    'bitcoin', 'politics', 'election', 'movie', 'music', 'song',
    'homework', 'essay', 'code', 'programming', 'javascript', 'python',
    'translate', 'write a story', 'poem', 'joke', 'riddle',
  ];

  /// Validates if the input is tennis-related
  /// Returns null if valid, or an error message if not tennis-related
  static String? validate(String input) {
    if (input.trim().isEmpty) {
      return null; // Empty input handled elsewhere
    }

    final trimmedInput = input.trim();
    final lowerInput = trimmedInput.toLowerCase();
    final wordCount = trimmedInput.split(RegExp(r'\s+')).length;

    // Reject single-word inputs - need more context
    if (wordCount <= 1) {
      return "Please provide more detail.\n\nExamples:\n• \"How do I beat a pusher?\"\n• \"My backhand breaks down under pressure\"\n• \"I lost 6-4 6-3 to a baseliner\"";
    }

    // Check for obvious off-topic content
    for (final indicator in _offTopicIndicators) {
      if (lowerInput.contains(indicator)) {
        return _getErrorMessage();
      }
    }

    // Check if any tennis keyword is present
    bool hasTennisContent = false;
    for (final keyword in _tennisKeywords) {
      if (lowerInput.contains(keyword.toLowerCase())) {
        hasTennisContent = true;
        break;
      }
    }

    // If no tennis keywords found in a substantial input, ask for clarity
    if (!hasTennisContent && trimmedInput.length > 15) {
      return _getErrorMessage();
    }

    return null; // Valid tennis-related content
  }

  static String _getErrorMessage() {
    return "Please describe a tennis-related situation.\n\nExamples:\n• \"How do I beat a pusher?\"\n• \"My backhand breaks down under pressure\"\n• \"I lost to a weaker opponent\"";
  }

  /// Quick check without detailed message (for real-time validation)
  static bool isTennisRelated(String input) {
    return validate(input) == null;
  }
}
