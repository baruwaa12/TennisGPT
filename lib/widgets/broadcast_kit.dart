import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/broadcast_theme.dart';

/// ============================================================
/// Broadcast Kit — shared components for the Broadcast visual
/// language (TV-graphics canvas, electric-lime accent, mono
/// scorelines, uppercase labels).
///
/// Every interactive component here has a real pressed state
/// (scale + brighten), haptics, Semantics, and a ≥44px target.
/// ============================================================

/// Primary lime CTA. Press-to-brighten + subtle scale, loading state.
class BroadcastCta extends StatefulWidget {
  const BroadcastCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;

  @override
  State<BroadcastCta> createState() => _BroadcastCtaState();
}

class _BroadcastCtaState extends State<BroadcastCta> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    const accent = BroadcastTheme.accentFill;
    final fill = _down ? accent.withValues(alpha: 0.10) : Colors.transparent;
    final borderColor = _down
        ? Color.lerp(accent, Colors.white, 0.25)!
        : accent;

    final body = AnimatedScale(
      scale: _down ? 0.98 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.loading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
            ] else if (widget.icon != null) ...[
              Icon(widget.icon, color: accent, size: 20),
              const SizedBox(width: AppTheme.spaceSM),
            ],
            Text(
              widget.loading ? (widget.loadingLabel ?? widget.label) : widget.label,
              style: AppTheme.headingSmall.copyWith(
                color: accent,
                fontSize: 15,
                letterSpacing: 1.2,
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

/// Panel with the signature accent rule down the left edge.
/// When [onTap] is set, the whole panel presses (brighten + scale).
class BroadcastPanel extends StatefulWidget {
  const BroadcastPanel({
    super.key,
    required this.bc,
    required this.child,
    this.onTap,
    this.raised = false,
    this.accentRule = false,
    this.padding,
    this.semanticLabel,
  });

  final BroadcastTheme bc;
  final Widget child;
  final VoidCallback? onTap;
  final bool raised;
  final bool accentRule;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  @override
  State<BroadcastPanel> createState() => _BroadcastPanelState();
}

class _BroadcastPanelState extends State<BroadcastPanel> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final bc = widget.bc;
    final base = widget.raised ? bc.panelRaised : bc.panel;
    final fill = _down
        ? Color.lerp(base, bc.dark ? Colors.white : Colors.black,
            bc.dark ? 0.06 : 0.03)!
        : base;

    final panel = AnimatedScale(
      scale: _down ? 0.99 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: widget.padding ?? const EdgeInsets.all(AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: bc.panelShadow,
          border: widget.accentRule
              ? Border(
                  left: BorderSide(color: bc.accentInk, width: 3),
                  top: BorderSide(color: bc.border),
                  right: BorderSide(color: bc.border),
                  bottom: BorderSide(color: bc.border),
                )
              : Border.all(color: bc.border),
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) {
      return Semantics(label: widget.semanticLabel, child: panel);
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
        child: panel,
      ),
    );
  }
}

/// Uppercase section label with an optional trailing text action.
/// The action gets a proper ≥44px tap target.
class BroadcastSectionHeader extends StatelessWidget {
  const BroadcastSectionHeader({
    super.key,
    required this.bc,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final BroadcastTheme bc;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppTheme.labelThemed(context)
                  .copyWith(letterSpacing: 2, color: bc.textMuted),
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
                      const BoxConstraints(minHeight: 36, minWidth: 44),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSM),
                  alignment: Alignment.centerRight,
                  child: Text(
                    actionLabel!.toUpperCase(),
                    style: AppTheme.labelThemed(context)
                        .copyWith(color: bc.accentInk, letterSpacing: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Monospace scoreline with lost sets dimmed — "6-4 3-6 7-5" reads like a
/// scoreboard and the eye lands on the sets you won.
class BroadcastScoreline extends StatelessWidget {
  const BroadcastScoreline({
    super.key,
    required this.bc,
    required this.raw,
    this.size = 17,
  });

  final BroadcastTheme bc;
  final String raw;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sets = raw.trim().isEmpty
        ? const <String>[]
        : raw.trim().split(RegExp(r'\s+'));
    if (sets.isEmpty) {
      return Text('—',
          style: AppTheme.scorelineThemed(context, size: size)
              .copyWith(color: bc.textPrimary));
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < sets.length; i++)
          Padding(
            padding:
                EdgeInsets.only(right: i == sets.length - 1 ? 0 : size * 0.32),
            child: Text(
              sets[i],
              style: AppTheme.scorelineThemed(context, size: size).copyWith(
                color: _wonSet(sets[i])
                    ? bc.textPrimary
                    : bc.textMuted.withValues(alpha: 0.75),
              ),
            ),
          ),
      ],
    );
  }

  bool _wonSet(String token) {
    final clean = token.replaceAll(RegExp(r'\(.*?\)'), '');
    final parts = clean.split('-');
    if (parts.length < 2) return true;
    final me = int.tryParse(parts[0].trim()) ?? 0;
    final opp = int.tryParse(parts[1].trim()) ?? 0;
    return me >= opp;
  }
}

/// Compact W/L result badge used in fixtures-style rows.
class BroadcastResultBadge extends StatelessWidget {
  const BroadcastResultBadge({super.key, required this.bc, required this.isWin});

  final BroadcastTheme bc;
  final bool isWin;

  @override
  Widget build(BuildContext context) {
    final color = isWin ? bc.win : bc.loss;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isWin ? 'W' : 'L',
        style: AppTheme.label
            .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}
