class TimePredictor {
  const TimePredictor();

  /// Predicts study time in minutes for a topic.
  ///
  /// [topicDifficulty] and [currentMastery] are on a 0-1 scale.
  /// Returns an estimated number of minutes capped to the 5-60 range.
  int predictMinutes(double topicDifficulty, double currentMastery) {
    final difficulty = topicDifficulty.clamp(0.0, 1.0);
    final mastery = currentMastery.clamp(0.0, 1.0);

    final raw = 30.0 * (1.0 - mastery) * (0.5 + difficulty);
    final minutes = raw.round().clamp(5, 60);

    return minutes;
  }
}
