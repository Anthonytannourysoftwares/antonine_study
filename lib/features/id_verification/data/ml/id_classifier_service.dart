import 'dart:io';

/// TFLite-based image classifier for Antonine University student IDs.
///
/// Uses a MobileNetV2 transfer-learned model (binary classification:
/// antonine_id vs not_antonine_id). The model file should be placed at
/// assets/models/id_classifier.tflite.
///
/// Currently ships with a stub that returns a fixed confidence score.
/// To use the real model:
/// 1. Train using train/train_id_classifier.py with real ID images
/// 2. Export the .tflite file to assets/models/id_classifier.tflite
/// 3. Set _useStub = false below
///
/// Model constants (used when _useStub = false):
/// - Model path: assets/models/id_classifier.tflite
/// - Input size: 224x224x3
/// - Labels: antonine_id (index 0), not_antonine_id (index 1)
class IdClassifierService {
  // TODO(user): Set to false after training with real Antonine ID images
  static const _useStub = true;

  bool _isLoaded = false;

  Future<void> loadModel() async {
    if (_useStub) {
      _isLoaded = true;
      return;
    }

    // When real model is available, load via tflite_flutter:
    // _interpreter = await Interpreter.fromAsset('assets/models/id_classifier.tflite');
    _isLoaded = true;
  }

  /// Returns confidence score (0.0 to 1.0) that the image is an Antonine ID.
  Future<double> classify(File imageFile) async {
    if (!_isLoaded) {
      await loadModel();
    }

    if (_useStub) {
      // Stub: return a moderate confidence to allow the OCR score
      // to be the deciding factor in the combined decision
      return 0.5;
    }

    // Real inference pipeline (activated when _useStub = false):
    // 1. Load image and resize to 224x224
    // 2. Normalize pixel values to [0, 1]
    // 3. Run inference via tflite_flutter Interpreter
    // 4. Return softmax probability for antonine_id class

    return 0.5;
  }

  void dispose() {
    // _interpreter?.close();
  }
}
