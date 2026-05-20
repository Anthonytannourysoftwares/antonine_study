import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Stores flashcards and quizzes locally via Hive.
class StudyRepository {
  static const _streakBox = 'streaks';
  static const _flashcardsBox = 'flashcards';
  static const _quizzesBox = 'quizzes';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (!Hive.isBoxOpen(_streakBox)) await Hive.openBox<dynamic>(_streakBox);
    if (!Hive.isBoxOpen(_flashcardsBox)) await Hive.openBox<Map>(_flashcardsBox);
    if (!Hive.isBoxOpen(_quizzesBox)) await Hive.openBox<Map>(_quizzesBox);
    _initialized = true;
  }

  /// Get last studied date for a subject (ISO date string or null).
  String? getLastStudied(String subjectId) {
    final box = Hive.box<dynamic>(_streakBox);
    return box.get('last_studied_$subjectId') as String?;
  }

  /// Mark a subject as studied today.
  Future<void> markStudied(String subjectId) async {
    final box = Hive.box<dynamic>(_streakBox);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await box.put('last_studied_$subjectId', today);
  }

  /// Save a PDF summary as a flashcard.
  Future<void> saveFlashcard({
    required String title,
    required String summary,
    required String fileName,
    int pages = 0,
    int totalWords = 0,
  }) async {
    final box = Hive.box<Map>(_flashcardsBox);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, {
      'id': id,
      'title': title,
      'summary': summary,
      'fileName': fileName,
      'pages': pages,
      'totalWords': totalWords,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get all saved flashcards.
  List<Map<String, dynamic>> getFlashcards() {
    final box = Hive.box<Map>(_flashcardsBox);
    return box.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) => (b['createdAt'] as String)
          .compareTo(a['createdAt'] as String));
  }

  /// Delete a flashcard by ID.
  Future<void> deleteFlashcard(String id) async {
    final box = Hive.box<Map>(_flashcardsBox);
    await box.delete(id);
  }

  // ──────────────────────────── Quizzes ────────────────────────────

  /// Save a quiz.
  Future<void> saveQuiz(Map<String, dynamic> quiz) async {
    final box = Hive.box<Map>(_quizzesBox);
    await box.put(quiz['id'] as String, quiz);
  }

  /// Get all quizzes for a subject.
  List<Map<String, dynamic>> getQuizzes(String subjectId) {
    final box = Hive.box<Map>(_quizzesBox);
    return box.values
        .map((e) => Map<String, dynamic>.from(e))
        .where((q) => q['subjectId'] == subjectId)
        .toList()
      ..sort((a, b) => (b['createdAt'] as String)
          .compareTo(a['createdAt'] as String));
  }

  /// Delete a quiz by ID.
  Future<void> deleteQuiz(String id) async {
    final box = Hive.box<Map>(_quizzesBox);
    await box.delete(id);
  }

  /// Clear all study data.
  Future<void> clearAll() async {
    await Hive.box<dynamic>(_streakBox).clear();
  }
}

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return StudyRepository();
});
