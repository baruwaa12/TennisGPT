import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/match_performance.dart';

class ApiService extends ChangeNotifier {
  // Replace this with your actual Railway URL once deployed
  static const String _baseUrl = 'https://your-app-name.railway.app';
  
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

  Future<String?> mentalCheckIn(int mood, String journalEntry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mental-check-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'journal_entry': journalEntry,
          'mood_rating': mood,
        }),
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

  Future<String?> emotionalReset(String situation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/emotional-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'situation': situation,
        }),
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

  Future<String?> tacticalAnalysis(String matchDescription, List<MatchPerformance>? recentMatches) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final matchesJson = recentMatches != null && recentMatches.isNotEmpty 
        ? recentMatches.take(3).map((match) => match.toJson()).toList()
        : [];

      final response = await http.post(
        Uri.parse('$_baseUrl/tactical-analysis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'match_description': matchDescription,
          'recent_matches': matchesJson,
        }),
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

  Future<String?> generateDrillsFromHistory(List<MatchPerformance> matches) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final matchesJson = matches.map((match) => match.toJson()).toList();

      final response = await http.post(
        Uri.parse('$_baseUrl/drill-recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matches': matchesJson,
        }),
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

  Future<String?> quickTacticalTip(String situation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/quick-tactical-tip'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'situation': situation,
        }),
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
} 