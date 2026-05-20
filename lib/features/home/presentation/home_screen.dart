import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/theme_provider.dart';
import '../../../core/widgets/ant_card.dart';
import '../../id_gate/id_gate_controller.dart';
import '../../../core/widgets/ant_section_header.dart';
import '../../../data/local/curriculum_loader.dart';

final homeStudentNameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.keyStudentFirstName) ?? 'Student';
});

final homeSubjectsProvider = FutureProvider<List<Subject>>((ref) async {
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
    final nameAsync = ref.watch(homeStudentNameProvider);
    final subjectsAsync = ref.watch(homeSubjectsProvider);
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
                  _VerifiedChip(),
                  const SizedBox(width: AppSpacing.xxs),
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

              // Quick Actions
              const AntSectionHeader(title: 'Quick Actions'),
              const SizedBox(height: AppSpacing.xs),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.8,
                children: [
                  _QuickActionCard(
                    icon: PhosphorIconsBold.chatCircleDots,
                    color: AppColors.primary,
                    label: 'UA Chat',
                    onTap: () => context.push(AppRoutes.chatbot),
                  ),
                  _QuickActionCard(
                    icon: PhosphorIconsBold.binoculars,
                    color: AppColors.warning,
                    label: 'Lost & Found',
                    onTap: () => context.push(AppRoutes.lostFound),
                  ),
                  _QuickActionCard(
                    icon: PhosphorIconsBold.calendarCheck,
                    color: AppColors.tertiary,
                    label: 'Scheduler',
                    onTap: () => context.go(AppRoutes.schedule),
                  ),
                  _QuickActionCard(
                    icon: PhosphorIconsBold.filmSlate,
                    color: AppColors.secondary,
                    label: 'Video AI',
                    onTap: () => context.push(AppRoutes.videoSummarizer),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
              const SizedBox(height: AppSpacing.xl),

              // Subjects grid
              const AntSectionHeader(title: 'Your Subjects'),
              const SizedBox(height: AppSpacing.xs),
              subjectsAsync.when(
                data: (subjects) => _SubjectGrid(subjects: subjects),
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
  const _SubjectGrid({required this.subjects});

  final List<Subject> subjects;

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
        childAspectRatio: 1.3,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];

        return AntCard(
          elevation: AntCardElevation.soft,
          onTap: () => context.push('/subject/${subject.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.code,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
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
                '${subject.credits} credits \u2022 ${subject.topics.length} topics',
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AntCard(
      elevation: AntCardElevation.soft,
      onTap: onTap,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
    );
  }
}

class _VerifiedChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateState = ref.watch(idGateControllerProvider);
    if (gateState != IdGateState.verified) return const SizedBox.shrink();

    final gate = ref.read(idGateControllerProvider.notifier);
    final hours = gate.hoursRemaining;

    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ID Verification'),
            content: Text('Verified for today. ${hours}h remaining.\n\nWant to re-scan now?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  gate.forceExpire();
                },
                child: const Text('Re-scan now'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.12),
          borderRadius: AppRadius.borderRadiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsBold.shieldCheck,
              size: 14,
              color: AppColors.gold,
            ),
            const SizedBox(width: 4),
            Text(
              '${hours}h',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
