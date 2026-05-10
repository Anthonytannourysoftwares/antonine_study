import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/id_verification/presentation/id_verification_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/splash_screen.dart';
import '../../features/subject/presentation/subject_detail_screen.dart';
import '../../features/stats/presentation/stats_screen.dart';
import '../../features/home/presentation/main_shell.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String idVerification = '/id-verification';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String study = '/study';
  static const String stats = '/stats';
  static const String profile = '/profile';
  static const String subjectDetail = '/subject/:id';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.idVerification,
      builder: (context, state) => const IdVerificationScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.stats,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.subjectDetail,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return SubjectDetailScreen(subjectId: id);
      },
    ),
  ],
);
