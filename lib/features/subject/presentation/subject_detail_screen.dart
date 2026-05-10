import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/ant_empty_state.dart';

class SubjectDetailScreen extends StatelessWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subject: $subjectId'),
      ),
      body: const AntEmptyState(
        icon: PhosphorIconsBold.book,
        title: 'Subject Detail',
        message: 'Flashcards, quizzes, notes, and progress will appear here.',
      ),
    );
  }
}
