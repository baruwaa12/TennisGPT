import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OpenAIService extends ChangeNotifier {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  bool _isLoading = false;
  String? _error;
  String? _lastResponse;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastResponse => _lastResponse;

  Future<String?> analyzeTechnique(String description) async {
    return _makeRequest(
      'Analyze the following tennis technique and provide specific feedback for improvement: $description',
    );
  }

  Future<String?> getMatchStrategy(String opponentDescription) async {
    return _makeRequest(
      'Based on the following opponent description, provide a detailed match strategy: $opponentDescription',
    );
  }

  Future<String?> generateTrainingPlan(String playerLevel, String goals) async {
    return _makeRequest(
      'Create a detailed tennis training plan for a $playerLevel player with the following goals: $goals',
    );
  }

  Future<String?> analyzeVideo(String videoDescription) async {
    return _makeRequest(
      'Analyze the following tennis video description and provide technical feedback: $videoDescription',
    );
  }

  Future<String?> mentalCheckIn(String journalEntry) async {
    return _makeRequest(
      'As a tennis coach, provide an empathetic and motivating response to this player\'s journal entry. Focus on validating their feelings while offering constructive perspective and actionable next steps. Journal Entry: $journalEntry. Response should include: 1. Empathy and validation, 2. Reframing of the situation, 3. 2-3 actionable steps for improvement',
    );
  }

  Future<String?> emotionalReset(String situation) async {
    return _makeRequest(
      'As a tennis coach, provide immediate emotional support and reframing for this situation. Focus on quick recovery and maintaining a positive mindset. Situation: $situation. Response should include: 1. Quick validation of feelings, 2. Positive reframing, 3. Immediate next steps, 4. Encouraging reminder',
    );
  }

  Future<String?> _makeRequest(String prompt) async {
    if (_apiKey.isEmpty) {
      _error = 'OpenAI API key not found';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert tennis coach with deep knowledge of technique, strategy, and training methods.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastResponse = data['choices'][0]['message']['content'];
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