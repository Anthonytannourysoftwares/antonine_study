import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../core/widgets/ant_section_header.dart';
import '../../../data/repositories/study_repository.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AntSectionHeader(title: 'Academic Tools'),
            const SizedBox(height: AppSpacing.xs),
            _ToolCard(
              icon: PhosphorIconsBold.calculator,
              iconColor: AppColors.primary,
              title: 'GPA Calculator',
              subtitle: 'Calculate your semester and cumulative GPA',
              onTap: () => _showGpaCalculator(context, ref),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.sm),
            _ToolCard(
              icon: PhosphorIconsBold.timer,
              iconColor: AppColors.secondary,
              title: 'Study Timer',
              subtitle: 'Pomodoro timer to track your sessions',
              onTap: () => _showStudyTimer(context, ref),
            )
                .animate()
                .fadeIn(delay: 80.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.sm),
            _ToolCard(
              icon: PhosphorIconsBold.notepad,
              iconColor: AppColors.tertiary,
              title: 'Quick Notes',
              subtitle: 'Jot down ideas and reminders',
              onTap: () => _showQuickNotes(context),
            )
                .animate()
                .fadeIn(delay: 160.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.xl),

            const AntSectionHeader(title: 'Study Aids'),
            const SizedBox(height: AppSpacing.xs),
            _ToolCard(
              icon: PhosphorIconsBold.cards,
              iconColor: AppColors.info,
              title: 'Flashcard Review',
              subtitle: 'Saved PDF summaries as flashcards',
              onTap: () => _showFlashcards(context),
            )
                .animate()
                .fadeIn(delay: 240.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _showGpaCalculator(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _GpaCalculatorSheet(),
    );
  }

  void _showStudyTimer(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _StudyTimerSheet(),
    );
  }

  void _showQuickNotes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _QuickNotesSheet(),
    );
  }

  void _showFlashcards(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _FlashcardsScreen()),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AntCard(
      elevation: AntCardElevation.soft,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── GPA Calculator ────────────────────────────

class _GpaCalculatorSheet extends StatefulWidget {
  const _GpaCalculatorSheet();

  @override
  State<_GpaCalculatorSheet> createState() => _GpaCalculatorSheetState();
}

class _GpaCalculatorSheetState extends State<_GpaCalculatorSheet> {
  final _courses = <_GpaCourse>[_GpaCourse()];

  double get _gpa {
    double totalPoints = 0;
    int totalCredits = 0;
    for (final c in _courses) {
      if (c.credits > 0) {
        totalPoints += c.gradePoints * c.credits;
        totalCredits += c.credits;
      }
    }
    return totalCredits > 0 ? totalPoints / totalCredits : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('GPA Calculator', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(_courses.length, (i) {
            final course = _courses[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Course',
                        isDense: true,
                      ),
                      onChanged: (v) => course.name = v,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cr',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {
                        course.credits = int.tryParse(v) ?? 0;
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 72,
                    child: DropdownButtonFormField<double>(
                      decoration: const InputDecoration(
                        hintText: 'Grade',
                        isDense: true,
                      ),
                      initialValue: course.gradePoints,
                      items: const [
                        DropdownMenuItem(value: 4.0, child: Text('A')),
                        DropdownMenuItem(value: 3.7, child: Text('A-')),
                        DropdownMenuItem(value: 3.3, child: Text('B+')),
                        DropdownMenuItem(value: 3.0, child: Text('B')),
                        DropdownMenuItem(value: 2.7, child: Text('B-')),
                        DropdownMenuItem(value: 2.3, child: Text('C+')),
                        DropdownMenuItem(value: 2.0, child: Text('C')),
                        DropdownMenuItem(value: 1.7, child: Text('C-')),
                        DropdownMenuItem(value: 1.0, child: Text('D')),
                        DropdownMenuItem(value: 0.0, child: Text('F')),
                      ],
                      onChanged: (v) => setState(() {
                        course.gradePoints = v ?? 0;
                      }),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _courses.add(_GpaCourse())),
                icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                label: const Text('Add Course'),
              ),
              Text(
                'GPA: ${_gpa.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _GpaCourse {
  String name = '';
  int credits = 0;
  double gradePoints = 4.0;
}

// ──────────────────────────── Study Timer ────────────────────────────

class _StudyTimerSheet extends StatefulWidget {
  const _StudyTimerSheet();

  @override
  State<_StudyTimerSheet> createState() => _StudyTimerSheetState();
}

class _StudyTimerSheetState extends State<_StudyTimerSheet>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  int _selectedMinutes = 25;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(minutes: _selectedMinutes),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _timeDisplay {
    final remaining = _controller.duration! * (1 - _controller.value);
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Study Timer', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xl),
          Text(
            _timeDisplay,
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!_isRunning) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [15, 25, 45, 60].map((m) {
                final selected = m == _selectedMinutes;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  child: ChoiceChip(
                    label: Text('${m}m'),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedMinutes = m;
                        _controller.duration = Duration(minutes: m);
                        _controller.reset();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    if (_isRunning) {
                      _controller.stop();
                    } else {
                      _controller.forward();
                    }
                    _isRunning = !_isRunning;
                  });
                },
                icon: Icon(
                  _isRunning
                      ? PhosphorIconsBold.pause
                      : PhosphorIconsBold.play,
                  size: 18,
                ),
                label: Text(_isRunning ? 'Pause' : 'Start'),
              ),
              if (_isRunning) ...[
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _controller.reset();
                      _isRunning = false;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ──────────────────────────── Quick Notes ────────────────────────────

class _QuickNotesSheet extends StatefulWidget {
  const _QuickNotesSheet();

  @override
  State<_QuickNotesSheet> createState() => _QuickNotesSheetState();
}

class _QuickNotesSheetState extends State<_QuickNotesSheet> {
  final _controller = TextEditingController();
  final _notes = <String>[];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notes.addAll(prefs.getStringList('quick_notes') ?? []);
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('quick_notes', _notes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quick Notes', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addNote(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: _addNote,
                icon: const Icon(PhosphorIconsBold.plus),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _notes.length,
              itemBuilder: (_, i) => ListTile(
                dense: true,
                title: Text(_notes[i], style: theme.textTheme.bodyMedium),
                trailing: IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.trash,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () {
                    setState(() => _notes.removeAt(i));
                    _saveNotes();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  void _addNote() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _notes.insert(0, text);
      _controller.clear();
    });
    _saveNotes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ──────────────────────────── Flashcards Screen ────────────────────────────

class _FlashcardsScreen extends StatefulWidget {
  const _FlashcardsScreen();

  @override
  State<_FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<_FlashcardsScreen> {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.cards,
                          size: 48, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: AppSpacing.md),
                      Text('No flashcards yet',
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Summarize a PDF and tap Save',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
                                    await _repo.deleteFlashcard(
                                        card['id'] as String);
                                    _load();
                                  },
                                  child: Icon(PhosphorIconsRegular.trash,
                                      size: 16,
                                      color: theme.colorScheme.error),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              card['fileName'] as String? ?? '',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
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
                ),
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
                  width: 40,
                  height: 4,
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
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Text(card['summary'] as String? ?? '',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${card['pages'] ?? 0} pages',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${card['totalWords'] ?? 0} words',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
