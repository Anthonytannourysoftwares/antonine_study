import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_button.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../core/widgets/ant_chip.dart';
import '../../../core/widgets/ant_empty_state.dart';
import '../../../data/local/curriculum_loader.dart';
import '../../../data/api/api_client.dart';
import '../../../data/repositories/enrollment_repository.dart';
import '../../../data/repositories/professors_repository.dart';

// Use a fixed demo student ID for now
// TODO(user): derive from hashed student ID in secure storage
const _demoStudentId = 'b0000001-0000-0000-0000-000000000001';

final _profileProvider = FutureProvider<_ProfileInfo>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return _ProfileInfo(
    majorId: prefs.getString(AppConstants.keyMajorId) ?? 'ce',
    year: prefs.getInt(AppConstants.keyYear) ?? 1,
    semester: prefs.getInt(AppConstants.keySemester) ?? 1,
  );
});

class _ProfileInfo {
  final String majorId;
  final int year;
  final int semester;
  String get semesterCode => 'Y${year}S$semester';
  _ProfileInfo({required this.majorId, required this.year, required this.semester});
}

final _subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final profile = await ref.watch(_profileProvider.future);
  final curriculum = await CurriculumLoader().load();
  return curriculum.getSubjects(profile.majorId, profile.year, profile.semester);
});

final _enrollmentsProvider = FutureProvider<List<Enrollment>>((ref) async {
  final profile = await ref.watch(_profileProvider.future);
  return ref.watch(enrollmentRepositoryProvider).listEnrollments(
    studentId: _demoStudentId,
    semesterCode: profile.semesterCode,
  );
});

class EnrollmentScreen extends ConsumerStatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_profileProvider);
    final subjectsAsync = ref.watch(_subjectsProvider);
    final enrollmentsAsync = ref.watch(_enrollmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Course Enrollment')),
      body: profileAsync.when(
        data: (profile) {
          return subjectsAsync.when(
            data: (subjects) {
              final enrollments = enrollmentsAsync.valueOrNull ?? [];
              final enrolledCourseIds =
                  enrollments.map((e) => e.courseId).toSet();
              final currentCredits = enrollments.length * 3;

              return SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Semester + credits
                    Row(
                      children: [
                        AntChip(
                          label: 'Year ${profile.year} \u00b7 Semester ${profile.semester}',
                          selected: true,
                          selectedColor: AppColors.gold,
                        ),
                        const Spacer(),
                        _CreditMeter(current: currentCredits, max: 18),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (subjects.isEmpty)
                      const AntEmptyState(
                        icon: PhosphorIconsRegular.book,
                        title: 'No courses available',
                        message: 'No courses found for this semester.',
                      )
                    else
                      ...subjects.map((subject) {
                        final isEnrolled = enrolledCourseIds.contains(subject.id);
                        final enrollment = enrollments
                            .where((e) => e.courseId == subject.id)
                            .firstOrNull;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _CourseCard(
                            subject: subject,
                            isEnrolled: isEnrolled,
                            enrollment: enrollment,
                            isLoading: _isLoading,
                            onAdd: () => _enrollInCourse(
                              context, subject, profile,
                            ),
                            onDrop: enrollment != null
                                ? () => _dropCourse(enrollment)
                                : null,
                            onChangeSec: enrollment != null
                                ? () => _changeSectionFor(
                                    context, subject, profile, enrollment)
                                : null,
                          ),
                        ).animate().fadeIn(duration: 300.ms);
                      }),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _enrollInCourse(
    BuildContext ctx, Subject subject, _ProfileInfo profile,
  ) async {
    // Navigate to section picker and wait for selection
    Section? selected;
    await Navigator.push<void>(
      ctx,
      MaterialPageRoute(
        builder: (_) => _SectionPickerWrapper(
          courseId: subject.id,
          courseName: subject.name,
          onSelected: (s) {
            selected = s;
            Navigator.pop(ctx);
          },
        ),
      ),
    );

    if (selected == null) return;

    setState(() => _isLoading = true);
    try {
      // Validate
      final validation = await ref.read(enrollmentRepositoryProvider).validate(
        studentId: _demoStudentId,
        courseId: subject.id,
        sectionId: selected!.id,
        semesterCode: profile.semesterCode,
      );

      if (!validation.valid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(validation.errors.join('\n'))),
          );
        }
        return;
      }

      await ref.read(enrollmentRepositoryProvider).enroll(
        studentId: _demoStudentId,
        courseId: subject.id,
        sectionId: selected!.id,
        semesterCode: profile.semesterCode,
      );

      ref.invalidate(_enrollmentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrolled in ${subject.name}')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dropCourse(Enrollment enrollment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Drop Course'),
        content: Text('Drop ${enrollment.courseId}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Drop', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(enrollmentRepositoryProvider).drop(enrollment.id);
      ref.invalidate(_enrollmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course dropped')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeSectionFor(
    BuildContext ctx, Subject subject, _ProfileInfo profile, Enrollment enrollment,
  ) async {
    Section? selected;
    await Navigator.push<void>(
      ctx,
      MaterialPageRoute(
        builder: (_) => _SectionPickerWrapper(
          courseId: subject.id,
          courseName: subject.name,
          selectedSectionId: enrollment.sectionId,
          onSelected: (s) {
            selected = s;
            Navigator.pop(ctx);
          },
        ),
      ),
    );

    if (selected == null || selected!.id == enrollment.sectionId) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(enrollmentRepositoryProvider).updateSection(
        enrollment.id, selected!.id,
      );
      ref.invalidate(_enrollmentsProvider);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _SectionPickerWrapper extends ConsumerWidget {
  const _SectionPickerWrapper({
    required this.courseId,
    required this.courseName,
    this.selectedSectionId,
    required this.onSelected,
  });

  final String courseId;
  final String courseName;
  final String? selectedSectionId;
  final void Function(Section) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Builder(
        builder: (ctx) {
          // Reuse the SectionPickerScreen widget directly
          return _InlineSectionPicker(
            courseId: courseId,
            courseName: courseName,
            selectedSectionId: selectedSectionId,
            onSelected: onSelected,
          );
        },
      ),
    );
  }
}

class _InlineSectionPicker extends ConsumerWidget {
  const _InlineSectionPicker({
    required this.courseId,
    required this.courseName,
    this.selectedSectionId,
    required this.onSelected,
  });

  final String courseId;
  final String courseName;
  final String? selectedSectionId;
  final void Function(Section) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Import and reuse the existing SectionPickerScreen
    return __ImportedSectionPicker(
      courseId: courseId,
      courseName: courseName,
      selectedSectionId: selectedSectionId,
      onSelected: onSelected,
    );
  }
}

// Re-implemented inline to avoid circular imports
class __ImportedSectionPicker extends StatelessWidget {
  const __ImportedSectionPicker({
    required this.courseId,
    required this.courseName,
    this.selectedSectionId,
    required this.onSelected,
  });

  final String courseId;
  final String courseName;
  final String? selectedSectionId;
  final void Function(Section) onSelected;

  @override
  Widget build(BuildContext context) {
    // We use the SectionPickerScreen from professors feature
    return _ActualSectionPickerScreen(
      courseId: courseId,
      courseName: courseName,
      selectedSectionId: selectedSectionId,
      onSectionSelected: onSelected,
    );
  }
}

// Inline minimal section picker that fetches from API
class _ActualSectionPickerScreen extends ConsumerStatefulWidget {
  const _ActualSectionPickerScreen({
    required this.courseId,
    required this.courseName,
    this.selectedSectionId,
    this.onSectionSelected,
  });

  final String courseId;
  final String courseName;
  final String? selectedSectionId;
  final void Function(Section)? onSectionSelected;

  @override
  ConsumerState<_ActualSectionPickerScreen> createState() =>
      _ActualSectionPickerScreenState();
}

class _ActualSectionPickerScreenState
    extends ConsumerState<_ActualSectionPickerScreen> {
  String? _selectedId;
  List<Section>? _sections;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedSectionId;
    _loadSections();
  }

  Future<void> _loadSections() async {
    final repo = ref.read(professorsRepositoryProvider);
    final sections = await repo.listSections(courseId: widget.courseId);
    if (mounted) setState(() { _sections = sections; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.courseName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sections == null || _sections!.isEmpty
              ? Center(child: Text('No sections available', style: theme.textTheme.bodyLarge))
              : ListView.builder(
                  padding: AppSpacing.screenPadding,
                  itemCount: _sections!.length,
                  itemBuilder: (context, index) {
                    final section = _sections![index];
                    final isSelected = _selectedId == section.id;
                    final prof = section.professor;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AntCard(
                        elevation: isSelected ? AntCardElevation.medium : AntCardElevation.soft,
                        border: isSelected ? Border.all(color: AppColors.gold, width: 2) : null,
                        onTap: section.isFull
                            ? null
                            : () {
                                setState(() => _selectedId = section.id);
                                widget.onSectionSelected?.call(section);
                              },
                        child: Opacity(
                          opacity: section.isFull ? 0.5 : 1.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      (prof?.fullName ?? '?').substring(0, 1),
                                      style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${prof?.title ?? ''} ${prof?.fullName ?? 'TBA'}', style: theme.textTheme.titleSmall),
                                        Row(children: [
                                          Icon(PhosphorIconsBold.star, size: 12, color: AppColors.gold),
                                          const SizedBox(width: 2),
                                          Text('${prof?.ratingAvg.toStringAsFixed(1)} (${prof?.ratingCount})', style: theme.textTheme.labelSmall),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 24, height: 24,
                                      decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                                      child: const Icon(PhosphorIconsBold.check, size: 14, color: Colors.white),
                                    ),
                                  if (section.isFull)
                                    Text('Full', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.error)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: 4, runSpacing: 4,
                                children: section.schedule.map((slot) {
                                  return AntChip(label: '${slot.day} ${slot.start}\u2013${slot.end} \u00b7 ${slot.room}');
                                }).toList(),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: section.enrolledCount / section.capacity,
                                      backgroundColor: theme.colorScheme.outlineVariant,
                                      color: section.isFull ? AppColors.error : AppColors.gold,
                                      minHeight: 5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text('${section.enrolledCount}/${section.capacity}', style: theme.textTheme.labelSmall),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.subject,
    required this.isEnrolled,
    this.enrollment,
    required this.isLoading,
    required this.onAdd,
    this.onDrop,
    this.onChangeSec,
  });

  final Subject subject;
  final bool isEnrolled;
  final Enrollment? enrollment;
  final bool isLoading;
  final VoidCallback onAdd;
  final VoidCallback? onDrop;
  final VoidCallback? onChangeSec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(subject.id),
      direction: isEnrolled ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: AppRadius.borderRadiusLg,
        ),
        child: const Icon(PhosphorIconsBold.trash, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        onDrop?.call();
        return false; // We handle deletion ourselves
      },
      child: AntCard(
        elevation: AntCardElevation.soft,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        subject.code,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${subject.credits} cr',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subject.name, style: theme.textTheme.titleSmall),
                  if (isEnrolled && enrollment?.professor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${enrollment!.professor!.title} ${enrollment!.professor!.fullName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isEnrolled) ...[
              if (onChangeSec != null)
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.swap, size: 20),
                  onPressed: onChangeSec,
                  tooltip: 'Change section',
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderRadiusPill,
                ),
                child: Text(
                  'Enrolled',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else
              AntButton(
                label: 'Add',
                onPressed: isLoading ? null : onAdd,
                size: AntButtonSize.small,
                isLoading: isLoading,
              ),
          ],
        ),
      ),
    );
  }
}

class _CreditMeter extends StatelessWidget {
  const _CreditMeter({required this.current, required this.max});

  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overLimit = current > max;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$current / $max cr',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: overLimit ? AppColors.error : AppColors.gold,
          ),
        ),
      ],
    );
  }
}
