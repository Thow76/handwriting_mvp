/// Fixed letter sets offered on the Home screen.
class LetterSets {
  LetterSets._();

  static const alphabet = [
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', //
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  ];

  static const sitsOnLine = [
    'a', 'c', 'e', 'm', 'n', 'o', 'r', 's', 'u', 'v', 'w', 'x', 'z', //
  ];
  static const reachesUp = ['b', 'd', 'f', 'h', 'k', 'l', 't', 'i'];
  static const dropsBelow = ['g', 'j', 'p', 'q', 'y'];

  /// Letters picked in "Choose your own", in alphabetical order.
  static List<String> inAlphabeticalOrder(Iterable<String> picked) {
    final set = picked.toSet();
    return [
      for (final l in alphabet)
        if (set.contains(l)) l,
    ];
  }
}
