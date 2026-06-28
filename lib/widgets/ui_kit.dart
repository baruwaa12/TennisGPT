import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// ============================================================
/// UI Kit — Broadcast.
///
/// The app committed to a single visual language (Broadcast). These shared
/// components render in the calm, near-monochrome base look that Broadcast
/// screens build on top of.
///
/// Shared rules: real affordances, 44px targets, semantic labels, AA contrast,
/// skeletons over spinners.
/// ============================================================

/// Retained so existing component branches compile unchanged. Broadcast is the
/// only style now, so the colourful "vibrant" path is never taken.
bool _vibrant(BuildContext context) => false;

/// Accent palette. The vibrant fields are the rainbow "colour moments"; the
/// minimal style mostly ignores them in favour of a single brand accent.
class AppAccents {
  AppAccents._();

  // Vibrant palette.
  static const Color blue = Color(0xFF4C8DFF);
  static const Color violet = Color(0xFF8B7CFF);
  static const Color teal = Color(0xFF2BD9C0);
  static const Color green = Color(0xFF22C77E);
  static const Color coral = Color(0xFFFF6B81);
  static const Color amber = Color(0xFFFFB23E);

  /// The single brand accent (system-blue style).
  static Color accent(BuildContext context) => AppTheme.primary;

  /// Reserved for errors / destructive moments.
  static const Color negative = Color(0xFFFF453A);

  /// Reserved for positive confirmations (e.g. saved).
  static const Color positive = Color(0xFF32D74B);

  /// Primary brand gradient — the vibrant hero colour moment.
  static List<Color> heroGradient(BuildContext context) =>
      [AppTheme.primary, violet];

  /// Soft tonal fill for a given accent.
  static Color tint(Color color, {double alpha = 0.14}) =>
      color.withValues(alpha: alpha);
}

/// Backdrop behind scaffold content.
/// Vibrant → soft colour blobs. Minimal → a barely-there vertical lift.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (_vibrant(context)) {
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
              child: _blob(glow.withValues(alpha: 0.22), 360),
            ),
            Positioned(
              top: 120,
              left: -140,
              child: _blob(AppAccents.teal.withValues(alpha: 0.12), 300),
            ),
          ],
        ),
      );
    }

    final scaffold = AppTheme.scaffoldBackground(context);
    final lift = AppTheme.isDark(context)
        ? AppTheme.elevatedBackground(context).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.5);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lift, scaffold],
            stops: const [0.0, 0.45],
          ),
        ),
      ),
    );
  }

  Widget _blob(Color color, double size) {
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

/// Internal: the brighter surface a minimal card/button animates to on press.
Color _brighten(BuildContext context, Color base, {double dark = 0.10}) {
  return AppTheme.isDark(context)
      ? Color.lerp(base, Colors.white, dark)!
      : Color.lerp(base, Colors.white, 1.0)!;
}

/// Primary call-to-action.
/// Vibrant → gradient fill. Minimal → solid accent. Both brighten + lift.
class PrimaryActionButton extends StatefulWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.color,
    this.gradientColors,
    this.foreground = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;

  /// Solid fill (minimal). Defaults to the brand accent.
  final Color? color;

  /// Gradient fill (vibrant). Defaults to the hero gradient.
  final List<Color>? gradientColors;
  final Color foreground;

  @override
  State<PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<PrimaryActionButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final vibrant = _vibrant(context);

    final BoxDecoration decoration;
    final Color glow;
    if (vibrant) {
      final stops = widget.gradientColors ?? AppAccents.heroGradient(context);
      final pressedStops = _down
          ? stops.map((c) => Color.lerp(c, Colors.white, 0.16)!).toList()
          : stops;
      glow = stops.last;
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: pressedStops,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: _down ? 0.45 : 0.32),
            blurRadius: _down ? 28 : 20,
            offset: Offset(0, _down ? 12 : 10),
          ),
        ],
      );
    } else {
      final fill = widget.color ?? AppTheme.primary;
      glow = fill;
      decoration = BoxDecoration(
        color: _down ? Color.lerp(fill, Colors.white, 0.16)! : fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: _down ? 0.40 : 0.22),
            blurRadius: _down ? 28 : 16,
            offset: Offset(0, _down ? 12 : 8),
          ),
        ],
      );
    }

    final body = AnimatedScale(
      scale: _down ? 0.98 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 54,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
        decoration: decoration,
        child: widget.loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(widget.foreground),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSM),
                  Text(widget.loadingLabel ?? widget.label,
                      style: _labelStyle()),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: widget.foreground, size: 20),
                    const SizedBox(width: AppTheme.spaceSM),
                  ],
                  Text(widget.label, style: _labelStyle()),
                ],
              ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.onPressed!();
                }
              : null,
          child: body,
        ),
      ),
    );
  }

  TextStyle _labelStyle() => AppTheme.headingSmall.copyWith(
        color: widget.foreground,
        fontSize: 16,
        letterSpacing: 0.1,
      );
}

/// Tappable surface.
/// Vibrant → outlined card with an ink ripple. Minimal → lights up brighter
/// (and gently lifts) each time it's pressed.
class PressableCard extends StatefulWidget {
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
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLG);
    final accent = widget.accent ?? AppTheme.primary;
    final interactive = widget.onTap != null;

    if (_vibrant(context)) {
      return Semantics(
        button: interactive,
        label: widget.semanticLabel,
        child: Material(
          color: AppTheme.cardBackground(context).withValues(alpha: 0.92),
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: interactive
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onTap!();
                  }
                : null,
            child: Container(
              padding: widget.padding ?? AppTheme.cardPadding,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: widget.accent != null
                      ? accent.withValues(alpha: 0.30)
                      : AppTheme.borderColor(context),
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      );
    }

    // Minimal: press-to-brighten.
    final base = AppTheme.cardBackground(context)
        .withValues(alpha: AppTheme.isDark(context) ? 0.92 : 1);
    final pressed = _brighten(context, base);
    final dark = AppTheme.isDark(context);

    final restingShadow = <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.20 : 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
    final pressedShadow = <BoxShadow>[
      BoxShadow(
        color: accent.withValues(alpha: dark ? 0.24 : 0.16),
        blurRadius: 28,
        offset: const Offset(0, 12),
      ),
    ];

    final card = AnimatedScale(
      scale: _down ? 0.985 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: widget.padding ?? AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: _down ? pressed : base,
          borderRadius: radius,
          border: Border.all(
            color: _down
                ? accent.withValues(alpha: 0.45)
                : AppTheme.borderColor(context),
          ),
          boxShadow:
              interactive ? (_down ? pressedShadow : restingShadow) : null,
        ),
        child: widget.child,
      ),
    );

    if (!interactive) {
      return Semantics(label: widget.semanticLabel, child: card);
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap!();
        },
        child: card,
      ),
    );
  }
}

/// Icon tile.
/// Vibrant → soft tonal colour fill. Minimal → neutral monochrome.
class TonalIconBadge extends StatelessWidget {
  const TonalIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (_vibrant(context)) {
      final c = color ?? AppTheme.primary;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppAccents.tint(c),
          borderRadius: BorderRadius.circular(size * 0.30),
        ),
        child: Icon(icon, color: c, size: size * 0.46),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.elevatedBackground(context)
            .withValues(alpha: AppTheme.isDark(context) ? 0.6 : 1),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Icon(
        icon,
        color: color ?? AppTheme.textSecondaryColor(context),
        size: size * 0.46,
      ),
    );
  }
}

/// Pill chip.
/// Vibrant → soft tinted colour fill. Minimal → hairline outline (or [filled]).
class TonalChip extends StatelessWidget {
  const TonalChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final vibrant = _vibrant(context);
    final c = color ?? AppTheme.textMutedColor(context);
    final useFill = vibrant || filled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: useFill ? c.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: useFill ? Colors.transparent : AppTheme.borderColor(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTheme.label.copyWith(color: c, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

/// Segmented control.
/// Vibrant → gradient pill, white label. Minimal → floating elevated pill.
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
    final vibrant = _vibrant(context);

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.elevatedBackground(context)
            .withValues(alpha: vibrant ? 0.7 : 0.6),
        borderRadius: BorderRadius.circular(
            vibrant ? 999 : AppTheme.radiusMD),
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
                  decoration: vibrant
                      ? BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppAccents.heroGradient(context),
                          ),
                          borderRadius: BorderRadius.circular(999),
                        )
                      : BoxDecoration(
                          color: AppTheme.cardBackground(context),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM + 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: AppTheme.isDark(context) ? 0.25 : 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final selected = i == selectedIndex;
                  final Color textColor;
                  if (selected) {
                    textColor = vibrant
                        ? Colors.white
                        : AppTheme.textPrimaryColor(context);
                  } else {
                    textColor = AppTheme.textMutedColor(context);
                  }
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
                              color: textColor,
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

/// A shimmering skeleton block for loading states (preferred over spinners).
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
            color: base.withValues(alpha: 0.35 + (_controller.value * 0.3)),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// A circular progress gauge with a value in the middle.
/// Vibrant → thick gradient stroke. Minimal → thin monochrome stroke.
class StatRing extends StatelessWidget {
  const StatRing({
    super.key,
    required this.progress,
    required this.value,
    this.label,
    this.size = 120,
    this.valueColor,
  });

  final double progress; // 0..1
  final String value;
  final String? label;
  final double size;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final vibrant = _vibrant(context);
    final stroke = vibrant ? size * 0.11 : size * 0.05;
    final colors = vibrant
        ? AppAccents.heroGradient(context)
        : <Color>[
            AppTheme.textPrimaryColor(context),
            AppTheme.textPrimaryColor(context),
          ];
    final track = vibrant
        ? Colors.white.withValues(alpha: 0.22)
        : AppTheme.borderColor(context);
    final textColor = valueColor ??
        (vibrant ? Colors.white : AppTheme.textPrimaryColor(context));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0, 1),
              strokeWidth: stroke,
              colors: colors,
              track: track,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTheme.statMediumThemed(context).copyWith(
                  fontSize: size * 0.30,
                  letterSpacing: -1,
                  height: 1,
                  color: textColor,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: AppTheme.labelThemed(context).copyWith(
                    color: vibrant
                        ? Colors.white70
                        : AppTheme.textMutedColor(context),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.colors,
    required this.track,
  });

  final double progress;
  final double strokeWidth;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    const start = -math.pi / 2;
    final sweep = progress * 2 * math.pi;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + 2 * math.pi,
        colors: colors.length == 1 ? [colors.first, colors.first] : colors,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.track != track ||
      old.colors != colors;
}

/// A colourful stat tile for grid layouts (vibrant style).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLG);
    final content = Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: radius,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            value,
            style: AppTheme.statMediumThemed(context)
                .copyWith(fontSize: 26, letterSpacing: -0.8),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.labelThemed(context)),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: content,
      ),
    );
  }
}

/// Section header: a title with an optional trailing text action.
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
        Text(
          title,
          style: AppTheme.headingSmallThemed(context)
              .copyWith(letterSpacing: -0.2),
        ),
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
