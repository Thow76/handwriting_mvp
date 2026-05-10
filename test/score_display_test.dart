import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/formation_score.dart';
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
      const result = ScoreResult(coverage: 0.85, precision: 0.72, placement: 0.90, efficiency: 0.80);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('Coverage'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('displays precision percentage', (tester) async {
      const result = ScoreResult(coverage: 0.85, precision: 0.72, placement: 0.90, efficiency: 0.80);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('Precision'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
    });

    testWidgets('displays placement percentage', (tester) async {
      const result = ScoreResult(coverage: 0.85, precision: 0.72, placement: 0.90, efficiency: 0.80);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('Placement'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('rounds percentages to nearest integer', (tester) async {
      const result = ScoreResult(coverage: 0.666, precision: 0.333, placement: 0.555, efficiency: 0.444);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('67%'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('56%'), findsOneWidget);
      expect(find.text('44%'), findsOneWidget);
    });

    testWidgets('displays efficiency percentage', (tester) async {
      const result = ScoreResult(coverage: 0.85, precision: 0.72, placement: 0.90, efficiency: 0.80);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('Efficiency'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('displays 0% for zero scores', (tester) async {
      const result = ScoreResult(coverage: 0.0, precision: 0.0, placement: 0.0, efficiency: 0.0);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('0%'), findsNWidgets(4));
    });

    testWidgets('displays 100% for perfect scores', (tester) async {
      const result = ScoreResult(coverage: 1.0, precision: 1.0, placement: 1.0, efficiency: 1.0);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('100%'), findsNWidgets(4));
    });
  });

  group('ScoreDisplay — formation scores', () {
    testWidgets('shows em-dash for all null formation scores', (tester) async {
      const result = ScoreResult(coverage: 1.0, precision: 1.0, placement: 1.0, efficiency: 1.0);
      await tester.pumpWidget(_app(const ScoreDisplay(result: result)));

      expect(find.text('—'), findsNWidgets(4));
    });

    testWidgets('displays Start label and percentage', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeStart: const FormationScore(overallScore: 0.75, observations: [], summary: ''),
      );
      await tester.pumpWidget(_app(ScoreDisplay(result: result)));

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('displays Direction label and percentage', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeDirection: const FormationScore(overallScore: 0.50, observations: [], summary: ''),
      );
      await tester.pumpWidget(_app(ScoreDisplay(result: result)));

      expect(find.text('Direction'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('displays Path label and percentage', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        compoundStroke: const FormationScore(overallScore: 0.25, observations: [], summary: ''),
      );
      await tester.pumpWidget(_app(ScoreDisplay(result: result)));

      expect(find.text('Path'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('displays Strokes label and percentage', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeBreak: const FormationScore(overallScore: 0.60, observations: [], summary: ''),
      );
      await tester.pumpWidget(_app(ScoreDisplay(result: result)));

      expect(find.text('Strokes'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('shows em-dash for absent formation score alongside present ones', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeStart: const FormationScore(overallScore: 0.80, observations: [], summary: ''),
        // strokeDirection, compoundStroke, strokeBreak are null
      );
      await tester.pumpWidget(_app(ScoreDisplay(result: result)));

      expect(find.text('80%'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(3));
    });

    testWidgets('displays 0% for zero formation score (not em-dash)', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeStart: const FormationScore(overallScore: 0.0, observations: [], summary: ''),
      );
      await tester.pumpWidget(_app(ScoreDisplay(result: result)));

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(3));
    });

    testWidgets('displays 100% for perfect formation score', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeStart: const FormationScore(overallScore: 1.0, observations: [], summary: ''),
        strokeDirection: const FormationScore(overallScore: 1.0, observations: [], summary: ''),
        compoundStroke: const FormationScore(overallScore: 1.0, observations: [], summary: ''),
        strokeBreak: const FormationScore(overallScore: 1.0, observations: [], summary: ''),
      );
      await tester.pumpWidget(_app(ScoreDisplay(result: result)));

      expect(find.text('100%'), findsNWidgets(8));
    });
  });

  group('ScoreDisplay — stroke break suppression', () {
    testWidgets('hides Strokes row when minRequiredStrokes == 1 (e.g. o)', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeBreak: const FormationScore(overallScore: 1.0, observations: [], summary: ''),
      );
      await tester.pumpWidget(
        _app(ScoreDisplay(result: result, minRequiredStrokes: 1)),
      );

      expect(find.text('Strokes'), findsNothing);
    });

    testWidgets('shows Strokes row when minRequiredStrokes == 2 (e.g. t)', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeBreak: const FormationScore(overallScore: 0.80, observations: [], summary: ''),
      );
      await tester.pumpWidget(
        _app(ScoreDisplay(result: result, minRequiredStrokes: 2)),
      );

      expect(find.text('Strokes'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('shows Strokes row when minRequiredStrokes is null (default)', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeBreak: const FormationScore(overallScore: 0.60, observations: [], summary: ''),
      );
      await tester.pumpWidget(_app(ScoreDisplay(result: result)));

      expect(find.text('Strokes'), findsOneWidget);
    });
  });
}
