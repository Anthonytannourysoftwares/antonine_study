import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary — deep academic navy
  static const primary = Color(0xFF1E3A5F);
  static const primaryContainer = Color(0xFFD1DFEE);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF0A1929);

  // Secondary — muted gold accent
  static const secondary = Color(0xFFB8860B);
  static const secondaryContainer = Color(0xFFFFF0C8);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF3D2D04);

  // Tertiary (success/progress green)
  static const tertiary = Color(0xFF5B8C5A);
  static const tertiaryContainer = Color(0xFFE2F0E1);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF1A3019);

  // Error
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFF9DEDC);
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF410E0B);

  // Surfaces (light)
  static const surface = Color(0xFFFAFAF7);
  static const surfaceDim = Color(0xFFF2F1EC);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF7F6F1);
  static const surfaceContainer = Color(0xFFF2F1EC);
  static const surfaceContainerHigh = Color(0xFFECEBE6);
  static const surfaceContainerHighest = Color(0xFFE6E5E0);
  static const onSurface = Color(0xFF1B1C1A);
  static const onSurfaceVariant = Color(0xFF5C5F58);
  static const outline = Color(0xFF8C8F88);
  static const outlineVariant = Color(0xFFC8CBC4);

  // Dark surfaces
  static const surfaceDark = Color(0xFF0A1520);
  static const surfaceDimDark = Color(0xFF141F2B);
  static const surfaceContainerDark = Color(0xFF1A2635);
  static const surfaceContainerHighDark = Color(0xFF243040);
  static const surfaceContainerHighestDark = Color(0xFF2E3A4A);
  static const onSurfaceDark = Color(0xFFE1E5EA);
  static const onSurfaceVariantDark = Color(0xFFA4ABB5);
  static const primaryDark = Color(0xFF8EB4D9);
  static const primaryContainerDark = Color(0xFF152D4A);
  static const secondaryDark = Color(0xFFDAA520);
  static const secondaryContainerDark = Color(0xFF5C4308);
  static const outlineDark = Color(0xFF6A7280);
  static const outlineVariantDark = Color(0xFF3A4350);

  // Semantic
  static const warning = Color(0xFFE8A317);
  static const warningContainer = Color(0xFFFFF4D6);
  static const info = Color(0xFF1E3A5F);
  static const infoContainer = Color(0xFFD1DFEE);

  // Convenience aliases
  static const gold = secondary;
  static const navy = primary;
}
