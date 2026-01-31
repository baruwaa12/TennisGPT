import '../utils/match_format_utils.dart';

class MatchPerformance {
  final String id;
  final DateTime date;
  final String opponent;
  final String result; // Win/Loss
  final int setsWon;
  final int setsLost;
  final String matchFormat; // Fast4, Best of 3 sets, Short sets
  final String scoreLine; // e.g., "6-4 7-6(5)" or "4-3(5)"
  final List<String> setScores; // Parsed set scores
  final String opponentLevelSeed; // Optional: level/seed
  final String surface; // Hard, Clay, Grass, etc.
  final String weather;
  final String notes;
  final String matchSummary;
  final String mentalNotes;
  final String tacticalNotes;
  final String strengthNotes;
  final String weaknessNotes;
  final Map<String, int> strengths; // e.g., {"serve": 8, "forehand": 7}
  final Map<String, int> weaknesses; // e.g., {"backhand": 4, "volley": 3}
  final List<String> keyMoments; // Critical points or situations
  final String tacticalAnalysis; // AI-generated analysis
  final List<String> recommendedDrills; // AI-recommended drills

  MatchPerformance({
    required this.id,
    required this.date,
    required this.opponent,
    required this.result,
    required this.setsWon,
    required this.setsLost,
    required this.matchFormat,
    required this.scoreLine,
    required this.setScores,
    required this.opponentLevelSeed,
    required this.surface,
    required this.weather,
    required this.notes,
    required this.matchSummary,
    required this.mentalNotes,
    required this.tacticalNotes,
    required this.strengthNotes,
    required this.weaknessNotes,
    required this.strengths,
    required this.weaknesses,
    required this.keyMoments,
    required this.tacticalAnalysis,
    required this.recommendedDrills,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'opponent': opponent,
      'result': result,
      'setsWon': setsWon,
      'setsLost': setsLost,
      'matchFormat': matchFormat,
      'scoreLine': scoreLine,
      'setScores': setScores,
      'opponentLevelSeed': opponentLevelSeed,
      'surface': surface,
      'weather': weather,
      'notes': notes,
      'matchSummary': matchSummary,
      'mentalNotes': mentalNotes,
      'tacticalNotes': tacticalNotes,
      'strengthNotes': strengthNotes,
      'weaknessNotes': weaknessNotes,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'keyMoments': keyMoments,
      'tacticalAnalysis': tacticalAnalysis,
      'recommendedDrills': recommendedDrills,
    };
  }

  factory MatchPerformance.fromJson(Map<String, dynamic> json) {
    final fallbackScoreLine = '${json['setsWon'] ?? 0}-${json['setsLost'] ?? 0}';
    return MatchPerformance(
      id: json['id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      opponent: json['opponent'] ?? 'Unknown',
      result: json['result'] ?? 'Unknown',
      setsWon: json['setsWon'] ?? 0,
      setsLost: json['setsLost'] ?? 0,
      matchFormat: json['matchFormat'] ?? MatchFormat.bestOf3,
      scoreLine: json['scoreLine'] ?? fallbackScoreLine,
      setScores: json['setScores'] != null ? List<String>.from(json['setScores']) : <String>[],
      opponentLevelSeed: json['opponentLevelSeed'] ?? '',
      surface: json['surface'] ?? 'Hard',
      weather: json['weather'] ?? 'Unknown',
      notes: json['notes'] ?? '',
      matchSummary: json['matchSummary'] ?? '',
      mentalNotes: json['mentalNotes'] ?? '',
      tacticalNotes: json['tacticalNotes'] ?? '',
      strengthNotes: json['strengthNotes'] ?? '',
      weaknessNotes: json['weaknessNotes'] ?? '',
      strengths: json['strengths'] != null ? Map<String, int>.from(json['strengths']) : {},
      weaknesses: json['weaknesses'] != null ? Map<String, int>.from(json['weaknesses']) : {},
      keyMoments: json['keyMoments'] != null ? List<String>.from(json['keyMoments']) : [],
      tacticalAnalysis: json['tacticalAnalysis'] ?? '',
      recommendedDrills: json['recommendedDrills'] != null ? List<String>.from(json['recommendedDrills']) : [],
    );
  }

  MatchPerformance copyWith({
    String? id,
    DateTime? date,
    String? opponent,
    String? result,
    int? setsWon,
    int? setsLost,
    String? matchFormat,
    String? scoreLine,
    List<String>? setScores,
    String? opponentLevelSeed,
    String? surface,
    String? weather,
    String? notes,
    String? matchSummary,
    String? mentalNotes,
    String? tacticalNotes,
    String? strengthNotes,
    String? weaknessNotes,
    Map<String, int>? strengths,
    Map<String, int>? weaknesses,
    List<String>? keyMoments,
    String? tacticalAnalysis,
    List<String>? recommendedDrills,
  }) {
    return MatchPerformance(
      id: id ?? this.id,
      date: date ?? this.date,
      opponent: opponent ?? this.opponent,
      result: result ?? this.result,
      setsWon: setsWon ?? this.setsWon,
      setsLost: setsLost ?? this.setsLost,
      matchFormat: matchFormat ?? this.matchFormat,
      scoreLine: scoreLine ?? this.scoreLine,
      setScores: setScores ?? this.setScores,
      opponentLevelSeed: opponentLevelSeed ?? this.opponentLevelSeed,
      surface: surface ?? this.surface,
      weather: weather ?? this.weather,
      notes: notes ?? this.notes,
      matchSummary: matchSummary ?? this.matchSummary,
      mentalNotes: mentalNotes ?? this.mentalNotes,
      tacticalNotes: tacticalNotes ?? this.tacticalNotes,
      strengthNotes: strengthNotes ?? this.strengthNotes,
      weaknessNotes: weaknessNotes ?? this.weaknessNotes,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      keyMoments: keyMoments ?? this.keyMoments,
      tacticalAnalysis: tacticalAnalysis ?? this.tacticalAnalysis,
      recommendedDrills: recommendedDrills ?? this.recommendedDrills,
    );
  }
} 