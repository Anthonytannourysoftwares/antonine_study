import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

enum AntCardElevation { flat, soft, medium }

class AntCard extends StatelessWidget {
  const AntCard({
    super.key,
    required this.child,
    this.elevation = AntCardElevation.soft,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.color,
    this.border,
  });

  final Widget child;
  final AntCardElevation elevation;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final Border? border;

  List<BoxShadow> _shadows() {
    switch (elevation) {
      case AntCardElevation.flat:
        return [];
      case AntCardElevation.soft:
        return AppShadows.subtle;
      case AntCardElevation.medium:
        return AppShadows.soft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.surfaceContainerLowest;
    final effectiveRadius = borderRadius ?? AppRadius.borderRadiusLg;

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: padding ?? AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: _shadows(),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              effectiveRadius is BorderRadius ? effectiveRadius : null,
          child: container,
        ),
      );
    }

    return container;
  }
}
