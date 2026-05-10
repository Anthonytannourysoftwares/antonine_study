# Study Engine — ML Model Documentation

This document explains the machine learning models used in Antonine Study's study engine. All models run **on-device** using pure Dart implementations — no cloud APIs, no LLMs, no generative AI.

---

## 1. SM-2 Spaced Repetition (`sm2.dart`)

### What it does
Schedules flashcard reviews at optimal intervals to maximize long-term retention.

### How it works
The SM-2 algorithm (SuperMemo 2) was created by Piotr Wozniak in 1987. It tracks three values per card:
- **Repetitions (n):** How many times the card has been correctly recalled in a row.
- **Ease Factor (EF):** How easy the card is for this student (starts at 2.5, minimum 1.3).
- **Interval (I):** Days until the next review.

After each review, the student rates their recall quality (0–5):
- **Quality < 3 (fail):** Reset repetitions to 0, interval back to 1 day.
- **Quality ≥ 3 (pass):**
  - 1st repetition: interval = 1 day
  - 2nd repetition: interval = 6 days
  - Subsequent: interval = previous interval × EF

The ease factor updates as:
```
EF' = EF + (0.1 - (5 - q) × (0.08 + (5 - q) × 0.02))
```
where `q` is the quality rating. This means easy cards get reviewed less often, hard cards more often.

### Why SM-2?
It's the most widely validated spaced repetition algorithm, used by Anki and SuperMemo. It requires no training data — it adapts per-card based on the student's performance.

---

## 2. Bayesian Knowledge Tracing (`bkt.dart`)

### What it does
Estimates the probability that a student has truly "learned" a concept, distinguishing between lucky guesses and genuine mastery.

### How it works
BKT uses a Hidden Markov Model with four parameters per skill:
- **P(L₀)** — Prior probability the student already knows the skill (default: 0.3)
- **P(T)** — Probability of learning the skill on each practice opportunity (default: 0.1)
- **P(G)** — Probability of guessing correctly without knowing (default: 0.2)
- **P(S)** — Probability of slipping (answering incorrectly despite knowing) (default: 0.1)

After each student response, we update:

**If correct:**
```
P(L|correct) = P(L) × (1 - P(S)) / [P(L) × (1 - P(S)) + (1 - P(L)) × P(G)]
```

**If incorrect:**
```
P(L|incorrect) = P(L) × P(S) / [P(L) × P(S) + (1 - P(L)) × (1 - P(G))]
```

Then apply the learning transition:
```
P(L_new) = P(L|response) + (1 - P(L|response)) × P(T)
```

A skill is considered **mastered** when P(L) ≥ 0.95.

### Why BKT?
It's the gold standard for knowledge tracing in educational technology, used by systems like Khan Academy. It explicitly models guessing and slipping, giving more accurate mastery estimates than simple percentage-correct.

---

## 3. Item Response Theory — Rasch Model (`irt_engine.dart`)

### What it does
Powers adaptive quizzes by estimating student ability and selecting optimally difficult questions.

### How it works
The 1-Parameter Logistic (1PL / Rasch) model defines the probability of a correct response as:

```
P(correct) = 1 / (1 + exp(-(θ - b)))
```

where:
- **θ** (theta) = student ability (on a logit scale, roughly -3 to +3)
- **b** = item difficulty (same scale)

After each response, we update ability using a gradient step (simplified MLE):
```
θ_new = θ + η × (response - P(correct))
```
where η = 0.4 is the learning rate and response is 1 (correct) or 0 (incorrect).

**Question selection:** The most informative question is the one whose difficulty is closest to the student's current ability estimate (maximum information criterion).

### Why Rasch/1PL?
It's computationally lightweight (no matrix operations needed), runs efficiently on-device, and provides well-calibrated difficulty matching. More complex IRT models (2PL, 3PL) require larger datasets to calibrate; 1PL works well with small question banks.

---

## 4. Weakness Detection (`weakness_detector.dart`)

### What it does
Identifies the topics where the student needs the most help, factoring in both mastery level and study recency.

### How it works
For each topic, compute a weakness score:
```
score = (1 - mastery) × recency_weight
```

The recency weight increases for topics that haven't been studied recently:
- Never studied: weight = 1.0
- Studied today: weight = 0.5
- Studied N days ago: weight = min(N / 7, 2.0), clamped to [0.5, 2.0]

Topics are ranked by score in descending order. The top results appear in the "Today's Focus" card on the home screen.

---

## 5. Study Time Predictor (`time_predictor.dart`)

### What it does
Estimates how many minutes a student should spend on a topic to reach their mastery goal.

### How it works
Simple linear model:
```
minutes = max(5, round(30 × (1 - current_mastery) × (0.5 + difficulty)))
```

Capped at 60 minutes. This gives reasonable estimates:
- Easy topic (difficulty=0.2), high mastery (0.8): ~4 min (capped to 5)
- Hard topic (difficulty=0.9), low mastery (0.2): ~34 min

### Why linear?
For study time prediction, a simple interpretable model outperforms complex ones that might overfit to limited data. The coefficients can be easily adjusted based on real student feedback.

---

## 6. Topic Clustering (`topic_cluster.dart`)

### What it does
Groups related topics together so the app can suggest "study bundles" — topics that share prerequisite knowledge.

### How it works
Standard K-means clustering on topic feature vectors:
1. Initialize k centroids randomly from the topic set
2. Assign each topic to the nearest centroid (Euclidean distance)
3. Recompute centroids as the mean of assigned topics
4. Repeat until convergence or max iterations

Topic features are precomputed vectors (stored in JSON) that encode subject area, difficulty, and prerequisite relationships.

### Why K-means?
It's simple, deterministic for a given seed, and runs in O(n×k×d×iterations) — fast enough for on-device use with typical course sizes (5-50 topics).

---

## 7. Grade Forecaster (`grade_forecaster.dart`)

### What it does
Predicts the probability of passing a course based on current study metrics.

### How it works
Logistic regression with three features:
```
z = 2.5 × mastery + 1.5 × consistency + 1.8 × quiz_accuracy - 3.0
P(pass) = 1 / (1 + exp(-z))
```

where:
- **mastery** (0-1): Overall topic mastery across the course
- **consistency** (0-1): Study streak regularity (studied N of last 14 days)
- **quiz_accuracy** (0-1): Average quiz score

The coefficients are hand-tuned based on educational research showing mastery is the strongest predictor, followed by quiz performance, then consistency.

Grade mapping:
- A: P ≥ 0.85
- B: P ≥ 0.70
- C: P ≥ 0.55
- D: P ≥ 0.40
- F: P < 0.40

### Why logistic regression?
It produces well-calibrated probabilities (unlike decision trees or KNN), is fully interpretable (important for a grade prediction — students should understand why), and requires zero training data to deploy (coefficients derived from literature).

---

## 8. Item-Based KNN Recommender (`recommender.dart`)

### What it does
Suggests which topics to study next based on the student's interaction history.

### How it works
1. Build feature vectors per topic: [mastery, normalized study time, recency score]
2. For weak topics (mastery < 0.6), find k nearest neighbors by Euclidean distance
3. Recommend topics similar to weak areas that haven't been studied recently
4. Fallback: if insufficient data, sort by lowest mastery (cold-start strategy)

### Why item-based KNN?
Collaborative filtering (user-based) requires multiple users. Since all ML runs on-device with a single user's data, item-based similarity is the appropriate approach. KNN is non-parametric and adapts immediately to new study data without retraining.

---

## Summary

| Model | Type | Data needed | Runs on-device | Training required |
|---|---|---|---|---|
| SM-2 | Algorithm | Per-card recall history | Yes | No |
| BKT | Probabilistic (HMM) | Per-skill responses | Yes | No (tuned defaults) |
| IRT (Rasch) | Statistical | Quiz responses | Yes | No |
| Weakness Detector | Heuristic | Mastery + dates | Yes | No |
| Time Predictor | Linear regression | Difficulty + mastery | Yes | No |
| Topic Clustering | K-means | Topic features | Yes | No |
| Grade Forecaster | Logistic regression | 3 aggregate metrics | Yes | No |
| Recommender | KNN | Interaction history | Yes | No |

All models are designed to work with **zero pre-training** and adapt to individual students through their interactions with the app.
