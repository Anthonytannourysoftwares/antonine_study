import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/theme_provider.dart';
import 'features/id_gate/id_gate_controller.dart';

class AntonineStudyApp extends ConsumerStatefulWidget {
  const AntonineStudyApp({super.key});

  @override
  ConsumerState<AntonineStudyApp> createState() => _AntonineStudyAppState();
}

class _AntonineStudyAppState extends ConsumerState<AntonineStudyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check ID gate on resume from background
      ref.read(idGateControllerProvider.notifier).checkGate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Watch gate state — when it expires, redirect to gate screen
    final gateState = ref.watch(idGateControllerProvider);
    if (gateState == IdGateState.expired) {
      // Schedule navigation after frame to avoid build-time navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentLocation =
            appRouter.routerDelegate.currentConfiguration.uri.path;
        // Only redirect if user is past the initial setup flow
        const setupRoutes = ['/', '/onboarding', '/id-verification', '/profile-setup', '/id-gate'];
        if (!setupRoutes.contains(currentLocation)) {
          appRouter.go(AppRoutes.idGate);
        }
      });
    }

    return MaterialApp.router(
      title: 'Antonine University',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
