import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../guide/presentation/walkthrough_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          _HelpSection(
            icon: PhosphorIconsBold.play,
            title: 'Getting Started',
            body: 'New to Antonine Study? Re-run the welcome walkthrough to learn the basics.',
            action: 'Re-run Walkthrough',
            onAction: () async {
              await WalkthroughScreen.reset();
              if (context.mounted) context.go(AppRoutes.walkthrough);
            },
          ),
          _HelpSection(
            icon: PhosphorIconsBold.identificationCard,
            title: 'How ID Verification Works',
            body:
                'Every day, the app asks you to scan your Antonine University student ID. '
                'This ensures only current students can access their study data.\n\n'
                'Your ID image is never stored — it is processed on-device using OCR '
                '(Optical Character Recognition) and a TFLite classifier, then immediately deleted. '
                'Only a hashed version of your student number is kept for identity continuity.\n\n'
                'The daily re-verification protects against lost or shared devices.',
          ),
          _HelpSection(
            icon: PhosphorIconsBold.book,
            title: 'How to Enroll in Courses',
            body:
                '1. Go to the Enrollment screen from the home page.\n'
                '2. Select your semester.\n'
                '3. Browse available courses for your major and year.\n'
                '4. Tap "Add" on a course, then choose a section (professor + timeslot).\n'
                '5. Review your selection and confirm.\n\n'
                'The app enforces a credit cap (18 max), prerequisite checks, '
                'and time-conflict detection to keep your schedule valid.',
          ),
          _HelpSection(
            icon: PhosphorIconsBold.calendarCheck,
            title: 'How to Build a Schedule',
            body:
                'Your schedule is auto-generated from your enrolled courses and selected sections. '
                'Each section comes with fixed days, times, and rooms.\n\n'
                'To change your schedule, swap a section in the Dr Selection screen — '
                'your timetable updates automatically.\n\n'
                'You can export your schedule as a PDF or .ics calendar file via the share icon.',
          ),
          _HelpSection(
            icon: PhosphorIconsBold.brain,
            title: 'How the AI Study Helper Works',
            body:
                'The AI Study Helper consolidates seven on-device machine learning algorithms:\n\n'
                '• SM-2 (Spaced Repetition) — schedules flashcard reviews at optimal intervals '
                'based on how well you remember each card.\n\n'
                '• BKT (Bayesian Knowledge Tracing) — estimates the probability that you\'ve '
                'mastered each concept, using your quiz history.\n\n'
                '• IRT (Item Response Theory) — adapts quiz difficulty to your current ability '
                'level using a Rasch model.\n\n'
                '• Weakness Detector — scores topics by combining mastery level and recency '
                'to identify where to focus.\n\n'
                '• Grade Forecaster — uses logistic regression on your mastery, consistency, '
                'and accuracy to predict pass probability.\n\n'
                '• Recommender (Item-based KNN) — suggests topics based on patterns from '
                'similar study profiles.\n\n'
                '• Time Predictor — estimates study time needed using a linear model.\n\n'
                'All processing runs locally on your device. No data leaves your phone.',
          ),
          _HelpSection(
            icon: PhosphorIconsBold.question,
            title: 'FAQ',
            body:
                'Q: Does the app send my data anywhere?\n'
                'A: No. All ML runs on-device. The only network calls are to the local '
                'backend for course/enrollment data.\n\n'
                'Q: Why do I need to scan my ID every day?\n'
                'A: Daily verification ensures account security on shared or lost devices.\n\n'
                'Q: What if my ID scan keeps failing?\n'
                'A: Make sure your card is well-lit and flat. After 3 failures, a 5-minute '
                'cooldown activates. You can also use manual entry.\n\n'
                'Q: Can I change my major or year after setup?\n'
                'A: Yes — go to Settings > Edit Profile to update your academic info.\n\n'
                'Q: How accurate is the grade forecast?\n'
                'A: The forecast improves with usage. It needs 4+ weeks of study data to '
                'become meaningful.\n\n'
                'Q: Can I use this offline?\n'
                'A: Study features (flashcards, quizzes, stats) work offline. Enrollment '
                'and section selection require the backend.',
          ),
          _HelpSection(
            icon: PhosphorIconsBold.envelope,
            title: 'Contact Support',
            body:
                'Having issues? Reach out to the development team.\n\n'
                // TODO(user): set support email
                'Email: support@antonine-study.app',
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppColors.gold),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          // TODO(user): add screenshots as inline images here
          if (action != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              child: Text(action!),
            ),
          ],
          const Divider(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
