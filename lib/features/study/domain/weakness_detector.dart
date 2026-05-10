import 'dart:math';

class WeaknessScore {
  const WeaknessScore({
    required this.topicId,
    required this.subjectId,
    required this.score,
    required this.mastery,
  });

  final String topicId;
  final String subjectId;
  final double score;
  final double mastery;

  @override
  String toString() =>
      'WeaknessScore(topic: $topicId, subject: $subjectId, score: ${score.toStringAsFixed(3)}, mastery: ${mastery.toStringAsFixed(3)})';
}

class WeaknessDetector {
  const WeaknessDetector();

  /// Detects the weakest topics across all subjects.
  ///
  /// [subjectTopicMastery] maps subjectId -> (topicId -> mastery 0-1).
  /// [lastStudied] optionally maps topicId -> last study DateTime.
  /// Returns up to [maxResults] entries sorted by weakness score descending.
  List<WeaknessScore> detect(
    Map<String, Map<String, double>> subjectTopicMastery, {
    Map<String, DateTime>? lastStudied,
    int maxResults = 5,
  }) {
    final now = DateTime.now();
    final scores = <WeaknessScore>[];

    for (final entry in subjectTopicMastery.entries) {
      final subjectId = entry.key;
      final topics = entry.value;

      for (final topicEntry in topics.entries) {
        final topicId = topicEntry.key;
        final mastery = topicEntry.value.clamp(0.0, 1.0);

        final double recencyWeight;
        final studied = lastStudied?[topicId];

        if (studied == null) {
          recencyWeight = 1.0;
        } else {
          final daysSince = now.difference(studied).inHours / 24.0;
          recencyWeight = (daysSince / 7.0).clamp(0.5, 2.0);
        }

        final score = (1.0 - mastery) * recencyWeight;

        scores.add(WeaknessScore(
          topicId: topicId,
          subjectId: subjectId,
          score: score,
          mastery: mastery,
        ));
      }
    }

    scores.sort((a, b) => b.score.compareTo(a.score));

    return scores.take(min(maxResults, scores.length)).toList();
  }
}
