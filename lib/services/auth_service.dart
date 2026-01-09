import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'token_service.dart';

class AuthService extends ChangeNotifier {
  final String _apiBaseUrl = 'https://tennisgpt-production.up.railway.app';
  final TokenService _tokenService = TokenService();
  
  // GoogleSignIn setup
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // iOS client ID (from Google Cloud Console)
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? '861799920120-3hb4p4jsm65goguim07qhfm76e6eoktb.apps.googleusercontent.com'
        : null,
    // Server client ID for getting ID token to send to backend
    serverClientId: kIsWeb 
        ? null 
        : '861799920120-bhlgkr57n4f3ia1ulaiar0f3ss615g70.apps.googleusercontent.com',
  );

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _userDisplayName;
  String? _userPhotoURL;
  String? _userEmail;
  String _userPlan = 'free';
  bool _onboardingCompleted = false;
  int _tacticalRemaining = 4;
  
  // Callback to sync onboarding status to PlayerProfileService
  Function(bool)? onOnboardingStatusReceived;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  String? get userDisplayName => _userDisplayName;
  String? get userPhotoURL => _userPhotoURL;
  String? get userEmail => _userEmail;
  String get userPlan => _userPlan;
  bool get isPremium => _userPlan == 'premium';
  bool get onboardingCompleted => _onboardingCompleted;
  int get tacticalRemaining => _tacticalRemaining;

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

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (kDebugMode) {
        print('ID Token available: ${idToken != null}');
        print('Access Token available: ${accessToken != null}');
      }

      // On web, we may only get an access token (no ID token)
      // On mobile, we get an ID token
      if (idToken == null && accessToken == null) {
        _error = 'Failed to get authentication token from Google';
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (kDebugMode) {
        print('Sending token to backend...');
      }

      // Send to backend - prefer ID token, fall back to access token for web
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'accessToken': accessToken,
        }),
      );

      if (response.statusCode == 200) {
        // Check for empty response
        if (response.body.isEmpty) {
          _error = 'Server returned empty response';
          if (kDebugMode) {
            print('AuthService: Empty response from server');
          }
          return;
        }
        
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
        _userPlan = user['plan'] ?? 'free';
        _onboardingCompleted = user['onboardingCompleted'] ?? false;
        _tacticalRemaining = user['tacticalRemaining'] ?? 4;
        _isAuthenticated = true;
        _error = null;
        
        // Notify about onboarding status from backend
        onOnboardingStatusReceived?.call(_onboardingCompleted);

        if (kDebugMode) {
          print('AuthService: Authenticated as $_userEmail (plan: $_userPlan, remaining: $_tacticalRemaining, onboarding: $_onboardingCompleted)');
        }
      } else {
        // Handle error response
        String errorMessage = 'Authentication failed (${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
        final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (_) {
            errorMessage = response.body;
          }
        }
        _error = errorMessage;
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
      _userPlan = 'free';
      _onboardingCompleted = false;
      _tacticalRemaining = 4;
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

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
        final user = jsonDecode(response.body);
        _userDisplayName = user['displayName'];
        _userPhotoURL = user['photoUrl'];
        _userEmail = user['email'];
        _userPlan = user['plan'] ?? 'free';
        _onboardingCompleted = user['onboardingCompleted'] ?? false;
        _tacticalRemaining = user['tacticalRemaining'] ?? 4;
        _isAuthenticated = true;

        if (kDebugMode) {
          print('AuthService: Restored session for $_userEmail (plan: $_userPlan)');
          }
        } catch (e) {
          if (kDebugMode) {
            print('AuthService: Error parsing user data - $e');
          }
          await _tokenService.clearTokens();
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

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
        final data = jsonDecode(response.body);
        await _tokenService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        final user = data['user'];
        _userDisplayName = user['displayName'];
        _userPhotoURL = user['photoUrl'];
        _userEmail = user['email'];
        _userPlan = user['plan'] ?? 'free';
        _onboardingCompleted = user['onboardingCompleted'] ?? false;
        _tacticalRemaining = user['tacticalRemaining'] ?? 4;
        _isAuthenticated = true;

        if (kDebugMode) {
          print('AuthService: Token refreshed for $_userEmail (plan: $_userPlan)');
        }
        return true;
        } catch (e) {
          if (kDebugMode) {
            print('AuthService: Error parsing refresh response - $e');
          }
        }
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
