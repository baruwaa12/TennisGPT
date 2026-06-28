import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../services/theme_service.dart';
import '../services/ui_style_service.dart';

/// Token set for the Broadcast "TV-graphics" canvas.
///
/// Resolves to one of two treatments depending on [BroadcastCanvas]:
///  • fixedDark — always near-black TV graphics.
///  • adaptive — near-black in dark mode, clean true-white in light mode.
///
/// Wrap Broadcast screens in [themeData] so reused theme-aware widgets (and the
/// AppTheme.*Themed text getters) resolve to the matching brightness.
class BroadcastTheme {
  const BroadcastTheme._(this.dark);

  final bool dark;

  factory BroadcastTheme.of(BuildContext context, BroadcastCanvas canvas) {
    final dark =
        canvas == BroadcastCanvas.fixedDark ? true : AppTheme.isDark(context);
    return BroadcastTheme._(dark);
  }

  /// Forced base theme so reused widgets render at the canvas brightness.
  ThemeData get themeData =>
      dark ? ThemeService.darkTheme : ThemeService.lightTheme;

  // ---- Signature electric lime accent ----
  /// Filled accent (CTA, badges). Pairs with [onLime] text.
  static const Color limeFill = Color(0xFFCCFF00);
  static const Color onLime = Color(0xFF0A0C0A);

  // ---- Surfaces ----
  Color get bg => dark ? const Color(0xFF07090C) : const Color(0xFFF3F4F6);
  Color get panel => dark ? const Color(0xFF101319) : Colors.white;
  Color get panelRaised =>
      dark ? const Color(0xFF161B24) : const Color(0xFFFFFFFF);
  Color get border => dark ? const Color(0xFF262B35) : const Color(0xFFDFE3E9);

  // ---- Text ----
  Color get textPrimary =>
      dark ? const Color(0xFFFFFFFF) : const Color(0xFF0B0D11);
  Color get textSecondary =>
      dark ? const Color(0xFFC4CAD4) : const Color(0xFF3B414B);
  Color get textMuted =>
      dark ? const Color(0xFF888F9C) : const Color(0xFF6B717D);

  /// Accent for thin rules, labels and active states — kept readable on the
  /// canvas (bright lime on dark, deep olive-lime on white).
  Color get accentInk => dark ? limeFill : const Color(0xFF4E6B00);

  // ---- Reserved result colors (constant in both treatments) ----
  Color get win => AppTheme.win;
  Color get loss => AppTheme.loss;
}
