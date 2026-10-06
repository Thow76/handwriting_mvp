import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/practice_session.dart';
import 'package:handwriting_mvp/models/scoring_level.dart';
import 'package:handwriting_mvp/routes.dart';
import 'package:handwriting_mvp/theme/app_theme.dart';
import 'package:handwriting_mvp/widgets/letter_canvas.dart';

Future<PracticeSession> _open(
  WidgetTester tester, {
  required List<String> letters,
  required ScoringLevel level,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = PracticeSession(letters: letters, level: level);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      initialRoute: AppRoutes.guide,
      onGenerateRoute: (settings) {
        final builder =
            AppRoutes.table[settings.name] ?? (_) => const SizedBox.shrink();
        return MaterialPageRoute(
          settings:
              settings.name == AppRoutes.guide && settings.arguments == null
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

Future<void> _draw(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const Key('letterCanvas')),
    const Offset(60, 60),
  );
  await tester.pump();
}

Future<void> _finish(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.byKey(const Key('finishButton')));
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows progress when the set has several letters', (
    tester,
  ) async {
    await _open(
      tester,
      letters: ['a', 'b', 'c'],
      level: ScoringLevel.shapeOnly,
    );
    expect(find.byKey(const Key('guideProgress')), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('PRACTICE'), findsOneWidget);
    expect(find.text('Level 1 · Shape only'), findsOneWidget);
  });

  testWidgets('hides progress when the set has one letter', (tester) async {
    await _open(tester, letters: ['a'], level: ScoringLevel.shapeOnly);
    expect(find.byKey(const Key('guideProgress')), findsNothing);
  });

  testWidgets('Finish and Undo are disabled until something is drawn', (
    tester,
  ) async {
    await _open(tester, letters: ['a'], level: ScoringLevel.shapeOnly);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('finishButton')))
          .onPressed,
      isNull,
    );
    await _draw(tester);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('finishButton')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Undo clears the attempt', (tester) async {
    await _open(tester, letters: ['a'], level: ScoringLevel.shapeOnly);
    await _draw(tester);
    await tester.tap(find.byKey(const Key('undoButton')));
    await tester.pump();
    final canvas = tester.widget<LetterCanvas>(find.byType(LetterCanvas));
    expect(canvas.strokes, isEmpty);
  });

  testWidgets('eye toggle hides and shows the model letter', (tester) async {
    await _open(tester, letters: ['a'], level: ScoringLevel.shapeOnly);
    LetterCanvas canvas() =>
        tester.widget<LetterCanvas>(find.byType(LetterCanvas));
    expect(canvas().showModel, isTrue);
    await tester.tap(find.byKey(const Key('eyeToggle')));
    await tester.pump();
    expect(canvas().showModel, isFalse);
    await tester.tap(find.byKey(const Key('eyeToggle')));
    await tester.pump();
    expect(canvas().showModel, isTrue);
  });

  testWidgets('level 1 Finish goes straight to the next letter', (
    tester,
  ) async {
    final session = await _open(
      tester,
      letters: ['a', 'b'],
      level: ScoringLevel.shapeOnly,
    );
    await _draw(tester);
    await _finish(tester);
    expect(session.current, 'b');
    expect(find.text('2 of 2'), findsOneWidget);
    expect(session.lastResult, isNotNull);
  });

  testWidgets('level 1 Finish on the last letter opens Session complete', (
    tester,
  ) async {
    await _open(tester, letters: ['a'], level: ScoringLevel.shapeOnly);
    await _draw(tester);
    await _finish(tester);
    expect(find.text('Session complete'), findsOneWidget);
  });

  testWidgets('level 2 Finish opens Feedback', (tester) async {
    await _open(tester, letters: ['a', 'b'], level: ScoringLevel.shapeAndStart);
    await _draw(tester);
    await _finish(tester);
    expect(find.byKey(const Key('scoreRing')), findsOneWidget);
  });
}
