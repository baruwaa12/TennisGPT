import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/match_performance.dart';

class OpenAIService extends ChangeNotifier {
  // Update this URL to match your backend server
  final String _baseUrl = 'http://10.0.2.2:8000'; // For Android emulator
  // final String _baseUrl = 'http://localhost:8000'; // For iOS simulator
  
  bool _isLoading = false;
  String? _error;
  String? _lastResponse;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastResponse => _lastResponse;

  void clearResponse() {
    _lastResponse = null;
    _error = null;
    notifyListeners();
  }

  Future<String?> mentalCheckIn(String journalEntry) async {
    return _makeBackendRequest(
      '/mental-check-in',
      {'journal_entry': journalEntry},
    );
  }

  Future<String?> emotionalReset(String situation) async {
    return _makeBackendRequest(
      '/emotional-reset',
      {'situation': situation},
    );
  }

  Future<String?> tacticalAnalysis(String matchDescription, List<MatchPerformance>? recentMatches) async {
    final Map<String, dynamic> requestBody = {
      'match_description': matchDescription,
    };

    if (recentMatches != null && recentMatches.isNotEmpty) {
      requestBody['recent_matches'] = recentMatches.take(3).map((match) => {
        'date': match.date.toString().split(' ')[0],
        'result': match.result,
        'opponent': match.opponent,
        'surface': match.surface,
        'strengths': match.strengths,
        'weaknesses': match.weaknesses,
      }).toList();
    }

    return _makeBackendRequest('/tactical-analysis', requestBody);
  }

  Future<String?> generateDrillsFromHistory(List<MatchPerformance> matches) async {
    final List<Map<String, dynamic>> matchesData = matches.map((match) => {
      'date': match.date.toString().split(' ')[0],
      'result': match.result,
      'opponent': match.opponent,
      'surface': match.surface,
      'strengths': match.strengths,
      'weaknesses': match.weaknesses,
    }).toList();

    return _makeBackendRequest('/drill-recommendations', {'matches': matchesData});
  }

  Future<String?> quickTacticalTip(String situation) async {
    return _makeBackendRequest(
      '/quick-tactical-tip',
      {'situation': situation},
    );
  }

  Future<String?> _makeBackendRequest(String endpoint, Map<String, dynamic> body) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastResponse = data['response'];
        notifyListeners();
        return _lastResponse;
      } else {
        _error = 'Error: ${response.statusCode} - ${response.body}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Legacy methods for backward compatibility
  Future<String?> analyzeTechnique(String description) async {
    return _makeBackendRequest(
      '/tactical-analysis',
      {'match_description': 'Technique analysis: $description'},
    );
  }

  Future<String?> getMatchStrategy(String opponentDescription) async {
    return _makeBackendRequest(
      '/tactical-analysis',
      {'match_description': 'Match strategy for opponent: $opponentDescription'},
    );
  }

  Future<String?> generateTrainingPlan(String playerLevel, String goals) async {
    return _makeBackendRequest(
      '/drill-recommendations',
      {'matches': []}, // Empty matches for foundational drills
    );
  }

  Future<String?> analyzeVideo(String videoDescription) async {
    return _makeBackendRequest(
      '/tactical-analysis',
      {'match_description': 'Video analysis: $videoDescription'},
    );
  }
} 