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

  void clearResponse() {
    _lastResponse = null;
    _error = null;
    notifyListeners();
  }

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
      'You are a tough but fair tennis coach who cares deeply about your players\' success. Analyze this journal entry with brutal honesty and accountability. Ask tough questions like: "Did you perform as best as you can and better than the other person?" "Did you use your brain or just fly through?" "Were you mentally present or just going through the motions?" Journal Entry: $journalEntry. Response should include: 1. Brief acknowledgment of their feelings, 2. Tough accountability questions that force honest self-reflection, 3. Call out any excuses or blaming external factors (wind, luck, etc.), 4. Specific mental and physical actions they MUST take to improve, 5. A challenge to prove they have the mental toughness to succeed. Be direct and push them to take full responsibility for their performance.',
    );
  }

  Future<String?> emotionalReset(String situation) async {
    return _makeRequest(
      'You are a tough but caring tennis coach. Provide immediate emotional support AND accountability. Situation: $situation. Response should include: 1. Quick validation of feelings, 2. Tough love reminder that champions don\'t quit when things get hard, 3. Immediate action steps they MUST take right now, 4. A challenge to prove they have what it takes. Be supportive but push them to be mentally stronger. Tennis is as much mental as physical - they need to toughen up.',
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
              'content': 'You are an expert tennis coach with deep knowledge of technique, strategy, and training methods. You are tough but fair, pushing players to take tennis seriously while showing you care about their success. You balance empathy with accountability, never letting players make excuses but always believing in their potential. You ask tough questions that force honest self-reflection and call out excuses.',
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