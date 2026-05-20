import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

class Professor {
  final String id;
  final String fullName;
  final String title;
  final String facultyId;
  final String? bio;
  final String? avatarUrl;
  final String? email;
  final String? office;
  final double ratingAvg;
  final int ratingCount;
  final List<String> tags;

  Professor({
    required this.id,
    required this.fullName,
    required this.title,
    required this.facultyId,
    this.bio,
    this.avatarUrl,
    this.email,
    this.office,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.tags = const [],
  });

  factory Professor.fromJson(Map<String, dynamic> json) {
    return Professor(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      title: json['title'] as String? ?? 'Dr.',
      facultyId: json['faculty_id'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      office: json['office'] as String?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
    );
  }
}

class Section {
  final String id;
  final String courseId;
  final String professorId;
  final String semesterCode;
  final int capacity;
  final int enrolledCount;
  final List<ScheduleSlot> schedule;
  final Professor? professor;

  Section({
    required this.id,
    required this.courseId,
    required this.professorId,
    required this.semesterCode,
    this.capacity = 30,
    this.enrolledCount = 0,
    this.schedule = const [],
    this.professor,
  });

  bool get isFull => enrolledCount >= capacity;

  factory Section.fromJson(Map<String, dynamic> json) {
    final scheduleList = (json['schedule'] as List?)
            ?.map((s) => ScheduleSlot.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    final profJson = json['professor'];
    return Section(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      professorId: json['professor_id'] as String,
      semesterCode: json['semester_code'] as String,
      capacity: json['capacity'] as int? ?? 30,
      enrolledCount: json['enrolled_count'] as int? ?? 0,
      schedule: scheduleList,
      professor: profJson is Map<String, dynamic> ? Professor.fromJson(profJson) : null,
    );
  }
}

class ScheduleSlot {
  final String day;
  final String start;
  final String end;
  final String room;

  ScheduleSlot({
    required this.day,
    required this.start,
    required this.end,
    required this.room,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      day: json['day'] as String,
      start: json['start'] as String,
      end: json['end'] as String,
      room: json['room'] as String? ?? '',
    );
  }

  String get display => '$day $start\u2013$end';
}

class Review {
  final String id;
  final int rating;
  final List<String> tags;
  final String? comment;
  final String createdAt;

  Review({
    required this.id,
    required this.rating,
    this.tags = const [],
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      rating: json['rating'] as int,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      comment: json['comment'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ProfessorsRepository {
  final ApiClient _api;

  ProfessorsRepository(this._api);

  Future<List<Professor>> listProfessors({String? facultyId}) async {
    final params = <String, String>{};
    if (facultyId != null) params['faculty_id'] = facultyId;
    final data = await _api.get('/professors', queryParams: params);
    return (data as List).map((e) => Professor.fromJson(e)).toList();
  }

  Future<List<Section>> listSections({String? courseId, String? semesterCode}) async {
    final params = <String, String>{};
    if (courseId != null) params['course_id'] = courseId;
    if (semesterCode != null) params['semester_code'] = semesterCode;
    final data = await _api.get('/sections', queryParams: params);
    return (data as List).map((e) => Section.fromJson(e)).toList();
  }

  Future<List<Review>> getReviews(String professorId) async {
    final data = await _api.get('/reviews', queryParams: {'professor_id': professorId});
    return (data as List).map((e) => Review.fromJson(e)).toList();
  }
}

final professorsRepositoryProvider = Provider<ProfessorsRepository>((ref) {
  return ProfessorsRepository(ref.watch(apiClientProvider));
});
