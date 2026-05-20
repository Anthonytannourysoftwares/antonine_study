import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_empty_state.dart';
import '../../../data/repositories/enrollment_repository.dart';
import '../../../data/repositories/professors_repository.dart';
import 'package:go_router/go_router.dart';

const _demoStudentId = 'b0000001-0000-0000-0000-000000000001';

// Palette for course blocks
const _blockColors = [
  Color(0xFF1E3A5F), // navy
  Color(0xFFB8860B), // gold
  Color(0xFF5B8C5A), // green
  Color(0xFF8B4513), // brown
  Color(0xFF4A6FA5), // steel blue
  Color(0xFF8E6C88), // mauve
  Color(0xFF2E8B57), // sea green
  Color(0xFFC0392B), // muted red
];

final _timetableProvider = FutureProvider<_TimetableData>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final year = prefs.getInt(AppConstants.keyYear) ?? 1;
  final semester = prefs.getInt(AppConstants.keySemester) ?? 1;
  final semesterCode = 'Y${year}S$semester';

  final enrollments = await ref.watch(enrollmentRepositoryProvider).listEnrollments(
    studentId: _demoStudentId,
    semesterCode: semesterCode,
  );

  return _TimetableData(
    enrollments: enrollments,
    semesterCode: semesterCode,
    year: year,
    semester: semester,
  );
});

class _TimetableData {
  final List<Enrollment> enrollments;
  final String semesterCode;
  final int year;
  final int semester;

  _TimetableData({
    required this.enrollments,
    required this.semesterCode,
    required this.year,
    required this.semester,
  });

  int get totalWeeklyHours {
    var hours = 0;
    for (final e in enrollments) {
      if (e.section?.schedule != null) {
        hours += e.section!.schedule.length; // each slot ~1.5h
      }
    }
    return (hours * 1.5).round();
  }

  List<_Block> get blocks {
    final result = <_Block>[];
    final courseIds = <String>{};
    for (final e in enrollments) {
      courseIds.add(e.courseId);
    }
    final courseList = courseIds.toList();

    for (final e in enrollments) {
      final colorIndex = courseList.indexOf(e.courseId) % _blockColors.length;
      final schedule = e.section?.schedule ?? [];
      for (final slot in schedule) {
        result.add(_Block(
          courseId: e.courseId,
          professorName: e.professor?.fullName ?? '',
          room: slot.room,
          day: slot.day,
          startTime: slot.start,
          endTime: slot.end,
          color: _blockColors[colorIndex],
        ));
      }
    }
    return result;
  }

  List<String>? get conflicts {
    final allBlocks = blocks;
    final found = <String>[];
    for (var i = 0; i < allBlocks.length; i++) {
      for (var j = i + 1; j < allBlocks.length; j++) {
        if (allBlocks[i].day == allBlocks[j].day &&
            _timesOverlap(allBlocks[i], allBlocks[j])) {
          found.add('${allBlocks[i].courseId} conflicts with ${allBlocks[j].courseId} on ${allBlocks[i].day}');
        }
      }
    }
    return found.isEmpty ? null : found;
  }

  static bool _timesOverlap(_Block a, _Block b) {
    final aStart = _toMinutes(a.startTime);
    final aEnd = _toMinutes(a.endTime);
    final bStart = _toMinutes(b.startTime);
    final bEnd = _toMinutes(b.endTime);
    return aStart < bEnd && bStart < aEnd;
  }

  static int _toMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class _Block {
  final String courseId;
  final String professorName;
  final String room;
  final String day;
  final String startTime;
  final String endTime;
  final Color color;

  _Block({
    required this.courseId,
    required this.professorName,
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.color,
  });
}

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  bool _weekView = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(_timetableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          // TODO(user): implement PDF + .ics export
          IconButton(
            icon: const Icon(PhosphorIconsRegular.shareFat),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
            tooltip: 'Export schedule',
          ),
        ],
      ),
      body: dataAsync.when(
        data: (data) {
          if (data.enrollments.isEmpty) {
            return AntEmptyState(
              icon: PhosphorIconsRegular.calendarBlank,
              title: 'No classes yet',
              message: 'Enroll in courses to see your schedule.',
              actionLabel: 'Enroll in courses',
              onAction: () => context.push(AppRoutes.enrollment),
            );
          }

          return Column(
            children: [
              // Header strip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderRadiusPill,
                      ),
                      child: Text(
                        'Y${data.year}S${data.semester}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${data.totalWeeklyHours}h/week',
                      style: theme.textTheme.labelSmall,
                    ),
                    const Spacer(),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Week')),
                        ButtonSegment(value: false, label: Text('Day')),
                      ],
                      selected: {_weekView},
                      onSelectionChanged: (v) => setState(() => _weekView = v.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(theme.textTheme.labelSmall),
                      ),
                    ),
                  ],
                ),
              ),

              // Conflict banner
              if (data.conflicts != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  color: AppColors.error.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsBold.warning, size: 16, color: AppColors.error),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Schedule conflict detected',
                          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

              // Grid
              Expanded(
                child: _weekView
                    ? _WeekGrid(blocks: data.blocks)
                    : _DayAgenda(blocks: data.blocks),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({required this.blocks});
  final List<_Block> blocks;

  static const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
  static const _startHour = 8;
  static const _endHour = 19;
  static const _hourHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().weekday; // 1=MON

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time labels
          SizedBox(
            width: 44,
            child: Column(
              children: [
                const SizedBox(height: 32), // header
                for (var h = _startHour; h < _endHour; h++)
                  SizedBox(
                    height: _hourHeight,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4, top: 0),
                        child: Text(
                          '${h.toString().padLeft(2, '0')}:00',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Day columns
          ...List.generate(_days.length, (dayIndex) {
            final dayName = _days[dayIndex];
            final isToday = dayIndex + 1 == today;
            final dayBlocks = blocks.where((b) => b.day == dayName).toList();

            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: isToday
                      ? Border(left: BorderSide(color: AppColors.gold, width: 2))
                      : null,
                ),
                child: Column(
                  children: [
                    // Day header
                    Container(
                      height: 32,
                      alignment: Alignment.center,
                      child: Text(
                        dayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday ? AppColors.gold : null,
                        ),
                      ),
                    ),
                    // Grid area
                    SizedBox(
                      height: (_endHour - _startHour) * _hourHeight,
                      child: Stack(
                        children: [
                          // Grid lines
                          ...List.generate(_endHour - _startHour, (i) {
                            return Positioned(
                              top: i * _hourHeight,
                              left: 0,
                              right: 0,
                              child: Divider(
                                height: 1,
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            );
                          }),
                          // Blocks
                          ...dayBlocks.map((block) {
                            final startMin = _toMinutes(block.startTime) - _startHour * 60;
                            final endMin = _toMinutes(block.endTime) - _startHour * 60;
                            final top = startMin * _hourHeight / 60;
                            final height = (endMin - startMin) * _hourHeight / 60;

                            return Positioned(
                              top: top,
                              left: 1,
                              right: 1,
                              height: height,
                              child: Container(
                                margin: const EdgeInsets.all(1),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: block.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: block.color.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      block.courseId.replaceAll('ce_', '').toUpperCase(),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9,
                                        color: block.color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (height > 35)
                                      Text(
                                        block.professorName.split(' ').last,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontSize: 8,
                                          color: block.color.withValues(alpha: 0.7),
                                        ),
                                        maxLines: 1,
                                      ),
                                    if (height > 50)
                                      Text(
                                        block.room,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontSize: 8,
                                          color: block.color.withValues(alpha: 0.5),
                                        ),
                                        maxLines: 1,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  int _toMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class _DayAgenda extends StatelessWidget {
  const _DayAgenda({required this.blocks});
  final List<_Block> blocks;

  static const _dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayIdx = DateTime.now().weekday - 1; // 0=MON
    final dayName = todayIdx < 5 ? _dayNames[todayIdx] : _dayNames[0];
    final todayBlocks = blocks.where((b) => b.day == dayName).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (todayBlocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.coffee, size: 48, color: AppColors.gold),
            const SizedBox(height: AppSpacing.md),
            Text('No classes today', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: todayBlocks.length,
      itemBuilder: (context, index) {
        final block = todayBlocks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: block.color.withValues(alpha: 0.08),
              borderRadius: AppRadius.borderRadiusLg,
              border: Border.all(color: block.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                // Time column
                Column(
                  children: [
                    Text(
                      block.startTime,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'JetBrains Mono',
                        color: block.color,
                      ),
                    ),
                    Text(
                      block.endTime,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'JetBrains Mono',
                        color: block.color.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Container(width: 3, height: 40, color: block.color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.courseId.replaceAll('ce_', '').toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: block.color,
                        ),
                      ),
                      Text(
                        block.professorName,
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        block.room,
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
        );
      },
    );
  }
}
