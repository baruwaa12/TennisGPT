import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/match_performance.dart';

class OpenAIService extends ChangeNotifier {
  final String _openApiBaseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? 'NO_API_KEY';

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
    final prompt = """
You are a tough but fair tennis mental coach. Your goal is to build mental resilience, not to coddle. Write your response in a conversational, human-like tone, using paragraphs.

The user is checking in with a mood rating of $mood out of 5.
They wrote this in their journal: '$journalEntry'.

First, acknowledge their state based on their rating and journal entry. Be direct and validate their feelings without being overly soft.

Next, transition into asking a sharp, insightful, and challenging question that forces them to confront the root cause of their feelings or the reality of their performance. Frame it as a genuine question from a coach who sees their potential.

Finally, provide a concrete, actionable tip they can apply in their next practice or match. Break this down into simple steps if it makes sense. Explain *why* this tip is important for them right now. End on a firm but encouraging note.
""";
    return _makeOpenAIRequest(prompt);
  }

  Future<String?> emotionalReset(String situation) async {
    final prompt = """
You are a supportive and wise tennis coach. The user is feeling down about this situation: '$situation'.

Write a thoughtful, encouraging paragraph to help them reset emotionally. Acknowledge the frustration of the situation, validate their feelings, and then gently guide their perspective towards what they can control. Help them regain focus with a powerful, human-like message.
""";
    return _makeOpenAIRequest(prompt);
  }

  Future<String?> tacticalAnalysis(String matchDescription, List<MatchPerformance>? recentMatches) async {
    final matchesJson = recentMatches != null && recentMatches.isNotEmpty 
      ? jsonEncode(recentMatches.take(3).map((match) => match.toJson()).toList())
      : 'No recent match data provided.';
    
    final prompt = """
You are a world-class tennis strategist, but you're explaining your thoughts to your player in a clear, human-like way. Use paragraphs to explain your thinking.

Here's the situation you need to analyze:
- Current Match/Problem: '$matchDescription'
- Recent Match History: $matchesJson

Start by giving an overall assessment of the situation in a conversational paragraph. Then, lay out your 3 most important tactical recommendations. For each recommendation, present it as a clear step or point, and write a short paragraph explaining the reasoning behind it and how to execute it. Make it sound like you're talking directly to the player.
""";
    return _makeOpenAIRequest(prompt);
  }

  Future<String?> generateDrillsFromHistory(List<MatchPerformance> matches) async {
    final matchesJson = jsonEncode(matches.map((match) => match.toJson()).toList());

    final prompt = """
You are an expert tennis coach crafting a new training focus for your player. Write your response in a conversational tone, using paragraphs.

You've reviewed the player's recent match history here:
$matchesJson

Start by explaining what pattern or weakness you've identified from their matches. Talk about why it's important to address this now.

Then, introduce the specific, high-impact drill you want them to work on. Break down the drill into clear, easy-to-follow steps:
1.  **Setup:** What they need and where to be on the court.
2.  **Execution:** How to perform the drill.
3.  **Goal:** What they should be aiming for (e.g., number of successful shots, consistency).

End with an encouraging sentence about how this drill will impact their game.
""";
    return _makeOpenAIRequest(prompt);
  }

  Future<String?> quickTacticalTip(String situation) async {
    final prompt = "You are a tennis coach providing a quick tactical tip for your player. For the situation: '$situation', give a concise and helpful piece of advice in a supportive, human tone. Keep it to a couple of sentences.";
    return _makeOpenAIRequest(prompt);
  }

  Future<String?> _makeOpenAIRequest(String prompt) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_apiKey == 'NO_API_KEY') {
      _error = 'Error: OPENAI_API_KEY not found in .env file. Please make sure you have a .env file in the root of the tennisgpt project with OPENAI_API_KEY=your_key';
      _isLoading = false;
      notifyListeners();
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(_openApiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful tennis coaching assistant.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastResponse = data['choices'][0]['message']['content'].trim();
        notifyListeners();
        return _lastResponse;
      } else {
        final errorData = jsonDecode(response.body);
        _error = 'Error: ${response.statusCode} - ${errorData['error']?['message'] ?? response.body}';
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

  // Legacy methods for backward compatibility - now powered by OpenAI
  Future<String?> analyzeTechnique(String description) async {
    final prompt = "You are a friendly and knowledgeable tennis coach. A player has described their technique to you: '$description'. In a conversational paragraph, analyze what they've said, identify one key area for improvement, and then clearly explain a drill they can use to practice it.";
    return _makeOpenAIRequest(prompt);
  }

  Future<String?> getMatchStrategy(String opponentDescription) async {
    final prompt = "You are a smart tennis strategist talking to your player. You've been told about an opponent: '$opponentDescription'. Lay out a simple, 3-step game plan in a clear, encouraging, and human-like tone. Explain each point briefly.";
    return _makeOpenAIRequest(prompt);
  }

  Future<String?> generateTrainingPlan(String playerLevel, String goals) async {
    final prompt = "You are a helpful and organized tennis coach. A player who describes themselves as '$playerLevel' wants a training plan to achieve these goals: '$goals'. Create a sample weekly training plan, writing in a clear and encouraging tone. Use paragraphs and lists to make it easy to understand. Include sections for on-court drills and off-court fitness.";
    return _makeOpenAIRequest(prompt);
  }

  Future<String?> analyzeVideo(String videoDescription) async {
    final prompt = "You are a tennis coach with a keen eye. A player has described a video of themselves playing: '$videoDescription'. Based on their description, write a thoughtful paragraph explaining what the most likely flaw in their technique or tactics might be and why. Speak in a helpful, human-like tone.";
    return _makeOpenAIRequest(prompt);
  }
} 