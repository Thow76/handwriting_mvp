import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/practice_session.dart';
import 'package:handwriting_mvp/models/scoring_level.dart';
import 'package:handwriting_mvp/models/template_cache.dart';
import 'package:handwriting_mvp/routes.dart';
import 'package:handwriting_mvp/screens/home_screen.dart';
import 'package:handwriting_mvp/tester_mode.dart';
import 'package:handwriting_mvp/theme/app_theme.dart';

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
  setUp(TemplateCache.shared.clear);

  tearDown(() => TesterMode.enabled.value = false);

  testWidgets('home screen switch is off by default and turns it on', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const HomeScreen()),
    );
    expect(TesterMode.enabled.value, isFalse);
    await tester.tap(find.byKey(const Key('testerModeSwitch')));
    await tester.pump();
    expect(TesterMode.enabled.value, isTrue);
  });

  group('tester mode off', () {
    testWidgets('level 1 Finish goes to the next letter', (tester) async {
      await _open(tester, letters: ['a', 'b'], level: ScoringLevel.shapeOnly);
      await _draw(tester);
      await _finish(tester);
      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.byKey(const Key('breakdownTitle')), findsNothing);
    });

    testWidgets('level 2 Finish opens Feedback', (tester) async {
      await _open(tester, letters: ['a'], level: ScoringLevel.shapeAndStart);
      await _draw(tester);
      await _finish(tester);
      expect(find.byKey(const Key('scoreRing')), findsOneWidget);
      expect(find.byKey(const Key('breakdownTitle')), findsNothing);
    });
  });

  group('tester mode on', () {
    setUp(() => TesterMode.enabled.value = true);

    testWidgets('level 1: Breakdown names the letter just drawn, then '
        'Continue goes to the next letter', (tester) async {
      final s = await _open(
        tester,
        letters: ['a', 'b'],
        level: ScoringLevel.shapeOnly,
      );
      await _draw(tester);
      await _finish(tester);
      expect(find.text('a · Level 1'), findsOneWidget);
      expect(s.current, 'b');
      await tester.ensureVisible(find.byKey(const Key('continueButton')));
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2'), findsOneWidget);
    });

    testWidgets('level 1 on the last letter: Continue opens Session complete', (
      tester,
    ) async {
      await _open(tester, letters: ['a'], level: ScoringLevel.shapeOnly);
      await _draw(tester);
      await _finish(tester);
      expect(find.text('a · Level 1'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('continueButton')));
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();
      expect(find.text('Session complete'), findsOneWidget);
    });

    testWidgets('level 2: Continue opens Feedback', (tester) async {
      await _open(tester, letters: ['a'], level: ScoringLevel.shapeAndStart);
      await _draw(tester);
      await _finish(tester);
      expect(find.text('a · Level 2'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('continueButton')));
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scoreRing')), findsOneWidget);
    });
  });
}
