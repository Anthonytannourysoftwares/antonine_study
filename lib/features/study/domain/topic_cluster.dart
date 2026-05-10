import 'dart:math';

class TopicCluster {
  const TopicCluster();

  /// Clusters topics into [k] groups using K-means on their feature vectors.
  ///
  /// [topicFeatures] maps topicId to a list of numeric features.
  /// Returns a map of cluster index to the list of topic IDs in that cluster.
  Map<int, List<String>> cluster(
    Map<String, List<double>> topicFeatures, {
    int k = 3,
    int maxIterations = 50,
  }) {
    final topicIds = topicFeatures.keys.toList();
    final n = topicIds.length;

    if (n == 0) return {};

    // Edge case: fewer topics than k -> one cluster per topic.
    if (n <= k) {
      return {
        for (var i = 0; i < n; i++) i: [topicIds[i]],
      };
    }

    final dims = topicFeatures[topicIds.first]!.length;
    final rng = Random(42);

    // Initialize centroids by picking k random distinct topics.
    final indices = List<int>.generate(n, (i) => i)..shuffle(rng);
    var centroids = <List<double>>[
      for (var i = 0; i < k; i++)
        List<double>.from(topicFeatures[topicIds[indices[i]]]!),
    ];

    var assignments = List<int>.filled(n, 0);

    for (var iter = 0; iter < maxIterations; iter++) {
      // Assign each topic to the nearest centroid.
      final newAssignments = List<int>.filled(n, 0);
      for (var i = 0; i < n; i++) {
        final features = topicFeatures[topicIds[i]]!;
        var bestCluster = 0;
        var bestDist = double.infinity;

        for (var c = 0; c < k; c++) {
          final dist = _squaredEuclidean(features, centroids[c]);
          if (dist < bestDist) {
            bestDist = dist;
            bestCluster = c;
          }
        }
        newAssignments[i] = bestCluster;
      }

      // Check convergence.
      var converged = true;
      for (var i = 0; i < n; i++) {
        if (newAssignments[i] != assignments[i]) {
          converged = true; // will be set false below
          converged = false;
          break;
        }
      }
      assignments = newAssignments;

      if (converged && iter > 0) break;

      // Update centroids.
      final newCentroids = List<List<double>>.generate(
        k,
        (_) => List<double>.filled(dims, 0.0),
      );
      final counts = List<int>.filled(k, 0);

      for (var i = 0; i < n; i++) {
        final c = assignments[i];
        final features = topicFeatures[topicIds[i]]!;
        counts[c]++;
        for (var d = 0; d < dims; d++) {
          newCentroids[c][d] += features[d];
        }
      }

      for (var c = 0; c < k; c++) {
        if (counts[c] > 0) {
          for (var d = 0; d < dims; d++) {
            newCentroids[c][d] /= counts[c];
          }
        } else {
          // Empty cluster: reinitialize to a random topic.
          final ri = rng.nextInt(n);
          newCentroids[c] = List<double>.from(topicFeatures[topicIds[ri]]!);
        }
      }

      centroids = newCentroids;
    }

    // Build result map.
    final result = <int, List<String>>{};
    for (var i = 0; i < n; i++) {
      result.putIfAbsent(assignments[i], () => []).add(topicIds[i]);
    }
    return result;
  }

  double _squaredEuclidean(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return sum;
  }
}
