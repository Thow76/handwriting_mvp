import 'dart:math' show min, max;

import 'stroke.dart';

/// Scores how closely the user's strokes match the expected vertical zone.
///
/// Compares the top and bottom of the stroke bounding box against
/// the expected top and bottom positions. Each edge is scored based
/// on its distance from the expected position, normalised by the
/// zone height. The final score is the average of the two edge scores.
class PlacementScorer {
  /// Returns a placement score between 0.0 and 1.0.
  ///
  /// [expectedTop] and [expectedBottom] are Y coordinates in canvas space
  /// defining the vertical zone the letter should occupy.
  /// [strokes] are the user's drawn strokes.
  ///
  /// Returns 0.0 if there are no strokes or no points.
  static double score({
    required double expectedTop,
    required double expectedBottom,
    required List<Stroke> strokes,
  }) {
    // Collect all points across all strokes.
    final allPoints = strokes.expand((s) => s.points).toList();
    if (allPoints.isEmpty) return 0.0;

    // Find the vertical bounding box of the strokes.
    var strokeTop = allPoints.first.dy;
    var strokeBottom = allPoints.first.dy;
    for (final point in allPoints) {
      strokeTop = min(strokeTop, point.dy);
      strokeBottom = max(strokeBottom, point.dy);
    }

    final zoneHeight = expectedBottom - expectedTop;
    if (zoneHeight <= 0) return 0.0;

    // Score each edge: how far off is it, as a fraction of the zone height?
    final topError = (strokeTop - expectedTop).abs() / zoneHeight;
    final bottomError = (strokeBottom - expectedBottom).abs() / zoneHeight;

    final topScore = max(0.0, 1.0 - topError);
    final bottomScore = max(0.0, 1.0 - bottomError);

    return (topScore + bottomScore) / 2.0;
  }
}
