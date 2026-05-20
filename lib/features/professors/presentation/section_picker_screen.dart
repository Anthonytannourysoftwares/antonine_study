import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_button.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../core/widgets/ant_chip.dart';
import '../../../data/repositories/professors_repository.dart';

final _sectionsProvider =
    FutureProvider.family<List<Section>, String>((ref, courseId) {
  return ref.watch(professorsRepositoryProvider).listSections(courseId: courseId);
});

class SectionPickerScreen extends ConsumerStatefulWidget {
  const SectionPickerScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    this.selectedSectionId,
    this.onSectionSelected,
  });

  final String courseId;
  final String courseName;
  final String? selectedSectionId;
  final void Function(Section section)? onSectionSelected;

  @override
  ConsumerState<SectionPickerScreen> createState() => _SectionPickerScreenState();
}

class _SectionPickerScreenState extends ConsumerState<SectionPickerScreen> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedSectionId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionsAsync = ref.watch(_sectionsProvider(widget.courseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              'Choose a section',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: sectionsAsync.when(
        data: (sections) {
          if (sections.isEmpty) {
            return Center(
              child: Text(
                'No sections available.',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }
          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              final isSelected = _selectedId == section.id;
              final prof = section.professor;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AntCard(
                  elevation: isSelected
                      ? AntCardElevation.medium
                      : AntCardElevation.soft,
                  border: isSelected
                      ? Border.all(color: AppColors.gold, width: 2)
                      : null,
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
                        // Professor row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                (prof?.fullName ?? '?').substring(0, 1),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${prof?.title ?? ''} ${prof?.fullName ?? 'Unknown'}',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        PhosphorIconsBold.star,
                                        size: 14,
                                        color: AppColors.gold,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${prof?.ratingAvg.toStringAsFixed(1) ?? '0'} (${prof?.ratingCount ?? 0})',
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.gold,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  PhosphorIconsBold.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            if (section.isFull)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.borderRadiusPill,
                                ),
                                child: Text(
                                  'Full',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Schedule chips
                        Wrap(
                          spacing: AppSpacing.xxs,
                          runSpacing: AppSpacing.xxs,
                          children: section.schedule.map((slot) {
                            return AntChip(
                              label: '${slot.day} ${slot.start}\u2013${slot.end} \u00b7 ${slot.room}',
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Capacity bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: section.enrolledCount / section.capacity,
                                  backgroundColor: theme.colorScheme.outlineVariant,
                                  color: section.isFull ? AppColors.error : AppColors.gold,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${section.enrolledCount} / ${section.capacity}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Tags
                        if (prof != null && prof.tags.isNotEmpty)
                          Wrap(
                            spacing: AppSpacing.xxs,
                            children: prof.tags.take(3).map((tag) {
                              return AntChip(
                                label: tag,
                                selectedColor: AppColors.gold,
                              );
                            }).toList(),
                          ),

                        // View profile link
                        if (prof != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showProfessorDetail(context, prof, section),
                              child: const Text('View profile'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 80 * index),
                    duration: 300.ms,
                  );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading sections: $e'),
        ),
      ),
    );
  }

  void _showProfessorDetail(BuildContext context, Professor prof, Section section) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _ProfessorDetailSheet(
        professor: prof,
        section: section,
        onSelect: () {
          Navigator.pop(ctx);
          setState(() => _selectedId = section.id);
          widget.onSectionSelected?.call(section);
        },
      ),
    );
  }
}

class _ProfessorDetailSheet extends ConsumerWidget {
  const _ProfessorDetailSheet({
    required this.professor,
    required this.section,
    required this.onSelect,
  });

  final Professor professor;
  final Section section;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reviewsAsync = ref.watch(
      FutureProvider((ref) => ref.watch(professorsRepositoryProvider).getReviews(professor.id)),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      professor.fullName.substring(0, 1),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${professor.title} ${professor.fullName}',
                          style: theme.textTheme.titleLarge,
                        ),
                        if (professor.email != null)
                          Text(
                            professor.email!,
                            style: theme.textTheme.bodySmall,
                          ),
                        if (professor.office != null)
                          Text(
                            'Office: ${professor.office}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (professor.bio != null) ...[
                Text(professor.bio!, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Schedule
              Text('Schedule', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              ...section.schedule.map((slot) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${slot.day} ${slot.start}\u2013${slot.end}  \u00b7  ${slot.room}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )),
              const SizedBox(height: AppSpacing.lg),

              // Reviews
              Text('Reviews', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              reviewsAsync.when(
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return Text('No reviews yet.', style: theme.textTheme.bodySmall);
                  }
                  return Column(
                    children: reviews.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (i) => Icon(
                                i < r.rating ? PhosphorIconsBold.star : PhosphorIconsRegular.star,
                                size: 14,
                                color: AppColors.gold,
                              )),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                r.comment ?? '',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => Text('Could not load reviews.', style: theme.textTheme.bodySmall),
              ),
              const SizedBox(height: AppSpacing.xl),

              // CTA
              if (!section.isFull)
                AntButton(
                  label: 'Select this section',
                  onPressed: onSelect,
                  expand: true,
                  size: AntButtonSize.large,
                ),
            ],
          ),
        );
      },
    );
  }
}
