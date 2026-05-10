import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AntStatTile extends StatelessWidget {
  const AntStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: iconColor ?? theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          value,
          style: AppTypography.monoStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}
