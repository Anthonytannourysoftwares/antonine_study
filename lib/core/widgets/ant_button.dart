import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

enum AntButtonVariant { filled, tonal, outlined, text }
enum AntButtonSize { small, medium, large }

class AntButton extends StatelessWidget {
  const AntButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AntButtonVariant.filled,
    this.size = AntButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AntButtonVariant variant;
  final AntButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  EdgeInsetsGeometry get _padding {
    switch (size) {
      case AntButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        );
      case AntButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        );
      case AntButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        );
    }
  }

  double get _fontSize {
    switch (size) {
      case AntButtonSize.small:
        return 12;
      case AntButtonSize.medium:
        return 14;
      case AntButtonSize.large:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = isLoading ? null : onPressed;

    final child = isLoading
        ? SizedBox(
            width: _fontSize + 4,
            height: _fontSize + 4,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AntButtonVariant.filled
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _fontSize + 4),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label),
            ],
          );

    final style = ButtonStyle(
      padding: WidgetStatePropertyAll(_padding),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
      ),
      minimumSize: expand
          ? const WidgetStatePropertyAll(Size(double.infinity, 0))
          : null,
    );

    switch (variant) {
      case AntButtonVariant.filled:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: style.copyWith(
            backgroundColor:
                WidgetStatePropertyAll(theme.colorScheme.primary),
            foregroundColor:
                WidgetStatePropertyAll(theme.colorScheme.onPrimary),
            elevation: const WidgetStatePropertyAll(0),
          ),
          child: child,
        );
      case AntButtonVariant.tonal:
        return FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: style,
          child: child,
        );
      case AntButtonVariant.outlined:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: style,
          child: child,
        );
      case AntButtonVariant.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: style,
          child: child,
        );
    }
  }
}
