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

  // Light Theme — ComposureDesign1 tokens
  static ThemeData get lightTheme {
    final lightTextTheme = Typography.material2021().black.apply(
          fontFamily: AppTheme.fontFamily,
          bodyColor: AppTheme.textSecondaryLight,
          displayColor: AppTheme.textPrimaryLight,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTheme.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primary,
        brightness: Brightness.light,
        primary: AppTheme.primary,
        surface: AppTheme.surfaceCardLight,
        onSurface: AppTheme.textPrimaryLight,
      ),
      scaffoldBackgroundColor: AppTheme.surfaceLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.surfaceCardLight,
        foregroundColor: AppTheme.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _appBarTitle(AppTheme.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: AppTheme.surfaceCardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
      ),
      textTheme: lightTextTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.surfaceCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(color: AppTheme.surfaceBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(color: AppTheme.surfaceBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppTheme.textMutedLight),
        labelStyle: const TextStyle(color: AppTheme.textSecondaryLight),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppTheme.primary,
        selectionColor: AppTheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: AppTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
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

  // Dark Theme — ComposureDesign1 tokens
  static ThemeData get darkTheme {
    final darkTextTheme = Typography.material2021().white.apply(
          fontFamily: AppTheme.fontFamily,
          bodyColor: AppTheme.textSecondary,
          displayColor: AppTheme.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTheme.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primary,
        brightness: Brightness.dark,
        primary: AppTheme.primary,
        surface: AppTheme.surfaceCard,
        onSurface: AppTheme.textPrimary,
      ),
      scaffoldBackgroundColor: AppTheme.surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.surfaceSecondary,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _appBarTitle(AppTheme.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppTheme.surfaceCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
      ),
      textTheme: darkTextTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppTheme.primary,
        selectionColor: AppTheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: AppTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
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
      dividerColor: AppTheme.surfaceBorder,
    );
  }
}
