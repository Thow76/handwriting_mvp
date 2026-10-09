import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/drawing_canvas.dart';
import 'package:handwriting_mvp/main.dart';

void main() {
  testWidgets('app starts at Home and walks through every route', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Handwriting practice'), findsOneWidget);
    await tester.tap(find.byKey(const Key('modePractice')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('practiceAlphabet')), findsOneWidget);

    await tester.tap(find.byKey(const Key('practiceAlphabet')));
    await tester.pumpAndSettle();
    expect(find.text('Level'), findsOneWidget);

    await tester.tap(find.byKey(const Key('level_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('letterCanvas')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('letterCanvas')),
      const Offset(60, 60),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('finishButton')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    // Level 1 goes straight to the next letter (b of 26).
    expect(find.text('2 of 26'), findsOneWidget);
  });

  testWidgets('Dev link opens the existing DrawingCanvas', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byKey(const Key('modePractice')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dev'));
    await tester.tap(find.text('Dev'));
    await tester.pumpAndSettle();
    expect(find.byType(DrawingCanvas), findsOneWidget);
  });
}
