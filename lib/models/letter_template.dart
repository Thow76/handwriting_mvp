import 'dart:ui';

/// A letter stored as one or more strokes in template coordinate space.
///
/// Template space: x ∈ [0, 1], y ∈ [0, 1].
///   y = 0.00 → descender line
///   y = 0.25 → baseline
///   y = 0.55 → x-height
///   y = 0.75 → cap-height
///   y = 0.85 → ascender line
///   y = 1.00 → top of drawing zone
class LetterTemplate {
  const LetterTemplate({
    required this.letter,
    required this.isUppercase,
    required this.strokes,
  });

  /// The letter character (always stored lowercase — use [displayLabel]).
  final String letter;

  final bool isUppercase;

  /// Each stroke is an ordered list of control points.
  /// Multi-stroke letters (e.g. 't', 'f') have more than one entry.
  final List<List<Offset>> strokes;

  /// Display-ready label, respecting case.
  String get displayLabel =>
      isUppercase ? letter.toUpperCase() : letter.toLowerCase();

  /// Lookup key used by the template map: e.g. "a_lower" or "A_upper".
  String get key =>
      '${letter}_${isUppercase ? "upper" : "lower"}';
}
