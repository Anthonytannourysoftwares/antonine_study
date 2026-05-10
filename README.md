# Antonine Study

An on-device AI-powered study assistant for **Antonine University** students. Built with Flutter + pure Dart ML models — no cloud APIs, no LLMs, no generative AI. All intelligence runs locally.

## Features

### Student Verification
- Camera-based ID scanning with ML Kit OCR
- TFLite MobileNetV2 classifier (stub — ready for fine-tuning with real ID images)
- Combined OCR (60%) + classifier (40%) confidence scoring
- SHA-256 hashed ID storage — raw images are never saved

### Smart Study Engine
| Feature | Technique | File |
|---|---|---|
| Spaced Repetition | SM-2 Algorithm | `lib/features/study/domain/sm2.dart` |
| Knowledge Tracing | Bayesian Knowledge Tracing (HMM) | `lib/features/study/domain/bkt.dart` |
| Adaptive Quiz | 1-PL IRT / Rasch Model | `lib/features/study/domain/irt_engine.dart` |
| Recommendations | Item-based KNN | `lib/features/study/domain/recommender.dart` |
| Weakness Detection | Recency-weighted scoring | `lib/features/study/domain/weakness_detector.dart` |
| Time Prediction | Linear regression | `lib/features/study/domain/time_predictor.dart` |
| Topic Clustering | K-means | `lib/features/study/domain/topic_cluster.dart` |
| Grade Forecast | Logistic regression | `lib/features/study/domain/grade_forecaster.dart` |

See [`lib/features/study/README.md`](lib/features/study/README.md) for detailed math explanations of each model.

### Design
- Custom design system with Antonine-inspired brand palette
- Light and dark themes
- Crimson Pro (serif headings) + Plus Jakarta Sans (body) typography
- Animated mastery rings, entry animations, page transitions
- Material 3 throughout

## Setup

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Run tests (46 tests)
flutter test

# Analyze for warnings
flutter analyze
```

### Requirements
- Flutter 3.x (latest stable)
- Dart 3+
- Android SDK / Xcode for respective platforms

## How to Swap `curriculum.json`

The curriculum is schema-driven. Edit `assets/data/curriculum.json`:

```json
{
  "faculties": [
    {
      "id": "faculty_id",
      "name": "Faculty Name",
      "majors": [
        { "id": "major_id", "name": "Major Name" }
      ]
    }
  ],
  "subjects": {
    "major_id": {
      "year_number": {
        "semester_number": [
          {
            "id": "unique_id",
            "code": "CS101",
            "name": "Subject Name",
            "credits": 3,
            "topics": ["Topic 1", "Topic 2", "Topic 3"]
          }
        ]
      }
    }
  }
}
```

No code changes needed — the app reads this file at runtime.

## How to Train the ID Classifier

1. Collect images:
   ```
   train/data/antonine_id/     -- photos of real Antonine University IDs
   train/data/not_antonine_id/ -- photos of other cards, random objects
   ```
   Aim for 50-200 images per class.

2. Install Python dependencies:
   ```bash
   pip install tensorflow pillow numpy
   ```

3. Run the training script:
   ```bash
   python train/train_id_classifier.py
   ```

4. The script outputs `assets/models/id_classifier.tflite`

5. In `lib/features/id_verification/data/ml/id_classifier_service.dart`, set `_useStub = false`

## Project Structure

```
lib/
  main.dart                          -- App entry, Hive init
  app.dart                           -- MaterialApp with theming
  core/
    theme/                           -- Design tokens, themes, typography
    routing/                         -- GoRouter configuration
    widgets/                         -- Reusable design system components
    constants/                       -- App-wide constants
    utils/                           -- Theme provider, app state
  features/
    onboarding/                      -- 3-slide onboarding
    id_verification/
      data/ml/                       -- OCR + TFLite classifier services
      domain/                        -- ID validation logic
      presentation/                  -- Camera + verification screens
    profile/                         -- Major/year/semester selection
    home/                            -- Dashboard, subject grid, bottom nav
    subject/                         -- Subject detail with tabs
    study/
      domain/                        -- All ML algorithms (see table above)
      README.md                      -- Math explanations for viva
    stats/                           -- Charts and analytics
  data/
    local/                           -- Curriculum JSON loader
    repositories/                    -- Hive-based study data persistence
assets/
  data/curriculum.json               -- Editable curriculum data
  models/                            -- TFLite model files
train/
  train_id_classifier.py             -- Python training script
test/                                -- 46 unit tests
```

## Tech Stack

- **Flutter** (latest stable) + **Dart 3+**
- **Riverpod** -- state management
- **GoRouter** -- declarative routing
- **Hive** -- offline-first local database
- **Google ML Kit** -- text recognition (OCR)
- **fl_chart** -- statistics charts
- **flutter_animate** -- entry animations
- **Google Fonts** -- Crimson Pro, Plus Jakarta Sans, JetBrains Mono

## Testing

```bash
flutter test
# 46 tests covering:
# - Design system widgets (AntButton, AntCard, AntProgressRing)
# - Color tokens and theme configuration
# - Curriculum data models and loading
# - ID verification hashing and validation
# - All 8 ML algorithms with synthetic datasets
```

## License

University project -- Antonine University, Lebanon.
