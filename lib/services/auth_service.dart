import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'token_service.dart';

class AuthService extends ChangeNotifier {
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
  final TokenService _tokenService = TokenService();
  // Web client ID from google-services.json (client_type: 3)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '750269168426-5l9q1pskuunfuqqhrirko0u8p0plcvb8.apps.googleusercontent.com',
  );

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _userDisplayName;
  String? _userPhotoURL;
  String? _userEmail;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  String? get userDisplayName => _userDisplayName;
  String? get userPhotoURL => _userPhotoURL;
  String? get userEmail => _userEmail;

  Future<void> initialize() async {
    if (kDebugMode) {
      print('AuthService: Initializing...');
    }

    // Check for existing tokens
    final hasTokens = await _tokenService.hasTokens();
    if (hasTokens) {
      await _fetchCurrentUser();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Starting Google Sign-In...');
      }

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _error = 'Google sign-in was cancelled';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get ID token
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _error = 'Failed to get ID token from Google';
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (kDebugMode) {
        print('Got Google ID token, sending to backend...');
      }

      // Send to backend
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save tokens
        await _tokenService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        // Set user info
        final user = data['user'];
        _userDisplayName = user['displayName'];
        _userPhotoURL = user['photoUrl'];
        _userEmail = user['email'];
        _isAuthenticated = true;
        _error = null;

        if (kDebugMode) {
          print('AuthService: Authenticated as $_userEmail');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ?? 'Authentication failed';
        if (kDebugMode) {
          print('AuthService: Auth failed - $_error');
        }
      }
    } catch (e) {
      _error = 'Error: $e';
      if (kDebugMode) {
        print('AuthService: Exception - $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign out from Google
      await _googleSignIn.signOut();

      // Call backend logout
      final token = await _tokenService.getAccessToken();
      if (token != null) {
        try {
          await http.post(
            Uri.parse('$_apiBaseUrl/api/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (_) {
          // Ignore backend logout errors
        }
      }

      // Clear local tokens
      await _tokenService.clearTokens();

      _isAuthenticated = false;
      _userDisplayName = null;
      _userPhotoURL = null;
      _userEmail = null;
      _error = null;

      if (kDebugMode) {
        print('AuthService: Signed out');
      }
    } catch (e) {
      _error = 'Error signing out: $e';
      if (kDebugMode) {
        print('AuthService: Error signing out - $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final token = await _tokenService.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        _userDisplayName = user['displayName'];
        _userPhotoURL = user['photoUrl'];
        _userEmail = user['email'];
        _isAuthenticated = true;

        if (kDebugMode) {
          print('AuthService: Restored session for $_userEmail');
        }
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        await _refreshToken();
      } else {
        await _tokenService.clearTokens();
      }
    } catch (e) {
      // If we can't reach the server, don't clear tokens
      if (kDebugMode) {
        print('AuthService: Error fetching user - $e');
      }
    }
    notifyListeners();
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _tokenService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        final user = data['user'];
        _userDisplayName = user['displayName'];
        _userPhotoURL = user['photoUrl'];
        _userEmail = user['email'];
        _isAuthenticated = true;

        if (kDebugMode) {
          print('AuthService: Token refreshed for $_userEmail');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error refreshing token - $e');
      }
    }

    await _tokenService.clearTokens();
    _isAuthenticated = false;
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
