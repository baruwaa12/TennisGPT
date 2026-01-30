import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_performance.dart';
import 'user_storage_service.dart';

/// MatchHistoryService stores and retrieves match performance data.
/// Now uses user-specific storage keys for multi-account support.
class MatchHistoryService extends ChangeNotifier {
  static const String _baseStorageKey = 'match_history';
  
  // In-memory cache for faster access
  List<MatchPerformance>? _cachedMatches;
  bool _isLoaded = false;
  
  // Getters
  bool get isLoaded => _isLoaded;
  
  /// Get user-specific storage key
  String get _storageKey => UserStorageService.getUserKey(_baseStorageKey);
  
  /// Initialize and load match data into cache
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    _cachedMatches = await _loadMatchesFromStorage();
    _isLoaded = true;
    
    if (kDebugMode) {
      print('MatchHistoryService: Loaded ${_cachedMatches?.length ?? 0} matches for user');
    }
  }
  
  /// Load matches from SharedPreferences (user-specific)
  Future<List<MatchPerformance>> _loadMatchesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? matchesJson = prefs.getString(_storageKey);
    
    if (matchesJson == null || matchesJson.isEmpty) return [];
    
    try {
      final List<dynamic> matchesList = json.decode(matchesJson);
      return matchesList.map((json) => MatchPerformance.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get all match performances (user-specific)
  Future<List<MatchPerformance>> getAllMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final String? matchesJson = prefs.getString(_storageKey);
    
    if (matchesJson == null || matchesJson.isEmpty) return [];
    
    try {
    final List<dynamic> matchesList = json.decode(matchesJson);
    return matchesList
        .map((json) => MatchPerformance.fromJson(json))
        .toList();
    } catch (e) {
      // If JSON is corrupted, return empty list
      return [];
    }
  }
  
  // Save a new match performance (user-specific)
  Future<void> saveMatch(MatchPerformance match) async {
    final prefs = await SharedPreferences.getInstance();
    final List<MatchPerformance> matches = await getAllMatches();
    
    matches.add(match);
    
    final List<Map<String, dynamic>> matchesJson = 
        matches.map((match) => match.toJson()).toList();
    
    await prefs.setString(_storageKey, json.encode(matchesJson));
    _cachedMatches = matches;
  }
  
  // Update an existing match performance
  Future<void> updateMatch(MatchPerformance updatedMatch) async {
    final prefs = await SharedPreferences.getInstance();
    final List<MatchPerformance> matches = await getAllMatches();
    
    final int index = matches.indexWhere((match) => match.id == updatedMatch.id);
    if (index != -1) {
      matches[index] = updatedMatch;
      
      final List<Map<String, dynamic>> matchesJson = 
          matches.map((match) => match.toJson()).toList();
      
      await prefs.setString(_storageKey, json.encode(matchesJson));
      _cachedMatches = matches;
    }
  }
  
  // Delete a match performance
  Future<void> deleteMatch(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<MatchPerformance> matches = await getAllMatches();
    
    matches.removeWhere((match) => match.id == matchId);
    
    final List<Map<String, dynamic>> matchesJson = 
        matches.map((match) => match.toJson()).toList();
    
    await prefs.setString(_storageKey, json.encode(matchesJson));
    _cachedMatches = matches;
  }
  
  /// Reset in-memory state (for user switch - preserves stored data)
  /// With user-specific keys, we don't need to delete data, just reload for new user
  Future<void> resetAllMatches() async {
    _cachedMatches = null;
    _isLoaded = false; // Allow re-initialization for new user
    
    notifyListeners();
    
    if (kDebugMode) {
      print('MatchHistoryService: Reset in-memory state - ready for new user');
    }
  }
  
  /// Actually delete match data (for dev tools reset)
  Future<void> deleteAllMatches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    
    _cachedMatches = [];
    
    notifyListeners();
    
    if (kDebugMode) {
      print('MatchHistoryService: Deleted all match data for current user');
    }
  }
  
  /// Alias for backward compatibility
  Future<void> clearAllMatches() async => deleteAllMatches();
  
  // Get matches by surface type
  Future<List<MatchPerformance>> getMatchesBySurface(String surface) async {
    final List<MatchPerformance> matches = await getAllMatches();
    return matches.where((match) => match.surface.toLowerCase() == surface.toLowerCase()).toList();
  }
  
  // Get recent matches (last N matches)
  Future<List<MatchPerformance>> getRecentMatches(int count) async {
    final List<MatchPerformance> matches = await getAllMatches();
    matches.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
    return matches.take(count).toList();
  }
  
  // Get win rate
  Future<double> getWinRate() async {
    final List<MatchPerformance> matches = await getAllMatches();
    if (matches.isEmpty) return 0.0;
    
    final int wins = matches.where((match) => match.result.toLowerCase() == 'win').length;
    return wins / matches.length;
  }
  
  // Get total match count
  Future<int> getTotalMatches() async {
    final List<MatchPerformance> matches = await getAllMatches();
    return matches.length;
  }
  
  // Get common weaknesses across matches
  Future<Map<String, int>> getCommonWeaknesses() async {
    final List<MatchPerformance> matches = await getAllMatches();
    final Map<String, int> weaknessCounts = {};
    
    for (final match in matches) {
      for (final entry in match.weaknesses.entries) {
        weaknessCounts[entry.key] = (weaknessCounts[entry.key] ?? 0) + 1;
      }
    }
    
    return weaknessCounts;
  }
  
  // Get performance trends
  Future<Map<String, dynamic>> getPerformanceTrends() async {
    final List<MatchPerformance> matches = await getAllMatches();
    if (matches.isEmpty) return {};
    
    matches.sort((a, b) => a.date.compareTo(b.date));
    
    final Map<String, List<int>> skillTrends = {};
    
    for (final match in matches) {
      for (final entry in match.strengths.entries) {
        if (!skillTrends.containsKey(entry.key)) {
          skillTrends[entry.key] = [];
        }
        skillTrends[entry.key]!.add(entry.value);
      }
    }
    
    return {
      'skillTrends': skillTrends,
      'totalMatches': matches.length,
      'winRate': await getWinRate(),
      'favoriteSurface': _getFavoriteSurface(matches),
    };
  }
  
  String _getFavoriteSurface(List<MatchPerformance> matches) {
    final Map<String, int> surfaceCounts = {};
    
    for (final match in matches) {
      surfaceCounts[match.surface] = (surfaceCounts[match.surface] ?? 0) + 1;
    }
    
    if (surfaceCounts.isEmpty) return 'Unknown';
    
    return surfaceCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
} 