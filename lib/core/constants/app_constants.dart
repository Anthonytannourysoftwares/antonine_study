abstract final class AppConstants {
  static const String appName = 'Antonine Study';
  static const String universityName = 'Antonine University';
  static const String universityNameFr = 'Universit\u00e9 Antonine';

  static const Duration splashDuration = Duration(milliseconds: 1200);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 400);

  static const String curriculumAssetPath = 'assets/data/curriculum.json';
  static const String idClassifierModelPath = 'assets/models/id_classifier.tflite';

  // Shared preferences keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyProfileComplete = 'profile_complete';
  static const String keyIdVerified = 'id_verified';
  static const String keyThemeMode = 'theme_mode';
  static const String keyStudentFirstName = 'student_first_name';
  static const String keyMajorId = 'major_id';
  static const String keyYear = 'year';
  static const String keySemester = 'semester';
}
