import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/main.dart';
import 'package:handwriting_mvp/models/letter_sets.dart';

Future<void> _scrollTo(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

FilledButton _chosenButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const Key('practiceChosen')));

void main() {
  testWidgets('Practice button is disabled until a letter is selected', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await _scrollTo(tester, find.byKey(const Key('practiceChosen')));
    expect(_chosenButton(tester).onPressed, isNull);

    await _scrollTo(tester, find.byKey(const Key('letter_c')));
    await tester.tap(find.byKey(const Key('letter_c')));
    await tester.pump();
    expect(_chosenButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('letter_c')));
    await tester.pump();
    expect(_chosenButton(tester).onPressed, isNull);
  });

  testWidgets('chosen letters go to the guide in alphabetical order', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await _scrollTo(tester, find.byKey(const Key('letter_z')));
    await tester.tap(find.byKey(const Key('letter_z')));
    await _scrollTo(tester, find.byKey(const Key('letter_b')));
    await tester.tap(find.byKey(const Key('letter_b')));
    await tester.pump();
    await _scrollTo(tester, find.byKey(const Key('practiceChosen')));
    await tester.tap(find.byKey(const Key('practiceChosen')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('level_4')), findsOneWidget);
    await tester.tap(find.byKey(const Key('level_3')));
    await tester.pumpAndSettle();
    expect(find.text('Guide – b'), findsOneWidget);
  });

  testWidgets('shape groups lead to level select with the group', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await _scrollTo(tester, find.byKey(const Key('shape_dropsBelow')));
    await tester.tap(find.byKey(const Key('shape_dropsBelow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('level_2')));
    await tester.pumpAndSettle();
    expect(find.text('Guide – g'), findsOneWidget);
  });

  test('letter sets cover a–z exactly once', () {
    final all = [
      ...LetterSets.sitsOnLine,
      ...LetterSets.reachesUp,
      ...LetterSets.dropsBelow,
    ]..sort();
    expect(all, LetterSets.alphabet);
    expect(LetterSets.alphabet.length, 26);
    expect(LetterSets.inAlphabeticalOrder({'z', 'a', 'm'}), ['a', 'm', 'z']);
  });
}
