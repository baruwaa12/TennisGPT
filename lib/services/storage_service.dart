import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/check_in_entry.dart';

class StorageService {
  static const String _checkInsKey = 'check_ins';
  static const String _lastRatingKey = 'last_rating';

  // Save a new check-in entry
  static Future<void> saveCheckIn(CheckInEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing check-ins
    final existingData = prefs.getStringList(_checkInsKey) ?? [];
    
    // Add new entry
    existingData.add(jsonEncode(entry.toJson()));
    
    // Save back to storage
    await prefs.setStringList(_checkInsKey, existingData);
    
    // Save last rating for default value
    await prefs.setInt(_lastRatingKey, entry.rating);
  }

  // Get all check-in entries
  static Future<List<CheckInEntry>> getCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_checkInsKey) ?? [];
    
    return data.map((jsonString) {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CheckInEntry.fromJson(json);
    }).toList();
  }

  // Get the last saved rating (defaults to 3 if none exists)
  static Future<int> getLastRating() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastRatingKey) ?? 3;
  }

  // Clear all check-ins (for testing)
  static Future<void> clearCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_checkInsKey);
    await prefs.remove(_lastRatingKey);
  }
} 