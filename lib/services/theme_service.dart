import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _brandDirectionKey = 'brand_direction';

  ThemeMode _themeMode = ThemeMode.system;
  BrandDirection _brandDirection = BrandDirection.burntOrangeTactical;

  ThemeMode get themeMode => _themeMode;
  BrandDirection get brandDirection => _brandDirection;

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
    final savedBrandDirection = prefs.getString(_brandDirectionKey);

    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }

    if (savedBrandDirection != null) {
      _brandDirection = BrandDirection.values.firstWhere(
        (direction) => direction.name == savedBrandDirection,
        orElse: () => BrandDirection.burntOrangeTactical,
      );
    }

    AppTheme.setBrandDirection(_brandDirection);
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

  Future<void> setBrandDirection(BrandDirection direction) async {
    _brandDirection = direction;
    AppTheme.setBrandDirection(direction);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_brandDirectionKey, direction.name);
  }

  // Light Theme
  static ThemeData get lightTheme {
    // Define light mode text colors explicitly
    final lightTextTheme = GoogleFonts.ibmPlexSansTextTheme().apply(
      bodyColor: Colors.grey[800],
      displayColor: Colors.grey[800],
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primary,
        brightness: Brightness.light,
        onSurface: Colors.grey[800]!, // Text color on surfaces
      ),
      scaffoldBackgroundColor: const Color(0xFFF3ECE3),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: lightTextTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey[500]),
        labelStyle: TextStyle(color: Colors.grey[700]),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    // Define dark mode text colors explicitly
    final darkTextTheme =
        GoogleFonts.ibmPlexSansTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primary,
        brightness: Brightness.dark,
        onSurface: Colors.white, // Text color on surfaces
      ),
      scaffoldBackgroundColor: AppTheme.surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.surfaceSecondary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppTheme.surfaceCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: darkTextTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey[500]),
        labelStyle: TextStyle(color: Colors.grey[400]),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: AppTheme.surfaceBorder,
    );
  }
}
