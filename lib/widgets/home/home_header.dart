import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../common/streak_badge.dart';

/// Home screen header with greeting and streak
class HomeHeader extends StatelessWidget {
  final String? userName;
  final int streakCount;
  final String streakType;
  final bool hasCheckedInToday;

  const HomeHeader({
    super.key,
    this.userName,
    required this.streakCount,
    this.streakType = 'day',
    this.hasCheckedInToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _getSubtitle(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (streakCount > 0)
              StreakBadge(
                streakCount: streakCount,
                streakType: streakType,
                isCompact: true,
              ),
          ],
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = userName ?? 'Player';

    if (hour < 12) {
      return 'Good morning${userName != null ? ', $name' : ''}';
    } else if (hour < 17) {
      return 'Good afternoon${userName != null ? ', $name' : ''}';
    } else {
      return 'Good evening${userName != null ? ', $name' : ''}';
    }
  }

  String _getSubtitle() {
    if (!hasCheckedInToday && streakCount > 0) {
      return "Don't break your streak! Check in today.";
    } else if (!hasCheckedInToday) {
      return "How are you feeling today?";
    } else if (streakCount >= 7) {
      return "You're on fire! Keep it up.";
    } else if (streakCount > 0) {
      return "Building momentum. Great progress!";
    }
    return "Ready for your next session?";
  }
}

/// Primary focus card based on user context
class PrimaryFocusCard extends StatelessWidget {
  final bool hasCheckedInToday;
  final int daysSinceLastMatch;
  final int? lastMoodRating;
  final VoidCallback onCheckIn;
  final VoidCallback onLogMatch;
  final VoidCallback onEmotionalReset;
  final VoidCallback onTacticalTip;

  const PrimaryFocusCard({
    super.key,
    required this.hasCheckedInToday,
    required this.daysSinceLastMatch,
    this.lastMoodRating,
    required this.onCheckIn,
    required this.onLogMatch,
    required this.onEmotionalReset,
    required this.onTacticalTip,
  });

  @override
  Widget build(BuildContext context) {
    final focus = _determineFocus();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            focus.color.withOpacity(0.15),
            focus.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: focus.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: focus.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'TODAY\'S FOCUS',
                  style: AppTypography.labelSmall.copyWith(
                    color: focus.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                focus.icon,
                color: focus.color,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      focus.title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      focus.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: focus.onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: focus.color,
                    foregroundColor: AppColors.textOnPrimary,
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(focus.actionLabel),
                ),
              ),
              if (focus.secondaryAction != null) ...[
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: focus.secondaryAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: focus.color,
                    side: BorderSide(color: focus.color),
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(focus.secondaryLabel ?? 'Later'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  _FocusData _determineFocus() {
    // Priority 1: Check-in if not done today
    if (!hasCheckedInToday) {
      return _FocusData(
        title: 'Mental Check-In',
        description: 'Take a moment to log how you\'re feeling.',
        icon: Icons.psychology_outlined,
        color: AppColors.info,
        actionLabel: 'Check In',
        onAction: onCheckIn,
      );
    }

    // Priority 2: Log match if none in 7+ days
    if (daysSinceLastMatch >= 7) {
      return _FocusData(
        title: 'Log Your Match',
        description: 'Track your recent match to see your progress.',
        icon: Icons.sports_tennis,
        color: AppColors.primary,
        actionLabel: 'Log Match',
        onAction: onLogMatch,
      );
    }

    // Priority 3: Emotional reset if low mood
    if (lastMoodRating != null && lastMoodRating! <= 2) {
      return _FocusData(
        title: 'Emotional Reset',
        description: 'Let\'s work through those feelings together.',
        icon: Icons.spa_outlined,
        color: AppColors.warning,
        actionLabel: 'Start Reset',
        onAction: onEmotionalReset,
        secondaryLabel: 'Skip',
        secondaryAction: onTacticalTip,
      );
    }

    // Default: Tactical tip
    return _FocusData(
      title: 'Get a Tactical Tip',
      description: 'Get AI-powered advice for your next match.',
      icon: Icons.lightbulb_outline,
      color: AppColors.success,
      actionLabel: 'Get Tip',
      onAction: onTacticalTip,
    );
  }
}

class _FocusData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? secondaryAction;

  _FocusData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.secondaryAction,
  });
}
