import 'stroke_formation_enums.dart';
import 'stroke_start_rect.dart';

/// The expected behaviour of a single stroke within a letter.
///
/// [primaryDirection] drives direction scoring for non-compound, non-dot
/// strokes. [startRect] is the target zone for start-position scoring.
/// [waypoints] is the ordered list of [WaypointRegion] cells the stroke must
/// pass through. When non-empty, waypoint scoring is used regardless of
/// [primaryDirection].
///
/// All fields are immutable.
class ExpectedStroke {
  /// The primary direction of this stroke, used for direction scoring.
  final StrokeDirection primaryDirection;

  /// The expected start rectangle, expressed as bounds-relative fractions.
  ///
  /// Used as the target zone for start-position scoring and as the spatial
  /// anchor for stroke matching.
  final StrokeStartRect startRect;

  /// Ordered waypoints for waypoint-scored strokes; empty for direction-scored
  /// strokes.
  final List<WaypointRegion> waypoints;

  /// Creates an [ExpectedStroke].
  ///
  ExpectedStroke({
    required this.primaryDirection,
    required this.startRect,
    this.waypoints = const [],
  });
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
  LetterFormationData({required this.strokes, required this.minRequiredStrokes})
    : assert(minRequiredStrokes >= 1, 'minRequiredStrokes must be at least 1');

  /// The canonical stroke count for this letter, derived as [strokes.length].
  int get canonicalStrokeCount => strokes.length;
}
