import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../core/widgets/ant_section_header.dart';
import '../../../core/widgets/ant_stat_tile.dart';
import '../../../data/local/curriculum_loader.dart';
import '../../../data/repositories/study_repository.dart';
import '../../study/domain/grade_forecaster.dart';

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

          final streak = studyRepo.getStreak();
          final masteries =
              subjects.map((s) => studyRepo.getMastery(s.id)).toList();
          final avgMastery = masteries.isEmpty
              ? 0.0
              : masteries.reduce((a, b) => a + b) / masteries.length;
          const forecaster = GradeForecaster();
          final passProbability =
              forecaster.predictPassProbability(avgMastery, 0.5, avgMastery);

          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick stats row
                Row(
                  children: [
                    Expanded(
                      child: AntCard(
                        elevation: AntCardElevation.soft,
                        child: AntStatTile(
                          label: 'Current Streak',
                          value: '$streak',
                          icon: PhosphorIconsBold.flame,
                          iconColor: AppColors.secondary,
                          subtitle: streak > 0 ? 'days' : 'Start today!',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AntCard(
                        elevation: AntCardElevation.soft,
                        child: AntStatTile(
                          label: 'Avg Mastery',
                          value: '${(avgMastery * 100).round()}%',
                          icon: PhosphorIconsBold.brain,
                          iconColor: AppColors.tertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AntCard(
                        elevation: AntCardElevation.soft,
                        child: AntStatTile(
                          label: 'Forecast',
                          value: forecaster.gradeLabel(passProbability),
                          icon: PhosphorIconsBold.trendUp,
                          iconColor: AppColors.primary,
                          subtitle:
                              '${(passProbability * 100).round()}% pass',
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),
                const SizedBox(height: AppSpacing.xl),

                // Mastery by subject bar chart
                const AntSectionHeader(title: 'Mastery by Subject'),
                AntCard(
                  elevation: AntCardElevation.soft,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${subjects[groupIndex].code}\n${rod.toY.round()}%',
                                theme.textTheme.labelSmall!,
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= subjects.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(top: AppSpacing.xs),
                                  child: Text(
                                    subjects[value.toInt()]
                                        .code
                                        .replaceAll(RegExp(r'[A-Z]+'), ''),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(fontSize: 9),
                                  ),
                                );
                              },
                              reservedSize: 24,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 25,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: AppTypography.monoStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        barGroups:
                            subjects.asMap().entries.map((entry) {
                          final mastery =
                              studyRepo.getMastery(entry.value.id);
                          final color = mastery >= 0.8
                              ? AppColors.tertiary
                              : mastery >= 0.5
                                  ? AppColors.secondary
                                  : AppColors.error;
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: mastery * 100,
                                color: color,
                                width: 16,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),
                const SizedBox(height: AppSpacing.xl),

                // Topic mastery heatmap-style list
                const AntSectionHeader(title: 'Topic Breakdown'),
                ...subjects.expand((subject) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xxs,
                      ),
                      child: Text(
                        subject.code,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...subject.topics.map((topic) {
                      final topicMastery =
                          studyRepo.getTopicMastery(subject.id, topic);
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.xxs),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                topic,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: topicMastery,
                                  backgroundColor: theme
                                      .colorScheme.outlineVariant
                                      .withValues(alpha: 0.2),
                                  color: topicMastery >= 0.8
                                      ? AppColors.tertiary
                                      : topicMastery >= 0.5
                                          ? AppColors.secondary
                                          : AppColors.error
                                              .withValues(alpha: 0.7),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${(topicMastery * 100).round()}%',
                                style: AppTypography.monoStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ];
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
