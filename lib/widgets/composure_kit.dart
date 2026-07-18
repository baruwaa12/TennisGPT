import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// ============================================================
/// Composure Kit — shared components for the ComposureDesign1
/// (TypeUI) design system.
///
/// Everything here derives its values from [AppTheme] tokens:
/// brand blue, slate neutrals, base-16 radius, shadow scale, and
/// the Zalando Sans SemiExpanded brand font. These are the building
/// blocks every screen should compose from so the app stays
/// visually consistent.
///
/// Shared rules: real pressed states, haptics, Semantics, >=44px
/// tap targets, AA contrast.
/// ============================================================

/// Badge intent — maps to ComposureDesign1 status/brand color families.
enum CBadgeVariant { brand, neutral, success, danger, warning }

/// Small labelled eyebrow (uppercase, tracked) used above headings.
class CEyebrow extends StatelessWidget {
  const CEyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTheme.labelThemed(context).copyWith(
        color: color ?? AppTheme.primary,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Section header: title on the left, optional text action on the right
/// (with a proper >=44px tap target).
class CSectionHeader extends StatelessWidget {
  const CSectionHeader({
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
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTheme.headingSmallThemed(context)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Semantics(
              button: true,
              label: actionLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onAction!();
                },
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 40, minWidth: 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM),
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: AppTheme.bodyMediumThemed(context).copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Primary brand button (filled). Base-16 radius, shadow, press scale,
/// haptics, optional leading icon and loading state. >=44px target.
class CPrimaryButton extends StatefulWidget {
  const CPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;
  final bool expand;

  @override
  State<CPrimaryButton> createState() => _CPrimaryButtonState();
}

class _CPrimaryButtonState extends State<CPrimaryButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final fill = _down ? AppTheme.primaryDark : AppTheme.primary;

    final body = AnimatedScale(
      scale: _down ? 0.98 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: _down ? null : AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
            ] else if (widget.icon != null) ...[
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: AppTheme.spaceSM),
            ],
            Flexible(
              child: Text(
                widget.loading ? (widget.loadingLabel ?? widget.label) : widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontVariations: AppTheme.fontVariationsSemiExpanded,
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Opacity(
        opacity: enabled || widget.loading ? 1 : 0.5,
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
}

/// Secondary button (neutral surface + 1px border, body text).
class CSecondaryButton extends StatelessWidget {
  const CSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
          decoration: BoxDecoration(
            color: AppTheme.elevatedBackground(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppTheme.textSecondaryColor(context), size: 20),
                const SizedBox(width: AppTheme.spaceSM),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMediumThemed(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge / chip. Default radius 10 (design "default"), or [pill] for 9999.
/// 1px border, soft tinted background, per badges.md.
class CBadge extends StatelessWidget {
  const CBadge({
    super.key,
    required this.label,
    this.variant = CBadgeVariant.neutral,
    this.icon,
    this.pill = false,
  });

  final String label;
  final CBadgeVariant variant;
  final IconData? icon;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final (Color bg, Color border, Color fg) = _colors(dark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
            pill ? AppTheme.radiusFull : AppTheme.radiusMD),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTheme.labelThemed(context)
                .copyWith(color: fg, fontSize: 12, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color) _colors(bool dark) {
    switch (variant) {
      case CBadgeVariant.brand:
        return (
          AppTheme.primary.withValues(alpha: dark ? 0.16 : 0.10),
          AppTheme.primary.withValues(alpha: 0.35),
          dark ? AppTheme.primaryLight : AppTheme.primaryDark,
        );
      case CBadgeVariant.success:
        return (
          AppTheme.win.withValues(alpha: dark ? 0.16 : 0.12),
          AppTheme.win.withValues(alpha: 0.35),
          AppTheme.win,
        );
      case CBadgeVariant.danger:
        return (
          AppTheme.loss.withValues(alpha: dark ? 0.16 : 0.12),
          AppTheme.loss.withValues(alpha: 0.35),
          AppTheme.loss,
        );
      case CBadgeVariant.warning:
        return (
          AppTheme.warning.withValues(alpha: dark ? 0.16 : 0.12),
          AppTheme.warning.withValues(alpha: 0.35),
          AppTheme.warning,
        );
      case CBadgeVariant.neutral:
        return (
          dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.10),
          dark ? AppTheme.textSecondary : AppTheme.textSecondaryLight,
        );
    }
  }
}

/// Compact W/L result badge for fixtures-style rows.
class CResultBadge extends StatelessWidget {
  const CResultBadge({super.key, required this.isWin});

  final bool isWin;

  @override
  Widget build(BuildContext context) {
    final color = isWin ? AppTheme.win : AppTheme.loss;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isWin ? 'W' : 'L',
        style: AppTheme.label
            .copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

/// Labelled statistic block: small tracked label above a large value.
class CStatBlock extends StatelessWidget {
  const CStatBlock({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueSize = 40,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.labelThemed(context).copyWith(
            color: AppTheme.textMutedColor(context),
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.statMediumThemed(context).copyWith(
            fontSize: valueSize,
            height: 1.0,
            color: valueColor ?? AppTheme.textPrimaryColor(context),
          ),
        ),
      ],
    );
  }
}

/// Empty-state block: eyebrow + title + message + optional action button.
class CEmptyState extends StatelessWidget {
  const CEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.eyebrow,
    this.icon,
    this.action,
  });

  final String title;
  final String message;
  final String? eyebrow;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return TGCard(
      padding: AppTheme.cardPaddingLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.primary, size: 28),
            const SizedBox(height: AppTheme.spaceSM),
          ],
          if (eyebrow != null) ...[
            CEyebrow(eyebrow!),
            const SizedBox(height: AppTheme.spaceSM),
          ],
          Text(title, style: AppTheme.headingMediumThemed(context)),
          const SizedBox(height: AppTheme.spaceXS),
          Text(message, style: AppTheme.bodyMediumThemed(context)),
          if (action != null) ...[
            const SizedBox(height: AppTheme.spaceLG),
            action!,
          ],
        ],
      ),
    );
  }
}
