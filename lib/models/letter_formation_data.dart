import 'stroke_formation_enums.dart';

/// The expected behaviour of a single stroke within a letter.
///
/// [primaryDirection] drives direction scoring for non-compound, non-dot
/// strokes. [startRegion] is checked for every stroke. [waypoints] is the
/// ordered list of [WaypointRegion] cells the stroke must pass through, and
/// must be non-empty only when [primaryDirection] is
/// [StrokeDirection.compound].
///
/// All fields are immutable. The constructor asserts the waypoints invariant
/// at runtime.
class ExpectedStroke {
  /// The primary direction of this stroke, used for direction scoring.
  final StrokeDirection primaryDirection;

  /// The expected start region, used for start-region scoring.
  final StrokeStartRegion startRegion;

  /// Ordered waypoints for compound strokes; empty for all other strokes.
  ///
  /// Must be empty unless [primaryDirection] is [StrokeDirection.compound].
  final List<WaypointRegion> waypoints;

  /// Creates an [ExpectedStroke].
  ///
  /// Asserts that [waypoints] is empty whenever [primaryDirection] is not
  /// [StrokeDirection.compound].
  ExpectedStroke({
    required this.primaryDirection,
    required this.startRegion,
    this.waypoints = const [],
  }) : assert(
         primaryDirection == StrokeDirection.compound || waypoints.isEmpty,
         'waypoints must be empty unless primaryDirection is StrokeDirection.compound',
       );
}

/// The complete formation specification for a single letter.
///
/// [strokes] is the ordered list of [ExpectedStroke] definitions. The
/// canonical stroke count is derived as `strokes.length`; no separate field
/// is provided.
///
/// [minRequiredStrokes] is the pen-lift floor: the minimum number of strokes
/// the learner must produce for the letter to be considered correctly formed.
/// Must be ≥ 1.
class LetterFormationData {
  /// The ordered list of expected strokes for this letter.
  final List<ExpectedStroke> strokes;

  /// The minimum number of strokes required for correct formation.
  ///
  /// Must be ≥ 1.
  final int minRequiredStrokes;

  /// Creates a [LetterFormationData].
  ///
  /// Asserts that [minRequiredStrokes] is at least 1.
  LetterFormationData({
    required this.strokes,
    required this.minRequiredStrokes,
  }) : assert(
         minRequiredStrokes >= 1,
         'minRequiredStrokes must be at least 1',
       );

  /// The canonical stroke count for this letter, derived as [strokes.length].
  int get canonicalStrokeCount => strokes.length;
}
