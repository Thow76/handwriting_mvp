import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/feedback/feedback_strings.dart';
import 'package:handwriting_mvp/models/formation_score.dart';
import 'package:handwriting_mvp/models/practice_session.dart';
import 'package:handwriting_mvp/models/score_result.dart';
import 'package:handwriting_mvp/models/scoring_level.dart';
import 'package:handwriting_mvp/routes.dart';
import 'package:handwriting_mvp/theme/app_theme.dart';

FormationScore _fs(double v) =>
    FormationScore(overallScore: v, observations: const [], summary: '');

ScoreResult _result({
  double bitmap = 1,
  double? start,
  double? path,
  double? strokes,
}) => ScoreResult(
  coverage: bitmap,
  precision: bitmap,
  placement: bitmap,
  efficiency: bitmap,
  strokeStart: start == null ? null : _fs(start),
  compoundStroke: path == null ? null : _fs(path),
  strokeBreak: strokes == null ? null : _fs(strokes),
);

Future<PracticeSession> _open(
  WidgetTester tester,
  ScoreResult result, {
  List<String> letters = const ['a', 'b'],
  ScoringLevel level = ScoringLevel.full,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = PracticeSession(letters: letters, level: level)
    ..lastResult = result;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      initialRoute: AppRoutes.feedback,
      onGenerateRoute: (settings) {
        final builder =
            AppRoutes.table[settings.name] ?? (_) => const SizedBox.shrink();
        return MaterialPageRoute(
          settings: settings.name == AppRoutes.feedback
              ? RouteSettings(name: settings.name, arguments: session)
              : settings,
          builder: builder,
        );
      },
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

void main() {
  group('bands', () {
    test('thresholds', () {
      expect(bandFor(0.49), FeedbackBand.morePractice);
      expect(bandFor(0.50), FeedbackBand.okay);
      expect(bandFor(0.74), FeedbackBand.okay);
      expect(bandFor(0.75), FeedbackBand.good);
    });

    test('overall is the mean of the scores permitted at the level', () {
      final r = _result(bitmap: 1, start: 0, path: 0, strokes: 0);
      expect(overallScore(r, ScoringLevel.shapeOnly), 1);
      expect(overallScore(r, ScoringLevel.shapeAndStart), closeTo(0.8, 1e-9));
      expect(overallScore(r, ScoringLevel.full), closeTo(4 / 7, 1e-9));
    });

    test('note names the weakest formation score; none for bitmap', () {
      expect(
        feedbackNote(_result(start: 0.2, path: 1), ScoringLevel.full),
        feedbackNotes[ScoreKind.start]!.needsWork,
      );
      expect(
        feedbackNote(_result(bitmap: 0.3, start: 0.9), ScoringLevel.full),
        isNull,
      );
      // Path is not shown at level 2, so it cannot be named there.
      expect(
        feedbackNote(_result(start: 0.9, path: 0), ScoringLevel.shapeAndStart),
        feedbackNotes[ScoreKind.start]!.done,
      );
    });
  });

  testWidgets('More practice: word, ring, note, two buttons', (tester) async {
    await _open(
      tester,
      _result(bitmap: 0.2, start: 0.1),
      level: ScoringLevel.shapeAndStart,
    );
    expect(find.text('More practice'), findsOneWidget);
    expect(find.byKey(const Key('scoreRing')), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.byKey(const Key('tryAgainButton')), findsOneWidget);
    expect(find.byKey(const Key('nextLetterButton')), findsOneWidget);
  });

  testWidgets('Okay: two buttons and a note', (tester) async {
    await _open(
      tester,
      _result(bitmap: 0.7, start: 0.6),
      level: ScoringLevel.shapeAndStart,
    );
    expect(find.text('Okay'), findsOneWidget);
    expect(find.byKey(const Key('tryAgainButton')), findsOneWidget);
    expect(find.byKey(const Key('nextLetterButton')), findsOneWidget);
    expect(find.byKey(const Key('feedbackNote')), findsOneWidget);
  });

  testWidgets('Good: only Next letter; no note when bitmap is weakest', (
    tester,
  ) async {
    await _open(tester, _result(bitmap: 0.8, start: 1, path: 1, strokes: 1));
    expect(find.text('Good'), findsOneWidget);
    expect(find.byKey(const Key('tryAgainButton')), findsNothing);
    expect(find.byKey(const Key('nextLetterButton')), findsOneWidget);
    expect(find.byKey(const Key('feedbackNote')), findsNothing);
  });

  testWidgets('Next letter records the result and moves on', (tester) async {
    final r = _result(bitmap: 0.8, start: 1, path: 1, strokes: 1);
    final session = await _open(tester, r);
    await tester.tap(find.byKey(const Key('nextLetterButton')));
    await tester.pumpAndSettle();
    expect(session.results[0], same(r));
    expect(session.current, 'b');
    expect(find.byKey(const Key('letterCanvas')), findsOneWidget);
  });

  testWidgets('Try again returns to the same letter, nothing recorded', (
    tester,
  ) async {
    final session = await _open(tester, _result(bitmap: 0.6, start: 0.5));
    await tester.tap(find.byKey(const Key('tryAgainButton')));
    await tester.pumpAndSettle();
    expect(session.current, 'a');
    expect(session.results[0], isNull);
    expect(find.byKey(const Key('letterCanvas')), findsOneWidget);
  });

  testWidgets('Next letter on the last letter ends the session', (
    tester,
  ) async {
    await _open(
      tester,
      _result(bitmap: 0.9, start: 1, path: 1, strokes: 1),
      letters: const ['a'],
    );
    await tester.tap(find.byKey(const Key('nextLetterButton')));
    await tester.pumpAndSettle();
    expect(find.text('Session complete'), findsOneWidget);
  });
}
