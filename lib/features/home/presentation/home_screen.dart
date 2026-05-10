import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/theme_provider.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../core/widgets/ant_progress_ring.dart';
import '../../../core/widgets/ant_section_header.dart';
import '../../../data/local/curriculum_loader.dart';
import '../../../data/repositories/study_repository.dart';

final _studentNameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.keyStudentFirstName) ?? 'Student';
});

final _subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final majorId = prefs.getString(AppConstants.keyMajorId);
  final year = prefs.getInt(AppConstants.keyYear);
  final semester = prefs.getInt(AppConstants.keySemester);
  if (majorId == null || year == null || semester == null) return [];

  final curriculum = await CurriculumLoader().load();
  return curriculum.getSubjects(majorId, year, semester);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nameAsync = ref.watch(_studentNameProvider);
    final subjectsAsync = ref.watch(_subjectsProvider);
    final studyRepo = ref.watch(studyRepositoryProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        nameAsync.when(
                          data: (name) => Text(
                            '$greeting, $name',
                            style: theme.textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => Text(
                            greeting,
                            style: theme.textTheme.headlineSmall,
                          ),
                          error: (_, _) => Text(
                            greeting,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _formattedDate(now),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).toggle(),
                    icon: Icon(
                      theme.brightness == Brightness.dark
                          ? PhosphorIconsBold.sun
                          : PhosphorIconsBold.moon,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: AppSpacing.xl),

              // Today's Focus card
              AntCard(
                elevation: AntCardElevation.medium,
                color: theme.colorScheme.primaryContainer,
                padding: AppSpacing.paddingAllLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsBold.target,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          "Today's Focus",
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    subjectsAsync.when(
                      data: (subjects) {
                        if (subjects.isEmpty) {
                          return Text(
                            'No subjects loaded for this semester. '
                            'Check your profile settings.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          );
                        }
                        // Show top 3 weakest subjects
                        final sorted = List.of(subjects)
                          ..sort((a, b) {
                            final ma = studyRepo.getMastery(a.id);
                            final mb = studyRepo.getMastery(b.id);
                            return ma.compareTo(mb);
                          });
                        final weakest = sorted.take(3);
                        return Column(
                          children: weakest
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xxs,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        PhosphorIconsRegular.caretRight,
                                        size: 14,
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                      ),
                                      const SizedBox(width: AppSpacing.xxs),
                                      Text(
                                        s.name,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, _) => Text(
                        'Could not load subjects.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSpacing.xl),

              // Subjects grid
              const AntSectionHeader(title: 'Your Subjects'),
              const SizedBox(height: AppSpacing.xs),
              subjectsAsync.when(
                data: (subjects) => _SubjectGrid(
                  subjects: subjects,
                  studyRepo: studyRepo,
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedDate(DateTime date) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({required this.subjects, required this.studyRepo});

  final List<Subject> subjects;
  final StudyRepository studyRepo;

  String _lastStudiedLabel(String? dateStr) {
    if (dateStr == null) return 'Not started';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'Not started';
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${diff}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          'No subjects for this semester.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.1,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final mastery = studyRepo.getMastery(subject.id);
        final lastStudied = studyRepo.getLastStudied(subject.id);

        return AntCard(
          elevation: AntCardElevation.soft,
          onTap: () => context.push('/subject/${subject.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      subject.code,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AntProgressRing(
                    progress: mastery,
                    size: 40,
                    strokeWidth: 4,
                    showPercentage: true,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                subject.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _lastStudiedLabel(lastStudied),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 150 + index * 60),
              duration: 400.ms,
            )
            .slideY(begin: 0.05, end: 0);
      },
    );
  }
}
