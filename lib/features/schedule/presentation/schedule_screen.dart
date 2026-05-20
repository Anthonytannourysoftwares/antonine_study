import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../data/local/curriculum_loader.dart';

final _scheduleSubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final majorId = prefs.getString(AppConstants.keyMajorId);
  final year = prefs.getInt(AppConstants.keyYear);
  final semester = prefs.getInt(AppConstants.keySemester);
  if (majorId == null || year == null || semester == null) return [];
  final curriculum = await CurriculumLoader().load();
  return curriculum.getSubjects(majorId, year, semester);
});

// Persisted study budget preference
final _studyBudgetProvider = StateProvider<int>((ref) => 60);

class _PlanItem {
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String topic;
  final int estimatedMinutes;

  const _PlanItem({
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.topic,
    required this.estimatedMinutes,
  });
}

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  List<_PlanItem> _buildSmartPlan(
    List<Subject> subjects,
    int budgetMinutes,
  ) {
    final allItems = <_PlanItem>[];

    for (final subject in subjects) {
      for (final topic in subject.topics) {
        allItems.add(_PlanItem(
          subjectId: subject.id,
          subjectCode: subject.code,
          subjectName: subject.name,
          topic: topic,
          estimatedMinutes: 15,
        ));
      }
    }

    // Pick items: spread across subjects, fit within budget
    final picked = <_PlanItem>[];
    final subjectCount = <String, int>{};
    var usedMinutes = 0;
    final maxPerSubject = 2;

    for (final item in allItems) {
      if (usedMinutes >= budgetMinutes) break;
      final count = subjectCount[item.subjectId] ?? 0;
      if (count >= maxPerSubject) continue;
      if (usedMinutes + item.estimatedMinutes > budgetMinutes + 5) continue;

      picked.add(item);
      subjectCount[item.subjectId] = count + 1;
      usedMinutes += item.estimatedMinutes;
    }

    // If still under budget, allow more from same subjects
    if (usedMinutes < budgetMinutes - 10) {
      for (final item in allItems) {
        if (usedMinutes >= budgetMinutes) break;
        if (picked.contains(item)) continue;
        if (usedMinutes + item.estimatedMinutes > budgetMinutes + 5) continue;
        picked.add(item);
        usedMinutes += item.estimatedMinutes;
      }
    }

    return picked;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(_scheduleSubjectsProvider);
    final budget = ref.watch(_studyBudgetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Study Plan')),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.paddingAllXl,
                child: Text(
                  'Complete your profile to see your study plan.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          final todayPlan = _buildSmartPlan(subjects, budget);
          final totalMinutes =
              todayPlan.fold<int>(0, (sum, i) => sum + i.estimatedMinutes);

          // Group by subject for visual clarity
          final grouped = <String, List<_PlanItem>>{};
          for (final item in todayPlan) {
            grouped.putIfAbsent(item.subjectCode, () => []).add(item);
          }

          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time budget selector
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
                            PhosphorIconsBold.calendarCheck,
                            size: 24,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              "Today's Study Plan",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            '~$totalMinutes min',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'How much time do you have?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [30, 45, 60, 90, 120].map((m) {
                          final selected = m == budget;
                          return ChoiceChip(
                            label: Text(
                              m < 60 ? '${m}m' : '${m ~/ 60}h${m % 60 > 0 ? "${m % 60}m" : ""}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: selected,
                            onSelected: (_) =>
                                ref.read(_studyBudgetProvider.notifier).state = m,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),
                const SizedBox(height: AppSpacing.xl),

                // Grouped plan
                ...grouped.entries.toList().asMap().entries.map((groupEntry) {
                  final groupIndex = groupEntry.key;
                  final subjectCode = groupEntry.value.key;
                  final items = groupEntry.value.value;
                  final subjectMinutes =
                      items.fold<int>(0, (s, i) => s + i.estimatedMinutes);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              subjectCode,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${subjectMinutes}min',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...items.asMap().entries.map((itemEntry) {
                        final itemIndex = itemEntry.key;
                        final item = itemEntry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: AntCard(
                            elevation: AntCardElevation.soft,
                            onTap: () =>
                                context.push('/subject/${item.subjectId}'),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.topic,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.estimatedMinutes} min',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.estimatedMinutes}m',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                              delay: Duration(
                                  milliseconds:
                                      100 + groupIndex * 80 + itemIndex * 40),
                              duration: 400.ms,
                            )
                            .slideX(begin: 0.03, end: 0);
                      }),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  );
                }),

                // Tip
                const SizedBox(height: AppSpacing.md),
                AntCard(
                  elevation: AntCardElevation.flat,
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.lightbulb,
                        size: 18,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Sessions are spread across subjects to avoid burnout.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }
}
