import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// PatternService detects recurring patterns across matches
/// to provide smarter insights and suggestions.
class PatternService {
  static const String _reflectionsKey = 'match_reflections';
  static const int _patternThreshold = 3; // Minimum occurrences to detect pattern

  /// Save reflection data for pattern analysis
  Future<void> saveReflection({
    required String matchId,
    required List<String> strengths,
    required List<String> weaknesses,
    required String result,
    required DateTime date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final reflectionsJson = prefs.getString(_reflectionsKey);
    
    List<Map<String, dynamic>> reflections = [];
    if (reflectionsJson != null && reflectionsJson.isNotEmpty) {
      try {
      reflections = List<Map<String, dynamic>>.from(json.decode(reflectionsJson));
      } catch (e) {
        // If JSON is corrupted, start fresh
        reflections = [];
      }
    }
    
    reflections.add({
      'matchId': matchId,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'result': result,
      'date': date.toIso8601String(),
    });
    
    // Keep only last 20 reflections
    if (reflections.length > 20) {
      reflections = reflections.sublist(reflections.length - 20);
    }
    
    await prefs.setString(_reflectionsKey, json.encode(reflections));
  }

  /// Get all stored reflections
  Future<List<Map<String, dynamic>>> getReflections() async {
    final prefs = await SharedPreferences.getInstance();
    final reflectionsJson = prefs.getString(_reflectionsKey);
    
    if (reflectionsJson == null || reflectionsJson.isEmpty) return [];
    
    try {
    return List<Map<String, dynamic>>.from(json.decode(reflectionsJson));
    } catch (e) {
      // If JSON is corrupted, return empty list
      return [];
    }
  }

  /// Detect weakness patterns across recent matches
  Future<List<PatternInsight>> detectWeaknessPatterns() async {
    final reflections = await getReflections();
    if (reflections.length < 3) return [];
    
    // Count weakness occurrences
    final weaknessCounts = <String, int>{};
    for (final reflection in reflections) {
      final weaknesses = List<String>.from(reflection['weaknesses'] ?? []);
      for (final weakness in weaknesses) {
        weaknessCounts[weakness] = (weaknessCounts[weakness] ?? 0) + 1;
      }
    }
    
    // Find patterns (occurring in threshold+ matches)
    final patterns = <PatternInsight>[];
    for (final entry in weaknessCounts.entries) {
      if (entry.value >= _patternThreshold) {
        patterns.add(PatternInsight(
          type: PatternType.recurringWeakness,
          key: entry.key,
          count: entry.value,
          totalMatches: reflections.length,
          suggestion: _getSuggestionForWeakness(entry.key),
        ));
      }
    }
    
    // Sort by frequency
    patterns.sort((a, b) => b.count.compareTo(a.count));
    
    return patterns;
  }

  /// Detect strength patterns across recent matches
  Future<List<PatternInsight>> detectStrengthPatterns() async {
    final reflections = await getReflections();
    if (reflections.length < 3) return [];
    
    final strengthCounts = <String, int>{};
    for (final reflection in reflections) {
      final strengths = List<String>.from(reflection['strengths'] ?? []);
      for (final strength in strengths) {
        strengthCounts[strength] = (strengthCounts[strength] ?? 0) + 1;
      }
    }
    
    final patterns = <PatternInsight>[];
    for (final entry in strengthCounts.entries) {
      if (entry.value >= _patternThreshold) {
        patterns.add(PatternInsight(
          type: PatternType.consistentStrength,
          key: entry.key,
          count: entry.value,
          totalMatches: reflections.length,
          suggestion: _getSuggestionForStrength(entry.key),
        ));
      }
    }
    
    patterns.sort((a, b) => b.count.compareTo(a.count));
    
    return patterns;
  }

  /// Get weakness patterns related to losses specifically
  Future<List<PatternInsight>> detectLossPatterns() async {
    final reflections = await getReflections();
    final losses = reflections.where((r) => 
      r['result']?.toString().toLowerCase() == 'loss'
    ).toList();
    
    if (losses.length < 2) return [];
    
    final weaknessCounts = <String, int>{};
    for (final reflection in losses) {
      final weaknesses = List<String>.from(reflection['weaknesses'] ?? []);
      for (final weakness in weaknesses) {
        weaknessCounts[weakness] = (weaknessCounts[weakness] ?? 0) + 1;
      }
    }
    
    final patterns = <PatternInsight>[];
    for (final entry in weaknessCounts.entries) {
      if (entry.value >= 2) {
        patterns.add(PatternInsight(
          type: PatternType.lossCorrelation,
          key: entry.key,
          count: entry.value,
          totalMatches: losses.length,
          suggestion: 'This issue appeared in ${entry.value} of your ${losses.length} losses. Prioritize this in practice.',
        ));
      }
    }
    
    patterns.sort((a, b) => b.count.compareTo(a.count));
    
    return patterns;
  }

  /// Get a formatted pattern message
  Future<String?> getTopPatternMessage() async {
    final weaknessPatterns = await detectWeaknessPatterns();
    
    if (weaknessPatterns.isEmpty) return null;
    
    final top = weaknessPatterns.first;
    return "📊 Pattern: \"${_formatWeaknessLabel(top.key)}\" in ${top.count} of your last ${top.totalMatches} matches.";
  }

  String _formatWeaknessLabel(String key) {
    const labels = {
      'errors': 'Unforced errors',
      'backhand': 'Backhand issues',
      'focus': 'Focus problems',
      'fitness': 'Fitness/stamina',
      'serve': 'Serve inconsistency',
      'nerves': 'Nerves',
    };
    return labels[key] ?? key;
  }

  String _getSuggestionForWeakness(String key) {
    const suggestions = {
      'errors': 'Focus on shot selection and playing within your comfort zone. Drill: 10 consecutive crosscourt rallies without error.',
      'backhand': 'Dedicate practice time to backhand stability. Drill: 50 crosscourt backhands with target placement.',
      'focus': 'Work on between-point routines. Practice breathing exercises and have a consistent ritual.',
      'fitness': 'Add cardio and on-court movement drills. Consider interval training to simulate match conditions.',
      'serve': 'Focus on toss consistency and rhythm. Drill: 20 serves to each target with 70% accuracy goal.',
      'nerves': 'Practice pressure situations. Play more tie-breakers and simulate match points in practice.',
    };
    return suggestions[key] ?? 'Review this area in your next practice session.';
  }

  String _getSuggestionForStrength(String key) {
    const suggestions = {
      'serve': 'Your serve is a weapon. Use it more aggressively in key moments.',
      'movement': 'Great movement! Keep this up and use it to extend rallies.',
      'shot_selection': 'Smart shot selection is winning you points. Trust your instincts.',
      'focus': 'Your mental game is strong. Leverage this in tight situations.',
      'returns': 'Strong returns give you an advantage. Keep the pressure on servers.',
      'net_play': 'Your net play is effective. Look for more opportunities to come forward.',
    };
    return suggestions[key] ?? 'This is a consistent strength. Keep it up!';
  }

  /// Clear all pattern data (for testing)
  Future<void> clearPatterns() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reflectionsKey);
  }
}

/// Types of patterns detected
enum PatternType {
  recurringWeakness,
  consistentStrength,
  lossCorrelation,
}

/// A detected pattern insight
class PatternInsight {
  final PatternType type;
  final String key;
  final int count;
  final int totalMatches;
  final String suggestion;

  PatternInsight({
    required this.type,
    required this.key,
    required this.count,
    required this.totalMatches,
    required this.suggestion,
  });

  String get label {
    const labels = {
      'errors': 'Unforced errors',
      'backhand': 'Backhand issues',
      'focus': 'Focus problems',
      'fitness': 'Fitness/stamina',
      'serve': 'Serve inconsistency',
      'nerves': 'Nerves',
      'movement': 'Good movement',
      'shot_selection': 'Smart shot selection',
      'returns': 'Solid returns',
      'net_play': 'Effective net play',
    };
    return labels[key] ?? key;
  }

  String get emoji {
    switch (type) {
      case PatternType.recurringWeakness:
        return '⚠️';
      case PatternType.consistentStrength:
        return '💪';
      case PatternType.lossCorrelation:
        return '📉';
    }
  }
}
