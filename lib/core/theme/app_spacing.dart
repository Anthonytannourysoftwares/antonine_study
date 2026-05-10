import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double xxxxl = 64;

  // Padding helpers
  static const EdgeInsets paddingAllXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);

  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl =
      EdgeInsets.symmetric(horizontal: xl);

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: md,
  );
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderRadiusXl =
      BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderRadiusPill =
      BorderRadius.all(Radius.circular(pill));
}

abstract final class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          blurRadius: 24,
          color: Colors.black.withValues(alpha: 0.06),
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          blurRadius: 16,
          color: Colors.black.withValues(alpha: 0.08),
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get subtle => [
        BoxShadow(
          blurRadius: 8,
          color: Colors.black.withValues(alpha: 0.04),
          offset: const Offset(0, 2),
        ),
      ];
}
