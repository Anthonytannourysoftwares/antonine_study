import 'dart:convert';
import 'package:flutter/services.dart';

class Faculty {
  const Faculty({required this.id, required this.name, required this.majors});

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'] as String,
      name: json['name'] as String,
      majors: (json['majors'] as List)
          .map((m) => Major.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final List<Major> majors;
}

class Major {
  const Major({required this.id, required this.name});

  factory Major.fromJson(Map<String, dynamic> json) {
    return Major(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;
}

class Subject {
  const Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.topics,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      credits: json['credits'] as int,
      topics: (json['topics'] as List?)?.cast<String>() ?? [],
    );
  }

  final String id;
  final String code;
  final String name;
  final int credits;
  final List<String> topics;
}

class Curriculum {
  const Curriculum({required this.faculties, required this.subjectsByMajor});

  final List<Faculty> faculties;
  // majorId → year → semester → subjects
  final Map<String, Map<String, Map<String, List<Subject>>>> subjectsByMajor;

  List<Major> get allMajors =>
      faculties.expand((f) => f.majors).toList();

  List<Subject> getSubjects(String majorId, int year, int semester) {
    final yearStr = year.toString();
    final semStr = semester.toString();
    return subjectsByMajor[majorId]?[yearStr]?[semStr] ?? [];
  }

  Major? getMajorById(String id) {
    for (final faculty in faculties) {
      for (final major in faculty.majors) {
        if (major.id == id) return major;
      }
    }
    return null;
  }

  Faculty? getFacultyForMajor(String majorId) {
    for (final faculty in faculties) {
      if (faculty.majors.any((m) => m.id == majorId)) return faculty;
    }
    return null;
  }
}

class CurriculumLoader {
  Curriculum? _cached;

  Future<Curriculum> load({String assetPath = 'assets/data/curriculum.json'}) async {
    if (_cached != null) return _cached!;

    final jsonStr = await rootBundle.loadString(assetPath);
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    final faculties = (data['faculties'] as List)
        .map((f) => Faculty.fromJson(f as Map<String, dynamic>))
        .toList();

    final subjectsRaw = data['subjects'] as Map<String, dynamic>;
    final subjectsByMajor =
        <String, Map<String, Map<String, List<Subject>>>>{};

    for (final majorEntry in subjectsRaw.entries) {
      final majorId = majorEntry.key;
      final years = majorEntry.value as Map<String, dynamic>;
      subjectsByMajor[majorId] = {};

      for (final yearEntry in years.entries) {
        final yearStr = yearEntry.key;
        final semesters = yearEntry.value as Map<String, dynamic>;
        subjectsByMajor[majorId]![yearStr] = {};

        for (final semEntry in semesters.entries) {
          final semStr = semEntry.key;
          final subjects = (semEntry.value as List)
              .map((s) => Subject.fromJson(s as Map<String, dynamic>))
              .toList();
          subjectsByMajor[majorId]![yearStr]![semStr] = subjects;
        }
      }
    }

    _cached = Curriculum(
      faculties: faculties,
      subjectsByMajor: subjectsByMajor,
    );
    return _cached!;
  }
}
