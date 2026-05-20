import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:antonine_study/core/theme/app_theme.dart';
import 'package:antonine_study/core/theme/app_colors.dart';
import 'package:antonine_study/core/widgets/ant_button.dart';
import 'package:antonine_study/core/widgets/ant_card.dart';
import 'package:antonine_study/core/widgets/ant_progress_ring.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppColors', () {
    test('primary color is academic navy', () {
      expect(AppColors.primary, equals(const Color(0xFF1E3A5F)));
    });

    test('surface is warm off-white', () {
      expect(AppColors.surface, equals(const Color(0xFFFAFAF7)));
    });

    test('dark surface is correct', () {
      expect(AppColors.surfaceDark, equals(const Color(0xFF0A1520)));
    });

    test('secondary is muted gold', () {
      expect(AppColors.secondary, equals(const Color(0xFFB8860B)));
    });
  });

  group('AntButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AntButton(
              label: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AntButton(
              label: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });
  });

  group('AntCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AntCard(
              child: Text('Card content'),
            ),
          ),
        ),
      );
      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('is tappable when onTap provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AntCard(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });
  });

  group('AntProgressRing', () {
    testWidgets('shows percentage text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AntProgressRing(
              progress: 0.75,
              animate: false,
            ),
          ),
        ),
      );
      expect(find.text('75%'), findsOneWidget);
    });
  });
}
