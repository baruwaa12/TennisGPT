import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UserStorageService provides user-specific storage key management.
/// This allows multiple accounts to have separate data on the same device.
class UserStorageService {
  static const String _currentUserKey = 'current_user_email';
  static String? _currentUserEmail;
  
  /// Get the current user email for key prefixing
  static String? get currentUserEmail => _currentUserEmail;
  
  /// Set the current user email (called after login)
  static Future<void> setCurrentUser(String? email) async {
    _currentUserEmail = email;
    
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString(_currentUserKey, email);
    } else {
      await prefs.remove(_currentUserKey);
    }
    
    if (kDebugMode) {
      print('UserStorageService: Current user set to $email');
    }
  }
  
  /// Load the current user from storage (called on app init)
  static Future<void> loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = prefs.getString(_currentUserKey);
    
    if (kDebugMode) {
      print('UserStorageService: Loaded current user: $_currentUserEmail');
    }
  }
  
  /// Get a user-specific storage key
  /// If no user is logged in, returns the base key (for backward compatibility)
  static String getUserKey(String baseKey) {
    if (_currentUserEmail == null || _currentUserEmail!.isEmpty) {
      return baseKey;
    }
    // Use a sanitized email as prefix (replace special chars)
    final sanitizedEmail = _currentUserEmail!
        .replaceAll('@', '_at_')
        .replaceAll('.', '_dot_');
    return 'user_${sanitizedEmail}_$baseKey';
  }
  
  /// Get a value for the current user
  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(getUserKey(key));
  }
  
  /// Set a value for the current user
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(getUserKey(key), value);
  }
  
  /// Get a bool value for the current user
  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(getUserKey(key));
  }
  
  /// Set a bool value for the current user
  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(getUserKey(key), value);
  }
  
  /// Get an int value for the current user
  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(getUserKey(key));
  }
  
  /// Set an int value for the current user
  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(getUserKey(key), value);
  }
  
  /// Remove a value for the current user
  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(getUserKey(key));
  }
  
  /// Clear all data for the current user (NOT recommended - use specific removes)
  static Future<void> clearCurrentUserData() async {
    if (_currentUserEmail == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final userPrefix = 'user_${_currentUserEmail!.replaceAll('@', '_at_').replaceAll('.', '_dot_')}_';
    
    for (final key in keys) {
      if (key.startsWith(userPrefix)) {
        await prefs.remove(key);
      }
    }
    
    if (kDebugMode) {
      print('UserStorageService: Cleared all data for $_currentUserEmail');
    }
  }
}


