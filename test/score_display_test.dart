import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/score_result.dart';
import 'package:handwriting_mvp/widgets/score_display.dart';

/// Wraps a widget in a MaterialApp for testing.
Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ScoreDisplay', () {
    testWidgets('is invisible when result is null', (tester) async {
      await tester.pumpWidget(_app(const ScoreDisplay(result: null)));

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.0);
    });

    testWidgets('displays coverage percentage', (tester) async {
      const result = ScoreResult(coverage: 0.85, precision: 0.72, placement: 0.90);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('Coverage'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('displays precision percentage', (tester) async {
      const result = ScoreResult(coverage: 0.85, precision: 0.72, placement: 0.90);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('Precision'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
    });

    testWidgets('displays placement percentage', (tester) async {
      const result = ScoreResult(coverage: 0.85, precision: 0.72, placement: 0.90);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('Placement'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('rounds percentages to nearest integer', (tester) async {
      const result = ScoreResult(coverage: 0.666, precision: 0.333, placement: 0.555);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('67%'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('56%'), findsOneWidget);
    });

    testWidgets('displays 0% for zero scores', (tester) async {
      const result = ScoreResult(coverage: 0.0, precision: 0.0, placement: 0.0);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('0%'), findsNWidgets(3));
    });

    testWidgets('displays 100% for perfect scores', (tester) async {
      const result = ScoreResult(coverage: 1.0, precision: 1.0, placement: 1.0);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('100%'), findsNWidgets(3));
    });
  });
}
