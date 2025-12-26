import 'package:flutter/material.dart';

/// TennisGPT Color Palette
/// A tennis-inspired dark theme with neon green accents
class AppColors {
  AppColors._();

  // Primary - Neon Green (Tennis Ball)
  static const primary = Color(0xFFCCFF00);
  static const primaryDark = Color(0xFF9ACD00);
  static const primaryLight = Color(0xFFE0FF66);

  // Background colors - Deep Charcoal
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceLight = Color(0xFF2A2A2A);
  static const surfaceElevated = Color(0xFF333333);

  // Text colors
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFB3B3B3);
  static const textMuted = Color(0xFF808080);
  static const textOnPrimary = Color(0xFF121212);

  // Semantic colors
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFEF5350);
  static const warning = Color(0xFFFFA726);
  static const info = Color(0xFF42A5F5);

  // Match result colors
  static const win = Color(0xFF4CAF50);
  static const loss = Color(0xFFEF5350);

  // Mood spectrum (1-5)
  static const mood1 = Color(0xFFEF5350); // Struggling
  static const mood2 = Color(0xFFFFA726); // Frustrated
  static const mood3 = Color(0xFFFFEB3B); // Neutral
  static const mood4 = Color(0xFF66BB6A); // Good
  static const mood5 = Color(0xFF26A69A); // Excellent

  // Streak colors
  static const streakFire = Color(0xFFFF6B35);
  static const streakGold = Color(0xFFFFD700);

  // Card border
  static const cardBorder = Color(0xFF2A2A2A);

  /// Get mood color by rating (1-5)
  static Color getMoodColor(int rating) {
    switch (rating) {
      case 1:
        return mood1;
      case 2:
        return mood2;
      case 3:
        return mood3;
      case 4:
        return mood4;
      case 5:
        return mood5;
      default:
        return mood3;
    }
  }
}
