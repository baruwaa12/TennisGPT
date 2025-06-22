class MatchPerformance {
  final String id;
  final DateTime date;
  final String opponent;
  final String result; // Win/Loss
  final int setsWon;
  final int setsLost;
  final String surface; // Hard, Clay, Grass, etc.
  final String weather;
  final String notes;
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
    required this.surface,
    required this.weather,
    required this.notes,
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
      'surface': surface,
      'weather': weather,
      'notes': notes,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'keyMoments': keyMoments,
      'tacticalAnalysis': tacticalAnalysis,
      'recommendedDrills': recommendedDrills,
    };
  }

  factory MatchPerformance.fromJson(Map<String, dynamic> json) {
    return MatchPerformance(
      id: json['id'],
      date: DateTime.parse(json['date']),
      opponent: json['opponent'],
      result: json['result'],
      setsWon: json['setsWon'],
      setsLost: json['setsLost'],
      surface: json['surface'],
      weather: json['weather'],
      notes: json['notes'],
      strengths: Map<String, int>.from(json['strengths']),
      weaknesses: Map<String, int>.from(json['weaknesses']),
      keyMoments: List<String>.from(json['keyMoments']),
      tacticalAnalysis: json['tacticalAnalysis'],
      recommendedDrills: List<String>.from(json['recommendedDrills']),
    );
  }

  MatchPerformance copyWith({
    String? id,
    DateTime? date,
    String? opponent,
    String? result,
    int? setsWon,
    int? setsLost,
    String? surface,
    String? weather,
    String? notes,
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
      surface: surface ?? this.surface,
      weather: weather ?? this.weather,
      notes: notes ?? this.notes,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      keyMoments: keyMoments ?? this.keyMoments,
      tacticalAnalysis: tacticalAnalysis ?? this.tacticalAnalysis,
      recommendedDrills: recommendedDrills ?? this.recommendedDrills,
    );
  }
} 