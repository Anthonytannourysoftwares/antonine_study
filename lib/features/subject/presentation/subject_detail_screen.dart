import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../core/widgets/ant_empty_state.dart';
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
          _OverviewTab(subject: widget.subject),
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
  const _OverviewTab({required this.subject});

  final Subject subject;

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
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: AppSpacing.sm),

          // Course Materials button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                '/courses/${subject.id}/materials?name=${Uri.encodeComponent(subject.name)}',
              ),
              icon: const Icon(PhosphorIconsBold.folderOpen, size: 18),
              label: const Text('Course Materials'),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: AppSpacing.xl),

          // Topics list
          Text('Topics', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...subject.topics.asMap().entries.map((entry) {
            final index = entry.key;
            final topic = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AntCard(
                elevation: AntCardElevation.flat,
                padding: const EdgeInsets.all(AppSpacing.sm),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        topic,
                        style: theme.textTheme.bodyMedium,
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

// --- Flashcards Tab ---
class _FlashcardsTab extends StatefulWidget {
  const _FlashcardsTab({required this.subject});

  final Subject subject;

  @override
  State<_FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<_FlashcardsTab> {
  final _repo = StudyRepository();
  List<Map<String, dynamic>> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _repo.init();
    setState(() {
      _cards = _repo.getFlashcards();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_cards.isEmpty) {
      return const AntEmptyState(
        icon: PhosphorIconsBold.cards,
        title: 'No Flashcards Yet',
        message: 'Open Course Materials, tap the sparkle icon on a PDF, then tap Save.',
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AntCard(
            elevation: AntCardElevation.soft,
            onTap: () => _showCard(card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsBold.sparkle,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        card['title'] as String? ?? '',
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await _repo.deleteFlashcard(card['id'] as String);
                        _load();
                      },
                      child: Icon(PhosphorIconsRegular.trash,
                          size: 16, color: theme.colorScheme.error),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  card['fileName'] as String? ?? '',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  card['summary'] as String? ?? '',
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 50 + index * 40),
              duration: 300.ms,
            );
      },
    );
  }

  void _showCard(Map<String, dynamic> card) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(card['title'] as String? ?? '',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(card['fileName'] as String? ?? '',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Text(card['summary'] as String? ?? '',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Quiz Tab ---
class _QuizTab extends StatefulWidget {
  const _QuizTab({required this.subject});

  final Subject subject;

  @override
  State<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<_QuizTab> {
  final _repo = StudyRepository();
  List<Map<String, dynamic>> _quizzes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _repo.init();
    setState(() {
      _quizzes = _repo.getQuizzes(widget.subject.id);
      _loading = false;
    });
  }

  void _createQuiz() {
    final titleController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Create Quiz', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Quiz title (e.g. Chapter 1 Review)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _submitQuiz(titleController, ctx),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _submitQuiz(titleController, ctx),
                  icon: const Icon(PhosphorIconsBold.plus, size: 18),
                  label: const Text('Create'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _submitQuiz(TextEditingController controller, BuildContext ctx) {
    final title = controller.text.trim();
    if (title.isEmpty) return;
    final quiz = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'subjectId': widget.subject.id,
      'title': title,
      'questions': <Map<String, dynamic>>[],
      'createdAt': DateTime.now().toIso8601String(),
    };
    _repo.saveQuiz(quiz);
    Navigator.pop(ctx);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Expanded(
          child: _quizzes.isEmpty
              ? AntEmptyState(
                  icon: PhosphorIconsBold.exam,
                  title: 'No Quizzes Yet',
                  message: 'Create a quiz to start adding questions for ${widget.subject.name}.',
                )
              : ListView.builder(
                  padding: AppSpacing.screenPadding,
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    final questions = (quiz['questions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AntCard(
                        elevation: AntCardElevation.soft,
                        onTap: () => _openQuizEditor(quiz),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${questions.length}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz['title'] as String? ?? '',
                                    style: theme.textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${questions.length} question${questions.length == 1 ? '' : 's'}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (questions.isNotEmpty)
                              IconButton(
                                onPressed: () => _startQuiz(quiz),
                                icon: Icon(
                                  PhosphorIconsBold.play,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                tooltip: 'Take Quiz',
                              ),
                            IconButton(
                              onPressed: () async {
                                await _repo.deleteQuiz(quiz['id'] as String);
                                _load();
                              },
                              icon: Icon(
                                PhosphorIconsRegular.trash,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 50 + index * 40),
                          duration: 300.ms,
                        );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _createQuiz,
              icon: const Icon(PhosphorIconsBold.plus, size: 18),
              label: const Text('Create Quiz'),
            ),
          ),
        ),
      ],
    );
  }

  void _openQuizEditor(Map<String, dynamic> quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QuizEditorScreen(
          quiz: quiz,
          repo: _repo,
          onSaved: _load,
        ),
      ),
    );
  }

  void _startQuiz(Map<String, dynamic> quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QuizPlayerScreen(quiz: quiz),
      ),
    );
  }
}

// --- Quiz Editor Screen ---
class _QuizEditorScreen extends StatefulWidget {
  const _QuizEditorScreen({
    required this.quiz,
    required this.repo,
    required this.onSaved,
  });

  final Map<String, dynamic> quiz;
  final StudyRepository repo;
  final VoidCallback onSaved;

  @override
  State<_QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<_QuizEditorScreen> {
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = (widget.quiz['questions'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  Future<void> _save() async {
    widget.quiz['questions'] = _questions;
    await widget.repo.saveQuiz(widget.quiz);
    widget.onSaved();
  }

  void _addQuestion() {
    final questionController = TextEditingController();
    final optionControllers = List.generate(4, (_) => TextEditingController());
    int correctIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text('Add Question', style: theme.textTheme.titleLarge),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: questionController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Question',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Options (tap radio to mark correct)',
                        style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    ...List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: i,
                              groupValue: correctIndex,
                              onChanged: (v) =>
                                  setSheetState(() => correctIndex = v!),
                            ),
                            Expanded(
                              child: TextField(
                                controller: optionControllers[i],
                                decoration: InputDecoration(
                                  hintText: 'Option ${String.fromCharCode(65 + i)}',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final q = questionController.text.trim();
                          final opts = optionControllers
                              .map((c) => c.text.trim())
                              .toList();
                          if (q.isEmpty || opts.any((o) => o.isEmpty)) return;

                          setState(() {
                            _questions.add({
                              'question': q,
                              'options': opts,
                              'correctIndex': correctIndex,
                            });
                          });
                          _save();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(PhosphorIconsBold.checkCircle, size: 18),
                        label: const Text('Add Question'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz['title'] as String? ?? 'Quiz'),
        actions: [
          if (_questions.isNotEmpty)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _QuizPlayerScreen(quiz: {
                      ...widget.quiz,
                      'questions': _questions,
                    }),
                  ),
                );
              },
              icon: const Icon(PhosphorIconsBold.play),
              tooltip: 'Take Quiz',
            ),
        ],
      ),
      body: _questions.isEmpty
          ? const AntEmptyState(
              icon: PhosphorIconsBold.plusCircle,
              title: 'No Questions',
              message: 'Tap the button below to add your first question.',
            )
          : ReorderableListView.builder(
              padding: AppSpacing.screenPadding,
              itemCount: _questions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _questions.removeAt(oldIndex);
                  _questions.insert(newIndex, item);
                });
                _save();
              },
              itemBuilder: (context, index) {
                final q = _questions[index];
                final options = (q['options'] as List).cast<String>();
                final correctIdx = q['correctIndex'] as int;

                return Padding(
                  key: ValueKey('q_$index'),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AntCard(
                    elevation: AntCardElevation.soft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                q['question'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _questions.removeAt(index));
                                _save();
                              },
                              child: Icon(PhosphorIconsRegular.trash,
                                  size: 16, color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ...options.asMap().entries.map((e) {
                          final isCorrect = e.key == correctIdx;
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 32,
                              bottom: 2,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect
                                      ? PhosphorIconsBold.checkCircle
                                      : PhosphorIconsRegular.circle,
                                  size: 14,
                                  color: isCorrect
                                      ? AppColors.tertiary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isCorrect
                                          ? AppColors.tertiary
                                          : null,
                                      fontWeight: isCorrect
                                          ? FontWeight.w600
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        child: const Icon(PhosphorIconsBold.plus),
      ),
    );
  }
}

// --- Quiz Player Screen ---
class _QuizPlayerScreen extends StatefulWidget {
  const _QuizPlayerScreen({required this.quiz});

  final Map<String, dynamic> quiz;

  @override
  State<_QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends State<_QuizPlayerScreen> {
  late List<Map<String, dynamic>> _questions;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _correctCount = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = (widget.quiz['questions'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == _questions[_currentIndex]['correctIndex']) {
        _correctCount++;
      }
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_finished) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: Center(
          child: Padding(
            padding: AppSpacing.paddingAllXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _correctCount == _questions.length
                      ? PhosphorIconsBold.trophy
                      : PhosphorIconsBold.checkCircle,
                  size: 64,
                  color: _correctCount == _questions.length
                      ? AppColors.gold
                      : AppColors.tertiary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '$_correctCount / ${_questions.length}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _correctCount == _questions.length
                      ? 'Perfect score!'
                      : _correctCount >= _questions.length * 0.7
                          ? 'Great job!'
                          : 'Keep practicing!',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 0;
                          _selectedOption = null;
                          _answered = false;
                          _correctCount = 0;
                          _finished = false;
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final options = (question['options'] as List).cast<String>();
    final correctIdx = question['correctIndex'] as int;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_questions.length}'),
      ),
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                minHeight: 4,
                backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Question
            Text(
              question['question'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Options
            ...options.asMap().entries.map((e) {
              final idx = e.key;
              final option = e.value;
              final isSelected = _selectedOption == idx;
              final isCorrect = idx == correctIdx;

              Color? borderColor;
              Color? bgColor;
              if (_answered) {
                if (isCorrect) {
                  borderColor = AppColors.tertiary;
                  bgColor = AppColors.tertiary.withValues(alpha: 0.08);
                } else if (isSelected && !isCorrect) {
                  borderColor = AppColors.error;
                  bgColor = AppColors.error.withValues(alpha: 0.08);
                }
              } else if (isSelected) {
                borderColor = theme.colorScheme.primary;
                bgColor = theme.colorScheme.primary.withValues(alpha: 0.08);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InkWell(
                  onTap: () => _selectOption(idx),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(
                        color: borderColor ?? theme.colorScheme.outlineVariant,
                        width: isSelected || (_answered && isCorrect) ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: (borderColor ?? AppColors.primary)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + idx),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: borderColor ?? AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(option, style: theme.textTheme.bodyMedium),
                        ),
                        if (_answered && isCorrect)
                          Icon(PhosphorIconsBold.checkCircle,
                              size: 20, color: AppColors.tertiary),
                        if (_answered && isSelected && !isCorrect)
                          Icon(PhosphorIconsBold.xCircle,
                              size: 20, color: AppColors.error),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            // Next button
            if (_answered)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _currentIndex < _questions.length - 1
                        ? 'Next Question'
                        : 'See Results',
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
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
