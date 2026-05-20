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
import '../../../core/widgets/ant_section_header.dart';
import '../../../data/repositories/study_repository.dart';
import '../../home/presentation/home_screen.dart';

final _profileProvider = FutureProvider<_ProfileData>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return _ProfileData(
    name: prefs.getString(AppConstants.keyStudentFirstName) ?? 'Student',
    majorId: prefs.getString(AppConstants.keyMajorId) ?? '',
    year: prefs.getInt(AppConstants.keyYear) ?? 1,
    semester: prefs.getInt(AppConstants.keySemester) ?? 1,
  );
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(_profileProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            profileAsync.when(
              data: (profile) => AntCard(
                elevation: AntCardElevation.medium,
                padding: AppSpacing.paddingAllLg,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : 'S',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Year ${profile.year} \u2022 Semester ${profile.semester}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (profile.majorId.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              profile.majorId,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 80),
              error: (_, _) => const SizedBox.shrink(),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.xl),

            // Appearance
            const AntSectionHeader(title: 'Appearance'),
            AntCard(
              elevation: AntCardElevation.soft,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: PhosphorIconsRegular.moon,
                    title: 'Theme',
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(PhosphorIconsRegular.sun, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(PhosphorIconsRegular.devices, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(PhosphorIconsRegular.moon, size: 16),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (modes) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(modes.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.xl),

            // Academic
            const AntSectionHeader(title: 'Academic'),
            profileAsync.when(
              data: (profile) => AntCard(
                elevation: AntCardElevation.soft,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: PhosphorIconsRegular.graduationCap,
                      title: 'Year',
                      trailing: DropdownButton<int>(
                        value: profile.year,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: List.generate(5, (i) => i + 1)
                            .map((y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('Year $y'),
                                ))
                            .toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt(AppConstants.keyYear, v);
                          await prefs.setInt(AppConstants.keySemester, 1);
                          ref.invalidate(_profileProvider);
                          ref.invalidate(homeSubjectsProvider);
                        },
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: AppSpacing.xxxl,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    _SettingsTile(
                      icon: PhosphorIconsRegular.calendarBlank,
                      title: 'Semester',
                      trailing: DropdownButton<int>(
                        value: profile.semester,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: [1, 2]
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text('Semester $s'),
                                ))
                            .toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt(AppConstants.keySemester, v);
                          ref.invalidate(_profileProvider);
                          ref.invalidate(homeSubjectsProvider);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 80),
              error: (_, _) => const SizedBox.shrink(),
            )
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.xl),

            // Account
            const AntSectionHeader(title: 'Account'),
            AntCard(
              elevation: AntCardElevation.soft,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: PhosphorIconsRegular.identificationCard,
                    title: 'ID Verification',
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.idVerification),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.xl),

            // About
            const AntSectionHeader(title: 'About'),
            AntCard(
              elevation: AntCardElevation.soft,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: PhosphorIconsRegular.lifebuoy,
                    title: 'Help Center',
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.help),
                  ),
                  Divider(
                    height: 1,
                    indent: AppSpacing.xxxl,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _SettingsTile(
                    icon: PhosphorIconsRegular.info,
                    title: 'About ${AppConstants.appName}',
                    showChevron: true,
                    onTap: () => _showAbout(context),
                  ),
                  Divider(
                    height: 1,
                    indent: AppSpacing.xxxl,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _SettingsTile(
                    icon: PhosphorIconsRegular.buildings,
                    title: AppConstants.universityNameFr,
                    trailing: Image.asset(
                      'assets/images/ua_logo.png',
                      height: 24,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.xl),

            // Danger zone
            const AntSectionHeader(title: 'Data'),
            AntCard(
              elevation: AntCardElevation.soft,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: PhosphorIconsRegular.arrowCounterClockwise,
                    title: 'Reset Progress',
                    titleColor: AppColors.warning,
                    onTap: () => _confirmResetProgress(context, ref),
                  ),
                  Divider(
                    height: 1,
                    indent: AppSpacing.xxxl,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _SettingsTile(
                    icon: PhosphorIconsRegular.trashSimple,
                    title: 'Reset All Data',
                    titleColor: AppColors.error,
                    onTap: () => _confirmResetAll(context, ref),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.xl),

            // Version
            Center(
              child: Text(
                '${AppConstants.appName} v1.0.0',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Image.asset('assets/images/ua_logo.png', height: 32),
            const SizedBox(width: AppSpacing.sm),
            const Text('Antonine Study'),
          ],
        ),
        content: Text(
          'An AI-powered study assistant built exclusively for '
          '${AppConstants.universityNameFr} students.\n\n'
          'All processing happens on your device. '
          'Your data never leaves your phone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmResetProgress(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text(
          'This will reset your study data. '
          'Your profile will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final studyRepo = ref.read(studyRepositoryProvider);
              await studyRepo.clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress reset.')),
                );
              }
            },
            child: Text(
              'Reset',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will erase everything — progress, profile, and settings. '
          'You will need to set up the app again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              final studyRepo = ref.read(studyRepositoryProvider);
              await studyRepo.clearAll();
              if (context.mounted) {
                context.go(AppRoutes.onboarding);
              }
            },
            child: Text(
              'Erase Everything',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.showChevron = false,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: titleColor ?? theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(color: titleColor),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Align(alignment: Alignment.centerRight, child: trailing!)),
            ] else
              const Spacer(),
            if (showChevron)
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileData {
  final String name;
  final String majorId;
  final int year;
  final int semester;

  const _ProfileData({
    required this.name,
    required this.majorId,
    required this.year,
    required this.semester,
  });
}
