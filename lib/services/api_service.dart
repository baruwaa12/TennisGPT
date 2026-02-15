import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  quotaExceeded,  // 402 - Quota exceeded, upgrade required
  unknown,
}

class ApiService extends ChangeNotifier {
  final String _baseUrl = 'https://tennisgpt-production.up.railway.app';
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
  String _humanizeError(ApiErrorCode code, {String? context}) {
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
        return 'You\'ve used all your free analyses. Upgrade to Premium for unlimited access!';
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
      
      _log('Request attempt $attempt to $endpoint', 
        requestId: requestId,
        data: {'payloadSize': jsonEncode(body).length},
      );

      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeout);

      _log('Response: ${response.statusCode}', 
        requestId: requestId,
        data: {'bodyLength': response.body.length},
      );

      return response;
    } on TimeoutException {
      _log('Timeout on attempt $attempt', requestId: requestId);
      
      // Retry once for timeouts
      if (attempt < _maxRetries + 1) {
        _log('Retrying after timeout...', requestId: requestId);
        await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
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
        _setError(ApiErrorCode.invalidPayload, 
          debugMessage: 'Bad request: ${response.body}',
          requestId: requestId);
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
          debugMessage: 'Server ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}',
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

  Future<String?> mentalCheckIn(int mood, String journalEntry) async {
    _isLoading = true;
    _error = null;
    _lastRequestId = _generateRequestId();
    notifyListeners();

    try {
      final response = await _makeRequest(
        endpoint: '/api/coaching/mental-check-in',
        body: {'mood': mood, 'journalEntry': journalEntry},
        requestId: _lastRequestId!,
      );
      return _processResponse(response, _lastRequestId!);
    } catch (e) {
      _setError(ApiErrorCode.networkError, 
        debugMessage: e.toString(),
        requestId: _lastRequestId);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> emotionalReset(String situation) async {
    _isLoading = true;
    _error = null;
    _lastRequestId = _generateRequestId();
    notifyListeners();

    try {
      final response = await _makeRequest(
        endpoint: '/api/coaching/emotional-reset',
        body: {'situation': situation},
        requestId: _lastRequestId!,
      );
      return _processResponse(response, _lastRequestId!);
    } catch (e) {
      _setError(ApiErrorCode.networkError,
        debugMessage: e.toString(),
        requestId: _lastRequestId);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tactical analysis returns structured Control Mode JSON from the backend.
  /// Returns a Map with keys: whatToControl, nextMatchRule, constraintDrill, reminder, patternDetection.
  Future<Map<String, dynamic>?> tacticalAnalysis(String matchDescription, List<MatchPerformance>? recentMatches) async {
    _isLoading = true;
    _error = null;
    _lastRequestId = _generateRequestId();
    notifyListeners();

    try {
      final matchesJson = recentMatches != null && recentMatches.isNotEmpty
          ? recentMatches.take(10).map((match) => match.toJson()).toList()
          : null;

      final response = await _makeRequest(
        endpoint: '/api/coaching/tactical-analysis',
        body: {
          'matchDescription': matchDescription,
          'recentMatches': matchesJson,
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

        // The backend returns Control Mode format:
        // whatToControl, nextMatchRule, constraintDrill, reminder, patternDetection
        if (data.containsKey('whatToControl')) {
          _lastErrorCode = ApiErrorCode.none;
          _error = null;
          notifyListeners();
          return data;
        }

        // Fallback: legacy CoachingResponse format (response field)
        if (data.containsKey('response')) {
          _lastResponse = data['response'];
          _lastErrorCode = ApiErrorCode.none;
          _error = null;
          notifyListeners();
          // Wrap in Control Mode format for backward compatibility
          return {
            'whatToControl': data['response'] ?? '',
            'nextMatchRule': '',
            'constraintDrill': '',
            'reminder':
                'Stick to what you practiced. Control the controllables.',
            'patternDetection': null,
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
        debugMessage: e.toString(),
        requestId: _lastRequestId);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns just the whatToControl text from tactical analysis.
  /// Use this for screens that store/display a plain string.
  Future<String?> tacticalAnalysisSummary(String matchDescription, List<MatchPerformance>? recentMatches) async {
    final result = await tacticalAnalysis(matchDescription, recentMatches);
    if (result == null) return null;
    // Return whatToControl, or fall back to full JSON string
    return result['whatToControl'] as String? ?? result.toString();
  }

  Future<String?> generateDrillsFromHistory(List<MatchPerformance> matches) async {
    _isLoading = true;
    _error = null;
    _lastRequestId = _generateRequestId();
    notifyListeners();

    try {
      final matchesJson = matches.map((match) => match.toJson()).toList();
      final response = await _makeRequest(
        endpoint: '/api/coaching/drills',
        body: {'matches': matchesJson},
        requestId: _lastRequestId!,
      );
      return _processResponse(response, _lastRequestId!);
    } catch (e) {
      _setError(ApiErrorCode.networkError,
        debugMessage: e.toString(),
        requestId: _lastRequestId);
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
        debugMessage: e.toString(),
        requestId: _lastRequestId);
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
        debugMessage: e.toString(),
        requestId: _lastRequestId);
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
        debugMessage: e.toString(),
        requestId: _lastRequestId);
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
        debugMessage: e.toString(),
        requestId: _lastRequestId);
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
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode({'content': content}),
      ).timeout(_timeout);

      if (response.statusCode == 200) return true;

      _log('Save entry failed: ${response.statusCode}', requestId: requestId);
      return false;
    } catch (e) {
      _log('Save entry exception: $e', requestId: requestId);
      return false;
    }
  }

  /// Get saved entries (returns list of maps with id, content, createdAtUtc).
  Future<List<Map<String, dynamic>>> getSavedEntries(String endpoint) async {
    final requestId = _generateRequestId();
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
      }

      _log('Get saved entries failed: ${response.statusCode}', requestId: requestId);
      return [];
    } catch (e) {
      _log('Get saved entries exception: $e', requestId: requestId);
      return [];
    }
  }

  // Convenience wrappers

  Future<bool> saveTacticalAdvice(String content) =>
      saveEntry(endpoint: '/api/tactical/save', content: content);

  Future<bool> saveDebrief(String content) =>
      saveEntry(endpoint: '/api/debrief/save', content: content);

  Future<bool> savePreMatchPlan(String content) =>
      saveEntry(endpoint: '/api/prematch/save', content: content);

  Future<List<Map<String, dynamic>>> getSavedTactical() =>
      getSavedEntries('/api/tactical/saved');

  Future<List<Map<String, dynamic>>> getSavedDebriefs() =>
      getSavedEntries('/api/debrief/saved');

  Future<List<Map<String, dynamic>>> getSavedPreMatchPlans() =>
      getSavedEntries('/api/prematch/saved');
}
