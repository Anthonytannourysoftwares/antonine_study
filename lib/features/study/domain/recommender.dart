import 'dart:math';

/// A record of a student's interaction with a single topic.
class TopicInteraction {
  final String topicId;

  /// Mastery level in [0, 1].
  final double mastery;

  /// Total minutes the student has spent on this topic.
  final int studyMinutes;

  /// When the topic was last studied, or `null` if never.
  final DateTime? lastStudied;

  const TopicInteraction({
    required this.topicId,
    required this.mastery,
    required this.studyMinutes,
    this.lastStudied,
  });
}

/// Item-based KNN recommender that surfaces topics a student should revisit.
class Recommender {
  /// Returns up to [maxResults] topic IDs the student should study next.
  ///
  /// The algorithm:
  /// 1. Builds a feature vector for each topic (mastery, normalised study
  ///    minutes, recency score).
  /// 2. Identifies weak topics (mastery < 0.6).
  /// 3. For every weak topic, finds its [k] nearest neighbours by Euclidean
  ///    distance.
  /// 4. Neighbours that have not been studied recently and are themselves
  ///    weak receive the highest recommendation score.
  /// 5. Returns topic IDs sorted by descending recommendation score.
  ///
  /// Falls back to a simple lowest-mastery-first ordering when fewer than
  /// [k] interactions are available.
  List<String> recommend(
    List<TopicInteraction> interactions, {
    int k = 3,
    int maxResults = 5,
  }) {
    if (interactions.isEmpty) return [];

    // Fallback: not enough data for KNN.
    if (interactions.length < k) {
      final sorted = [...interactions]
        ..sort((a, b) => a.mastery.compareTo(b.mastery));
      return sorted.map((e) => e.topicId).take(maxResults).toList();
    }

    // --- 1. Build feature vectors ---
    final now = DateTime.now();

    final maxMinutes = interactions
        .map((e) => e.studyMinutes)
        .reduce((a, b) => a > b ? a : b);
    final normaliser = maxMinutes > 0 ? maxMinutes.toDouble() : 1.0;

    final vectors = <String, List<double>>{};
    for (final t in interactions) {
      vectors[t.topicId] = [
        t.mastery,
        t.studyMinutes / normaliser,
        _recencyScore(t.lastStudied, now),
      ];
    }

    // --- 2. Identify weak topics ---
    final weakTopics =
        interactions.where((t) => t.mastery < 0.6).toList();

    if (weakTopics.isEmpty) {
      // Nothing weak -- recommend lowest-mastery topics anyway.
      final sorted = [...interactions]
        ..sort((a, b) => a.mastery.compareTo(b.mastery));
      return sorted.map((e) => e.topicId).take(maxResults).toList();
    }

    // --- 3 & 4. KNN scoring ---
    final scores = <String, double>{};

    for (final weak in weakTopics) {
      final weakVec = vectors[weak.topicId]!;

      // Compute distances to every other topic.
      final distances = <_Neighbour>[];
      for (final other in interactions) {
        if (other.topicId == weak.topicId) continue;
        final dist = _euclideanDistance(weakVec, vectors[other.topicId]!);
        distances.add(_Neighbour(other.topicId, dist));
      }

      distances.sort((a, b) => a.distance.compareTo(b.distance));

      final neighbours = distances.take(k);
      for (final n in neighbours) {
        final vec = vectors[n.topicId]!;
        final mastery = vec[0];
        final recency = vec[2];

        // Higher score = more recommended.
        // Prefer low mastery and low recency (not studied recently).
        final score = (1.0 - mastery) + (1.0 - recency);
        scores[n.topicId] = (scores[n.topicId] ?? 0.0) + score;
      }
    }

    // Also include the weak topics themselves (they need work).
    for (final weak in weakTopics) {
      final vec = vectors[weak.topicId]!;
      final score = (1.0 - vec[0]) + (1.0 - vec[2]);
      scores[weak.topicId] = (scores[weak.topicId] ?? 0.0) + score;
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ranked.map((e) => e.key).take(maxResults).toList();
  }

  /// Euclidean distance between two equal-length feature vectors.
  double _euclideanDistance(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Vectors must have the same length.');
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      sum += d * d;
    }
    return sqrt(sum);
  }

  /// Returns a recency score in [0, 1].
  /// 1.0 = studied within the last day, decaying towards 0 over 30 days.
  double _recencyScore(DateTime? lastStudied, DateTime now) {
    if (lastStudied == null) return 0.0;
    final daysSince = now.difference(lastStudied).inDays;
    if (daysSince <= 0) return 1.0;
    if (daysSince >= 30) return 0.0;
    return 1.0 - (daysSince / 30.0);
  }
}

class _Neighbour {
  final String topicId;
  final double distance;

  const _Neighbour(this.topicId, this.distance);
}
