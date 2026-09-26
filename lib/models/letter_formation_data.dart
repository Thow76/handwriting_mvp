import 'stroke_start_rect.dart';
import 'waypoint_section.dart';

/// The expected behaviour of a single stroke within a letter.
///
/// [startRect] is the target zone for start-position scoring. [sections] is
/// the ordered list of bespoke rectangular sections the stroke must pass
/// through, used by section (path) scoring.
///
/// All fields are immutable.
class ExpectedStroke {
  /// The expected start rectangle, expressed as bounds-relative fractions.
  ///
  /// Used as the target zone for start-position scoring and as the spatial
  /// anchor for stroke matching.
  final StrokeStartRect startRect;

  /// Ordered bespoke rectangular sections for section-scored strokes; empty
  /// for strokes scored only on start position and stroke count.
  final List<WaypointSection> sections;

  /// Creates an [ExpectedStroke].
  ///
  ExpectedStroke({
    required this.startRect,
    this.sections = const [],
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
