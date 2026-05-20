import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/routing/app_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.schedule)) return 1;
    if (location.startsWith(AppRoutes.aiHelper)) return 2;
    if (location.startsWith(AppRoutes.stats)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.schedule);
            case 2:
              context.go(AppRoutes.aiHelper);
            case 3:
              context.go(AppRoutes.stats);
            case 4:
              context.go(AppRoutes.settings);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.house),
            selectedIcon: Icon(PhosphorIconsBold.house),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.calendarCheck),
            selectedIcon: Icon(PhosphorIconsBold.calendarCheck),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.brain),
            selectedIcon: Icon(PhosphorIconsBold.brain),
            label: 'AI Helper',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.chartBar),
            selectedIcon: Icon(PhosphorIconsBold.chartBar),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.gear),
            selectedIcon: Icon(PhosphorIconsBold.gear),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
