import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Initializes all app services before runApp.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox<dynamic>('streaks');
  await Hive.openBox<Map>('flashcards');
  await Hive.openBox<Map>('quizzes');
  await Hive.openBox<Map>('video_summaries');

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}
