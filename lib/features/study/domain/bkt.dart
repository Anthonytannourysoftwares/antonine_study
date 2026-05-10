/// Bayesian Knowledge Tracing (BKT) implementation.
///
/// Models a learner's latent knowledge state as a probability and updates it
/// after each observed response using Bayesian inference.
class BktParams {
  /// Creates BKT parameters with sensible defaults.
  const BktParams({
    this.pInit = 0.3,
    this.pLearn = 0.1,
    this.pGuess = 0.2,
    this.pSlip = 0.1,
  });

  /// Prior probability that the skill is already known.
  final double pInit;

  /// Probability of transitioning from unlearned to learned on each opportunity.
  final double pLearn;

  /// Probability of a correct answer despite not knowing the skill.
  final double pGuess;

  /// Probability of an incorrect answer despite knowing the skill.
  final double pSlip;

  @override
  String toString() =>
      'BktParams(pInit: $pInit, pLearn: $pLearn, '
      'pGuess: $pGuess, pSlip: $pSlip)';
}

/// Engine that runs the BKT update equations.
class BktEngine {
  const BktEngine();

  /// Update the probability of knowledge given an observed response.
  ///
  /// [pKnown] is the current probability that the learner knows the skill.
  /// [correct] indicates whether the learner answered correctly.
  /// [params] contains the BKT model parameters.
  ///
  /// Returns the updated probability of knowledge (0.0 - 1.0).
  double update(double pKnown, bool correct, BktParams params) {
    // Posterior update via Bayes' rule.
    final double pKnownPosterior;

    if (correct) {
      final double pCorrectAndKnown = pKnown * (1 - params.pSlip);
      final double pCorrectAndNotKnown = (1 - pKnown) * params.pGuess;
      pKnownPosterior = pCorrectAndKnown / (pCorrectAndKnown + pCorrectAndNotKnown);
    } else {
      final double pIncorrectAndKnown = pKnown * params.pSlip;
      final double pIncorrectAndNotKnown = (1 - pKnown) * (1 - params.pGuess);
      pKnownPosterior =
          pIncorrectAndKnown / (pIncorrectAndKnown + pIncorrectAndNotKnown);
    }

    // Apply learning transition.
    final double pKnownNew =
        pKnownPosterior + (1 - pKnownPosterior) * params.pLearn;

    return pKnownNew;
  }

  /// Predict the probability of a correct response.
  ///
  /// Uses the law of total probability over the latent knowledge state.
  double predictCorrect(double pKnown, BktParams params) {
    return pKnown * (1 - params.pSlip) + (1 - pKnown) * params.pGuess;
  }

  /// Whether the learner has mastered the skill.
  ///
  /// Returns `true` when [pKnown] meets or exceeds [threshold].
  bool isMastered(double pKnown, {double threshold = 0.95}) {
    return pKnown >= threshold;
  }
}
