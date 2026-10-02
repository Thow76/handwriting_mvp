import 'scoring_level.dart';

/// A run of practice: a set of one or more letters at one scoring level.
class PracticeSession {
  PracticeSession({
    required List<String> letters,
    required this.level,
    this.index = 0,
  }) : letters = List.unmodifiable(letters) {
    if (this.letters.isEmpty) {
      throw ArgumentError.value(letters, 'letters', 'must not be empty');
    }
    if (index < 0 || index >= this.letters.length) {
      throw RangeError.index(index, this.letters, 'index');
    }
  }

  final List<String> letters;
  final ScoringLevel level;
  int index;

  /// The letter being practised now.
  String get current => letters[index];

  bool get isLast => index == letters.length - 1;

  /// How many letters are in the set.
  int get length => letters.length;

  /// The progress bar is hidden when the set has exactly one letter.
  bool get showsProgress => letters.length > 1;

  /// Moves to the next letter. Does nothing on the last letter.
  void next() {
    if (!isLast) index++;
  }

  /// The same set and level, back at the first letter.
  PracticeSession restarted() =>
      PracticeSession(letters: letters, level: level);
}
