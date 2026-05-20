import 'package:flutter_test/flutter_test.dart';
import 'package:antonine_study/features/id_verification/domain/id_validator.dart';

void main() {
  group('IdValidator', () {
    test('hashStudentId produces consistent SHA-256 hash', () {
      final hash1 = IdValidator.hashStudentId('12345678', 'salt');
      final hash2 = IdValidator.hashStudentId('12345678', 'salt');
      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 = 64 hex chars
    });

    test('hashStudentId differs with different salt', () {
      final hash1 = IdValidator.hashStudentId('12345678', 'salt1');
      final hash2 = IdValidator.hashStudentId('12345678', 'salt2');
      expect(hash1, isNot(equals(hash2)));
    });

    test('hashStudentId differs with different ID', () {
      final hash1 = IdValidator.hashStudentId('12345678', 'salt');
      final hash2 = IdValidator.hashStudentId('87654321', 'salt');
      expect(hash1, isNot(equals(hash2)));
    });
  });

  group('VerificationResult', () {
    test('success result has correct status', () {
      const result = VerificationResult(
        status: VerificationStatus.success,
        combinedScore: 0.85,
        ocrScore: 0.9,
        classifierScore: 0.8,
        studentName: 'John Doe',
      );
      expect(result.status, equals(VerificationStatus.success));
      expect(result.combinedScore, equals(0.85));
      expect(result.studentName, equals('John Doe'));
    });

    test('failed result includes error message', () {
      const result = VerificationResult(
        status: VerificationStatus.failed,
        combinedScore: 0.3,
        ocrScore: 0.2,
        classifierScore: 0.4,
        errorMessage: 'Not an Antonine ID',
      );
      expect(result.status, equals(VerificationStatus.failed));
      expect(result.errorMessage, isNotNull);
    });
  });

  group('computeOcrScore', () {
    test('clean Antonine ID scores high', () {
      // Simulates a well-scanned real Antonine student ID
      final blocks = [
        'Université Antonine',
        'Student Card',
        'John Khoury',
        '20234567',
        'Valid until 2025',
        'Hadat - Baabda',
      ];
      final score = IdValidator.computeOcrScore(blocks);
      // Should get: +0.35 (antonine keyword) + 0.25 (ID match) +
      //             0.15 (student) + 0.15 (date) + 0.10 (3+ blocks) = 1.0
      expect(score, equals(1.0));
    });

    test('blurry Antonine ID scores moderate', () {
      // Partial OCR — only some text readable
      final blocks = [
        'Antonine',
        'Joh Kh...',
        '2023',
      ];
      final score = IdValidator.computeOcrScore(blocks);
      // +0.35 (antonine) + 0.15 (date 2023) + 0.10 (3 blocks) = 0.60
      expect(score, closeTo(0.60, 0.01));
    });

    test('other university ID scores low', () {
      // A different university card
      final blocks = [
        'Lebanese American University',
        'Student ID',
        'Jane Smith',
        '30098765',
      ];
      final score = IdValidator.computeOcrScore(blocks);
      // +0.25 (ID match) + 0.15 (student) + 0.10 (3+ blocks) = 0.50
      expect(score, closeTo(0.50, 0.01));
    });

    test('blank card scores very low', () {
      // Almost nothing detected
      final blocks = [''];
      final score = IdValidator.computeOcrScore(blocks);
      expect(score, equals(0.0));
    });

    test('expired card still scores for content', () {
      final blocks = [
        'Antonine University',
        'Étudiant',
        'Expired 2019',
        '12345678',
        'Baabda',
      ];
      final score = IdValidator.computeOcrScore(blocks);
      // +0.35 (antonine) + 0.25 (ID) + 0.15 (étudiant) + 0.15 (2019) + 0.10 (5 blocks) = 1.0
      expect(score, equals(1.0));
    });

    test('paper printout with partial text', () {
      // Low quality printout scan
      final blocks = [
        'anton...',
        'some text',
      ];
      final score = IdValidator.computeOcrScore(blocks);
      // No full keyword match, no ID, no date = 0.0
      expect(score, equals(0.0));
    });
  });
}
