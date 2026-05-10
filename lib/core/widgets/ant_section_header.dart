import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class AntSectionHeader extends StatelessWidget {
  const AntSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.actionLabel,
    this.onAction,
    this.padding,
  });

  final String title;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          if (action != null)
            action!
          else if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
