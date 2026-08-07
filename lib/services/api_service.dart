import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/match_performance.dart';
import 'token_service.dart';

/// Error codes for structured logging and debugging
enum ApiErrorCode {
  none,
  networkError,
  timeout,
  unauthorized,
  invalidPayload,
  serverError,
  rateLimited,
  invalidResponse,
  quotaExceeded, // 402 - Quota exceeded, upgrade required
  unknown,
}

class ApiService extends ChangeNotifier {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final TokenService _tokenService = TokenService();
  static const Duration _timeout = Duration(seconds: 45);
  static const int _maxRetries = 1;

  bool _isLoading = false;
  String? _error;
  String? _lastResponse;
  ApiErrorCode _lastErrorCode = ApiErrorCode.none;
  String? _lastRequestId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastResponse => _lastResponse;
  ApiErrorCode get lastErrorCode => _lastErrorCode;

  void clearResponse() {
    _lastResponse = null;
    _error = null;
    _lastErrorCode = ApiErrorCode.none;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _lastErrorCode = ApiErrorCode.none;
    notifyListeners();
  }

  /// Generate a request ID for logging
  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Log API activity with structured data
  void _log(String message, {String? requestId, Map<String, dynamic>? data}) {
    if (kDebugMode) {
      final prefix = requestId != null ? '[$requestId] ' : '';
      print('ApiService: $prefix$message');
      if (data != null) {
        print('  Data: $data');
      }
    }
  }

  /// Safely decode JSON, handling empty responses
  Map<String, dynamic>? _safeJsonDecode(String body) {
    if (body.isEmpty) {
      _log('Empty response body');
      return null;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      _log('Response is not a Map: $decoded');
      return null;
    } catch (e) {
      _log('JSON decode error: $e');
      return null;
    }
  }

  /// Convert error code to human-readable message (NO HTTP codes exposed)
  String _humanizeError(ApiErrorCode code) {
    switch (code) {
      case ApiErrorCode.networkError:
        return 'Please check your connection and try again.';
      case ApiErrorCode.timeout:
        return 'This is taking longer than expected. Please try again.';
      case ApiErrorCode.unauthorized:
        return 'Please sign in again to continue.';
      case ApiErrorCode.invalidPayload:
        return 'Something went wrong. Please try again.';
      case ApiErrorCode.serverError:
        return 'We couldn\'t complete your request right now. Please try again in a moment.';
      case ApiErrorCode.rateLimited:
        return 'Too many requests. Please wait a moment and try again.';
      case ApiErrorCode.invalidResponse:
        return 'We received an unexpected response. Please try again.';
      case ApiErrorCode.quotaExceeded:
        return 'You\'ve reached your free coaching limit for today. Subscribe for unlimited access.';
      case ApiErrorCode.unknown:
      case ApiErrorCode.none:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Check if the last error requires an upgrade (quota exceeded)
  bool get requiresUpgrade => _lastErrorCode == ApiErrorCode.quotaExceeded;

  /// Set error with structured logging
  void _setError(ApiErrorCode code, {String? debugMessage, String? requestId}) {
    _lastErrorCode = code;
    _error = _humanizeError(code);
    _log('Error: $code - ${debugMessage ?? _error}', requestId: requestId);
    notifyListeners();
  }

  /// Set a custom user-facing error message when backend provides guidance.
  void _setCustomError(ApiErrorCode code, String message,
      {String? debugMessage, String? requestId}) {
    _lastErrorCode = code;
    _error = message;
    _log('Error: $code - ${debugMessage ?? message}', requestId: requestId);
    notifyListeners();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Make an API request with retry logic
  Future<http.Response?> _makeRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    required String requestId,
    int attempt = 1,
  }) async {
    try {
      final headers = await _getHeaders();

      _log(
        'Request attempt $attempt to $endpoint',
        requestId: requestId,
        data: {'payloadSize': jsonEncode(body).length},
      );

      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      _log(
        'Response: ${response.statusCode}',
        requestId: requestId,
        data: {'bodyLength': response.body.length},
      );

      return response;
    } on TimeoutException {
      _log('Timeout on attempt $attempt', requestId: requestId);

      // Retry once for timeouts
      if (attempt < _maxRetries + 1) {
        _log('Retrying after timeout...', requestId: requestId);
        await Future.delayed(
            Duration(seconds: attempt * 2)); // Exponential backoff
        return _makeRequest(
          endpoint: endpoint,
          body: body,
          requestId: requestId,
          attempt: attempt + 1,
        );
      }
      return null;
    } catch (e) {
      _log('Exception on attempt $attempt: $e', requestId: requestId);

      // Retry once for network errors
      if (attempt < _maxRetries + 1 &&
          (e.toString().contains('SocketException') ||
              e.toString().contains('Connection'))) {
        _log('Retrying after network error...', requestId: requestId);
        await Future.delayed(Duration(seconds: attempt * 2));
        return _makeRequest(
          endpoint: endpoint,
          body: body,
          requestId: requestId,
          attempt: attempt + 1,
        );
      }
      return null;
    }
  }

  /// Process API response and extract data
  String? _processResponse(http.Response? response, String requestId) {
    if (response == null) {
      _setError(ApiErrorCode.timeout, requestId: requestId);
      return null;
    }

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body);
      if (data == null) {
        _setError(ApiErrorCode.invalidResponse, requestId: requestId);
        return null;
      }
      _lastResponse = data['response'] ?? data['message'] ?? data.toString();
      _lastErrorCode = ApiErrorCode.none;
      _error = null;
      notifyListeners();
      return _lastResponse;
    }

    // Handle specific status codes
    switch (response.statusCode) {
      case 400:
        final data = _safeJsonDecode(response.body);
        final backendMessage = data?['error']?.toString().trim();
        if (backendMessage != null && backendMessage.isNotEmpty) {
          _setCustomError(
            ApiErrorCode.invalidPayload,
            backendMessage,
            debugMessage: 'Bad request (backend message)',
            requestId: requestId,
          );
        } else {
          _setError(ApiErrorCode.invalidPayload,
              debugMessage: 'Bad request: ${response.body}',
              requestId: requestId);
        }
        break;
      case 401:
        _setError(ApiErrorCode.unauthorized, requestId: requestId);
        break;
      case 402:
        // Payment required / quota exceeded
        _setError(ApiErrorCode.quotaExceeded, requestId: requestId);
        break;
      case 429:
        _setError(ApiErrorCode.rateLimited, requestId: requestId);
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        _setError(ApiErrorCode.serverError,
            debugMessage:
                'Server ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}',
            requestId: requestId);
        break;
      default:
        _setError(ApiErrorCode.unknown,
            debugMessage: 'Status ${response.statusCode}',
            requestId: requestId);
    }
    return null;
  }

  // ============ Coaching Endpoints ============

  /// Tactical analysis returns structured coach JSON from the backend.
  /// Returns keys: dataScope, whatKeepsShowingUp, whatsHelpingYouWin,
  /// whatBreaksUnderPressure, nextMatchFocus, optionalPracticePlan.
  Future<Map<String, dynamic>?> tacticalAnalysis(
    String matchDescription,
    List<MatchPerformance>? recentMatches, {
    String? focusType,
  }) async {
    _isLoading = true;
    _error = null;
    _lastRequestId = _generateRequestId();
    notifyListeners();

    try {
      final matchesJson = recentMatches != null && recentMatches.isNotEmpty
          ? recentMatches.take(35).map((match) => match.toCoachingJson()).toList()
          : null;

      final response = await _makeRequest(
        endpoint: '/api/coaching/tactical-analysis',
        body: {
          'matchDescription': matchDescription,
          'recentMatches': matchesJson,
          'focusType': focusType,
        },
        requestId: _lastRequestId!,
      );

      if (response == null) {
        _setError(ApiErrorCode.timeout, requestId: _lastRequestId);
        return null;
      }

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data == null) {
          _setError(ApiErrorCode.invalidResponse, requestId: _lastRequestId);
          return null;
        }

        // The backend returns structured coach format.
        if (data.containsKey('whatKeepsShowingUp') &&
            data.containsKey('whatsHelpingYouWin') &&
            data.containsKey('whatBreaksUnderPressure') &&
            data.containsKey('nextMatchFocus')) {
          _lastErrorCode = ApiErrorCode.none;
          _error = null;
          notifyListeners();
          return data;
        }

        // Fallback: previous tactical format
        if (data.containsKey('whatYoureSeeing')) {
          _lastErrorCode = ApiErrorCode.none;
          _error = null;
          notifyListeners();
          return {
            'dataScope': {'matchesUsed': matchesJson?.length ?? 0, 'note': ''},
            'whatKeepsShowingUp': {
              'text': data['whatYoureSeeing'] ?? '',
              'evidence': '',
              'confidence': 'medium',
              'trend': 'unclear',
            },
            'whatsHelpingYouWin': {
              'text': data['whyItMatters'] ?? '',
              'evidence': '',
              'confidence': 'medium',
              'trend': 'unclear',
            },
            'whatBreaksUnderPressure': {
              'text': '',
              'evidence': '',
              'confidence': 'low',
              'trend': 'unclear',
            },
            'nextMatchFocus': {
              'text': data['nextFocus'] ?? '',
              'triggerRule': '',
              'confidence': 'medium',
            },
            'optionalPracticePlan': data['optionalPracticePlan'],
          };
        }

        // Fallback: legacy CoachingResponse format (response field)
        if (data.containsKey('response')) {
          _lastResponse = data['response'];
          _lastErrorCode = ApiErrorCode.none;
          _error = null;
          notifyListeners();
          // Wrap in current coach format for backward compatibility.
          return {
            'dataScope': {'matchesUsed': 0, 'note': ''},
            'whatKeepsShowingUp': {
              'text': data['response'] ?? '',
              'evidence': '',
              'confidence': 'low',
              'trend': 'unclear',
            },
            'whatsHelpingYouWin': {
              'text': '',
              'evidence': '',
              'confidence': 'low',
              'trend': 'unclear',
            },
            'whatBreaksUnderPressure': {
              'text': '',
              'evidence': '',
              'confidence': 'low',
              'trend': 'unclear',
            },
            'nextMatchFocus': {
              'text': '',
              'triggerRule': '',
              'confidence': 'low',
            },
            'optionalPracticePlan': null,
          };
        }

        _setError(ApiErrorCode.invalidResponse, requestId: _lastRequestId);
        return null;
      }

      // Handle error status codes
      _processResponse(response, _lastRequestId!);
      return null;
    } catch (e) {
      _setError(ApiErrorCode.networkError,
          debugMessage: e.toString(), requestId: _lastRequestId);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns a readable plain-text summary of the tactical analysis.
  /// Use this for screens that store/display a plain string.
  Future<String?> tacticalAnalysisSummary(
      String matchDescription, List<MatchPerformance>? recentMatches) async {
    final result = await tacticalAnalysis(matchDescription, recentMatches);
    if (result == null) return null;

    String sectionText(String key) {
      final section = result[key];
      if (section is Map<String, dynamic>) {
        return (section['text'] as String? ?? '').trim();
      }
      return '';
    }

    final parts = <String>[
      sectionText('whatKeepsShowingUp'),
      sectionText('whatsHelpingYouWin'),
      sectionText('whatBreaksUnderPressure'),
    ].where((t) => t.isNotEmpty).toList();

    final nextFocus = result['nextMatchFocus'];
    if (nextFocus is Map<String, dynamic>) {
      final focusText = (nextFocus['text'] as String? ?? '').trim();
      final trigger = (nextFocus['triggerRule'] as String? ?? '').trim();
      if (focusText.isNotEmpty) {
        parts.add('Next match focus: $focusText');
        if (trigger.isNotEmpty) parts.add('In-match trigger: $trigger');
      }
    }

    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  Future<String?> generateDrillsFromHistory(
      List<MatchPerformance> matches) async {
    _isLoading = true;
    _error = null;
    _lastRequestId = _generateRequestId();
    notifyListeners();

    try {
      final matchesJson = matches.map((match) => match.toCoachingJson()).toList();
      final response = await _makeRequest(
        endpoint: '/api/coaching/drills',
        body: {'matches': matchesJson},
        requestId: _lastRequestId!,
      );
      return _processResponse(response, _lastRequestId!);
    } catch (e) {
      _setError(ApiErrorCode.networkError,
          debugMessage: e.toString(), requestId: _lastRequestId);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> quickTacticalTip(String situation) async {
    _isLoading = true;
    _error = null;
    _lastRequestId = _generateRequestId();
    notifyListeners();

    try {
      final response = await _makeRequest(
        endpoint: '/api/coaching/quick-tip',
        body: {'situation': situation},
        requestId: _lastRequestId!,
      );
      return _processResponse(response, _lastRequestId!);
    } catch (e) {
      _setError(ApiErrorCode.networkError,
          debugMessage: e.toString(), requestId: _lastRequestId);
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
    _lastRequestId = _generateRequestId();
    notifyListeners();

    try {
      final response = await _makeRequest(
        endpoint: '/api/coaching/technique',
        body: {'description': description},
        requestId: _lastRequestId!,
      );
      return _processResponse(response, _lastRequestId!);
    } catch (e) {
      _setError(ApiErrorCode.networkError,
          debugMessage: e.toString(), requestId: _lastRequestId);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getMatchStrategy(String opponentDescription) async {
    _isLoading = true;
    _error = null;
    _lastRequestId = _generateRequestId();
    notifyListeners();

    try {
      final response = await _makeRequest(
        endpoint: '/api/coaching/match-strategy',
        body: {'opponentDescription': opponentDescription},
        requestId: _lastRequestId!,
      );
      return _processResponse(response, _lastRequestId!);
    } catch (e) {
      _setError(ApiErrorCode.networkError,
          debugMessage: e.toString(), requestId: _lastRequestId);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateTrainingPlan(String playerLevel, String goals) async {
    _isLoading = true;
    _error = null;
    _lastRequestId = _generateRequestId();
    notifyListeners();

    try {
      final response = await _makeRequest(
        endpoint: '/api/coaching/training-plan',
        body: {'playerLevel': playerLevel, 'goals': goals},
        requestId: _lastRequestId!,
      );
      return _processResponse(response, _lastRequestId!);
    } catch (e) {
      _setError(ApiErrorCode.networkError,
          debugMessage: e.toString(), requestId: _lastRequestId);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ Saved Entries ============

  /// Save an entry (tactical / debrief / prematch). Returns true on success.
  Future<bool> saveEntry({
    required String endpoint,
    required String content,
  }) async {
    final requestId = _generateRequestId();
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode({'content': content}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) return true;

      _log('Save entry failed: ${response.statusCode}', requestId: requestId);
      return false;
    } catch (e) {
      _log('Save entry exception: $e', requestId: requestId);
      return false;
    }
  }

  /// Get saved entries (returns list of maps with id, content, createdAtUtc).
  /// Calls backend to pull RevenueCat entitlements and update the signed-in user's plan.
  Future<bool> syncSubscriptionWithBackend() async {
    final requestId = _generateRequestId();
    try {
      final headers = await _getHeaders();
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        _log('syncSubscription: no access token', requestId: requestId);
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/subscription/sync'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        _log('Subscription sync OK', requestId: requestId);
        return true;
      }

      if (response.statusCode == 503) {
        _log('Subscription sync not configured on server',
            requestId: requestId);
        return false;
      }

      _log('Subscription sync failed: ${response.statusCode}',
          requestId: requestId);
      return false;
    } catch (e) {
      _log('Subscription sync exception: $e', requestId: requestId);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedEntries(String endpoint) async {
    final requestId = _generateRequestId();
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
      }

      _log('Get saved entries failed: ${response.statusCode}',
          requestId: requestId);
      return [];
    } catch (e) {
      _log('Get saved entries exception: $e', requestId: requestId);
      return [];
    }
  }

  // Convenience wrappers

  Future<bool> saveTacticalAdvice(String content) =>
      saveEntry(endpoint: '/api/tactical/save', content: content);

  Future<List<Map<String, dynamic>>> getSavedTactical() =>
      getSavedEntries('/api/tactical/saved');
}
