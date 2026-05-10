import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../data/ml/ocr_service.dart';
import '../data/ml/id_classifier_service.dart';

enum VerificationStatus { success, failed, pending }

class VerificationResult {
  const VerificationResult({
    required this.status,
    required this.combinedScore,
    required this.ocrScore,
    required this.classifierScore,
    this.studentName,
    this.studentIdHash,
    this.errorMessage,
  });

  final VerificationStatus status;
  final double combinedScore;
  final double ocrScore;
  final double classifierScore;
  final String? studentName;
  final String? studentIdHash;
  final String? errorMessage;
}

class IdValidator {
  IdValidator({
    OcrService? ocrService,
    IdClassifierService? classifierService,
  })  : _ocr = ocrService ?? OcrService(),
        _classifier = classifierService ?? IdClassifierService();

  final OcrService _ocr;
  final IdClassifierService _classifier;

  // OCR contributes 60%, classifier contributes 40%
  static const _ocrWeight = 0.6;
  static const _classifierWeight = 0.4;
  static const _threshold = 0.7;

  /// Hash a student ID with SHA-256 + device salt for privacy.
  /// Never store the raw ID.
  static String hashStudentId(String rawId, String deviceSalt) {
    final bytes = utf8.encode('$rawId:$deviceSalt');
    return sha256.convert(bytes).toString();
  }

  /// Run the full verification pipeline on a captured ID image.
  Future<VerificationResult> verify(File imageFile, String deviceSalt) async {
    try {
      // Stage B: OCR
      final ocrResult = await _ocr.processImage(imageFile);

      // Stage C: Classifier
      final classifierScore = await _classifier.classify(imageFile);

      // Stage D: Combined decision
      final combinedScore =
          ocrResult.confidence * _ocrWeight + classifierScore * _classifierWeight;

      String? idHash;
      if (ocrResult.detectedId != null) {
        idHash = hashStudentId(ocrResult.detectedId!, deviceSalt);
      }

      if (combinedScore >= _threshold) {
        return VerificationResult(
          status: VerificationStatus.success,
          combinedScore: combinedScore,
          ocrScore: ocrResult.confidence,
          classifierScore: classifierScore,
          studentName: ocrResult.detectedName,
          studentIdHash: idHash,
        );
      } else {
        return VerificationResult(
          status: VerificationStatus.failed,
          combinedScore: combinedScore,
          ocrScore: ocrResult.confidence,
          classifierScore: classifierScore,
          studentName: ocrResult.detectedName,
          studentIdHash: idHash,
          errorMessage:
              'Could not verify this as an Antonine University ID. '
              'Score: ${(combinedScore * 100).round()}% (need 70%)',
        );
      }
    } catch (e) {
      return VerificationResult(
        status: VerificationStatus.failed,
        combinedScore: 0,
        ocrScore: 0,
        classifierScore: 0,
        errorMessage: 'Verification failed: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _ocr.dispose();
    _classifier.dispose();
  }
}
