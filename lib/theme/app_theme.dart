import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TennisGPT Design System
/// Direction: calm tactical intelligence.
/// Clarity-first hierarchy, premium restraint, and pressure-ready readability.

class AppTheme {
  AppTheme._();

  // ============ COLORS ============
  // ComposureDesign1 brand palette (TypeUI design system).
  static const Color primary = Color(0xFF0166FF); // brand
  static const Color primaryLight = Color(0xFF4D9AFF); // fg-brand (dark)
  static const Color primaryDark = Color(0xFF0052CC); // brand-strong

  /// Glow tone for highlighted surfaces
  static const Color softGlow = Color(0xFF4D9AFF);

  /// Brand-tinted background surfaces (light mode), from ComposureDesign1.
  static const Color brandSofter = Color(0xFFE8F1FF); // brand-softer
  static const Color brandSoft = Color(0xFFCCE0FF); // brand-soft

  /// Surface colors - layered depth system (DARK MODE DEFAULTS)
  /// ComposureDesign1 dark neutral scale. Use theme-aware getters for usage.
  static const Color surfaceDark = Color(0xFF060B18); // neutral-primary
  static const Color surfaceSecondary = Color(0xFF0C1222); // neutral-*-soft
  static const Color surfaceCard = Color(0xFF131B2E); // neutral-*-medium
  static const Color surfaceElevated = Color(0xFF1E293B); // neutral-*-strong
  static const Color surfaceBorder = Color(0xFF334155); // quaternary-medium

  /// Text colors - clear hierarchy (DARK MODE DEFAULTS)
  /// ComposureDesign1 slate text scale (contrast-verified against surfaceDark).
  static const Color textPrimary = Color(0xFFF1F5F9); // heading
  static const Color textSecondary = Color(0xFFCBD5E1); // body (>=7:1)
  static const Color textMuted = Color(0xFF94A3B8); // body-subtle (>=4.5:1)

  /// Accent colors for data/stats (ComposureDesign1 status + accent tokens)
  static const Color win = Color(0xFF10B981); // success
  static const Color loss = Color(0xFFF43F5E); // danger (dark fg)
  static const Color neutral = Color(0xFF14B8A6); // teal accent
  static const Color warning = Color(0xFFF97316); // warning

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
  // ComposureDesign1 light neutral scale (public so ThemeService can reuse).
  static const Color surfaceLight = Color(0xFFF8FAFC); // neutral-secondary-soft
  static const Color surfaceCardLight = Color(0xFFFFFFFF); // neutral-primary
  static const Color surfaceElevatedLight = Color(0xFFF0F4F8); // neutral-tertiary
  static const Color surfaceBorderLight = Color(0xFFE2E8F0); // border-default
  static const Color textPrimaryLight = Color(0xFF0F172A); // heading
  static const Color textSecondaryLight = Color(0xFF475569); // body
  static const Color textMutedLight = Color(0xFF64748B); // body-subtle

  // ============ THEME-AWARE COLOR GETTERS ============

  /// Get scaffold background color based on theme
  static Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surfaceLight;
  }

  /// Get card background color based on theme
  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceCard
        : surfaceCardLight;
  }

  /// Get elevated surface color based on theme
  static Color elevatedBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceElevated
        : surfaceElevatedLight;
  }

  /// Get border color based on theme
  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceBorder
        : surfaceBorderLight;
  }

  /// Get primary text color based on theme
  static Color textPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimary
        : textPrimaryLight;
  }

  /// Get secondary text color based on theme
  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondary
        : textSecondaryLight;
  }

  /// Get muted text color based on theme
  static Color textMutedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textMuted
        : textMutedLight;
  }

  /// Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get theme-aware card decoration.
  /// ComposureDesign1 card: base radius (16), 1px border, shadow-md depth.
  static BoxDecoration cardDecorationThemed(BuildContext context) {
    return BoxDecoration(
      color: cardBackground(context),
      borderRadius: BorderRadius.circular(radiusLG),
      border: Border.all(color: borderColor(context), width: 1),
      boxShadow: cardShadow,
    );
  }

  /// Get theme-aware elevated card decoration (shadow-lg step-up).
  static BoxDecoration elevatedCardDecorationThemed(BuildContext context) {
    return BoxDecoration(
      color: elevatedBackground(context),
      borderRadius: BorderRadius.circular(radiusLG),
      border: Border.all(color: borderColor(context), width: 1),
      boxShadow: elevatedShadow,
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
  // ComposureDesign1 radius scale: sm 6, default 10, base 16, full 9999.
  static const double radiusSM = 6.0; // sm - checkboxes, tiny elements
  static const double radiusMD = 10.0; // default - badges, small controls
  static const double radiusLG = 16.0; // base - buttons, cards, inputs, modals
  static const double radiusXL = 16.0; // base (no larger tier in the scale)
  static const double radiusFull = 9999.0; // pills, avatars, toggles

  // ============ TYPOGRAPHY ============
  // ComposureDesign1 font: Zalando Sans SemiExpanded (bundled variable font).
  // Single family for display + body, per the design system.
  static const String fontFamily = 'ZalandoSans';

  /// SemiExpanded width on the variable `wdth` axis (75–125 range).
  static const double _semiExpandedWidth = 112.5;

  /// Width variation shared by all brand type (SemiExpanded).
  static const List<FontVariation> fontVariationsSemiExpanded = [
    FontVariation('wdth', _semiExpandedWidth),
  ];

  static TextStyle _brandFont({
    required double size,
    required FontWeight weight,
    required Color color,
    double spacing = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [
        FontVariation('wght', weight.value.toDouble()),
        const FontVariation('wdth', _semiExpandedWidth),
      ],
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  // Display + body share the single brand family; kept as separate helpers
  // so existing call sites and intent (headings vs. copy) stay readable.
  static TextStyle _display({
    required double size,
    required FontWeight weight,
    required Color color,
    double spacing = 0,
    double? height,
  }) =>
      _brandFont(
        size: size,
        weight: weight,
        color: color,
        spacing: spacing,
        height: height,
      );

  static TextStyle _body({
    required double size,
    required FontWeight weight,
    required Color color,
    double spacing = 0,
    double? height,
  }) =>
      _brandFont(
        size: size,
        weight: weight,
        color: color,
        spacing: spacing,
        height: height,
      );

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
          borderRadius: BorderRadius.circular(radiusLG),
          borderSide: BorderSide(color: borderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          borderSide: BorderSide(color: borderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceMD,
        ),
      );

  // ============ SHADOWS ============

  /// ComposureDesign1 shadow-md (standard cards, popovers, dropdowns).
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x14000000), // black / 0.08
          blurRadius: 16,
          spreadRadius: -4,
          offset: Offset(0, 6),
        ),
        BoxShadow(
          color: Color(0x0D000000), // black / 0.05
          blurRadius: 6,
          spreadRadius: -2,
          offset: Offset(0, 2),
        ),
      ];

  /// ComposureDesign1 shadow-lg (prominent cards, sticky/glass surfaces).
  static List<BoxShadow> get elevatedShadow => const [
        BoxShadow(
          color: Color(0x1A000000), // black / 0.10
          blurRadius: 28,
          spreadRadius: -6,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color(0x0F000000), // black / 0.06
          blurRadius: 12,
          spreadRadius: -4,
          offset: Offset(0, 4),
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
          borderRadius: BorderRadius.circular(radiusLG),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          borderSide: const BorderSide(color: primary, width: 2),
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

/// ComposureDesign1 glassmorphism card (opt-in, for hero/feature surfaces).
///
/// Implements the design system's frosted-glass spec: `backdrop blur(16)`,
/// translucent fill, a 1px translucent-white frosted edge, base radius (16),
/// and shadow-md. Use for signature surfaces; standard content should keep
/// [TGCard] for readability and performance.
class TGGlassCard extends StatelessWidget {
  const TGGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    // Glass fill + frosted edge (translucent white), per cards.md.
    final fill = Colors.white.withValues(alpha: dark ? 0.06 : 0.65);
    final edge = Colors.white.withValues(alpha: dark ? 0.10 : 0.50);

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? AppTheme.cardPadding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: edge, width: 1),
            boxShadow: AppTheme.cardShadow,
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}
