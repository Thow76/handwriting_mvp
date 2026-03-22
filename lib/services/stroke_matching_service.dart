import 'dart:ui';

/// Reorders user strokes to match the template stroke order using greedy
/// centroid assignment, then concatenates both into single comparable paths.
///
/// This enables point-by-point comparison (Procrustes / Frechet) even when the
/// user draws strokes in a different order than the template defines them.
class StrokeMatchingService {
  const StrokeMatchingService._();

  /// Given template and user strokes (both in the same coordinate space),
  /// returns `(templatePath, userPath)` — two concatenated, order-aligned
  /// point lists ready for resampling and comparison.
  static (List<Offset>, List<Offset>) alignAndConcatenate(
    List<List<Offset>> templateStrokes,
    List<List<Offset>> userStrokes,
  ) {
    // Concatenate template in its canonical order.
    final templatePath = _concat(templateStrokes);

    if (userStrokes.isEmpty) return (templatePath, <Offset>[]);
    if (templateStrokes.length <= 1 || userStrokes.length <= 1) {
      // No multi-stroke matching needed.
      return (templatePath, _concat(userStrokes));
    }

    // Compute overall centroids and the offset between them so that stroke
    // matching uses *relative* positions.  Without this, a drawing that is
    // shifted on the canvas can cause strokes to be matched to the wrong
    // template strokes (e.g. the user's stem centroid is closer to the
    // template's circle centroid than the user's own circle centroid).
    final tAllCentroid = _centroid(_concat(templateStrokes));
    final uAllCentroid = _centroid(_concat(userStrokes));
    final offset = uAllCentroid - tAllCentroid;

    // Greedy centroid matching: for each template stroke (in order), pick the
    // closest unmatched user stroke, comparing in template-centred space.
    final matched = List<bool>.filled(userStrokes.length, false);
    final ordering = <int>[]; // indices into userStrokes, in template order

    for (final tStroke in templateStrokes) {
      final tCentroid = _centroid(tStroke);
      var bestIdx = -1;
      var bestDist = double.infinity;

      for (var i = 0; i < userStrokes.length; i++) {
        if (matched[i]) continue;
        // Subtract the overall offset so we compare relative positions.
        final d = (_centroid(userStrokes[i]) - offset - tCentroid).distance;
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }

      if (bestIdx >= 0) {
        matched[bestIdx] = true;
        ordering.add(bestIdx);
      }
    }

    // Append any unmatched user strokes to the end (they'll slightly hurt the
    // shape score but shouldn't be silently dropped).
    for (var i = 0; i < userStrokes.length; i++) {
      if (!matched[i]) ordering.add(i);
    }

    final userPath = <Offset>[];
    for (final idx in ordering) {
      userPath.addAll(userStrokes[idx]);
    }

    return (templatePath, userPath);
  }

  static List<Offset> _concat(List<List<Offset>> strokes) =>
      [for (final s in strokes) ...s];

  static Offset _centroid(List<Offset> pts) {
    if (pts.isEmpty) return Offset.zero;
    var sx = 0.0, sy = 0.0;
    for (final p in pts) {
      sx += p.dx;
      sy += p.dy;
    }
    return Offset(sx / pts.length, sy / pts.length);
  }
}
