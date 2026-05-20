import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'professors_repository.dart';

class Enrollment {
  final String id;
  final String studentId;
  final String courseId;
  final String? sectionId;
  final String semesterCode;
  final String status;
  final Section? section;
  final Professor? professor;

  Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    this.sectionId,
    required this.semesterCode,
    this.status = 'enrolled',
    this.section,
    this.professor,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    final sectionJson = json['section'];
    final profJson = json['professor'];
    return Enrollment(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      courseId: json['course_id'] as String,
      sectionId: json['section_id'] as String?,
      semesterCode: json['semester_code'] as String,
      status: json['status'] as String? ?? 'enrolled',
      section: sectionJson is Map<String, dynamic> ? Section.fromJson(sectionJson) : null,
      professor: profJson is Map<String, dynamic> ? Professor.fromJson(profJson) : null,
    );
  }
}

class ValidationResult {
  final bool valid;
  final List<String> errors;

  ValidationResult({required this.valid, this.errors = const []});

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      valid: json['valid'] as bool? ?? false,
      errors: (json['errors'] as List?)?.cast<String>() ?? [],
    );
  }
}

class EnrollmentRepository {
  final ApiClient _api;

  EnrollmentRepository(this._api);

  Future<List<Enrollment>> listEnrollments({
    required String studentId,
    String? semesterCode,
  }) async {
    final params = <String, String>{'student_id': studentId};
    if (semesterCode != null) params['semester_code'] = semesterCode;
    final data = await _api.get('/enrollments', queryParams: params);
    return (data as List).map((e) => Enrollment.fromJson(e)).toList();
  }

  Future<Enrollment> enroll({
    required String studentId,
    required String courseId,
    required String sectionId,
    required String semesterCode,
  }) async {
    final data = await _api.post('/enrollments', body: {
      'student_id': studentId,
      'course_id': courseId,
      'section_id': sectionId,
      'semester_code': semesterCode,
    });
    return Enrollment.fromJson(data);
  }

  Future<ValidationResult> validate({
    required String studentId,
    required String courseId,
    required String sectionId,
    required String semesterCode,
  }) async {
    final data = await _api.post('/enrollments/validate', body: {
      'student_id': studentId,
      'course_id': courseId,
      'section_id': sectionId,
      'semester_code': semesterCode,
    });
    return ValidationResult.fromJson(data);
  }

  Future<void> drop(String enrollmentId) async {
    await _api.delete('/enrollments/$enrollmentId');
  }

  Future<void> updateSection(String enrollmentId, String sectionId) async {
    await _api.put('/enrollments/$enrollmentId', body: {
      'section_id': sectionId,
    });
  }
}

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository(ref.watch(apiClientProvider));
});
