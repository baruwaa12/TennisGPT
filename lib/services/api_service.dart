import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/match_performance.dart';
import 'token_service.dart';

class ApiService extends ChangeNotifier {
  final String _baseUrl = 'https://tennisgpt-production.up.railway.app';
  final TokenService _tokenService = TokenService();
  static const Duration _timeout = Duration(seconds: 60);

  bool _isLoading = false;
  String? _error;
  String? _lastResponse;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastResponse => _lastResponse;

  /// Safely decode JSON, handling empty responses
  Map<String, dynamic>? _safeJsonDecode(String body) {
    if (body.isEmpty) {
      if (kDebugMode) {
        print('ApiService: Empty response body');
      }
      return null;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (kDebugMode) {
        print('ApiService: Response is not a Map: $decoded');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('ApiService: JSON decode error - $e');
        print('ApiService: Body was: $body');
      }
      return null;
    }
  }

  void clearResponse() {
    _lastResponse = null;
    _error = null;
    notifyListeners();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============ Coaching Endpoints ============

  Future<String?> mentalCheckIn(int mood, String journalEntry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/coaching/mental-check-in'),
        headers: headers,
        body: jsonEncode({
          'mood': mood,
          'journalEntry': journalEntry,
        }),
      );

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data == null) {
          _error = 'Invalid response from server';
          notifyListeners();
          return null;
        }
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

  Future<String?> emotionalReset(String situation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/coaching/emotional-reset'),
        headers: headers,
        body: jsonEncode({'situation': situation}),
      );

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data == null) {
          _error = 'Invalid response from server';
          notifyListeners();
          return null;
        }
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

  Future<String?> tacticalAnalysis(String matchDescription, List<MatchPerformance>? recentMatches) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final matchesJson = recentMatches != null && recentMatches.isNotEmpty
          ? recentMatches.take(3).map((match) => match.toJson()).toList()
          : null;

      if (kDebugMode) {
        print('ApiService: Calling tactical-analysis...');
        print('ApiService: Headers: $headers');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/coaching/tactical-analysis'),
        headers: headers,
        body: jsonEncode({
          'matchDescription': matchDescription,
          'recentMatches': matchesJson,
        }),
      ).timeout(_timeout);

      if (kDebugMode) {
        print('ApiService: Response status: ${response.statusCode}');
        print('ApiService: Response body: ${response.body.substring(0, response.body.length.clamp(0, 500))}');
      }

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data == null) {
          _error = 'Server returned invalid data';
          notifyListeners();
          return null;
        }
        _lastResponse = data['response'] ?? data['message'] ?? data.toString();
        notifyListeners();
        return _lastResponse;
      } else if (response.statusCode == 401) {
        _error = 'Please sign in again';
        notifyListeners();
        return null;
      } else {
        _error = 'Server error (${response.statusCode})';
        notifyListeners();
        return null;
      }
    } on TimeoutException {
      _error = 'Request timed out. Please try again.';
      notifyListeners();
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('ApiService: Exception - $e');
      }
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        _error = 'No internet connection';
      } else {
        _error = 'Connection failed. Please try again.';
      }
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateDrillsFromHistory(List<MatchPerformance> matches) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final matchesJson = matches.map((match) => match.toJson()).toList();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/coaching/drills'),
        headers: headers,
        body: jsonEncode({'matches': matchesJson}),
      );

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data == null) {
          _error = 'Invalid response from server';
          notifyListeners();
          return null;
        }
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

  Future<String?> quickTacticalTip(String situation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/coaching/quick-tip'),
        headers: headers,
        body: jsonEncode({'situation': situation}),
      );

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data == null) {
          _error = 'Invalid response from server';
          notifyListeners();
          return null;
        }
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/coaching/technique'),
        headers: headers,
        body: jsonEncode({'description': description}),
      );

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data == null) {
          _error = 'Invalid response from server';
          notifyListeners();
          return null;
        }
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

  Future<String?> getMatchStrategy(String opponentDescription) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/coaching/match-strategy'),
        headers: headers,
        body: jsonEncode({'opponentDescription': opponentDescription}),
      );

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data == null) {
          _error = 'Invalid response from server';
          notifyListeners();
          return null;
        }
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

  Future<String?> generateTrainingPlan(String playerLevel, String goals) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/coaching/training-plan'),
        headers: headers,
        body: jsonEncode({
          'playerLevel': playerLevel,
          'goals': goals,
        }),
      );

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data == null) {
          _error = 'Invalid response from server';
          notifyListeners();
          return null;
        }
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
}
