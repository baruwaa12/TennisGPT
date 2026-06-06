import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class BrandDirectionSwitcher extends StatelessWidget {
  const BrandDirectionSwitcher({
    super.key,
    this.padding,
  });

  final EdgeInsetsGeometry? padding;

  static const List<(BrandDirection, String)> _options = [
    (BrandDirection.deepBlueIntelligence, 'Deep Blue'),
    (BrandDirection.burntOrangeTactical, 'Burnt Orange'),
    (BrandDirection.copperBronzePremium, 'Copper/Bronze'),
  ];

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceSM,
            vertical: AppTheme.spaceSM,
          ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compare design direction',
            style: AppTheme.labelThemed(context),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _options.map((option) {
                final isSelected = themeService.brandDirection == option.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spaceSM),
                  child: _DirectionChip(
                    label: option.$2,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeService.setBrandDirection(option.$1);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  const _DirectionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD,
          vertical: AppTheme.spaceSM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.18)
              : AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                isSelected ? AppTheme.primary : AppTheme.borderColor(context),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.labelThemed(context).copyWith(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.textSecondaryColor(context),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
