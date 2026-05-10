import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/theme_provider.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../core/widgets/ant_progress_ring.dart';
import '../../../core/widgets/ant_section_header.dart';

final _studentNameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.keyStudentFirstName) ?? 'Student';
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nameAsync = ref.watch(_studentNameProvider);
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      nameAsync.when(
                        data: (name) => Text(
                          '$greeting, $name',
                          style: theme.textTheme.headlineSmall,
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
                    Text(
                      'Complete your profile to unlock personalized study recommendations.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSpacing.xl),

              // Subjects
              const AntSectionHeader(
                title: 'Your Subjects',
                actionLabel: 'See all',
              ),
              const SizedBox(height: AppSpacing.xs),
              _SubjectGrid(),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _SubjectGrid extends StatelessWidget {
  // Placeholder subjects — Phase 3 will load from curriculum
  static const _subjects = [
    _SubjectData('Intro to Programming', 'CS101', 0.72),
    _SubjectData('Calculus I', 'MATH101', 0.45),
    _SubjectData('Data Structures', 'CS102', 0.38),
    _SubjectData('Physics I', 'PHYS101', 0.61),
    _SubjectData('English Communication', 'ENG101', 0.85),
    _SubjectData('Discrete Mathematics', 'MATH102', 0.28),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.1,
      ),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        return AntCard(
          elevation: AntCardElevation.soft,
          onTap: () {
            // Phase 4: navigate to subject detail
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subject.code,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  AntProgressRing(
                    progress: subject.mastery,
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
                'Last studied 2d ago',
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

class _SubjectData {
  const _SubjectData(this.name, this.code, this.mastery);
  final String name;
  final String code;
  final double mastery;
}
