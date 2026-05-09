import 'dart:math' show min;
import 'dart:ui' show Offset, Rect;

import 'stroke_formation_enums.dart';

/// The result of matching one expected waypoint against the observed path.
///
/// [waypoint] is the [WaypointRegion] that was checked.
/// [isHit] is `true` when an observed point lay within tolerance of the
/// waypoint's cell centre AND occurred after the previous match in the
/// point stream.
/// [hitPointIndex] is the index into the observed-points list where the hit
/// was recorded, or `null` when [isHit] is `false`.
class WaypointHit {
  /// The waypoint region that was evaluated.
  final WaypointRegion waypoint;

  /// Whether the waypoint was successfully matched.
  final bool isHit;

  /// Index of the matching observed point, or `null` on a miss.
  final int? hitPointIndex;

  const WaypointHit({
    required this.waypoint,
    required this.isHit,
    this.hitPointIndex,
  });
}

/// The complete result of [matchWaypoints].
///
/// [hitCount] is the number of expected waypoints that were hit.
/// [hits] contains one [WaypointHit] per expected waypoint, in sequence
/// order, providing per-waypoint hit/miss detail for learner feedback.
class WaypointMatchResult {
  /// Number of waypoints successfully matched, 0 … expectedSequence.length.
  final int hitCount;

  /// Per-waypoint breakdown, one entry per element of [expectedSequence].
  final List<WaypointHit> hits;

  const WaypointMatchResult({
    required this.hitCount,
    required this.hits,
  });
}

/// Matches an ordered sequence of [WaypointRegion] waypoints against a list
/// of observed stroke points.
///
/// ## Algorithm
///
/// For each expected waypoint (in sequence order):
/// - Scan forward through [observedPoints] starting from the index after the
///   previous match (or from the beginning for the first waypoint).
/// - Among those forward points, find the one closest to the waypoint's cell
///   centre in the 3×3 grid overlaid on [tightBounds].
/// - If that closest point lies within [tolerance] AND its index is strictly
///   after the previous match index, it counts as a hit and becomes the new
///   last-match index.
/// - Otherwise the waypoint is a miss and the last-match index is unchanged.
///
/// ## Sequence enforcement
///
/// Because each scan starts from the last-match index, every new match must
/// occur strictly later in the point stream than the previous match. A stroke
/// that visits the correct regions in the wrong order will score fewer hits
/// than one that visits them in the right order.
///
/// ## Tolerance
///
/// Tolerance is computed as:
///
///     tolerance = toleranceFraction × min(cellWidth, cellHeight)
///
/// where `cellWidth = tightBounds.width / 3` and
/// `cellHeight = tightBounds.height / 3`. Using `min` produces a circular hit
/// zone that fits inside any cell regardless of aspect ratio, and tying the
/// value to the bounding box makes scoring scale-invariant across device sizes.
///
/// ## Parameters
///
/// - [observedPoints]: the raw point stream of a single observed stroke.
/// - [expectedSequence]: ordered list of waypoint cells the stroke must pass
///   through.
/// - [tightBounds]: the tight bounding box of the letter template, used to
///   compute cell centres and tolerance.
/// - [toleranceFraction]: fraction of the smaller cell dimension used as the
///   hit radius.  Defaults to 0.5.
///
/// Returns a [WaypointMatchResult] with the total hit count and per-waypoint
/// detail.
WaypointMatchResult matchWaypoints(
  List<Offset> observedPoints,
  List<WaypointRegion> expectedSequence,
  Rect tightBounds, {
  double toleranceFraction = 0.5,
}) {
  final cellWidth = tightBounds.width / 3;
  final cellHeight = tightBounds.height / 3;
  final tolerance = toleranceFraction * min(cellWidth, cellHeight);
  final toleranceSq = tolerance * tolerance;

  var lastMatchedIndex = -1;
  var hitCount = 0;
  final hits = <WaypointHit>[];

  for (final waypoint in expectedSequence) {
    final centroid = _waypointCentroid(waypoint, tightBounds);

    var bestDistSq = double.infinity;
    var bestIdx = -1;

    for (var i = lastMatchedIndex + 1; i < observedPoints.length; i++) {
      final d = _distSq(observedPoints[i], centroid);
      if (d < bestDistSq) {
        bestDistSq = d;
        bestIdx = i;
      }
    }

    if (bestIdx != -1 && bestDistSq <= toleranceSq) {
      hitCount++;
      hits.add(WaypointHit(
        waypoint: waypoint,
        isHit: true,
        hitPointIndex: bestIdx,
      ));
      lastMatchedIndex = bestIdx;
    } else {
      hits.add(WaypointHit(waypoint: waypoint, isHit: false));
    }
  }

  return WaypointMatchResult(hitCount: hitCount, hits: hits);
}

/// Returns the centre of [region]'s cell within [bounds], where [bounds] is
/// divided into a 3×3 grid.
Offset _waypointCentroid(WaypointRegion region, Rect bounds) {
  final thirdW = bounds.width / 3;
  final thirdH = bounds.height / 3;
  final (col, row) = switch (region) {
    WaypointRegion.topLeft => (0, 0),
    WaypointRegion.top => (1, 0),
    WaypointRegion.topRight => (2, 0),
    WaypointRegion.left => (0, 1),
    WaypointRegion.middle => (1, 1),
    WaypointRegion.right => (2, 1),
    WaypointRegion.bottomLeft => (0, 2),
    WaypointRegion.bottom => (1, 2),
    WaypointRegion.bottomRight => (2, 2),
  };
  return Offset(
    bounds.left + (col + 0.5) * thirdW,
    bounds.top + (row + 0.5) * thirdH,
  );
}

/// Returns the squared Euclidean distance between [a] and [b].
double _distSq(Offset a, Offset b) {
  final dx = a.dx - b.dx;
  final dy = a.dy - b.dy;
  return dx * dx + dy * dy;
}
