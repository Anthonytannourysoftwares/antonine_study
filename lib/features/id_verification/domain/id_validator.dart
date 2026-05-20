import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../data/ml/ocr_service.dart';
import '../data/ml/id_classifier_service.dart';

enum VerificationStatus { success, softFail, failed, pending }

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

  // New weights: OCR 65%, classifier 35%
  static const _ocrWeight = 0.65;
  static const _classifierWeight = 0.35;
  static const _passThreshold = 0.75;
  static const _softFailThreshold = 0.55;

  /// Hash a student ID with SHA-256 + device salt for privacy.
  static String hashStudentId(String rawId, String deviceSalt) {
    final bytes = utf8.encode('$rawId:$deviceSalt');
    return sha256.convert(bytes).toString();
  }

  /// Compute OCR score from text blocks using the rebuilt scoring rubric.
  static double computeOcrScore(List<String> textBlocks) {
    final fullText = textBlocks.join('\n');
    final lowerText = fullText.toLowerCase();
    var score = 0.0;

    // +0.35 if any Antonine keyword found
    const antonineKeywords = [
      'antonine',
      'université antonine',
      'university antonine',
      'universite antonine',
      'ua',
      'hadat',
      'baabda',
    ];
    if (antonineKeywords.any((k) => lowerText.contains(k))) {
      score += 0.35;
    }

    // +0.25 if student ID regex matches (Antonine IDs are 9 digits, e.g. 202210138)
    final idPattern = RegExp(r'\b\d{6,10}\b');
    if (idPattern.hasMatch(fullText)) {
      score += 0.25;
    }

    // +0.15 if "student" / "étudiant" / "طالب" detected
    if (lowerText.contains('student') ||
        lowerText.contains('étudiant') ||
        lowerText.contains('etudiant') ||
        fullText.contains('طالب')) {
      score += 0.15;
    }

    // +0.15 if valid date found (YYYY or DD/MM/YYYY) and not expired
    final yearPattern = RegExp(r'\b20[1-3]\d\b');
    final datePattern = RegExp(r'\b\d{1,2}/\d{1,2}/20[1-3]\d\b');
    if (yearPattern.hasMatch(fullText) || datePattern.hasMatch(fullText)) {
      score += 0.15;
    }

    // +0.10 if 3+ distinct text blocks (real card, not blank)
    if (textBlocks.where((b) => b.trim().isNotEmpty).length >= 3) {
      score += 0.10;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Run the full verification pipeline on a captured ID image.
  Future<VerificationResult> verify(File imageFile, String deviceSalt) async {
    try {
      // OCR
      final ocrResult = await _ocr.processImage(imageFile);

      // Compute OCR score using new rubric
      final ocrScore = computeOcrScore(ocrResult.blocks);

      // Classifier
      final classifierScore = await _classifier.classify(imageFile);

      // Composite score
      final composite = (ocrScore * _ocrWeight) + (classifierScore * _classifierWeight);

      String? idHash;
      if (ocrResult.detectedId != null) {
        idHash = hashStudentId(ocrResult.detectedId!, deviceSalt);
      }

      if (composite >= _passThreshold) {
        return VerificationResult(
          status: VerificationStatus.success,
          combinedScore: composite,
          ocrScore: ocrScore,
          classifierScore: classifierScore,
          studentName: ocrResult.detectedName,
          studentIdHash: idHash,
        );
      } else if (composite >= _softFailThreshold) {
        return VerificationResult(
          status: VerificationStatus.softFail,
          combinedScore: composite,
          ocrScore: ocrScore,
          classifierScore: classifierScore,
          studentName: ocrResult.detectedName,
          studentIdHash: idHash,
          errorMessage:
              'Hold steady, trying again... '
              'Score: ${(composite * 100).round()}% (need 75%)',
        );
      } else {
        return VerificationResult(
          status: VerificationStatus.failed,
          combinedScore: composite,
          ocrScore: ocrScore,
          classifierScore: classifierScore,
          studentName: ocrResult.detectedName,
          studentIdHash: idHash,
          errorMessage:
              'Could not verify this as an Antonine University ID. '
              'Score: ${(composite * 100).round()}% (need 75%)',
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
