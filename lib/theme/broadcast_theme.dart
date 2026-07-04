import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../services/theme_service.dart';

/// Token set for the Broadcast "TV-graphics" canvas.
///
/// The canvas is committed: always near-black TV graphics, regardless of the
/// app's light/dark toggle. This is the app's identity face — scoreboard hero,
/// tabular numbers, electric-lime accent rules, uppercase labels.
///
/// Wrap Broadcast screens in [themeData] so reused theme-aware widgets (and
/// the AppTheme.*Themed text getters) resolve to dark.
class BroadcastTheme {
  const BroadcastTheme._();

  static const BroadcastTheme _instance = BroadcastTheme._();

  factory BroadcastTheme.of(BuildContext context) => _instance;

  /// Always dark — kept for widgets that branch on canvas brightness.
  bool get dark => true;

  /// Forced dark base theme so reused widgets render at the canvas brightness.
  ThemeData get themeData => ThemeService.darkTheme;

  // ---- Signature electric lime accent ----
  /// Filled accent (CTA, badges). Pairs with [onLime] text.
  static const Color limeFill = Color(0xFFCCFF00);
  static const Color onLime = Color(0xFF0A0C0A);

  // ---- Surfaces ----
  Color get bg => const Color(0xFF07090C);
  Color get panel => const Color(0xFF101319);
  Color get panelRaised => const Color(0xFF161B24);
  Color get border => const Color(0xFF262B35);

  // ---- Text ----
  Color get textPrimary => const Color(0xFFFFFFFF);
  Color get textSecondary => const Color(0xFFC4CAD4);
  Color get textMuted => const Color(0xFF888F9C);

  /// Accent for thin rules, labels and active states.
  Color get accentInk => limeFill;

  // ---- Reserved result colors ----
  Color get win => AppTheme.win;
  Color get loss => AppTheme.loss;
}
