import 'dart:math' show sqrt;

import 'stroke.dart';

/// Measures how efficiently the user traced the letter by comparing
/// the ideal path length (from the skeleton) to the actual path length
/// (from the user's strokes).
///
/// A perfect trace has efficiency ~1.0. Scribbling back and forth
/// produces a much longer path than necessary, yielding low efficiency.
class EfficiencyScorer {
  /// Estimates the ideal path length from a skeleton mask.
  ///
  /// Approximated as the count of active skeleton pixels. Each pixel
  /// represents roughly one unit of path length along the centre-line.
  ///
  /// Returns 0.0 if the skeleton is empty or has no active pixels.
  static double idealPathLength(List<List<bool>> skeleton) {
    var count = 0;
    for (final row in skeleton) {
      for (final pixel in row) {
        if (pixel) count++;
      }
    }
    return count.toDouble();
  }

  /// Calculates the total path length of the user's strokes.
  ///
  /// Sum of Euclidean distances between consecutive points in each
  /// stroke. Includes all pen movement, even back-and-forth scribbling.
  ///
  /// Returns 0.0 if there are no strokes or no multi-point strokes.
  static double actualPathLength(List<Stroke> strokes) {
    var total = 0.0;
    for (final stroke in strokes) {
      for (var i = 1; i < stroke.points.length; i++) {
        final dx = stroke.points[i].dx - stroke.points[i - 1].dx;
        final dy = stroke.points[i].dy - stroke.points[i - 1].dy;
        total += sqrt(dx * dx + dy * dy);
      }
    }
    return total;
  }

  /// Returns an efficiency ratio between 0.0 and 1.0.
  ///
  /// Calculated as `idealPathLength / actualPathLength`, clamped to 1.0.
  /// A ratio of 1.0 means the user used exactly the right amount of
  /// pen movement. Lower values indicate excessive movement (scribbling).
  ///
  /// Returns 0.0 if either path length is zero or negative.
  static double calculate({
    required double idealPathLength,
    required double actualPathLength,
  }) {
    if (idealPathLength <= 0 || actualPathLength <= 0) return 0.0;
    return (idealPathLength / actualPathLength).clamp(0.0, 1.0);
  }
}
