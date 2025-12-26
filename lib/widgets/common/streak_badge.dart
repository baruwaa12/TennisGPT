import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// A badge displaying the current streak
class StreakBadge extends StatelessWidget {
  final int streakCount;
  final String streakType; // 'day' or 'win'
  final bool isCompact;

  const StreakBadge({
    super.key,
    required this.streakCount,
    this.streakType = 'day',
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (streakCount <= 0) {
      return const SizedBox.shrink();
    }

    final color = _getStreakColor();
    final label = _getStreakLabel();

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getEmoji(),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$streakCount',
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getEmoji(),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streakCount $label Streak',
                style: AppTypography.streak.copyWith(color: color),
              ),
              Text(
                _getEncouragement(),
                style: AppTypography.bodySmall.copyWith(
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStreakColor() {
    if (streakCount >= 30) return AppColors.streakGold;
    if (streakCount >= 7) return AppColors.streakFire;
    return AppColors.primary;
  }

  String _getStreakLabel() {
    return streakType == 'day' ? 'Day' : 'Win';
  }

  String _getEmoji() {
    if (streakCount >= 30) return '🏆';
    if (streakCount >= 14) return '🔥';
    if (streakCount >= 7) return '⚡';
    if (streakCount >= 3) return '💪';
    return '✨';
  }

  String _getEncouragement() {
    if (streakCount >= 30) return 'Legendary!';
    if (streakCount >= 14) return 'On fire!';
    if (streakCount >= 7) return 'Keep it up!';
    if (streakCount >= 3) return 'Building momentum';
    return 'Getting started';
  }
}

/// A smaller inline streak indicator
class StreakIndicator extends StatelessWidget {
  final int count;
  final String type;

  const StreakIndicator({
    super.key,
    required this.count,
    this.type = 'day',
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return Text(
        'Start your streak!',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textMuted,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count >= 7 ? '🔥' : '⚡',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$count ${type == 'day' ? 'day' : 'win'} streak',
          style: AppTypography.labelMedium.copyWith(
            color: count >= 7 ? AppColors.streakFire : AppColors.primary,
          ),
        ),
      ],
    );
  }
}
