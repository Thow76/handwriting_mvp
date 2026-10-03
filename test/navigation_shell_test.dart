import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/drawing_canvas.dart';
import 'package:handwriting_mvp/main.dart';

void main() {
  testWidgets('app starts at Home and walks through every route', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Practice'), findsWidgets);

    await tester.tap(find.byKey(const Key('practiceAlphabet')));
    await tester.pumpAndSettle();
    expect(find.text('Level select'), findsOneWidget);

    await tester.tap(find.byKey(const Key('level_1')));
    await tester.pumpAndSettle();
    expect(find.text('Guide – a'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Feedback'), findsOneWidget);

    await tester.tap(find.text('Next letter'));
    await tester.pumpAndSettle();
    expect(find.text('Session complete'), findsOneWidget);
  });

  testWidgets('Dev link opens the existing DrawingCanvas', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Dev'));
    await tester.tap(find.text('Dev'));
    await tester.pumpAndSettle();
    expect(find.byType(DrawingCanvas), findsOneWidget);
  });
}
