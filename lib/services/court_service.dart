import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The tennis court surface used for the home screen background.
/// Each surface pairs with a complementary primary-button color so the
/// call-to-action always contrasts against the court behind it.
enum CourtSurface { clay, hard, grass }

class CourtService extends ChangeNotifier {
  static const String _courtKey = 'court_surface';

  CourtSurface _surface = CourtSurface.clay;

  CourtSurface get surface => _surface;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_courtKey);
    if (saved != null) {
      _surface = CourtSurface.values.firstWhere(
        (s) => s.name == saved,
        orElse: () => CourtSurface.clay,
      );
    }
    notifyListeners();
  }

  Future<void> setSurface(CourtSurface surface) async {
    _surface = surface;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_courtKey, surface.name);
  }

  /// Background image asset for the current surface.
  String get backgroundAsset {
    switch (_surface) {
      case CourtSurface.clay:
        return 'assets/images/court_clay.png';
      case CourtSurface.hard:
        return 'assets/images/court_hard_blue.png';
      case CourtSurface.grass:
        return 'assets/images/court_grass.png';
    }
  }

  String get displayName {
    switch (_surface) {
      case CourtSurface.clay:
        return 'Clay';
      case CourtSurface.hard:
        return 'Hard (Blue)';
      case CourtSurface.grass:
        return 'Grass';
    }
  }

  /// Lighter stop of the primary-button gradient (complement of the court).
  Color get buttonColorLight {
    switch (_surface) {
      case CourtSurface.clay: // red court -> blue button
        return const Color(0xFF4DA3FF);
      case CourtSurface.hard: // blue court -> red button
        return const Color(0xFFFF6A4E);
      case CourtSurface.grass: // green court -> dark navy button
        return const Color(0xFF2D4F86);
    }
  }

  /// Darker stop of the primary-button gradient.
  Color get buttonColorDark {
    switch (_surface) {
      case CourtSurface.clay:
        return const Color(0xFF2E7DD6);
      case CourtSurface.hard:
        return const Color(0xFFE6462E);
      case CourtSurface.grass:
        return const Color(0xFF16243D);
    }
  }

  /// Text/icon color that sits on top of the button gradient.
  Color get buttonForeground => Colors.white;

  /// Soft glow used for the button shadow.
  Color get buttonGlow => buttonColorDark.withValues(alpha: 0.45);
}
