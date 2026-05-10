import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../core/widgets/ant_empty_state.dart';
import '../../../core/widgets/ant_progress_ring.dart';
import '../../../data/local/curriculum_loader.dart';
import '../../../data/repositories/study_repository.dart';

final _subjectProvider = FutureProvider.family<Subject?, String>(
  (ref, id) async {
    final curriculum = await CurriculumLoader().load();
    for (final majorEntry in curriculum.subjectsByMajor.values) {
      for (final yearEntry in majorEntry.values) {
        for (final semEntry in yearEntry.values) {
          for (final subject in semEntry) {
            if (subject.id == id) return subject;
          }
        }
      }
    }
    return null;
  },
);

class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectAsync = ref.watch(_subjectProvider(subjectId));

    return subjectAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (subject) {
        if (subject == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const AntEmptyState(
              icon: PhosphorIconsBold.question,
              title: 'Subject Not Found',
              message: 'This subject could not be loaded.',
            ),
          );
        }
        return _SubjectDetailBody(subject: subject);
      },
    );
  }
}

class _SubjectDetailBody extends ConsumerStatefulWidget {
  const _SubjectDetailBody({required this.subject});

  final Subject subject;

  @override
  ConsumerState<_SubjectDetailBody> createState() => _SubjectDetailBodyState();
}

class _SubjectDetailBodyState extends ConsumerState<_SubjectDetailBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studyRepo = ref.watch(studyRepositoryProvider);
    final mastery = studyRepo.getMastery(widget.subject.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.code),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Flashcards'),
            Tab(text: 'Quiz'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(subject: widget.subject, mastery: mastery, repo: studyRepo),
          _FlashcardsTab(subject: widget.subject),
          _QuizTab(subject: widget.subject),
          _NotesTab(subject: widget.subject),
        ],
      ),
    );
  }
}

// --- Overview Tab ---
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.subject,
    required this.mastery,
    required this.repo,
  });

  final Subject subject;
  final double mastery;
  final StudyRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject header
          AntCard(
            elevation: AntCardElevation.medium,
            padding: AppSpacing.paddingAllLg,
            child: Row(
              children: [
                AntProgressRing(
                  progress: mastery,
                  size: 72,
                  strokeWidth: 6,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${subject.credits} credits \u2022 ${subject.topics.length} topics',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: AppSpacing.xl),

          // Topics list with mastery bars
          Text('Topics', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...subject.topics.asMap().entries.map((entry) {
            final index = entry.key;
            final topic = entry.value;
            final topicMastery = repo.getTopicMastery(subject.id, topic);
            final isWeakest = topicMastery < 0.3;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AntCard(
                elevation: AntCardElevation.flat,
                padding: const EdgeInsets.all(AppSpacing.sm),
                border: Border.all(
                  color: isWeakest
                      ? AppColors.error.withValues(alpha: 0.3)
                      : theme.colorScheme.outlineVariant,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  topic,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              if (isWeakest)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: AppRadius.borderRadiusPill,
                                  ),
                                  child: Text(
                                    'Needs work',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.error,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: topicMastery,
                              backgroundColor: theme
                                  .colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                              color: topicMastery >= 0.8
                                  ? AppColors.tertiary
                                  : topicMastery >= 0.5
                                      ? AppColors.secondary
                                      : AppColors.error,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${(topicMastery * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 100 + index * 50),
                  duration: 300.ms,
                )
                .slideX(begin: 0.02, end: 0);
          }),
        ],
      ),
    );
  }
}

// --- Flashcards Tab (Phase 5 will populate with SM-2) ---
class _FlashcardsTab extends StatelessWidget {
  const _FlashcardsTab({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return const AntEmptyState(
      icon: PhosphorIconsBold.cards,
      title: 'Flashcards Coming Soon',
      message:
          'Spaced-repetition flashcards powered by the SM-2 algorithm will appear here.',
    );
  }
}

// --- Quiz Tab (Phase 5 will populate with IRT) ---
class _QuizTab extends StatelessWidget {
  const _QuizTab({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return const AntEmptyState(
      icon: PhosphorIconsBold.exam,
      title: 'Adaptive Quiz Coming Soon',
      message:
          'AI-powered adaptive quizzes using Item Response Theory will appear here.',
    );
  }
}

// --- Notes Tab ---
class _NotesTab extends StatefulWidget {
  const _NotesTab({required this.subject});

  final Subject subject;

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Notes',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Write your notes for ${widget.subject.name}...',
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
