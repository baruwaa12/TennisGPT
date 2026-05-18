import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../config/app_config.dart';
import 'token_service.dart';
import 'user_storage_service.dart';

class AuthService extends ChangeNotifier {
  final String _apiBaseUrl = AppConfig.apiBaseUrl;
  final TokenService _tokenService = TokenService();
  
  // GoogleSignIn setup — kIsWeb must be checked first because on iPhone browsers
  // defaultTargetPlatform reports iOS, which would incorrectly use the native client ID
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb
        ? null
        : (defaultTargetPlatform == TargetPlatform.iOS
            ? '861799920120-3hb4p4jsm65goguim07qhfm76e6eoktb.apps.googleusercontent.com'
            : null),
    serverClientId: kIsWeb 
        ? null 
        : '861799920120-bhlgkr57n4f3ia1ulaiar0f3ss615g70.apps.googleusercontent.com',
  );

  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isGuest = false;
  String? _error;
  String? _userDisplayName;
  String? _userPhotoURL;
  String? _userEmail;
  String _userPlan = 'free';
  bool _onboardingCompleted = false;
  int _tacticalRemaining = 4;
  
  // Callback to sync onboarding status to PlayerProfileService
  Function(bool)? onOnboardingStatusReceived;
  
  // Callback to clear all local data on sign out (MUST be awaited)
  Future<void> Function()? onSignOut;
  
  // Callback to reinitialize user-scoped services after login/restored session
  Future<void> Function()? onUserChanged;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  String? get error => _error;
  String? get userDisplayName => _userDisplayName;
  String? get userPhotoURL => _userPhotoURL;
  String? get userEmail => _userEmail;
  String get userPlan => _userPlan;
  bool get isPremium => _userPlan == 'premium';
  bool get onboardingCompleted => _onboardingCompleted;
  int get tacticalRemaining => _tacticalRemaining;

  void enterGuestMode() {
    _isGuest = true;
    _isAuthenticated = false;
    notifyListeners();
  }

  void exitGuestMode() {
    _isGuest = false;
    notifyListeners();
  }

  Future<void> signInWithApple() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!await SignInWithApple.isAvailable()) {
        _error = 'Apple Sign-In is not available on this device';
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        _error = 'Failed to get Apple identity token';
        return;
      }

      final displayName = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((part) => part.isNotEmpty).join(' ').trim();

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/auth/apple'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identityToken': identityToken,
          'email': credential.email,
          'displayName': displayName.isNotEmpty ? displayName : null,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Server request timed out. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          _error = 'Server returned empty response';
          return;
        }

        final data = jsonDecode(response.body);
        await _handleAuthResponse(data);
      } else {
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
      }
    } catch (e) {
      _error = 'Error: $e';
      if (kDebugMode) {
        print('AuthService: Apple Sign-In exception - $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (kDebugMode) {
      print('AuthService: Initializing...');
    }

    // Load stored current user for user-specific storage
    await UserStorageService.loadCurrentUser();

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

    // Remember the previous user's email to detect account switches
    final String? previousUserEmail = _userEmail;

    try {
      if (kDebugMode) {
        print('Starting Google Sign-In... (previous user: $previousUserEmail)');
      }

      // Sign in with Google FIRST (before clearing data)
      // This way if user cancels, we don't lose their existing data
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _error = 'Google sign-in was cancelled';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // With user-specific storage, we don't need to clear data when switching accounts
      // Each user's data is stored with their email as a key prefix
      final String newUserEmail = googleUser.email;
      final bool isDifferentUser = previousUserEmail != null && previousUserEmail != newUserEmail;
      
      if (isDifferentUser) {
        if (kDebugMode) {
          print('AuthService: Switching from $previousUserEmail to $newUserEmail - user data preserved separately');
        }
        // Reset in-memory state so services reload data for new user
        if (onSignOut != null) {
          await onSignOut!();
        }
      } else {
        if (kDebugMode) {
          print('AuthService: Same user ($newUserEmail) - continuing session');
        }
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
      // Add timeout to prevent infinite hanging if server is slow/down
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'accessToken': accessToken,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Server request timed out. Please try again.');
        },
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
        await _handleAuthResponse(data);
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
      if (kDebugMode) {
        print('AuthService: 🔔 FINAL STATE - isAuthenticated=$_isAuthenticated, isLoading=$_isLoading, email=$_userEmail');
        print('AuthService: 🔔 Calling notifyListeners() NOW');
      }
      notifyListeners();
      if (kDebugMode) {
        print('AuthService: 🔔 notifyListeners() completed');
      }
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
      
      // Clear current user from storage (but preserve their data for when they log back in)
      await UserStorageService.setCurrentUser(null);
      
      // Reset in-memory state for all services via callback
      // This allows services to reload fresh data for the next user
      if (onSignOut != null) {
        await onSignOut!();
      }

      _isAuthenticated = false;
      _userDisplayName = null;
      _userPhotoURL = null;
      _userEmail = null;
      _userPlan = 'free';
      _onboardingCompleted = false;
      _tacticalRemaining = 4;
      _error = null;

      if (kDebugMode) {
        print('AuthService: Signed out and cleared ALL local data');
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

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        _error = 'You are not signed in.';
        return false;
      }

      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/api/auth/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Server request timed out. Please try again.');
        },
      );

      if (response.statusCode != 204 && response.statusCode != 404) {
        String errorMessage = 'Could not delete account (${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (_) {
            errorMessage = response.body;
          }
        }
        _error = errorMessage;
        return false;
      }

      await _googleSignIn.signOut();
      await _tokenService.clearTokens();

      // Wipe all SharedPreferences data for this user before clearing the
      // user pointer — must happen while the email key is still set so
      // clearCurrentUserData can find the right prefixed keys.
      await UserStorageService.clearCurrentUserData();
      await UserStorageService.setCurrentUser(null);

      if (onSignOut != null) {
        await onSignOut!();
      }

      _isAuthenticated = false;
      _userDisplayName = null;
      _userPhotoURL = null;
      _userEmail = null;
      _userPlan = 'free';
      _onboardingCompleted = false;
      _tacticalRemaining = 4;
      _error = null;

      return true;
    } catch (e) {
      _error = 'Error deleting account: $e';
      if (kDebugMode) {
        print('AuthService: Error deleting account - $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes profile from GET /api/auth/me (e.g. after subscription sync).
  Future<void> refreshProfile() async {
    await _fetchCurrentUser();
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
        
        // Set current user for user-specific storage
        await UserStorageService.setCurrentUser(_userEmail);
        
        // Reinitialize user-scoped services after session restore
        if (onUserChanged != null) {
          await onUserChanged!();
        }

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

  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
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

    // Set current user for user-specific storage (each user gets their own data)
    await UserStorageService.setCurrentUser(_userEmail);

    // Reinitialize user-scoped services for the signed-in user
    if (onUserChanged != null) {
      await onUserChanged!();
    }

    // Notify about onboarding status from backend
    onOnboardingStatusReceived?.call(_onboardingCompleted);

    if (kDebugMode) {
      print('AuthService: ✅ Authenticated as $_userEmail (plan: $_userPlan, remaining: $_tacticalRemaining, onboarding: $_onboardingCompleted)');
      print('AuthService: ✅ isAuthenticated=$_isAuthenticated, isLoading=$_isLoading');
    }
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
