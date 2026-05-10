import 'dart:math';

class GradeForecaster {
  const GradeForecaster();

  /// Predicts the probability of passing based on study metrics.
  ///
  /// All inputs are on a 0-1 scale.
  /// Returns a calibrated probability between 0 and 1.
  double predictPassProbability(
    double overallMastery,
    double studyConsistency,
    double quizAccuracy,
  ) {
    final mastery = overallMastery.clamp(0.0, 1.0);
    final consistency = studyConsistency.clamp(0.0, 1.0);
    final accuracy = quizAccuracy.clamp(0.0, 1.0);

    final z = 2.5 * mastery + 1.5 * consistency + 1.8 * accuracy - 3.0;
    return 1.0 / (1.0 + exp(-z));
  }

  /// Returns a letter grade label for the given pass probability.
  String gradeLabel(double probability) {
    if (probability >= 0.85) return 'A';
    if (probability >= 0.7) return 'B';
    if (probability >= 0.55) return 'C';
    if (probability >= 0.4) return 'D';
    return 'F';
  }
}
