import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_state_provider.dart';
import '../../../core/widgets/ant_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: PhosphorIconsBold.graduationCap,
      title: 'Built for Antonine Students',
      body:
          'Your personal study companion, designed specifically for the Antonine University curriculum and academic experience.',
      color: AppColors.primary,
    ),
    _OnboardingPage(
      icon: PhosphorIconsBold.shieldCheck,
      title: 'On-Device AI, Your Data Stays Private',
      body:
          'All intelligence runs locally on your device. No cloud processing, no data sharing. Your study habits are yours alone.',
      color: AppColors.tertiary,
    ),
    _OnboardingPage(
      icon: PhosphorIconsBold.chartLineUp,
      title: 'Track Mastery, Not Just Hours',
      body:
          'Smart algorithms adapt to your learning style, identify weak spots, and guide you to focus where it matters most.',
      color: AppColors.secondary,
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(appStateProvider.notifier).completeOnboarding();
    context.go(AppRoutes.idVerification);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
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
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: AppSpacing.paddingHorizontalXl,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 56,
                            color: page.color,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.body,
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

            // Page indicator + button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxs,
                        ),
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

class _OnboardingPage {
  const _OnboardingPage({
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
