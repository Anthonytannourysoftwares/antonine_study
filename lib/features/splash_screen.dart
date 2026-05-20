import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_state_provider.dart';
import 'id_gate/id_gate_controller.dart';

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

    // If user is past setup, check the daily ID gate
    if (destination == AppState.home) {
      await ref.read(idGateControllerProvider.notifier).checkGate();
      if (!mounted) return;
      final gateState = ref.read(idGateControllerProvider);
      if (gateState == IdGateState.expired) {
        context.go(AppRoutes.idGate);
        return;
      }
    }

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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO(user): drop the real logo at assets/images/logo_antonine.png
            // and assets/images/logo_antonine_mono.png for app bars
            Image.asset(
              'assets/images/ua_logo.png',
              width: 260,
            )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic)
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
            const SizedBox(height: 24),
            Text(
              'Study',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 4,
                  ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}
