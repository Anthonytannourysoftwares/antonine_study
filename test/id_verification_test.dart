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
}
