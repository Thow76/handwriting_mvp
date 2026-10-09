import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/completion_checker.dart';
import 'package:handwriting_mvp/models/formation_score.dart';
import 'package:handwriting_mvp/models/practice_session.dart';
import 'package:handwriting_mvp/models/score_result.dart';
import 'package:handwriting_mvp/models/scoring_level.dart';
import 'package:handwriting_mvp/routes.dart';
import 'package:handwriting_mvp/screens/breakdown_screen.dart';
import 'package:handwriting_mvp/theme/app_theme.dart';

FormationScore _fs(double v) =>
    FormationScore(overallScore: v, observations: const [], summary: '');

ScoreResult _result({
  required double start,
  required double path,
  required CompletionResult completion,
}) => ScoreResult(
  coverage: 0.95,
  precision: 0.95,
  placement: 0.95,
  efficiency: 0.95,
  strokeStart: _fs(start),
  compoundStroke: _fs(path),
  completion: completion,
);

const _done = CompletionResult(complete: true, missingSections: []);
const _notDone = CompletionResult(complete: false, missingSections: [5, 6, 7]);

Future<void> _pumpRoute(
  WidgetTester tester,
  String route,
  Object arguments,
) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      theme: buildAppTheme(),
      initialRoute: route,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: RouteSettings(name: settings.name, arguments: arguments),
        builder: AppRoutes.table[settings.name]!,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _level = ScoringLevel.shapeStartAndPath;

/// The word each of the three screens shows for [result].
Future<List<String>> _wordsOnEachScreen(
  WidgetTester tester,
  ScoreResult result,
) async {
  final words = <String>[];
  const all = ['More practice', 'Okay', 'Good'];

  final feedbackSession = PracticeSession(
    letters: const ['a', 'b'],
    level: _level,
  )..lastResult = result;
  await _pumpRoute(tester, AppRoutes.feedback, feedbackSession);
  words.add(all.singleWhere((w) => find.text(w).evaluate().isNotEmpty));

  final doneSession = PracticeSession(
    letters: const ['a', 'b'],
    level: _level,
    index: 1,
  );
  doneSession.results[0] = result;
  await _pumpRoute(tester, AppRoutes.sessionComplete, doneSession);
  words.add(all.singleWhere((w) => find.text(w).evaluate().isNotEmpty));

  await _pumpRoute(
    tester,
    AppRoutes.breakdown,
    BreakdownArgs(
      session: PracticeSession(letters: const ['a', 'b'], level: _level),
      letter: 'a',
      result: result,
      continueRoute: AppRoutes.sessionComplete,
    ),
  );
  final text = tester.widget<Text>(find.byKey(const Key('breakdownBand')));
  words.add(all.singleWhere((w) => text.data!.contains(w)));
  return words;
}

void main() {
  testWidgets('unfinished letter: all three screens say More practice', (
    tester,
  ) async {
    final words = await _wordsOnEachScreen(
      tester,
      _result(start: 1, path: 1, completion: _notDone),
    );
    expect(words, ['More practice', 'More practice', 'More practice']);
  });

  testWidgets('wrong path: all three screens say Okay', (tester) async {
    final words = await _wordsOnEachScreen(
      tester,
      _result(start: 1, path: 0, completion: _done),
    );
    expect(words, ['Okay', 'Okay', 'Okay']);
  });

  testWidgets('good letter: all three screens say Good', (tester) async {
    final words = await _wordsOnEachScreen(
      tester,
      _result(start: 1, path: 1, completion: _done),
    );
    expect(words, ['Good', 'Good', 'Good']);
  });

  group('Breakdown screen', () {
    Future<void> open(WidgetTester tester, ScoreResult result) => _pumpRoute(
      tester,
      AppRoutes.breakdown,
      BreakdownArgs(
        session: PracticeSession(letters: const ['a'], level: _level),
        letter: 'a',
        result: result,
        continueRoute: AppRoutes.sessionComplete,
      ),
    );

    testWidgets('unfinished: Complete row, reason line and Copy text', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await open(tester, _result(start: 1, path: 1, completion: _notDone));
      expect(find.byKey(const Key('row_Complete')), findsOneWidget);
      expect(find.text('no (zones 5, 6, 7 empty)'), findsOneWidget);
      expect(
        find.text('Letter not finished (no ink in zone 5, 6, 7)'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('copyButton')));
      await tester.pumpAndSettle();
      expect(copied, contains(' · Complete no (5,6,7) · '));
      expect(
        copied,
        endsWith(
          'app said More practice (97) · guardrail: letter not finished',
        ),
      );
    });

    testWidgets('complete: yes, and no reason line', (tester) async {
      await open(tester, _result(start: 1, path: 1, completion: _done));
      expect(find.text('yes'), findsOneWidget);
      expect(find.byKey(const Key('breakdownReason')), findsNothing);
    });

    testWidgets('wrong path: reason line names the path', (tester) async {
      await open(tester, _result(start: 1, path: 0, completion: _done));
      expect(find.text('Path was wrong'), findsOneWidget);
    });
  });
}
