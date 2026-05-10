import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class AntChip extends StatelessWidget {
  const AntChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.selectedColor,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = selectedColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? effectiveColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: AppRadius.borderRadiusPill,
          border: Border.all(
            color: selected ? effectiveColor : theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected
                    ? effectiveColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? effectiveColor
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
