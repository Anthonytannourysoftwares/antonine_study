import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_state_provider.dart';
import '../../../core/widgets/ant_button.dart';
import '../../../core/widgets/ant_chip.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  String? _selectedMajor;
  int? _selectedYear;
  int? _selectedSemester;

  // Placeholder data — Phase 3 loads from curriculum.json
  static const _majors = [
    'Computer Science',
    'Computer Engineering',
    'Telecom Engineering',
    'Business Administration',
    'Finance',
  ];

  bool get _isComplete =>
      _selectedMajor != null &&
      _selectedYear != null &&
      _selectedSemester != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Icon(
                PhosphorIconsBold.student,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Set Up Your Profile',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Select your major, year, and semester so we can personalize your study plan.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Major
              Text('Major', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _majors.map((m) {
                  return AntChip(
                    label: m,
                    selected: _selectedMajor == m,
                    onTap: () => setState(() => _selectedMajor = m),
                  );
                }).toList(),
              ),
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
              const SizedBox(height: AppSpacing.xxxl),

              AntButton(
                label: 'Continue',
                onPressed: _isComplete
                    ? () {
                        ref
                            .read(appStateProvider.notifier)
                            .completeProfileSetup();
                        context.go(AppRoutes.home);
                      }
                    : null,
                expand: true,
                size: AntButtonSize.large,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
