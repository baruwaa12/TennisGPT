import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TennisGPT Design System
/// Inspired by Whoop + Strava: calm, confident, premium sports aesthetic

class AppTheme {
  AppTheme._();

  // ============ COLORS ============
  
  /// Primary brand color - deep teal/green, confident but not aggressive
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0F766E);
  
  /// Surface colors - layered depth system
  static const Color surfaceDark = Color(0xFF0A0A0B);
  static const Color surfaceCard = Color(0xFF141416);
  static const Color surfaceElevated = Color(0xFF1C1C1F);
  static const Color surfaceBorder = Color(0xFF2A2A2E);
  
  /// Text colors - clear hierarchy
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  
  /// Accent colors for data/stats
  static const Color win = Color(0xFF22C55E);
  static const Color loss = Color(0xFFEF4444);
  static const Color neutral = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);

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
  
  /// Screen titles - bold, commanding
  static TextStyle get headingLarge => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  /// Section/Card headers
  static TextStyle get headingMedium => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  /// Card titles
  static TextStyle get headingSmall => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );
  
  /// Body text - readable, calm
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.4,
  );
  
  /// Labels and captions
  static TextStyle get label => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textMuted,
    letterSpacing: 0.5,
  );
  
  /// Stats/numbers - tabular for alignment
  static TextStyle get statLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -1,
  );
  
  static TextStyle get statMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // ============ SHADOWS ============
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

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
}

/// Reusable card widget following design system
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
          ? AppTheme.elevatedCardDecoration 
          : AppTheme.cardDecoration,
      child: child,
    );
  }
}

/// Card with header
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
                  size: 18,
                  color: iconColor ?? AppTheme.primary,
                ),
                const SizedBox(width: AppTheme.spaceSM),
              ],
              Text(title, style: AppTheme.headingSmall),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          child,
        ],
      ),
    );
  }
}

/// Bullet point item for lists
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
            child: Text(text, style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

