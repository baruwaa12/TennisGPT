import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's single visual language: Broadcast — a sports "match centre" look
/// (high-contrast scoreboard hero, tabular numbers, accent rules, uppercase
/// labels, fixtures-style lists).
enum UiStyle {
  broadcast,
}

/// TEMPORARY: two canvas treatments for Broadcast, kept side-by-side so we can
/// compare them in-app before committing. Once a winner is chosen this enum and
/// the Settings toggle get removed and the choice is hard-coded.
enum BroadcastCanvas {
  /// Always near-black TV-graphics, regardless of the app's light/dark toggle.
  fixedDark,

  /// Obeys the app theme: near-black in dark, clean true-white in light.
  adaptive,
}

class UiStyleService extends ChangeNotifier {
  static const _kCanvasKey = 'broadcast_canvas';

  BroadcastCanvas _canvas = BroadcastCanvas.fixedDark;

  UiStyle get style => UiStyle.broadcast;
  BroadcastCanvas get canvas => _canvas;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kCanvasKey);
      if (saved != null) {
        _canvas = BroadcastCanvas.values.firstWhere(
          (c) => c.name == saved,
          orElse: () => BroadcastCanvas.fixedDark,
        );
        notifyListeners();
      }
    } catch (_) {
      // Non-fatal: fall back to the default canvas.
    }
  }

  Future<void> setCanvas(BroadcastCanvas value) async {
    if (_canvas == value) return;
    _canvas = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCanvasKey, value.name);
    } catch (_) {}
  }

  String get label => 'Broadcast';
}
