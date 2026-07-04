import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================
/// UI Kit — shared neutral components.
///
/// The app's visual language is Broadcast (see broadcast_kit.dart for the
/// signature components). What lives here are the calm, near-monochrome
/// utility pieces reused across screens.
///
/// Shared rules: real affordances, 44px targets, semantic labels, AA contrast,
/// skeletons over spinners.
/// ============================================================

/// Semantic feedback colors.
class AppAccents {
  AppAccents._();

  /// Reserved for errors / destructive moments.
  static const Color negative = Color(0xFFFF453A);

  /// Reserved for positive confirmations (e.g. saved).
  static const Color positive = Color(0xFF32D74B);
}

/// Icon tile — neutral monochrome.
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

/// Pill chip — hairline outline (or soft [filled] tint).
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
    final c = color ?? AppTheme.textMutedColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? c.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled ? Colors.transparent : AppTheme.borderColor(context),
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
