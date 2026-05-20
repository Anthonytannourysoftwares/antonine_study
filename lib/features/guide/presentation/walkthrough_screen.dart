import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_button.dart';

const _hasSeenGuideKey = 'has_seen_guide';

class WalkthroughScreen extends ConsumerStatefulWidget {
  const WalkthroughScreen({super.key});

  /// Whether the guide has already been seen.
  static Future<bool> hasBeenSeen() async {
    final box = Hive.box<dynamic>('streaks');
    return box.get(_hasSeenGuideKey, defaultValue: false) as bool;
  }

  /// Mark as seen.
  static Future<void> markSeen() async {
    final box = Hive.box<dynamic>('streaks');
    await box.put(_hasSeenGuideKey, true);
  }

  /// Reset for re-run from help center.
  static Future<void> reset() async {
    final box = Hive.box<dynamic>('streaks');
    await box.put(_hasSeenGuideKey, false);
  }

  @override
  ConsumerState<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends ConsumerState<WalkthroughScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _Slide(
      icon: PhosphorIconsBold.shieldCheck,
      title: 'Scan daily. Stay secure.',
      body: 'A quick ID check each day keeps your account safe and your data private.',
      color: AppColors.gold,
    ),
    _Slide(
      icon: PhosphorIconsBold.graduationCap,
      title: 'Find your courses.',
      body: 'Browse the full Antonine CE curriculum and enroll in courses for your semester.',
      color: AppColors.primary,
    ),
    _Slide(
      icon: PhosphorIconsBold.calendarCheck,
      title: 'Build your schedule.',
      body: 'Pick your sections and professors. Your weekly timetable builds itself.',
      color: AppColors.tertiary,
    ),
    _Slide(
      icon: PhosphorIconsBold.brain,
      title: 'Meet your AI study helper.',
      body: 'Adaptive quizzes, mastery tracking, and grade forecasts — all on-device.',
      color: AppColors.secondary,
    ),
    _Slide(
      icon: PhosphorIconsBold.rocketLaunch,
      title: "You're ready.",
      body: 'Dive in and start studying smarter.',
      color: AppColors.gold,
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await WalkthroughScreen.markSeen();
    if (mounted) context.go(AppRoutes.profileSetup);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: AppSpacing.paddingHorizontalXl,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: slide.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon, size: 56, color: slide.color),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                            ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          slide.title,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          slide.body,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots + button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AntButton(
                    label: isLast ? 'Get Started' : 'Next',
                    onPressed: _next,
                    expand: true,
                    size: AntButtonSize.large,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color color;
}
