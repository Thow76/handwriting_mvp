import 'dart:ui' show Rect;

import 'letter_formation_data.dart';
import 'stroke.dart';

/// Maps each observed [Stroke] to its corresponding [ExpectedStroke] by
/// **stroke order (index)**: observed stroke `i` is paired with expected
/// stroke `i`.  No spatial or distance matching is performed.
///
/// ## Why order-based pairing
///
/// Expected strokes are authored in canonical drawing order, and learners are
/// guided to draw in that order.  The previous nearest-centroid matching
/// compared an observed stroke's bounding-box centroid against each expected
/// stroke's *start* target.  For stem-first letters (f, t, i, b, d, h, k …)
/// the tall first stroke's centroid sits in the middle of the letter — nearer
/// the second stroke's start target than its own — so the two strokes were
/// silently swapped, and every downstream sub-score (start, direction, path)
/// was computed against the wrong stroke.  Order-based pairing removes that
/// failure mode and makes pairing deterministic.
///
/// ## Count-mismatch behaviour
///
/// - **Fewer observed strokes than expected:** the trailing expected strokes
///   (index >= [observed].length) have no observed counterpart and are left
///   unmatched.  They represent *missing* strokes; treating a missing required
///   stroke as a failure (score 0) is the formation scorers' responsibility,
///   because this function's return is indexed by observed stroke and cannot
///   itself surface an unmatched expected index.
/// - **More observed strokes than expected:** the surplus observed strokes
///   (index >= [expected].length) map to -1 and are ignored here.  Over-counting
///   is scored separately by `StrokeBreakCounter`.
///
/// An observed stroke with no points maps to -1 (it cannot be scored).
///
/// The [templateTightBounds] parameter is retained for signature stability and
/// possible future use; order-based pairing does not consult it.
///
/// Returns a [List<int>] of length [observed].length where each element is the
/// index of the matched expected stroke, or -1 when unmatched.
List<int> matchStrokes(
  List<Stroke> observed,
  List<ExpectedStroke> expected,
  Rect templateTightBounds,
) {
  final result = List<int>.filled(observed.length, -1);

  for (var i = 0; i < observed.length; i++) {
    // An empty stroke cannot be scored; leave it unmatched.
    if (observed[i].points.isEmpty) continue;
    // Positional pairing: observed[i] ↔ expected[i].
    // Surplus observed strokes (i >= expected.length) stay -1.
    if (i < expected.length) result[i] = i;
  }

  return result;
}
