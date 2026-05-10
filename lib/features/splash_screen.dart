import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_state_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    final appState = ref.read(appStateProvider.notifier);
    final destination = await appState.determineInitialRoute();

    if (!mounted) return;

    final route = switch (destination) {
      AppState.onboarding => AppRoutes.onboarding,
      AppState.idVerification => AppRoutes.idVerification,
      AppState.profileSetup => AppRoutes.profileSetup,
      AppState.home => AppRoutes.home,
      AppState.splash => AppRoutes.onboarding,
    };

    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Antonine',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 4),
            Text(
              'Study',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 4,
                  ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 400.ms)
                .scaleX(begin: 0, end: 1, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}
