import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary
  static const primary = Color(0xFF1E3A5F);
  static const primaryContainer = Color(0xFFE7EEF8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF0D1F33);

  // Secondary (gold accent)
  static const secondary = Color(0xFFB8860B);
  static const secondaryContainer = Color(0xFFFFF3D6);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF3D2C00);

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
  static const surfaceDark = Color(0xFF0F1419);
  static const surfaceDimDark = Color(0xFF1A1F26);
  static const surfaceContainerDark = Color(0xFF1E242B);
  static const surfaceContainerHighDark = Color(0xFF282F37);
  static const surfaceContainerHighestDark = Color(0xFF333A42);
  static const onSurfaceDark = Color(0xFFE3E2DD);
  static const onSurfaceVariantDark = Color(0xFFA8ABA4);
  static const primaryDark = Color(0xFFA8C5E8);
  static const primaryContainerDark = Color(0xFF2A4A6B);
  static const outlineDark = Color(0xFF6C6F68);
  static const outlineVariantDark = Color(0xFF44473F);

  // Semantic
  static const warning = Color(0xFFE8A317);
  static const warningContainer = Color(0xFFFFF4D6);
  static const info = Color(0xFF3B82F6);
  static const infoContainer = Color(0xFFDBEAFE);
}
