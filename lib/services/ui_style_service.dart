import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two visual languages the app can switch between at runtime.
enum UiStyle {
  /// Bold, youthful, colourful — gradients, vivid accents, ink ripples.
  vibrant,

  /// Apple-level minimal — near-monochrome, big type, press-to-brighten cards.
  minimal,
}

/// Persists and broadcasts the user's chosen UI style so the whole app can
/// re-render live when it changes.
class UiStyleService extends ChangeNotifier {
  static const String _key = 'ui_style';

  UiStyle _style = UiStyle.minimal;
  UiStyle get style => _style;

  bool get isVibrant => _style == UiStyle.vibrant;
  bool get isMinimal => _style == UiStyle.minimal;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _style = UiStyle.values.firstWhere(
        (s) => s.name == saved,
        orElse: () => UiStyle.minimal,
      );
    }
    notifyListeners();
  }

  Future<void> setStyle(UiStyle style) async {
    if (_style == style) return;
    _style = style;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, style.name);
  }

  Future<void> toggle() async {
    await setStyle(isVibrant ? UiStyle.minimal : UiStyle.vibrant);
  }

  String get label => isVibrant ? 'Vibrant' : 'Minimal';
}
