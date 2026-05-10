import 'package:flutter_test/flutter_test.dart';
import 'package:antonine_study/data/local/curriculum_loader.dart';

void main() {
  group('Curriculum models', () {
    test('Faculty.fromJson parses correctly', () {
      final json = {
        'id': 'fea',
        'name': 'Faculty of Engineering',
        'majors': [
          {'id': 'cs', 'name': 'Computer Science'},
        ],
      };
      final faculty = Faculty.fromJson(json);
      expect(faculty.id, 'fea');
      expect(faculty.name, 'Faculty of Engineering');
      expect(faculty.majors.length, 1);
      expect(faculty.majors[0].id, 'cs');
    });

    test('Subject.fromJson parses with topics', () {
      final json = {
        'id': 'cs101',
        'code': 'CS101',
        'name': 'Intro to Programming',
        'credits': 3,
        'topics': ['Variables', 'Functions', 'OOP'],
      };
      final subject = Subject.fromJson(json);
      expect(subject.id, 'cs101');
      expect(subject.code, 'CS101');
      expect(subject.credits, 3);
      expect(subject.topics.length, 3);
    });

    test('Subject.fromJson handles missing topics', () {
      final json = {
        'id': 'x',
        'code': 'X',
        'name': 'Test',
        'credits': 1,
      };
      final subject = Subject.fromJson(json);
      expect(subject.topics, isEmpty);
    });

    test('Curriculum.getSubjects returns correct list', () {
      const curriculum = Curriculum(
        faculties: [],
        subjectsByMajor: {
          'cs': {
            '1': {
              '1': [
                Subject(
                  id: 'cs101',
                  code: 'CS101',
                  name: 'Intro',
                  credits: 3,
                  topics: [],
                ),
              ],
            },
          },
        },
      );
      expect(curriculum.getSubjects('cs', 1, 1).length, 1);
      expect(curriculum.getSubjects('cs', 1, 2), isEmpty);
      expect(curriculum.getSubjects('ba', 1, 1), isEmpty);
    });

    test('Curriculum.getMajorById finds across faculties', () {
      const curriculum = Curriculum(
        faculties: [
          Faculty(
            id: 'f1',
            name: 'Faculty 1',
            majors: [Major(id: 'a', name: 'Major A')],
          ),
          Faculty(
            id: 'f2',
            name: 'Faculty 2',
            majors: [Major(id: 'b', name: 'Major B')],
          ),
        ],
        subjectsByMajor: {},
      );
      expect(curriculum.getMajorById('b')?.name, 'Major B');
      expect(curriculum.getMajorById('z'), isNull);
    });
  });
}
