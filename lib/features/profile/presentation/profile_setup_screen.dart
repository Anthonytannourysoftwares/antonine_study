import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_state_provider.dart';
import '../../../core/widgets/ant_button.dart';
import '../../../core/widgets/ant_chip.dart';
import '../../../data/local/curriculum_loader.dart';

final _curriculumProvider = FutureProvider<Curriculum>((ref) {
  return CurriculumLoader().load();
});

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  String? _selectedMajorId;
  int? _selectedYear;
  int? _selectedSemester;

  bool get _isComplete =>
      _selectedMajorId != null &&
      _selectedYear != null &&
      _selectedSemester != null;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyMajorId, _selectedMajorId!);
    await prefs.setInt(AppConstants.keyYear, _selectedYear!);
    await prefs.setInt(AppConstants.keySemester, _selectedSemester!);

    if (!mounted) return;
    ref.read(appStateProvider.notifier).completeProfileSetup();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final curriculumAsync = ref.watch(_curriculumProvider);

    return Scaffold(
      body: SafeArea(
        child: curriculumAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading curriculum: $e')),
          data: (curriculum) => SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Icon(
                  PhosphorIconsBold.student,
                  size: 48,
                  color: theme.colorScheme.primary,
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                    ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Set Up Your Profile',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Select your major, year, and semester so we can '
                  'personalize your study plan.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.xxl),

                // Major — grouped by faculty
                ...curriculum.faculties.expand((faculty) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.lg,
                        bottom: AppSpacing.xs,
                      ),
                      child: Text(
                        faculty.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: faculty.majors.map((m) {
                        return AntChip(
                          label: m.name,
                          selected: _selectedMajorId == m.id,
                          onTap: () => setState(() {
                            _selectedMajorId = m.id;
                          }),
                        );
                      }).toList(),
                    ),
                  ];
                }),
                const SizedBox(height: AppSpacing.xl),

                // Year
                Text('Year', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: List.generate(5, (i) {
                    final year = i + 1;
                    return AntChip(
                      label: 'Year $year',
                      selected: _selectedYear == year,
                      onTap: () => setState(() => _selectedYear = year),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Semester
                Text('Semester', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [1, 2].map((s) {
                    return AntChip(
                      label: 'Semester $s',
                      selected: _selectedSemester == s,
                      onTap: () => setState(() => _selectedSemester = s),
                    );
                  }).toList(),
                ),

                // Subject preview
                if (_isComplete) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Your Subjects',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...curriculum
                      .getSubjects(
                        _selectedMajorId!,
                        _selectedYear!,
                        _selectedSemester!,
                      )
                      .map((s) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Row(
                              children: [
                                Text(
                                  s.code,
                                  style:
                                      theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    s.name,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  '${s.credits} cr',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          )),
                  if (curriculum
                      .getSubjects(
                        _selectedMajorId!,
                        _selectedYear!,
                        _selectedSemester!,
                      )
                      .isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No subjects defined for this combination yet. '
                        'You can continue and add them later.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],

                const SizedBox(height: AppSpacing.xxl),
                AntButton(
                  label: 'Continue',
                  onPressed: _isComplete ? _finish : null,
                  expand: true,
                  size: AntButtonSize.large,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
