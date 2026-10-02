import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/practice_session.dart';
import 'package:handwriting_mvp/models/scoring_level.dart';

void main() {
  PracticeSession make(List<String> l) =>
      PracticeSession(letters: l, level: ScoringLevel.shapeAndStart);

  test('starts on the first letter', () {
    final s = make(['a', 'b', 'c']);
    expect(s.index, 0);
    expect(s.current, 'a');
    expect(s.isLast, isFalse);
  });

  test('next() walks through the letters and stops at the last', () {
    final s = make(['a', 'b']);
    s.next();
    expect(s.current, 'b');
    expect(s.isLast, isTrue);
    s.next();
    expect(s.current, 'b');
    expect(s.index, 1);
  });

  test('a one-letter set is last at once and hides progress', () {
    final s = make(['q']);
    expect(s.isLast, isTrue);
    expect(s.showsProgress, isFalse);
    expect(make(['a', 'b']).showsProgress, isTrue);
  });

  test('rejects an empty set or a bad index', () {
    expect(() => make([]), throwsArgumentError);
    expect(
      () => PracticeSession(letters: ['a'], level: ScoringLevel.full, index: 1),
      throwsRangeError,
    );
  });

  test('letters cannot be changed from outside', () {
    final input = ['a', 'b'];
    final s = make(input);
    input.add('c');
    expect(s.length, 2);
    expect(() => s.letters.add('z'), throwsUnsupportedError);
  });

  test('restarted() keeps the set and level but returns to letter 1', () {
    final s = make(['a', 'b'])..next();
    final r = s.restarted();
    expect(r.index, 0);
    expect(r.letters, s.letters);
    expect(r.level, s.level);
  });
}
