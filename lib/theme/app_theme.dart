import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BrandDirection {
  deepBlueIntelligence,
  burntOrangeTactical,
  copperBronzePremium,
}

class _BrandAccentPalette {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color softGlow;
  final Color neutral;
  final Color warning;

  const _BrandAccentPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.softGlow,
    required this.neutral,
    required this.warning,
  });
}

/// TennisGPT Design System
/// Direction: calm tactical intelligence.
/// Clarity-first hierarchy, premium restraint, and pressure-ready readability.

class AppTheme {
  AppTheme._();

  // ============ COLORS ============
  static BrandDirection _activeBrandDirection =
      BrandDirection.deepBlueIntelligence;

  static const Map<BrandDirection, _BrandAccentPalette> _accentPalettes = {
    BrandDirection.deepBlueIntelligence: _BrandAccentPalette(
      primary: Color(0xFF4DA3FF),
      primaryLight: Color(0xFF7DC2FF),
      primaryDark: Color(0xFF2E7DD6),
      softGlow: Color(0xFF7DC2FF),
      neutral: Color(0xFF27D3B2),
      warning: Color(0xFFFFB547),
    ),
    BrandDirection.burntOrangeTactical: _BrandAccentPalette(
      primary: Color(0xFFE6462E),
      primaryLight: Color(0xFFFF6A4E),
      primaryDark: Color(0xFFB92E1A),
      softGlow: Color(0xFFFF7C58),
      neutral: Color(0xFFFFA248),
      warning: Color(0xFFF4C152),
    ),
    BrandDirection.copperBronzePremium: _BrandAccentPalette(
      primary: Color(0xFFB87333),
      primaryLight: Color(0xFFD6A063),
      primaryDark: Color(0xFF8B5A2B),
      softGlow: Color(0xFFE0B173),
      neutral: Color(0xFFC8945A),
      warning: Color(0xFFD9A441),
    ),
  };

  static _BrandAccentPalette get _activeAccent =>
      _accentPalettes[_activeBrandDirection]!;

  static void setBrandDirection(BrandDirection direction) {
    _activeBrandDirection = direction;
  }

  static BrandDirection get activeBrandDirection => _activeBrandDirection;

  static Color get primary => _activeAccent.primary;
  static Color get primaryLight => _activeAccent.primaryLight;
  static Color get primaryDark => _activeAccent.primaryDark;

  /// Glow tone for highlighted surfaces
  static Color get softGlow => _activeAccent.softGlow;

  /// Surface colors - layered depth system (DARK MODE DEFAULTS)
  /// Use the theme-aware getters below for actual usage
  static const Color surfaceDark = Color(0xFF0A0E14);
  static const Color surfaceSecondary = Color(0xFF0F1622);
  static const Color surfaceCard = Color(0xFF111824);
  static const Color surfaceElevated = Color(0xFF162132);
  static const Color surfaceBorder = Color(0xFF263246);

  /// Text colors - clear hierarchy (DARK MODE DEFAULTS)
  /// Use the theme-aware getters below for actual usage
  static const Color textPrimary = Color(0xFFF7FBFF);
  static const Color textSecondary = Color(0xFFC7D2E5);
  static const Color textMuted = Color(0xFF9FB0CB);

  /// Accent colors for data/stats
  static const Color win = Color(0xFF2ED47A);
  static const Color loss = Color(0xFFFF5C7A);
  static Color get neutral => _activeAccent.neutral;
  static Color get warning => _activeAccent.warning;

  /// Court-surface accent language (Authored style).
  /// Surface becomes a small meaningful accent, never a full theme:
  /// clay → terracotta, grass → green, carpet → violet, hard → court blue.
  static Color surfaceAccent(String surface) {
    switch (surface.trim().toLowerCase()) {
      case 'clay':
        return const Color(0xFFD8662E); // terracotta
      case 'grass':
        return const Color(0xFF3FA866); // grass green
      case 'carpet':
        return const Color(0xFF8B7CFF); // indoor violet
      case 'hard':
      default:
        return const Color(0xFF3C82E6); // court blue
    }
  }

  // ============ LIGHT MODE COLORS ============
  static const Color _surfaceLight = Color(0xFFF3ECE3);
  static const Color _surfaceCardLight = Color(0xFFFFFBF5);
  static const Color _surfaceElevatedLight = Color(0xFFEDE2D3);
  static const Color _surfaceBorderLight = Color(0xFFD7C6B0);
  static const Color _textPrimaryLight = Color(0xFF1B1715);
  static const Color _textSecondaryLight = Color(0xFF463E38);
  static const Color _textMutedLight = Color(0xFF7A6F65);

  // ============ THEME-AWARE COLOR GETTERS ============

  /// Get scaffold background color based on theme
  static Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : _surfaceLight;
  }

  /// Get card background color based on theme
  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceCard
        : _surfaceCardLight;
  }

  /// Get elevated surface color based on theme
  static Color elevatedBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceElevated
        : _surfaceElevatedLight;
  }

  /// Get border color based on theme
  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceBorder
        : _surfaceBorderLight;
  }

  /// Get primary text color based on theme
  static Color textPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimary
        : _textPrimaryLight;
  }

  /// Get secondary text color based on theme
  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondary
        : _textSecondaryLight;
  }

  /// Get muted text color based on theme
  static Color textMutedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textMuted
        : _textMutedLight;
  }

  /// Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get theme-aware card decoration
  static BoxDecoration cardDecorationThemed(BuildContext context) {
    return BoxDecoration(
      color: cardBackground(context),
      borderRadius: BorderRadius.circular(radiusLG),
      border: Border.all(color: borderColor(context), width: 1),
    );
  }

  /// Get theme-aware elevated card decoration
  static BoxDecoration elevatedCardDecorationThemed(BuildContext context) {
    return BoxDecoration(
      color: elevatedBackground(context),
      borderRadius: BorderRadius.circular(radiusLG),
      boxShadow: cardShadow,
    );
  }

  // ============ SPACING ============

  /// Consistent spacing scale (4px base)
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  /// Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spaceMD,
    vertical: spaceLG,
  );

  /// Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceMD);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(spaceLG);

  // ============ BORDER RADIUS ============

  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;

  // ============ TYPOGRAPHY ============
  // Display font: Sora (calm authority)
  // Body font: Inter (decision-first readability)
  // NOTE: These use dark mode colors by default. Use themed versions for proper light/dark support.
  static TextStyle _display({
    required double size,
    required FontWeight weight,
    required Color color,
    double spacing = 0,
    double? height,
  }) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  static TextStyle _body({
    required double size,
    required FontWeight weight,
    required Color color,
    double spacing = 0,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  /// Screen titles - bold, commanding (increased ~15%)
  static TextStyle get headingLarge => _display(
        size: 38,
        weight: FontWeight.w600,
        color: textPrimary,
        spacing: -0.4,
        height: 1.1,
      );

  /// Section/Card headers (increased ~18%)
  static TextStyle get headingMedium => _display(
        size: 26,
        weight: FontWeight.w600,
        color: textPrimary,
        spacing: -0.25,
        height: 1.15,
      );

  /// Card titles / Row headers (increased ~15%)
  static TextStyle get headingSmall => _display(
        size: 20,
        weight: FontWeight.w500,
        color: textPrimary,
        spacing: -0.1,
        height: 1.2,
      );

  /// Body text - readable, calm (increased ~15%)
  static TextStyle get bodyLarge => _body(
        size: 18,
        weight: FontWeight.w400,
        color: textSecondary,
        height: 1.55,
      );

  /// Standard body (increased ~14%)
  static TextStyle get bodyMedium => _body(
        size: 16,
        weight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      );

  /// Helper text, descriptions (increased ~15%)
  static TextStyle get bodySmall => _body(
        size: 15,
        weight: FontWeight.w400,
        color: textMuted,
        height: 1.45,
      );

  /// Labels and captions (increased ~17%)
  static TextStyle get label => _body(
        size: 13,
        weight: FontWeight.w600,
        color: textMuted,
        spacing: 0.8,
        height: 1.4,
      );

  /// Stats/numbers - large display (hero stats like win rate)
  static TextStyle get statLarge => _display(
        size: 42,
        weight: FontWeight.w800,
        color: textPrimary,
        spacing: -1.0,
        height: 1.0,
      );

  /// Stats - medium display
  static TextStyle get statMedium => _display(
        size: 30,
        weight: FontWeight.w600,
        color: textPrimary,
        spacing: -0.4,
        height: 1.05,
      );

  /// Score display - prominent
  static TextStyle get scoreDisplay => _display(
        size: 36,
        weight: FontWeight.w700,
        color: textPrimary,
        spacing: -0.6,
      );

  // ============ THEME-AWARE TEXT STYLES ============

  static TextStyle headingLargeThemed(BuildContext context) => _display(
        size: 38,
        weight: FontWeight.w600,
        color: textPrimaryColor(context),
        spacing: -0.4,
        height: 1.1,
      );

  static TextStyle headingMediumThemed(BuildContext context) => _display(
        size: 26,
        weight: FontWeight.w600,
        color: textPrimaryColor(context),
        spacing: -0.25,
        height: 1.15,
      );

  static TextStyle headingSmallThemed(BuildContext context) => _display(
        size: 20,
        weight: FontWeight.w500,
        color: textPrimaryColor(context),
        spacing: -0.1,
        height: 1.2,
      );

  static TextStyle bodyLargeThemed(BuildContext context) => _body(
        size: 18,
        weight: FontWeight.w400,
        color: textSecondaryColor(context),
        height: 1.55,
      );

  static TextStyle bodyMediumThemed(BuildContext context) => _body(
        size: 16,
        weight: FontWeight.w400,
        color: textSecondaryColor(context),
        height: 1.5,
      );

  static TextStyle bodySmallThemed(BuildContext context) => _body(
        size: 15,
        weight: FontWeight.w400,
        color: textMutedColor(context),
        height: 1.45,
      );

  static TextStyle labelThemed(BuildContext context) => _body(
        size: 13,
        weight: FontWeight.w600,
        color: textMutedColor(context),
        spacing: 0.8,
        height: 1.4,
      );

  static TextStyle statLargeThemed(BuildContext context) => _display(
        size: 42,
        weight: FontWeight.w800,
        color: textPrimaryColor(context),
        spacing: -1.0,
        height: 1.0,
      );

  static TextStyle statMediumThemed(BuildContext context) => _display(
        size: 30,
        weight: FontWeight.w600,
        color: textPrimaryColor(context),
        spacing: -0.4,
        height: 1.05,
      );

  /// Scoreline — the identity face for tennis scores (Authored style).
  /// Monospace with tabular figures so "6-4 3-6 7-5" reads like a scoreboard.
  /// This is pure typography doing identity work; nothing else looks like it.
  static TextStyle scorelineThemed(
    BuildContext context, {
    double size = 30,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? textPrimaryColor(context),
        letterSpacing: -0.5,
        height: 1.0,
      );

  /// Get theme-aware input decoration
  static InputDecoration inputDecorationThemed(
    BuildContext context, {
    String? label,
    String? hint,
    IconData? prefixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            bodyMediumThemed(context).copyWith(color: textMutedColor(context)),
        hintStyle: bodyMediumThemed(context)
            .copyWith(color: textMutedColor(context).withValues(alpha: 0.5)),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: textMutedColor(context))
            : null,
        filled: true,
        fillColor: cardBackground(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: borderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: borderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceMD,
        ),
      );

  // ============ SHADOWS ============

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  /// Subtle blue glow for primary CTA buttons
  static List<BoxShadow> get ctaGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.4),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: softGlow.withValues(alpha: 0.2),
          blurRadius: 32,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ];

  /// Theme-aware CTA glow (only applies in dark mode for subtlety)
  static List<BoxShadow> ctaGlowThemed(BuildContext context) {
    return isDark(context)
        ? ctaGlow
        : [
            BoxShadow(
              color: primary.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ];
  }

  // ============ DECORATIONS ============

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: surfaceBorder, width: 1),
      );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusLG),
        boxShadow: cardShadow,
      );

  // ============ INPUT DECORATION ============

  static InputDecoration inputDecoration({
    String? label,
    String? hint,
    IconData? prefixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: bodyMedium.copyWith(color: textMuted),
        hintStyle: bodyMedium.copyWith(color: textMuted.withValues(alpha: 0.5)),
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, color: textMuted) : null,
        filled: true,
        fillColor: surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceMD,
        ),
      );
}

/// Reusable card widget following design system - NOW THEME-AWARE
class TGCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool elevated;

  const TGCard({
    super.key,
    required this.child,
    this.padding,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? AppTheme.cardPadding,
      decoration: elevated
          ? AppTheme.elevatedCardDecorationThemed(context)
          : AppTheme.cardDecorationThemed(context),
      child: child,
    );
  }
}

/// Card with header - THEME-AWARE
class TGCardWithHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget child;

  const TGCardWithHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppTheme.primary,
                ),
                const SizedBox(width: AppTheme.spaceSM),
              ],
              Text(title, style: AppTheme.headingSmallThemed(context)),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          child,
        ],
      ),
    );
  }
}

/// Bullet point item for lists - THEME-AWARE
class TGBulletPoint extends StatelessWidget {
  final String text;
  final Color? bulletColor;

  const TGBulletPoint({
    super.key,
    required this.text,
    this.bulletColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: bulletColor ?? AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Text(text, style: AppTheme.bodyMediumThemed(context)),
          ),
        ],
      ),
    );
  }
}

/// Collapsible section for optional content
class TGCollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const TGCollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<TGCollapsibleSection> createState() => _TGCollapsibleSectionState();
}

class _TGCollapsibleSectionState extends State<TGCollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecorationThemed(context),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: AppTheme.cardPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title,
                      style: AppTheme.headingSmallThemed(context)),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMD,
                0,
                AppTheme.spaceMD,
                AppTheme.spaceMD,
              ),
              child: widget.child,
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
