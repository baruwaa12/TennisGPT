import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// ============================================================
/// UI Kit — modern, youthful, colourful-but-sleek components.
///
/// Design rules (per ui-design-brain):
/// - Restraint over decoration; white space is structure.
/// - One strong colour moment per surface; neutrals carry the rest.
/// - Real affordances: every interactive element has hover/press/disabled.
/// - Accessibility: 44px touch targets, semantic labels, AA contrast.
/// - Skeletons over spinners for predictable layouts.
/// ============================================================

/// A curated, vibrant-but-soft accent palette. These read consistently
/// across light/dark and brand directions, used for tonal "colour moments".
class AppAccents {
  AppAccents._();

  static const Color blue = Color(0xFF4C8DFF); // patterns / focus signal
  static const Color violet = Color(0xFF8B7CFF); // next focus
  static const Color teal = Color(0xFF2BD9C0); // energy / streaks
  static const Color green = Color(0xFF22C77E); // winning / positive
  static const Color coral = Color(0xFFFF6B81); // pressure / caution
  static const Color amber = Color(0xFFFFB23E); // practice / warm

  /// Primary brand gradient — the single hero colour moment.
  static List<Color> heroGradient(BuildContext context) =>
      [AppTheme.primary, violet];

  /// Soft tonal fill for a given accent.
  static Color tint(Color color, {double alpha = 0.14}) =>
      color.withValues(alpha: alpha);
}

/// A subtle accent glow painted behind the scaffold content. Replaces the
/// legibility-killing full-bleed photo with a clean, modern ambience.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final glow = color ?? AppTheme.primary;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: AppTheme.scaffoldBackground(context)),
          ),
          Positioned(
            top: -160,
            right: -120,
            child: _blurBlob(glow.withValues(alpha: 0.22), 360),
          ),
          Positioned(
            top: 120,
            left: -140,
            child: _blurBlob(AppAccents.teal.withValues(alpha: 0.12), 300),
          ),
        ],
      ),
    );
  }

  Widget _blurBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Primary call-to-action. Gradient fill, real ink ripple, loading + disabled
/// states, and a semantic label. Verb-first labels expected.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.gradientColors,
    this.foreground = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;
  final List<Color>? gradientColors;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final colors = gradientColors ?? AppAccents.heroGradient(context);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: colors.last.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              onTap: enabled
                  ? () {
                      HapticFeedback.mediumImpact();
                      onPressed!();
                    }
                  : null,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                child: loading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(foreground),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSM),
                          Text(
                            loadingLabel ?? label,
                            style: AppTheme.headingSmall
                                .copyWith(color: foreground, fontSize: 16),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: foreground, size: 20),
                            const SizedBox(width: AppTheme.spaceSM),
                          ],
                          Text(
                            label,
                            style: AppTheme.headingSmall.copyWith(
                              color: foreground,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tappable surface with a real ink ripple and an outlined card aesthetic
/// (border, not shadow). Use for navigable entities.
class PressableCard extends StatelessWidget {
  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.semanticLabel,
    this.accent,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLG);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: AppTheme.cardBackground(context).withValues(alpha: 0.92),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          child: Container(
            padding: padding ?? AppTheme.cardPadding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: accent != null
                    ? accent!.withValues(alpha: 0.30)
                    : AppTheme.borderColor(context),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A square icon badge with a soft tonal background — the small, repeated
/// "colour moments" that make the UI feel youthful without shouting.
class TonalIconBadge extends StatelessWidget {
  const TonalIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppAccents.tint(color),
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

/// Small pill chip for status/metadata.
class TonalChip extends StatelessWidget {
  const TonalChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppAccents.tint(color, alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTheme.label.copyWith(color: color, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

/// A compact two/three option segmented control with an animated indicator.
/// Immediate effect — use for view switching (not form input).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.elevatedBackground(context).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment(
                  labels.length == 1
                      ? 0
                      : -1 + (selectedIndex * 2 / (labels.length - 1)),
                  0,
                ),
                child: Container(
                  width: segmentWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppAccents.heroGradient(context),
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final selected = i == selectedIndex;
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: labels[i],
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onChanged(i);
                        },
                        child: Center(
                          child: Text(
                            labels[i],
                            style: AppTheme.label.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textMutedColor(context),
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A shimmering skeleton block for loading states (preferred over spinners
/// where the layout is predictable).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = AppTheme.radiusMD,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.elevatedBackground(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withValues(alpha: 0.45 + (_controller.value * 0.35)),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Section header: a strong title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTheme.headingSmallThemed(context)),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onAction!();
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: AppTheme.primary,
            ),
            child: Text(
              actionLabel!,
              style: AppTheme.label.copyWith(color: AppTheme.primary),
            ),
          ),
      ],
    );
  }
}
