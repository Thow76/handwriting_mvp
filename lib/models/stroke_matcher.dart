import 'dart:ui' show Offset, Rect;

import 'letter_formation_data.dart';
import 'stroke.dart';
import 'stroke_formation_enums.dart';

/// Maps each observed [Stroke] to its corresponding [ExpectedStroke] index
/// using greedy nearest-centroid spatial matching.
///
/// Each observed stroke's bounding-box centroid is compared against the
/// region centroid of every unclaimed expected stroke (derived from
/// [templateTightBounds]).  The nearest unclaimed expected stroke is assigned
/// to the observed stroke; if no expected strokes remain, the observed stroke
/// maps to -1.
///
/// Matching is greedy (first-come, first-served in observed order).  Each
/// expected stroke can be claimed by at most one observed stroke.  Observed
/// strokes with no points map to -1 without consuming an expected stroke.
///
/// Returns a [List<int>] of length [observed].length where each element is
/// the index of the matched expected stroke, or -1 when unmatched.
List<int> matchStrokes(
  List<Stroke> observed,
  List<ExpectedStroke> expected,
  Rect templateTightBounds,
) {
  final expectedCentroids = [
    for (final e in expected) _expectedRegionCentroid(e, templateTightBounds),
  ];

  final claimed = List<bool>.filled(expected.length, false);
  final result = List<int>.filled(observed.length, -1);

  for (var i = 0; i < observed.length; i++) {
    final oc = _strokeBoundsCentroid(observed[i]);
    if (oc == null) continue;

    var bestDistSq = double.infinity;
    var bestJ = -1;

    for (var j = 0; j < expected.length; j++) {
      if (claimed[j]) continue;
      final d = _distSq(oc, expectedCentroids[j]);
      if (d < bestDistSq) {
        bestDistSq = d;
        bestJ = j;
      }
    }

    if (bestJ >= 0) {
      result[i] = bestJ;
      claimed[bestJ] = true;
    }
  }

  return result;
}

/// Returns the bounding-box centroid of [stroke], or `null` if the stroke
/// has no points.
Offset? _strokeBoundsCentroid(Stroke stroke) {
  if (stroke.points.isEmpty) return null;
  var minX = stroke.points.first.dx;
  var maxX = stroke.points.first.dx;
  var minY = stroke.points.first.dy;
  var maxY = stroke.points.first.dy;
  for (final p in stroke.points) {
    if (p.dx < minX) minX = p.dx;
    if (p.dx > maxX) maxX = p.dx;
    if (p.dy < minY) minY = p.dy;
    if (p.dy > maxY) maxY = p.dy;
  }
  return Offset((minX + maxX) / 2, (minY + maxY) / 2);
}

/// Returns the representative centroid of [stroke]'s region within
/// [bounds].
///
/// For compound strokes the centroid is the average of each waypoint's
/// cell centre in the 3×3 grid.  For all other strokes the centroid is
/// the centre of the [StrokeStartRegion] band (horizontal thirds of
/// [bounds] height; horizontal position is the centre of [bounds]).
Offset _expectedRegionCentroid(ExpectedStroke stroke, Rect bounds) {
  if (stroke.primaryDirection == StrokeDirection.compound &&
      stroke.waypoints.isNotEmpty) {
    var sumX = 0.0;
    var sumY = 0.0;
    for (final w in stroke.waypoints) {
      final c = _waypointCentroid(w, bounds);
      sumX += c.dx;
      sumY += c.dy;
    }
    return Offset(sumX / stroke.waypoints.length, sumY / stroke.waypoints.length);
  }

  final thirdH = bounds.height / 3;
  final cx = bounds.left + bounds.width / 2;
  final cy = switch (stroke.startRegion) {
    StrokeStartRegion.top => bounds.top + thirdH * 0.5,
    StrokeStartRegion.middle => bounds.top + thirdH * 1.5,
    StrokeStartRegion.bottom => bounds.top + thirdH * 2.5,
  };
  return Offset(cx, cy);
}

/// Returns the centre of the [WaypointRegion] cell within [bounds],
/// where [bounds] is divided into a 3×3 grid.
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
///
/// Squared distance is used instead of actual distance to avoid a sqrt
/// call; the relative ordering is identical.
double _distSq(Offset a, Offset b) {
  final dx = a.dx - b.dx;
  final dy = a.dy - b.dy;
  return dx * dx + dy * dy;
}
