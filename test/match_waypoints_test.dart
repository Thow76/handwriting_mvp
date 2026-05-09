import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/match_waypoints.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';

void main() {
  // 300×300 bounding box used throughout.  Cells are 100×100.
  // Tolerance = 0.5 × min(100, 100) = 50.
  //
  // Waypoint centroids for 'n' (topLeft → bottomLeft → top → bottomRight):
  //   topLeft    → (  50,  50)
  //   bottomLeft → (  50, 250)
  //   top        → ( 150,  50)
  //   bottomRight→ ( 250, 250)
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  // Expected waypoint sequence for the letter 'n'.
  const nWaypoints = [
    WaypointRegion.topLeft,
    WaypointRegion.bottomLeft,
    WaypointRegion.top,
    WaypointRegion.bottomRight,
  ];

  // ---------------------------------------------------------------------------
  // Ideal 'n' path — 4/4
  // ---------------------------------------------------------------------------

  group("ideal 'n' path", () {
    // Points sit exactly on each waypoint centroid, in the correct sequence.
    final idealPath = [
      const Offset(50, 50),   // topLeft centroid
      const Offset(50, 250),  // bottomLeft centroid
      const Offset(150, 50),  // top centroid
      const Offset(250, 250), // bottomRight centroid
    ];

    test('hitCount is 4', () {
      final result = matchWaypoints(idealPath, nWaypoints, bounds);
      expect(result.hitCount, 4);
    });

    test('all four waypoints are hits', () {
      final result = matchWaypoints(idealPath, nWaypoints, bounds);
      expect(result.hits.every((h) => h.isHit), isTrue);
    });

    test('hit point indices are strictly increasing', () {
      final result = matchWaypoints(idealPath, nWaypoints, bounds);
      final indices =
          result.hits.map((h) => h.hitPointIndex!).toList();
      for (var i = 1; i < indices.length; i++) {
        expect(indices[i], greaterThan(indices[i - 1]));
      }
    });

    test('hits list length equals waypoints count', () {
      final result = matchWaypoints(idealPath, nWaypoints, bounds);
      expect(result.hits.length, nWaypoints.length);
    });
  });

  // ---------------------------------------------------------------------------
  // Arch peak slightly off-centre but within tolerance — 4/4
  // ---------------------------------------------------------------------------

  group("'n' with arch peak slightly off-centre (within tolerance)", () {
    // The 'top' waypoint centroid is at (150, 50).  Shifting to (165, 60)
    // gives distance ≈ sqrt(225+100) ≈ 18, well within the tolerance of 50.
    final offCentrePath = [
      const Offset(50, 50),   // topLeft — exact centroid
      const Offset(50, 250),  // bottomLeft — exact centroid
      const Offset(165, 60),  // top — 18 units from centroid, within tolerance
      const Offset(250, 250), // bottomRight — exact centroid
    ];

    test('hitCount is 4', () {
      final result = matchWaypoints(offCentrePath, nWaypoints, bounds);
      expect(result.hitCount, 4);
    });

    test('all four waypoints are hits', () {
      final result = matchWaypoints(offCentrePath, nWaypoints, bounds);
      expect(result.hits.every((h) => h.isHit), isTrue);
    });

    test('top waypoint is recorded as a hit', () {
      final result = matchWaypoints(offCentrePath, nWaypoints, bounds);
      final topHit = result.hits.firstWhere(
        (h) => h.waypoint == WaypointRegion.top,
      );
      expect(topHit.isHit, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Arch missing the top cell — 3/4
  // ---------------------------------------------------------------------------

  group("'n' with arch missing the top cell", () {
    // The 'top' waypoint centroid is at (150, 50).  Point (180, 180) is in the
    // middle region, ≈ 133 units away — outside the tolerance of 50.
    // bottomRight is still found after the missed top.
    final missingTopPath = [
      const Offset(50, 50),   // topLeft — exact centroid
      const Offset(50, 250),  // bottomLeft — exact centroid
      const Offset(180, 180), // middle region — 133 units from top, miss
      const Offset(250, 250), // bottomRight — exact centroid
    ];

    test('hitCount is 3', () {
      final result = matchWaypoints(missingTopPath, nWaypoints, bounds);
      expect(result.hitCount, 3);
    });

    test('top waypoint is a miss', () {
      final result = matchWaypoints(missingTopPath, nWaypoints, bounds);
      final topHit = result.hits.firstWhere(
        (h) => h.waypoint == WaypointRegion.top,
      );
      expect(topHit.isHit, isFalse);
      expect(topHit.hitPointIndex, isNull);
    });

    test('topLeft, bottomLeft and bottomRight are hits', () {
      final result = matchWaypoints(missingTopPath, nWaypoints, bounds);
      for (final region in [
        WaypointRegion.topLeft,
        WaypointRegion.bottomLeft,
        WaypointRegion.bottomRight,
      ]) {
        final h = result.hits.firstWhere((h) => h.waypoint == region);
        expect(h.isHit, isTrue, reason: '${region.name} should be a hit');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Upside-down 'n' — sequence violated
  // ---------------------------------------------------------------------------

  group("upside-down 'n' — sequence violated", () {
    // The path visits all four 'n' waypoint regions but in reverse order:
    //   bottomRight (index 0) → top (index 1) → bottomLeft (index 2) → topLeft (index 3)
    //
    // The forward-only scan matches topLeft at index 3 (the last point), but
    // all remaining waypoints (bottomLeft, top, bottomRight) cannot be found
    // strictly after index 3.  Only 1 of 4 waypoints is hit, demonstrating
    // that the wrong temporal order is penalised even when the correct regions
    // are all present.
    //
    // Note: the algorithm gives hitCount = 1 for this reversed path.  The
    // scope document describes the ideal outcome as 0 hits ("would score 0"),
    // which holds for paths that do not arrive at topLeft at all; here, because
    // topLeft appears as the final point, it is matched once before the forward
    // scan exhausts the remaining points.
    final upsideDownPath = [
      const Offset(250, 250), // bottomRight centroid (expected 4th)
      const Offset(150, 50),  // top centroid        (expected 3rd)
      const Offset(50, 250),  // bottomLeft centroid (expected 2nd)
      const Offset(50, 50),   // topLeft centroid    (expected 1st)
    ];

    test('hitCount is less than 4 — sequence enforced', () {
      final result = matchWaypoints(upsideDownPath, nWaypoints, bounds);
      expect(result.hitCount, lessThan(4));
    });

    test('bottomLeft, top, and bottomRight cannot be matched after topLeft', () {
      // topLeft is matched at the last point index (3).
      // Subsequent waypoints cannot find any point at index > 3.
      final result = matchWaypoints(upsideDownPath, nWaypoints, bounds);
      final bottomLeftHit = result.hits
          .firstWhere((h) => h.waypoint == WaypointRegion.bottomLeft);
      final topHit =
          result.hits.firstWhere((h) => h.waypoint == WaypointRegion.top);
      final bottomRightHit = result.hits
          .firstWhere((h) => h.waypoint == WaypointRegion.bottomRight);
      expect(bottomLeftHit.isHit, isFalse);
      expect(topHit.isHit, isFalse);
      expect(bottomRightHit.isHit, isFalse);
    });

    test('hits list has exactly nWaypoints entries', () {
      final result = matchWaypoints(upsideDownPath, nWaypoints, bounds);
      expect(result.hits.length, nWaypoints.length);
    });
  });

  // ---------------------------------------------------------------------------
  // Tolerance scaling — same proportional path scores identically at 2× scale
  // ---------------------------------------------------------------------------

  group('tolerance scaling — score is scale-invariant when bounds are doubled', () {
    // Points at exact waypoint centroids for the original 300×300 bounds.
    // These are the canonical positions inside each cell.
    final originalPoints = [
      const Offset(50, 50),   // topLeft centroid (300×300)
      const Offset(50, 250),  // bottomLeft centroid (300×300)
      const Offset(150, 50),  // top centroid (300×300)
      const Offset(250, 250), // bottomRight centroid (300×300)
    ];

    // Scaling both the observed points and the bounding box by 2 produces a
    // scenario that is geometrically identical at twice the resolution.
    // Cell dimensions double (200×200) and tolerance doubles (100), so every
    // point-to-centroid distance scaled by 2 still satisfies the tolerance.
    final scaledBounds = const Rect.fromLTWH(0, 0, 600, 600);
    final scaledPoints = originalPoints
        .map((p) => Offset(p.dx * 2, p.dy * 2))
        .toList();

    test('original bounds: hitCount is 4', () {
      final result = matchWaypoints(originalPoints, nWaypoints, bounds);
      expect(result.hitCount, 4);
    });

    test('doubled bounds with scaled points: hitCount is 4', () {
      final result =
          matchWaypoints(scaledPoints, nWaypoints, scaledBounds);
      expect(result.hitCount, 4);
    });

    test('hitCounts are equal for original and doubled configurations', () {
      final original = matchWaypoints(originalPoints, nWaypoints, bounds);
      final scaled =
          matchWaypoints(scaledPoints, nWaypoints, scaledBounds);
      expect(scaled.hitCount, original.hitCount);
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------

  group('edge cases', () {
    test('empty observedPoints returns hitCount 0', () {
      final result = matchWaypoints([], nWaypoints, bounds);
      expect(result.hitCount, 0);
      expect(result.hits.every((h) => !h.isHit), isTrue);
    });

    test('empty expectedSequence returns hitCount 0 and empty hits list', () {
      final result = matchWaypoints(
        [const Offset(50, 50)],
        [],
        bounds,
      );
      expect(result.hitCount, 0);
      expect(result.hits, isEmpty);
    });

    test('single point exactly on waypoint centroid scores 1/1', () {
      final result = matchWaypoints(
        [const Offset(50, 50)],
        [WaypointRegion.topLeft],
        bounds,
      );
      expect(result.hitCount, 1);
      expect(result.hits.first.isHit, isTrue);
    });

    test('point just inside tolerance boundary is a hit', () {
      // Tolerance = 50. Point 49 units from topLeft centroid (50,50).
      final result = matchWaypoints(
        [const Offset(50 + 49, 50)],
        [WaypointRegion.topLeft],
        bounds,
      );
      expect(result.hitCount, 1);
    });

    test('point just outside tolerance boundary is a miss', () {
      // Tolerance = 50. Point 51 units from topLeft centroid (50,50).
      final result = matchWaypoints(
        [const Offset(50 + 51, 50)],
        [WaypointRegion.topLeft],
        bounds,
      );
      expect(result.hitCount, 0);
    });

    test('toleranceFraction 0.0 requires exact centroid hit', () {
      // With toleranceFraction = 0.0, tolerance = 0, so only exact centroid
      // matches count.  Floating-point equality means we compare to distSq=0.
      final result = matchWaypoints(
        [const Offset(50, 50)],
        [WaypointRegion.topLeft],
        bounds,
        toleranceFraction: 0.0,
      );
      // distSq = 0 ≤ 0 (toleranceSq). Exact centroid is a hit.
      expect(result.hitCount, 1);
    });

    test('same point cannot satisfy two waypoints', () {
      // A single point at topLeft centroid.  The second waypoint (bottomLeft)
      // must be found strictly after index 0, so it will not hit the same
      // point.
      final result = matchWaypoints(
        [const Offset(50, 50)],
        [WaypointRegion.topLeft, WaypointRegion.bottomLeft],
        bounds,
      );
      expect(result.hitCount, 1); // only topLeft matched
    });
  });
}
