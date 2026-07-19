import 'package:flutter/material.dart';

/// Composure Design System — active skin: TypeUI · Cypherpunk.
/// Direction: stark, two-tone retro-tech. One electric-lime section surface,
/// near-black ink type + 2px ink borders, raised beige cards, crisp 2px
/// corners, flat/grounded elevation, and a retro-mono display voice.
///
/// Cypherpunk is a single stark identity, so the light and dark constants
/// resolve to the same palette; the app reads as Cypherpunk regardless of the
/// system theme toggle.

class AppTheme {
  AppTheme._();

  // ============ COLORS ============
  // Cypherpunk palette (TypeUI). `brand` is ink; the lime is the section fill.
  static const Color _ink = Color(0xFF1C1C1C); // brand / body / borders
  static const Color _lime = Color(0xFFD8FF7C); // neutral-secondary (sections)
  static const Color _beige = Color(0xFFEAE5DB); // neutral-primary (cards)

  static const Color primary = _ink; // brand (ink)
  static const Color primaryLight = _ink; // brand reads as ink at every step
  static const Color primaryDark = Color(0xFF000000); // pressed ink (dark-strong)

  /// Glow tone (Cypherpunk is flat; kept as ink for any legacy reference).
  static const Color softGlow = _ink;

  /// Brand-tinted background surfaces — Cypherpunk raised/soft neutrals.
  static const Color brandSofter = _beige; // brand-softer (#E9E5DB≈#EAE5DB)
  static const Color brandSoft = Color(0xFFC9C3B1); // brand-soft

  /// Surface colors (DARK MODE DEFAULTS — mapped to the single Cypherpunk skin).
  static const Color surfaceDark = _lime; // section surface (lime)
  static const Color surfaceSecondary = _lime; // app bars / bands (lime)
  static const Color surfaceCard = _beige; // raised card surface
  static const Color surfaceElevated = _beige; // raised/floating surface
  static const Color surfaceBorder = _ink; // 2px ink border

  /// Text colors — all ink; hierarchy comes from size/weight, not color.
  static const Color textPrimary = _ink; // heading
  static const Color textSecondary = _ink; // body
  static const Color textMuted = _ink; // body-subtle

  /// Status + accent tokens (used only when something truly is that state).
  static const Color win = Color(0xFF2D8654); // success
  static const Color loss = Color(0xFFE94736); // danger
  static const Color neutral = Color(0xFF2BB3A3); // teal accent
  static const Color warning = Color(0xFFA8852E); // warning-strong (legible)

  /// Court-surface accent language, mapped onto the Cypherpunk accent set:
  /// clay → orange, grass → teal, carpet → purple, hard → indigo.
  static Color surfaceAccent(String surface) {
    switch (surface.trim().toLowerCase()) {
      case 'clay':
        return const Color(0xFFF6913C); // orange
      case 'grass':
        return const Color(0xFF2BB3A3); // teal
      case 'carpet':
        return const Color(0xFF9D7CFF); // purple
      case 'hard':
      default:
        return const Color(0xFF4A5BE0); // indigo
    }
  }

  // ============ LIGHT MODE COLORS ============
  // Same single Cypherpunk skin (public so ThemeService can reuse).
  static const Color surfaceLight = _lime; // section surface (lime)
  static const Color surfaceCardLight = _beige; // raised card surface
  static const Color surfaceElevatedLight = _beige; // raised/floating surface
  static const Color surfaceBorderLight = _ink; // 2px ink border
  static const Color textPrimaryLight = _ink; // heading
  static const Color textSecondaryLight = _ink; // body
  static const Color textMutedLight = _ink; // body-subtle

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

  /// Cypherpunk is a single stark light identity — always report "not dark" so
  /// every screen takes the light branch and status-bar icons stay ink.
  static bool isDark(BuildContext context) => false;

  /// Cypherpunk card: raised beige surface, crisp 2px corner, bold 2px ink
  /// border, and NO resting shadow — separation comes from the border.
  static BoxDecoration cardDecorationThemed(BuildContext context) {
    return BoxDecoration(
      color: cardBackground(context),
      borderRadius: BorderRadius.circular(radiusLG),
      border: Border.all(color: borderColor(context), width: borderWidth),
      boxShadow: cardShadow,
    );
  }

  /// Elevated/raised card — same crisp beige shell with a whisper of ink lift.
  static BoxDecoration elevatedCardDecorationThemed(BuildContext context) {
    return BoxDecoration(
      color: elevatedBackground(context),
      borderRadius: BorderRadius.circular(radiusLG),
      border: Border.all(color: borderColor(context), width: borderWidth),
      boxShadow: elevatedShadow,
    );
  }

  /// Cypherpunk borders are a bold 2px ink stroke on every shell.
  static const double borderWidth = 2.0;

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
  // Cypherpunk is near-square: every component shell is a crisp 2px corner.
  // Only functionally-round controls (avatars, toggles, dots) use radiusFull.
  static const double radiusSM = 2.0; // nested children / tiny elements
  static const double radiusMD = 2.0; // badges, small controls
  static const double radiusLG = 2.0; // buttons, cards, inputs, modals (shell)
  static const double radiusXL = 4.0; // oversized hero / feature panels
  static const double radiusFull = 9999.0; // avatars, toggle track, status dots

  // ============ TYPOGRAPHY ============
  // Cypherpunk pairs two voices:
  //  • body/UI/headings — a clean neo-grotesque (Untitled Sans → bundled
  //    ZalandoSans at normal width).
  //  • the "loud moments" — a retro monospace (Offbit → bundled Space Mono)
  //    for stats, scorelines and uppercase eyebrows, for the terminal feel.
  static const String fontFamily = 'ZalandoSans'; // neo-grotesque body/UI
  static const String monoFamily = 'SpaceMono'; // retro-mono display voice

  /// Normal width on the variable `wdth` axis (Cypherpunk body is compact,
  /// not expanded). Kept under the old name so call sites stay valid.
  static const double _brandWidth = 100.0;

  static const List<FontVariation> fontVariationsSemiExpanded = [
    FontVariation('wdth', _brandWidth),
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
        const FontVariation('wdth', _brandWidth),
      ],
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  /// Retro-mono display voice (Space Mono). Used for stats, scorelines and
  /// uppercase eyebrows — the Cypherpunk "loud moments".
  static TextStyle _mono({
    required double size,
    required FontWeight weight,
    required Color color,
    double spacing = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  // Headings + body use the neo-grotesque; helpers kept separate so intent
  // (headings vs. copy) stays readable at call sites.
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

  /// Stats/numbers - large display (hero stats like win rate). Retro mono.
  static TextStyle get statLarge => _mono(
        size: 42,
        weight: FontWeight.w700,
        color: textPrimary,
        spacing: -0.5,
        height: 1.0,
      );

  /// Stats - medium display. Retro mono.
  static TextStyle get statMedium => _mono(
        size: 30,
        weight: FontWeight.w700,
        color: textPrimary,
        height: 1.05,
      );

  /// Score display - prominent. Retro mono.
  static TextStyle get scoreDisplay => _mono(
        size: 36,
        weight: FontWeight.w700,
        color: textPrimary,
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

  static TextStyle statLargeThemed(BuildContext context) => _mono(
        size: 42,
        weight: FontWeight.w700,
        color: textPrimaryColor(context),
        spacing: -0.5,
        height: 1.0,
      );

  static TextStyle statMediumThemed(BuildContext context) => _mono(
        size: 30,
        weight: FontWeight.w700,
        color: textPrimaryColor(context),
        height: 1.05,
      );

  /// Scoreline — the identity face for scores, and a natural fit for the
  /// Cypherpunk retro-mono voice. Bundled Space Mono with tabular figures so
  /// "6-4 3-6 7-5" reads like a terminal scoreboard.
  static TextStyle scorelineThemed(
    BuildContext context, {
    double size = 30,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) =>
      _mono(
        size: size,
        weight: weight,
        color: color ?? textPrimaryColor(context),
        spacing: -0.5,
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
          borderSide: BorderSide(color: borderColor(context), width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          borderSide: BorderSide(color: borderColor(context), width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          borderSide: const BorderSide(color: primary, width: borderWidth),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceMD,
        ),
      );

  // ============ SHADOWS ============
  // Cypherpunk reads flat and grounded: resting surfaces separate with the
  // 2px ink border, never a drop shadow. Depth (ink at low opacity) is
  // reserved for things that genuinely float.

  /// Resting cards/fields are flat — separation is the ink border.
  static List<BoxShadow> get cardShadow => const [];

  /// A whisper of ink lift for raised/floating surfaces (elevation-2).
  static List<BoxShadow> get elevatedShadow => const [
        BoxShadow(
          color: Color(0x141C1C1C), // ink / 0.08
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];

  /// Cypherpunk primary actions are flat ink — no glow.
  static List<BoxShadow> get ctaGlow => const [];

  /// Kept for API compatibility; Cypherpunk CTAs are flat.
  static List<BoxShadow> ctaGlowThemed(BuildContext context) => const [];

  // ============ DECORATIONS ============

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: surfaceBorder, width: borderWidth),
      );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: surfaceBorder, width: borderWidth),
        boxShadow: elevatedShadow,
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
          borderSide: const BorderSide(color: surfaceBorder, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          borderSide: const BorderSide(color: surfaceBorder, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          borderSide: const BorderSide(color: primary, width: borderWidth),
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

/// Signature/feature panel. Cypherpunk has no frosted glass — this is a raised
/// beige shell with the bold 2px ink border and a whisper of ink lift. Kept
/// under the same name so existing call sites stay valid.
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
    final content = Container(
      padding: padding ?? AppTheme.cardPadding,
      decoration: AppTheme.elevatedCardDecorationThemed(context),
      child: child,
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}
