import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/formation_score.dart';
import 'package:handwriting_mvp/models/score_result.dart';
import 'package:handwriting_mvp/widgets/debug_score_view.dart';

/// Wraps a widget in a MaterialApp for testing.
Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DebugScoreView — null result', () {
    testWidgets('shows placeholder when result is null', (tester) async {
      await tester.pumpWidget(_app(const DebugScoreView(result: null)));

      expect(find.text('(no score yet)'), findsOneWidget);
    });
  });

  group('DebugScoreView — bitmap scores', () {
    testWidgets('renders bitmap scores rounded to 2 decimal places',
        (tester) async {
      const result = ScoreResult(
        coverage: 0.856,
        precision: 0.721,
        placement: 0.9,
        efficiency: 0.333,
      );
      await tester.pumpWidget(_app(const DebugScoreView(result: result)));

      expect(find.textContaining('coverage: 0.86'), findsOneWidget);
      expect(find.textContaining('precision: 0.72'), findsOneWidget);
      expect(find.textContaining('placement: 0.90'), findsOneWidget);
      expect(find.textContaining('efficiency: 0.33'), findsOneWidget);
    });

    testWidgets('renders tight bounds when provided', (tester) async {
      const result = ScoreResult(
        coverage: 0.5,
        precision: 0.5,
        placement: 0.5,
        efficiency: 0.5,
      );
      final bounds = Rect.fromLTWH(10, 20, 100, 50);
      await tester.pumpWidget(
        _app(DebugScoreView(result: result, tightBounds: bounds)),
      );

      expect(find.textContaining('tightBounds:'), findsOneWidget);
      expect(find.textContaining('100.0\u00d750.0'), findsOneWidget);
    });
  });

  group('DebugScoreView — null FormationScore (not applicable)', () {
    testWidgets('shows (not applicable) for all null formation scores',
        (tester) async {
      const result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
      );
      await tester.pumpWidget(_app(const DebugScoreView(result: result)));

      expect(find.textContaining('StrokeStartScorer — (not applicable)'), findsOneWidget);
      expect(find.textContaining('CompoundStrokeScorer — (not applicable)'), findsOneWidget);
      expect(find.textContaining('StrokeBreakCounter — (not applicable)'), findsOneWidget);
    });

    testWidgets('shows (not applicable) only for absent scorer', (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeStart: const FormationScore(
          overallScore: 0.8,
          observations: [],
          summary: 'All strokes started in the right place.',
        ),
      );
      await tester.pumpWidget(_app(DebugScoreView(result: result)));

      expect(find.textContaining('StrokeStartScorer — 80%'), findsOneWidget);
      expect(find.textContaining('CompoundStrokeScorer — (not applicable)'), findsOneWidget);
      expect(find.textContaining('StrokeBreakCounter — (not applicable)'), findsOneWidget);
    });
  });

  group('DebugScoreView — formation scorer panels', () {
    testWidgets('renders StrokeStartScorer panel — inside-rect stroke',
        (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeStart: const FormationScore(
          overallScore: 1.0,
          observations: [
            StrokeObservation(
              strokeIndex: 0,
              expected: 'x 0–25%, y 0–15%',
              observed: '(10%, 10%)',
              score: 1.0,
              note: 'Started in the right place.',
            ),
          ],
          summary: 'All strokes started in the right place.',
        ),
      );
      await tester.pumpWidget(_app(DebugScoreView(result: result)));

      // Header line
      expect(find.textContaining('StrokeStartScorer — 100%'), findsOneWidget);
      // Technical column labels
      expect(find.text('Technical'), findsOneWidget);
      expect(find.text('Plain English'), findsOneWidget);
      // Technical column content shows rect label and point label
      expect(find.textContaining('expected=x 0–25%, y 0–15%'), findsOneWidget);
      expect(find.textContaining('observed=(10%, 10%)'), findsOneWidget);
      expect(find.textContaining('score=1.00'), findsOneWidget);
      // Plain-English column content
      expect(find.textContaining('Started in the right place.'), findsOneWidget);
      // Summary
      expect(
        find.textContaining('All strokes started in the right place.'),
        findsOneWidget,
      );
    });

    testWidgets('renders StrokeStartScorer panel — outside-rect stroke',
        (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeStart: const FormationScore(
          overallScore: 0.0,
          observations: [
            StrokeObservation(
              strokeIndex: 0,
              expected: 'x 0–25%, y 0–15%',
              observed: '(75%, 80%)',
              score: 0.0,
              note: 'Started bottom-right; should start in the top-left area.',
            ),
          ],
          summary: 'A stroke started in the wrong place — should start in x 0–25%, y 0–15%.',
        ),
      );
      await tester.pumpWidget(_app(DebugScoreView(result: result)));

      // Header line
      expect(find.textContaining('StrokeStartScorer — 0%'), findsOneWidget);
      // Technical column content shows rect label and point label
      expect(find.textContaining('expected=x 0–25%, y 0–15%'), findsOneWidget);
      expect(find.textContaining('observed=(75%, 80%)'), findsOneWidget);
      expect(find.textContaining('score=0.00'), findsOneWidget);
      // Plain-English directional hint
      expect(
        find.textContaining(
            'Started bottom-right; should start in the top-left area.'),
        findsOneWidget,
      );
      // Summary references the rect label
      expect(
        find.textContaining(
            'A stroke started in the wrong place — should start in x 0–25%, y 0–15%.'),
        findsOneWidget,
      );
    });

    testWidgets('renders CompoundStrokeScorer panel with both columns',
        (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        compoundStroke: const FormationScore(
          overallScore: 1.0,
          observations: [
            StrokeObservation(
              strokeIndex: 0,
              expected: 'top → bottom',
              observed: 'top → bottom',
              score: 1.0,
              note: 'Waypoints matched correctly.',
            ),
          ],
          summary: 'All waypoints matched.',
        ),
      );
      await tester.pumpWidget(_app(DebugScoreView(result: result)));

      expect(find.textContaining('CompoundStrokeScorer — 100%'), findsOneWidget);
      expect(find.textContaining('All waypoints matched.'), findsOneWidget);
    });

    testWidgets('renders StrokeBreakCounter panel with both columns',
        (tester) async {
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeBreak: const FormationScore(
          overallScore: 1.0,
          observations: [
            StrokeObservation(
              strokeIndex: 0,
              expected: '2',
              observed: '2',
              score: 1.0,
              note: 'Stroke count meets the minimum of 2 — correct.',
            ),
          ],
          summary: 'Correct number of strokes.',
        ),
      );
      await tester.pumpWidget(_app(DebugScoreView(result: result)));

      expect(find.textContaining('StrokeBreakCounter — 100%'), findsOneWidget);
      expect(find.textContaining('Correct number of strokes.'), findsOneWidget);
    });

    testWidgets('StrokeBreakCounter panel shown even when it would be suppressed in ScoreDisplay',
        (tester) async {
      // minRequiredStrokes == 1 (like "o") — StrokeBreakCounter is still visible
      // in debug view regardless.
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        strokeBreak: const FormationScore(
          overallScore: 1.0,
          observations: [
            StrokeObservation(
              strokeIndex: 0,
              expected: '1',
              observed: '1',
              score: 1.0,
              note: 'this letter accepts any number of strokes',
            ),
          ],
          summary: 'Stroke count is fine — this letter accepts any number of strokes.',
        ),
      );
      // Pass minRequiredStrokes: 1 — the debug view should still render the panel.
      await tester.pumpWidget(_app(DebugScoreView(result: result)));

      expect(find.textContaining('StrokeBreakCounter — 100%'), findsOneWidget);
    });
  });

  group('DebugScoreView — skipped strokes', () {
    testWidgets('renders skipped compound stroke with em-dash in score column',
        (tester) async {
      const skippedNote = 'skipped — handled by CompoundStrokeScorer';
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        compoundStroke: const FormationScore(
          overallScore: 1.0,
          observations: [
            StrokeObservation(
              strokeIndex: 0,
              expected: 'compound',
              observed: 'compound',
              score: 0.0,
              note: skippedNote,
            ),
          ],
          summary: 'No waypoint-scored strokes were found.',
        ),
      );
      await tester.pumpWidget(_app(DebugScoreView(result: result)));

      // The technical column should show "—" and the skip reason.
      expect(find.textContaining('— ($skippedNote)'), findsOneWidget);
      // The plain-English column should show the skip reason directly.
      expect(find.textContaining(skippedNote), findsNWidgets(2));
    });

    testWidgets('renders skipped dot stroke with em-dash in score column',
        (tester) async {
      const skippedNote = 'skipped — handled by StrokeBreakCounter';
      final result = ScoreResult(
        coverage: 1.0,
        precision: 1.0,
        placement: 1.0,
        efficiency: 1.0,
        compoundStroke: const FormationScore(
          overallScore: 1.0,
          observations: [
            StrokeObservation(
              strokeIndex: 1,
              expected: 'dot',
              observed: 'dot',
              score: 0.0,
              note: skippedNote,
            ),
          ],
          summary: 'No waypoint-scored strokes were found.',
        ),
      );
      await tester.pumpWidget(_app(DebugScoreView(result: result)));

      expect(find.textContaining('— ($skippedNote)'), findsOneWidget);
    });
  });
}
