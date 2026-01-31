class MatchFormat {
  static const String fast4 = 'Fast4';
  static const String bestOf3 = 'Best of 3 sets';
  static const String shortSets = 'Short sets';

  static const List<String> values = [
    fast4,
    bestOf3,
    shortSets,
  ];
}

class MatchScoreParseResult {
  final int setsWon;
  final int setsLost;
  final List<String> setScores;
  final String displayScore;

  const MatchScoreParseResult({
    required this.setsWon,
    required this.setsLost,
    required this.setScores,
    required this.displayScore,
  });
}

class MatchScoreValidator {
  static final RegExp _setScorePattern = RegExp(r'^(\d+)-(\d+)(?:\((\d+)\))?$');

  static List<String> _splitSets(String scoreLine) {
    return scoreLine
        .trim()
        .split(RegExp(r'[\s,]+'))
        .where((part) => part.isNotEmpty)
        .toList();
  }

  static String? validate(String format, String scoreLine) {
    final trimmed = scoreLine.trim();
    if (trimmed.isEmpty) {
      return 'Enter the score';
    }

    final sets = _splitSets(trimmed);
    if (sets.isEmpty) {
      return 'Enter at least one set score';
    }

    if (format == MatchFormat.bestOf3 && (sets.length < 2 || sets.length > 3)) {
      return 'Best of 3 requires 2 or 3 sets (e.g. 6-4 7-6(5))';
    }

    for (final set in sets) {
      final match = _setScorePattern.firstMatch(set);
      if (match == null) {
        return 'Use set scores like 6-4 or 7-6(5)';
      }

      final a = int.parse(match.group(1)!);
      final b = int.parse(match.group(2)!);
      final hasTiebreak = match.group(3) != null;

      if (a == b) {
        return 'Set scores cannot be tied';
      }

      if (format == MatchFormat.fast4) {
        if (!_isValidFast4Set(a, b)) {
          return 'Fast4 sets must be 4-0 to 4-3 (tiebreak score optional at 4-3)';
        }
      } else if (format == MatchFormat.bestOf3) {
        if (!_isValidBestOf3Set(a, b, hasTiebreak)) {
          return 'Best of 3 sets use 6-game sets (tiebreak required at 7-6)';
        }
      } else if (format == MatchFormat.shortSets) {
        if (!_isValidShortSet(a, b, hasTiebreak)) {
          return 'Short sets use 4-game or 6-game sets (tiebreak required at 7-6)';
        }
      }
    }

    return null;
  }

  static MatchScoreParseResult parse(String format, String scoreLine) {
    final sets = _splitSets(scoreLine);
    int setsWon = 0;
    int setsLost = 0;

    for (final set in sets) {
      final match = _setScorePattern.firstMatch(set);
      if (match == null) {
        continue;
      }
      final a = int.parse(match.group(1)!);
      final b = int.parse(match.group(2)!);
      if (a > b) {
        setsWon += 1;
      } else if (b > a) {
        setsLost += 1;
      }
    }

    return MatchScoreParseResult(
      setsWon: setsWon,
      setsLost: setsLost,
      setScores: sets,
      displayScore: sets.join(' '),
    );
  }

  static bool _isValidFast4Set(int a, int b) {
    if (!((a == 4 && b >= 0 && b <= 3) || (b == 4 && a >= 0 && a <= 3))) {
      return false;
    }
    return true;
  }

  static bool _isValidBestOf3Set(int a, int b, bool hasTiebreak) {
    final isTiebreakSet = (a == 7 && b == 6) || (a == 6 && b == 7);
    if (isTiebreakSet) {
      return hasTiebreak;
    }

    final validWinner = (a == 6 && b >= 0 && b <= 4) || (b == 6 && a >= 0 && a <= 4);
    final validSevenFive = (a == 7 && b == 5) || (b == 7 && a == 5);

    return validWinner || validSevenFive;
  }

  static bool _isValidShortSet(int a, int b, bool hasTiebreak) {
    final fast4Set = _isValidFast4Set(a, b);
    if (fast4Set) {
      return true;
    }

    final bestOf3Set = _isValidBestOf3Set(a, b, hasTiebreak);
    if (bestOf3Set) {
      return true;
    }

    return false;
  }
}

