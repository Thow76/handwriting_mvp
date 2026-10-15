import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/practice_session.dart';
import 'package:handwriting_mvp/models/score_result.dart';
import 'package:handwriting_mvp/models/scoring_level.dart';
import 'package:handwriting_mvp/routes.dart';
import 'package:handwriting_mvp/theme/app_theme.dart';

ScoreResult _result(double v) =>
    ScoreResult(coverage: v, precision: v, placement: v, efficiency: v);

Future<PracticeSession> _open(
  WidgetTester tester,
  List<String> letters,
  List<double> scores, {
  ScoringLevel level = ScoringLevel.shapeOnly,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = PracticeSession(
    letters: letters,
    level: level,
    index: letters.length - 1,
  );
  for (var i = 0; i < scores.length; i++) {
    session.results[i] = _result(scores[i]);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      initialRoute: AppRoutes.sessionComplete,
      onGenerateRoute: (settings) {
        final builder =
            AppRoutes.table[settings.name] ?? (_) => const SizedBox.shrink();
        return MaterialPageRoute(
          settings: settings.name == AppRoutes.sessionComplete
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
  testWidgets('several letters: a row per letter with its word', (
    tester,
  ) async {
    await _open(tester, ['a', 'b', 'c'], [0.9, 0.6, 0.2]);
    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('You practised 3 letters'), findsOneWidget);
    expect(find.byKey(const Key('resultList')), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Okay'), findsOneWidget);
    expect(find.text('More practice'), findsOneWidget);
    expect(find.byKey(const Key('ring_a')), findsOneWidget);
    expect(find.byKey(const Key('ring_c')), findsOneWidget);
  });

  testWidgets('one letter, level 2: big letter with ring and word', (
    tester,
  ) async {
    await _open(tester, ['a'], [0.9], level: ScoringLevel.shapeAndStart);
    expect(find.byKey(const Key('resultList')), findsNothing);
    expect(find.byKey(const Key('bigLetter')), findsOneWidget);
    expect(find.byKey(const Key('ring_a')), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.byKey(const Key('tick')), findsNothing);
    expect(find.text('Practice again'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('one letter, level 1: big letter with a tick, no ring or word', (
    tester,
  ) async {
    await _open(tester, ['a'], [0.9]);
    expect(find.byKey(const Key('resultList')), findsNothing);
    expect(find.byKey(const Key('bigLetter')), findsOneWidget);
    expect(find.byKey(const Key('tick')), findsOneWidget);
    expect(find.byKey(const Key('ring_a')), findsNothing);
    expect(find.text('Good'), findsNothing);
    expect(find.text('Practice again'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Practice again restarts the same set at the first letter', (
    tester,
  ) async {
    await _open(tester, ['a', 'b'], [0.9, 0.9]);
    await tester.tap(find.byKey(const Key('practiceAgainButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('letterCanvas')), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);
  });

  testWidgets('Home returns to the Home screen', (tester) async {
    await _open(tester, ['a', 'b'], [0.9, 0.9]);
    await tester.tap(find.byKey(const Key('homeButton')));
    await tester.pumpAndSettle();
    expect(find.text('Session complete'), findsNothing);
    expect(find.text('Practice'), findsWidgets);
  });
}
