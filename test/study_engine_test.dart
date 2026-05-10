import 'package:flutter_test/flutter_test.dart';
import 'package:antonine_study/features/study/domain/sm2.dart';
import 'package:antonine_study/features/study/domain/bkt.dart';
import 'package:antonine_study/features/study/domain/irt_engine.dart';
import 'package:antonine_study/features/study/domain/weakness_detector.dart';
import 'package:antonine_study/features/study/domain/time_predictor.dart';
import 'package:antonine_study/features/study/domain/topic_cluster.dart';
import 'package:antonine_study/features/study/domain/grade_forecaster.dart';
import 'package:antonine_study/features/study/domain/recommender.dart';

void main() {
  // --- SM-2 Tests ---
  group('SM2Engine', () {
    test('first correct review gives interval of 1', () {
      const engine = SM2Engine();
      final result = engine.review(4);
      expect(result.interval, 1);
      expect(result.repetitions, 1);
    });

    test('second correct review gives interval of 6', () {
      const engine = SM2Engine();
      final r1 = engine.review(4);
      final r2 = engine.review(
        4,
        repetitions: r1.repetitions,
        easeFactor: r1.easeFactor,
        interval: r1.interval,
      );
      expect(r2.interval, 6);
      expect(r2.repetitions, 2);
    });

    test('failed review resets to interval 1', () {
      const engine = SM2Engine();
      final r1 = engine.review(4);
      final r2 = engine.review(
        1,
        repetitions: r1.repetitions,
        easeFactor: r1.easeFactor,
        interval: r1.interval,
      );
      expect(r2.interval, 1);
      expect(r2.repetitions, 0);
    });

    test('ease factor does not go below 1.3', () {
      const engine = SM2Engine();
      var result = engine.review(0);
      result = engine.review(0,
          repetitions: result.repetitions,
          easeFactor: result.easeFactor,
          interval: result.interval);
      result = engine.review(0,
          repetitions: result.repetitions,
          easeFactor: result.easeFactor,
          interval: result.interval);
      expect(result.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('perfect reviews increase ease factor', () {
      const engine = SM2Engine();
      final r1 = engine.review(5);
      expect(r1.easeFactor, greaterThan(2.5));
    });
  });

  // --- BKT Tests ---
  group('BktEngine', () {
    test('correct answer increases knowledge probability', () {
      const engine = BktEngine();
      const params = BktParams();
      final updated = engine.update(0.3, true, params);
      expect(updated, greaterThan(0.3));
    });

    test('incorrect answer with low initial knowledge stays low', () {
      const engine = BktEngine();
      const params = BktParams();
      final updated = engine.update(0.1, false, params);
      expect(updated, lessThan(0.3));
    });

    test('mastery check at 0.95 threshold', () {
      const engine = BktEngine();
      expect(engine.isMastered(0.96), isTrue);
      expect(engine.isMastered(0.94), isFalse);
    });

    test('predict correct probability is bounded', () {
      const engine = BktEngine();
      const params = BktParams();
      final p = engine.predictCorrect(0.5, params);
      expect(p, greaterThan(0.0));
      expect(p, lessThan(1.0));
    });

    test('knowledge approaches 1.0 after many correct answers', () {
      const engine = BktEngine();
      const params = BktParams();
      var pKnown = 0.3;
      for (var i = 0; i < 20; i++) {
        pKnown = engine.update(pKnown, true, params);
      }
      expect(pKnown, greaterThan(0.9));
    });
  });

  // --- IRT Tests ---
  group('IrtEngine', () {
    test('initial ability is 0', () {
      final engine = IrtEngine();
      expect(engine.ability, 0.0);
    });

    test('probability is 0.5 when ability equals difficulty', () {
      final engine = IrtEngine();
      final p = engine.probability(0.0);
      expect(p, closeTo(0.5, 0.01));
    });

    test('correct answer increases ability', () {
      final engine = IrtEngine();
      engine.updateAbility(0.0, correct: true);
      expect(engine.ability, greaterThan(0.0));
    });

    test('incorrect answer decreases ability', () {
      final engine = IrtEngine();
      engine.updateAbility(0.0, correct: false);
      expect(engine.ability, lessThan(0.0));
    });

    test('selectNext picks question closest to ability', () {
      final engine = IrtEngine();
      const questions = [
        IrtQuestion(id: 'easy', difficulty: -2.0, topic: 'A'),
        IrtQuestion(id: 'medium', difficulty: 0.0, topic: 'B'),
        IrtQuestion(id: 'hard', difficulty: 2.0, topic: 'C'),
      ];
      final selected = engine.selectNext(questions);
      expect(selected.id, 'medium');
    });
  });

  // --- Weakness Detector Tests ---
  group('WeaknessDetector', () {
    test('detects weakest topics first', () {
      const detector = WeaknessDetector();
      final results = detector.detect({
        'cs101': {
          'Variables': 0.9,
          'Functions': 0.2,
          'OOP': 0.5,
        },
      });
      expect(results.first.topicId, 'Functions');
    });

    test('limits results to maxResults', () {
      const detector = WeaknessDetector();
      final results = detector.detect(
        {
          'cs101': {
            'A': 0.1,
            'B': 0.2,
            'C': 0.3,
            'D': 0.4,
          },
        },
        maxResults: 2,
      );
      expect(results.length, 2);
    });
  });

  // --- Time Predictor Tests ---
  group('TimePredictor', () {
    test('easy topic with high mastery returns minimum', () {
      const predictor = TimePredictor();
      final minutes = predictor.predictMinutes(0.2, 0.9);
      expect(minutes, greaterThanOrEqualTo(5));
    });

    test('hard topic with low mastery returns more time', () {
      const predictor = TimePredictor();
      final minutes = predictor.predictMinutes(0.9, 0.1);
      expect(minutes, greaterThan(20));
    });

    test('result is capped at 60', () {
      const predictor = TimePredictor();
      final minutes = predictor.predictMinutes(1.0, 0.0);
      expect(minutes, lessThanOrEqualTo(60));
    });
  });

  // --- Topic Cluster Tests ---
  group('TopicCluster', () {
    test('clusters topics into k groups', () {
      const clusterer = TopicCluster();
      final features = {
        'a': [0.0, 0.0],
        'b': [0.1, 0.1],
        'c': [5.0, 5.0],
        'd': [5.1, 5.1],
      };
      final clusters = clusterer.cluster(features, k: 2);
      expect(clusters.length, 2);
      final allTopics = clusters.values.expand((v) => v).toSet();
      expect(allTopics.length, 4);
    });

    test('handles fewer topics than k', () {
      const clusterer = TopicCluster();
      final features = {
        'a': [0.0],
        'b': [1.0],
      };
      final clusters = clusterer.cluster(features, k: 5);
      expect(clusters.values.expand((v) => v).length, 2);
    });
  });

  // --- Grade Forecaster Tests ---
  group('GradeForecaster', () {
    test('high metrics predict high pass probability', () {
      const forecaster = GradeForecaster();
      final p = forecaster.predictPassProbability(0.9, 0.9, 0.9);
      expect(p, greaterThan(0.8));
    });

    test('low metrics predict low pass probability', () {
      const forecaster = GradeForecaster();
      final p = forecaster.predictPassProbability(0.1, 0.1, 0.1);
      expect(p, lessThan(0.3));
    });

    test('grade labels are correct', () {
      const forecaster = GradeForecaster();
      expect(forecaster.gradeLabel(0.90), 'A');
      expect(forecaster.gradeLabel(0.75), 'B');
      expect(forecaster.gradeLabel(0.60), 'C');
      expect(forecaster.gradeLabel(0.45), 'D');
      expect(forecaster.gradeLabel(0.30), 'F');
    });
  });

  // --- Recommender Tests ---
  group('Recommender', () {
    test('recommends weak topics first', () {
      final recommender = Recommender();
      final interactions = [
        TopicInteraction(
          topicId: 'strong',
          mastery: 0.9,
          studyMinutes: 60,
          lastStudied: DateTime.now(),
        ),
        TopicInteraction(
          topicId: 'weak',
          mastery: 0.1,
          studyMinutes: 5,
          lastStudied: DateTime.now().subtract(const Duration(days: 7)),
        ),
        TopicInteraction(
          topicId: 'medium',
          mastery: 0.5,
          studyMinutes: 30,
          lastStudied: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
      final results = recommender.recommend(interactions);
      expect(results.first, 'weak');
    });

    test('handles empty interactions', () {
      final recommender = Recommender();
      final results = recommender.recommend([]);
      expect(results, isEmpty);
    });
  });
}
