import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Stores per-topic mastery, study time, and streaks locally via Hive.
class StudyRepository {
  static const _masteryBox = 'mastery';
  static const _studyTimeBox = 'study_time';
  static const _streakBox = 'streaks';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox<double>(_masteryBox);
    await Hive.openBox<int>(_studyTimeBox);
    await Hive.openBox<dynamic>(_streakBox);
    _initialized = true;
  }

  /// Get mastery for a subject (0.0–1.0). Returns 0 if not tracked yet.
  double getMastery(String subjectId) {
    final box = Hive.box<double>(_masteryBox);
    return box.get(subjectId, defaultValue: 0.0) ?? 0.0;
  }

  /// Set mastery for a subject.
  Future<void> setMastery(String subjectId, double value) async {
    final box = Hive.box<double>(_masteryBox);
    await box.put(subjectId, value.clamp(0.0, 1.0));
  }

  /// Get mastery for a specific topic within a subject.
  double getTopicMastery(String subjectId, String topic) {
    final box = Hive.box<double>(_masteryBox);
    return box.get('$subjectId:$topic', defaultValue: 0.0) ?? 0.0;
  }

  /// Set mastery for a specific topic.
  Future<void> setTopicMastery(
    String subjectId,
    String topic,
    double value,
  ) async {
    final box = Hive.box<double>(_masteryBox);
    await box.put('$subjectId:$topic', value.clamp(0.0, 1.0));
  }

  /// Record study minutes for today.
  Future<void> addStudyMinutes(String subjectId, int minutes) async {
    final box = Hive.box<int>(_studyTimeBox);
    final today = _todayKey(subjectId);
    final existing = box.get(today, defaultValue: 0) ?? 0;
    await box.put(today, existing + minutes);
  }

  /// Get total study minutes for a subject today.
  int getStudyMinutesToday(String subjectId) {
    final box = Hive.box<int>(_studyTimeBox);
    return box.get(_todayKey(subjectId), defaultValue: 0) ?? 0;
  }

  /// Get current study streak (consecutive days).
  int getStreak() {
    final box = Hive.box<dynamic>(_streakBox);
    return (box.get('current_streak', defaultValue: 0) as int?) ?? 0;
  }

  /// Update streak — call after each study session.
  Future<void> updateStreak() async {
    final box = Hive.box<dynamic>(_streakBox);
    final lastStudy = box.get('last_study_date') as String?;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastStudy == today) return;

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    final currentStreak =
        (box.get('current_streak', defaultValue: 0) as int?) ?? 0;

    if (lastStudy == yesterday) {
      await box.put('current_streak', currentStreak + 1);
    } else {
      await box.put('current_streak', 1);
    }
    await box.put('last_study_date', today);
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
    await updateStreak();
  }

  String _todayKey(String subjectId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return '${subjectId}_$today';
  }
}

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return StudyRepository();
});
