import 'dart:math';

/// A question with a calibrated difficulty on the logit scale.
class IrtQuestion {
  final String id;

  /// Difficulty parameter on the logit scale (roughly -3 to +3).
  final double difficulty;

  final String topic;

  const IrtQuestion({
    required this.id,
    required this.difficulty,
    required this.topic,
  });
}

/// 1-Parameter IRT (Rasch model) adaptive quiz engine.
///
/// Maintains a running estimate of student ability ([_theta]) and selects
/// the most informative next question from a pool.
class IrtEngine {
  double _theta = 0.0;

  /// Current ability estimate on the logit scale.
  double get ability => _theta;

  /// Returns P(correct) under the Rasch model:
  /// P = 1 / (1 + exp(-(theta - difficulty)))
  double probability(double difficulty) {
    return 1.0 / (1.0 + exp(-(_theta - difficulty)));
  }

  /// Performs a single MLE gradient-ascent step after the student responds.
  ///
  /// Uses a fixed learning rate of 0.4.
  void updateAbility(double difficulty, {required bool correct}) {
    final p = probability(difficulty);
    final response = correct ? 1.0 : 0.0;
    _theta += 0.4 * (response - p);
  }

  /// Selects the most informative question from [available].
  ///
  /// Under the Rasch model, maximum information is obtained when the
  /// question difficulty is closest to the current ability estimate.
  IrtQuestion selectNext(List<IrtQuestion> available) {
    assert(available.isNotEmpty, 'Available question pool must not be empty.');

    IrtQuestion best = available.first;
    double bestDelta = (_theta - best.difficulty).abs();

    for (var i = 1; i < available.length; i++) {
      final delta = (_theta - available[i].difficulty).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = available[i];
      }
    }

    return best;
  }

  /// Resets the ability estimate to zero (uninformative prior).
  void reset() {
    _theta = 0.0;
  }
}
