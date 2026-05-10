/// SM-2 spaced repetition algorithm.
///
/// Based on the SuperMemo SM-2 algorithm by Piotr Wozniak.
/// Quality ratings: 0-2 (fail), 3-5 (pass).
class SM2Result {
  const SM2Result({
    required this.interval,
    required this.repetitions,
    required this.easeFactor,
    required this.nextReviewDate,
  });

  /// Number of days until the next review.
  final int interval;

  /// Number of consecutive correct repetitions.
  final int repetitions;

  /// Ease factor (minimum 1.3).
  final double easeFactor;

  /// The date when the card should next be reviewed.
  final DateTime nextReviewDate;

  @override
  String toString() =>
      'SM2Result(interval: $interval, repetitions: $repetitions, '
      'easeFactor: ${easeFactor.toStringAsFixed(2)}, '
      'nextReviewDate: $nextReviewDate)';
}

/// Engine that runs the SM-2 algorithm.
class SM2Engine {
  const SM2Engine();

  /// Minimum allowed ease factor.
  static const double _minEaseFactor = 1.3;

  /// Process a review and return the updated scheduling parameters.
  ///
  /// [quality] must be in the range 0-5.
  /// [repetitions] is the current consecutive-correct count.
  /// [easeFactor] is the current ease factor (default 2.5).
  /// [interval] is the current interval in days.
  SM2Result review(
    int quality, {
    int repetitions = 0,
    double easeFactor = 2.5,
    int interval = 0,
  }) {
    assert(quality >= 0 && quality <= 5, 'Quality must be between 0 and 5');

    final int newRepetitions;
    final int newInterval;
    double newEaseFactor = easeFactor;

    if (quality >= 3) {
      // Correct response.
      newRepetitions = repetitions + 1;
      switch (repetitions) {
        case 0:
          newInterval = 1;
        case 1:
          newInterval = 6;
        default:
          newInterval = (interval * easeFactor).round();
      }
    } else {
      // Incorrect response — reset.
      newRepetitions = 0;
      newInterval = 1;
    }

    // Update ease factor using the SM-2 formula.
    final int q = quality;
    newEaseFactor =
        newEaseFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (newEaseFactor < _minEaseFactor) {
      newEaseFactor = _minEaseFactor;
    }

    final DateTime nextReviewDate =
        DateTime.now().add(Duration(days: newInterval));

    return SM2Result(
      interval: newInterval,
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      nextReviewDate: nextReviewDate,
    );
  }
}
