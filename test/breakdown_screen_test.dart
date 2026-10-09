import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/feedback/feedback_strings.dart';
import 'package:handwriting_mvp/models/practice_session.dart';
import 'package:handwriting_mvp/models/score_result.dart';
import 'package:handwriting_mvp/models/scoring_level.dart';
import 'package:handwriting_mvp/routes.dart';
import 'package:handwriting_mvp/screens/breakdown_screen.dart';
import 'package:handwriting_mvp/theme/app_theme.dart';
import 'package:handwriting_mvp/tester_mode.dart';

const _bitmapOnly = ScoreResult(
  coverage: 0.45,
  precision: 1.0,
  placement: 1.0,
  efficiency: 0.44,
);

Future<void> _open(
  WidgetTester tester,
  ScoringLevel level,
  ScoreResult result,
) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = PracticeSession(letters: const ['b'], level: level);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.breakdown,
              arguments: BreakdownArgs(
                session: session,
                letter: 'b',
                result: result,
                continueRoute: AppRoutes.sessionComplete,
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
      routes: {...AppRoutes.table}..remove(AppRoutes.home),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => TesterMode.enabled.value = false);

  const names = [
    'Coverage',
    'Precision',
    'Placement',
    'Efficiency',
    'Start',
    'Path',
    'Strokes',
  ];

  testWidgets('level 1: seven rows, bitmap counted, formation not', (
    tester,
  ) async {
    await _open(tester, ScoringLevel.shapeOnly, _bitmapOnly);
    for (final n in names) {
      expect(find.byKey(Key('row_$n')), findsOneWidget);
    }
    expect(find.text('counts at this level'), findsNWidgets(4));
    expect(find.text('not counted at this level'), findsNWidgets(3));
    expect(find.text('n/a'), findsNWidgets(3));
  });

  testWidgets('level 4: all seven counted', (tester) async {
    await _open(tester, ScoringLevel.full, _bitmapOnly);
    expect(find.text('counts at this level'), findsNWidgets(7));
    expect(find.text('not counted at this level'), findsNothing);
  });

  testWidgets('shows the same word and percentage as bandFor', (tester) async {
    await _open(tester, ScoringLevel.shapeOnly, _bitmapOnly);
    final overall = overallScore(_bitmapOnly, ScoringLevel.shapeOnly);
    expect(bandFor(overall), FeedbackBand.okay);
    expect(find.text('Learner would see: Okay (72%)'), findsOneWidget);
  });

  testWidgets('Copy puts the one-line text on the clipboard', (tester) async {
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
    await _open(tester, ScoringLevel.shapeOnly, _bitmapOnly);
    await tester.tap(find.byKey(const Key('copyButton')));
    await tester.pumpAndSettle();
    expect(
      copied,
      'b · level 1 · Coverage 45 · Precision 100 · Placement 100 · '
      'Efficiency 44 · Start n/a · Path n/a · Strokes n/a · '
      'app said Okay (72)',
    );
    expect(find.text('Copied'), findsOneWidget);
  });
}
