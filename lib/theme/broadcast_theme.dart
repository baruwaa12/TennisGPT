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

  // ---- Signature accent (deep blue intelligence) ----
  /// Accent used for CTA outlines, labels, rules and badges.
  /// Pairs with [onAccent] text when used as a solid fill.
  static const Color accentFill = AppTheme.primary;
  static const Color onAccent = Color(0xFFFFFFFF);

  // ---- Surfaces ----
  Color get bg => const Color(0xFF07090C);
  Color get panel => const Color(0xFF101319);
  Color get panelRaised => const Color(0xFF161B24);
  Color get border => const Color(0xFF262B35);

  /// Soft elevation for floating panels — separates a panel from the canvas
  /// without leaning on a hard border.
  List<BoxShadow> get panelShadow => const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ];

  // ---- Text ----
  Color get textPrimary => const Color(0xFFFFFFFF);
  Color get textSecondary => const Color(0xFFC4CAD4);
  Color get textMuted => const Color(0xFF888F9C);

  /// Accent for thin rules, labels and active states.
  Color get accentInk => accentFill;

  // ---- Reserved result colors ----
  Color get win => AppTheme.win;
  Color get loss => AppTheme.loss;
}
