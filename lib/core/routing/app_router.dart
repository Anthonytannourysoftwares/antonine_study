import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/id_verification/presentation/id_verification_screen.dart';
import '../../features/id_gate/presentation/id_gate_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/splash_screen.dart';
import '../../features/subject/presentation/subject_detail_screen.dart';
import '../../features/stats/presentation/stats_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/tools/presentation/tools_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/guide/presentation/walkthrough_screen.dart';
import '../../features/help/presentation/help_screen.dart';
import '../../features/ai_helper/presentation/ai_helper_screen.dart';
import '../../features/enrollment/presentation/enrollment_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/timetable/presentation/timetable_screen.dart';
import '../../features/professors/presentation/section_picker_screen.dart';
import '../../features/chatbot/presentation/chatbot_screen.dart';
import '../../features/lost_found/presentation/lost_found_screen.dart';
import '../../features/course_materials/presentation/course_materials_screen.dart';
import '../../features/video_summarizer/presentation/video_summarizer_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String idVerification = '/id-verification';
  static const String idGate = '/id-gate';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String stats = '/stats';
  static const String tools = '/tools';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String walkthrough = '/walkthrough';
  static const String help = '/help';
  static const String aiHelper = '/ai-helper';
  static const String enrollment = '/enrollment';
  static const String timetable = '/timetable';
  static const String chatbot = '/chatbot';
  static const String lostFound = '/lost-found';
  static const String videoSummarizer = '/video-summarizer';
  static const String courseMaterials = '/courses/:courseId/materials';
  static const String sectionPicker = '/courses/:courseId/sections';
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
      path: AppRoutes.idGate,
      builder: (context, state) => const IdGateScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.walkthrough,
      builder: (context, state) => const WalkthroughScreen(),
    ),
    GoRoute(
      path: AppRoutes.help,
      builder: (context, state) => const HelpScreen(),
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
          path: AppRoutes.schedule,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ScheduleScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.aiHelper,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AiHelperScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.stats,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.tools,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ToolsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.chatbot,
      builder: (context, state) => const ChatbotScreen(),
    ),
    GoRoute(
      path: AppRoutes.lostFound,
      builder: (context, state) => const LostFoundScreen(),
    ),
    GoRoute(
      path: AppRoutes.enrollment,
      builder: (context, state) => const EnrollmentScreen(),
    ),
    GoRoute(
      path: AppRoutes.timetable,
      builder: (context, state) => const TimetableScreen(),
    ),
    GoRoute(
      path: AppRoutes.videoSummarizer,
      builder: (context, state) => const VideoSummarizerScreen(),
    ),
    GoRoute(
      path: AppRoutes.courseMaterials,
      builder: (context, state) {
        final courseId = state.pathParameters['courseId'] ?? '';
        final courseName = state.uri.queryParameters['name'] ?? courseId;
        return CourseMaterialsScreen(
          courseId: courseId,
          courseName: courseName,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.sectionPicker,
      builder: (context, state) {
        final courseId = state.pathParameters['courseId'] ?? '';
        final courseName = state.uri.queryParameters['name'] ?? courseId;
        return SectionPickerScreen(
          courseId: courseId,
          courseName: courseName,
        );
      },
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
