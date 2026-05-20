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
import '../../../core/widgets/ant_stat_tile.dart';
import '../../../data/local/curriculum_loader.dart';
import '../../../data/repositories/study_repository.dart';

final _statsSubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final majorId = prefs.getString(AppConstants.keyMajorId);
  final year = prefs.getInt(AppConstants.keyYear);
  final semester = prefs.getInt(AppConstants.keySemester);
  if (majorId == null || year == null || semester == null) return [];
  final curriculum = await CurriculumLoader().load();
  return curriculum.getSubjects(majorId, year, semester);
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(_statsSubjectsProvider);
    final studyRepo = ref.watch(studyRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.paddingAllXl,
                child: Text(
                  'Complete your profile to see statistics.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          // Count quizzes
          int totalQuizzes = 0;
          for (final s in subjects) {
            totalQuizzes += studyRepo.getQuizzes(s.id).length;
          }

          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick stats row
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: AntCard(
                          elevation: AntCardElevation.soft,
                          child: AntStatTile(
                            label: 'Subjects',
                            value: '${subjects.length}',
                            icon: PhosphorIconsBold.books,
                            iconColor: AppColors.primary,
                            subtitle: 'this semester',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AntCard(
                          elevation: AntCardElevation.soft,
                          child: AntStatTile(
                            label: 'Quizzes',
                            value: '$totalQuizzes',
                            icon: PhosphorIconsBold.exam,
                            iconColor: AppColors.secondary,
                            subtitle: 'created',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AntCard(
                          elevation: AntCardElevation.soft,
                          child: AntStatTile(
                            label: 'Total Topics',
                            value: '${subjects.fold<int>(0, (sum, s) => sum + s.topics.length)}',
                            icon: PhosphorIconsBold.listBullets,
                            iconColor: AppColors.tertiary,
                            subtitle: 'across all',
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),
                const SizedBox(height: AppSpacing.xl),

                // Subject overview
                const AntSectionHeader(title: 'Subject Overview'),
                const SizedBox(height: AppSpacing.xs),
                ...subjects.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subject = entry.value;
                  final quizCount = studyRepo.getQuizzes(subject.id).length;

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
                            child: Center(
                              child: Text(
                                subject.code.replaceAll(RegExp(r'[A-Z]+'), ''),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subject.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500)),
                                Text(
                                  '${subject.topics.length} topics \u2022 ${subject.credits} cr \u2022 $quizCount quizzes',
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
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 200 + index * 60),
                        duration: 400.ms,
                      )
                      .slideY(begin: 0.05, end: 0);
                }),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }
}
