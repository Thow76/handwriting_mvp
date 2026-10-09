import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/main.dart';

void main() {
  testWidgets('first screen shows both cards and the COMING SOON chip', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Handwriting practice'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);
  });

  testWidgets('Practice card opens Home', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byKey(const Key('modePractice')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('practiceAlphabet')), findsOneWidget);
    expect(find.text('Handwriting practice'), findsNothing);
  });

  testWidgets('Games card does nothing when tapped', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byKey(const Key('modeGames')));
    await tester.pumpAndSettle();
    expect(find.text('Handwriting practice'), findsOneWidget);
    expect(find.byKey(const Key('practiceAlphabet')), findsNothing);
  });
}
