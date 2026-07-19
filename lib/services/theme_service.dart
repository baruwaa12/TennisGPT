import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  // Shared brand app-bar title style (Zalando Sans SemiExpanded).
  static TextStyle _appBarTitle(Color color) => TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontVariations: AppTheme.fontVariationsSemiExpanded,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      );

  // Shared brand button label style (spec: 16px, weight 500 medium).
  static const TextStyle _buttonText = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontVariations: AppTheme.fontVariationsSemiExpanded,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  // Cypherpunk is a single stark identity: lime section surface, ink type +
  // 2px ink borders, raised beige cards, crisp 2px corners, flat elevation.
  static ThemeData get lightTheme {
    final textTheme = Typography.material2021().black.apply(
          fontFamily: AppTheme.fontFamily,
          bodyColor: AppTheme.textSecondaryLight,
          displayColor: AppTheme.textPrimaryLight,
        );

    final inkBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      borderSide: const BorderSide(
        color: AppTheme.surfaceBorderLight,
        width: AppTheme.borderWidth,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTheme.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primary,
        brightness: Brightness.light,
        primary: AppTheme.primary,
        onPrimary: Colors.white,
        surface: AppTheme.surfaceCardLight,
        onSurface: AppTheme.textPrimaryLight,
        error: AppTheme.loss,
      ),
      scaffoldBackgroundColor: AppTheme.surfaceLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.surfaceLight,
        foregroundColor: AppTheme.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _appBarTitle(AppTheme.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: AppTheme.surfaceCardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          side: const BorderSide(
            color: AppTheme.surfaceBorderLight,
            width: AppTheme.borderWidth,
          ),
        ),
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.surfaceCardLight,
        border: inkBorder,
        enabledBorder: inkBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(
            color: AppTheme.primary,
            width: AppTheme.borderWidth,
          ),
        ),
        hintStyle: const TextStyle(color: AppTheme.textMutedLight),
        labelStyle: const TextStyle(color: AppTheme.textSecondaryLight),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppTheme.primary,
        selectionColor: AppTheme.primary.withValues(alpha: 0.2),
        selectionHandleColor: AppTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          textStyle: _buttonText,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
      ),
      dividerColor: AppTheme.surfaceBorderLight,
    );
  }

  // Cypherpunk has one identity — dark mode resolves to the same skin so the
  // app always reads as Cypherpunk regardless of the system theme toggle.
  static ThemeData get darkTheme => lightTheme;
}
