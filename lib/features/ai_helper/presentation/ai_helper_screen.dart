import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../core/widgets/ant_section_header.dart';
import '../../../data/local/curriculum_loader.dart';
import '../../../data/repositories/study_repository.dart';

final _subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final majorId = prefs.getString(AppConstants.keyMajorId) ?? 'ce';
  final year = prefs.getInt(AppConstants.keyYear) ?? 1;
  final semester = prefs.getInt(AppConstants.keySemester) ?? 1;
  final curriculum = await CurriculumLoader().load();
  return curriculum.getSubjects(majorId, year, semester);
});

class AiHelperScreen extends ConsumerWidget {
  const AiHelperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(_subjectsProvider);
    final studyRepo = ref.watch(studyRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: subjectsAsync.when(
          data: (subjects) => SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Your study assistant',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${subjects.length} subjects this semester',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  height: 2,
                  width: 60,
                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ).animate().scaleX(
                      begin: 0,
                      end: 1,
                      alignment: Alignment.centerLeft,
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: AppSpacing.xxl),

                // Subject Overview
                const AntSectionHeader(title: 'Your Subjects'),
                const SizedBox(height: AppSpacing.xs),
                ...subjects.asMap().entries.map((entry) {
                  final index = entry.key;
                  final s = entry.value;
                  final quizCount = studyRepo.getQuizzes(s.id).length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AntCard(
                      elevation: AntCardElevation.soft,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(PhosphorIconsBold.book,
                                size: 22, color: AppColors.primary),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500)),
                                Text(
                                  '${s.code} \u2022 ${s.topics.length} topics \u2022 $quizCount quizzes',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 100 + index * 60),
                        duration: 400.ms,
                      );
                }),
                const SizedBox(height: AppSpacing.xxl),

                // Study Tips
                const AntSectionHeader(title: 'Study Tips'),
                const SizedBox(height: AppSpacing.xs),
                ..._tips.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tip = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AntCard(
                      elevation: AntCardElevation.soft,
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.lightbulb,
                              size: 18, color: AppColors.gold),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(tip, style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 400 + index * 80),
                        duration: 400.ms,
                      );
                }),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  static const _tips = [
    'Create quizzes for each chapter to test your understanding.',
    'Review your flashcards from Course Materials regularly.',
    'Use the Video Summarizer to quickly grasp lecture content.',
    'Spread your study sessions across subjects to avoid burnout.',
    'Take breaks every 25-45 minutes for better retention.',
  ];
}
