import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Single-stroke letters — table-driven lookup tests
  //
  // Asserts that:
  //   1. Each letter has a non-null entry in the registry.
  //   2. minRequiredStrokes == 1.
  //   3. Exactly one ExpectedStroke is present.
  //   4. The stroke's primaryDirection matches the Universal Core table.
  //   5. The stroke's startRegion is top.
  // ---------------------------------------------------------------------------

  const cases = {
    'c': StrokeDirection.anticlockwise,
    'e': StrokeDirection.anticlockwise,
    'l': StrokeDirection.topToBottom,
    'o': StrokeDirection.anticlockwise,
    // s uses topToBottom as an interim placeholder — see registry comment.
    's': StrokeDirection.topToBottom,
    'v': StrokeDirection.topToBottom,
    'w': StrokeDirection.topToBottom,
    'z': StrokeDirection.topToBottom,
  };

  group('letterFormationRegistry — single-stroke letters', () {
    for (final entry in cases.entries) {
      final letter = entry.key;
      final expectedDirection = entry.value;

      test('$letter: entry is non-null', () {
        expect(letterFormationRegistry[letter], isNotNull);
      });

      test('$letter: minRequiredStrokes == 1', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.minRequiredStrokes, 1);
      });

      test('$letter: has exactly one ExpectedStroke', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes, hasLength(1));
        expect(data.canonicalStrokeCount, 1);
      });

      test('$letter: primaryDirection is $expectedDirection', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes.first.primaryDirection, expectedDirection);
      });

      test('$letter: startRegion is top', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes.first.startRegion, StrokeStartRegion.top);
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Optional-lift oval-and-bowl letters — a, b, d, g, p, q, r, y
  //
  // All entries have minRequiredStrokes = 1.  Connected (one-stroke) and
  // separated (multi-stroke) formations are both correct; the scoring floor
  // is 1, not the canonical stroke count.
  //
  // For b, d, g, p, q the strokes list has two entries (canonical separated
  // form) so direction scoring has the right structure while minRequiredStrokes
  // stays at 1.  The strokes.length == 2 assertions below are the regression
  // guard for this architectural distinction from the scope's revised
  // stroke-count treatment.
  // ---------------------------------------------------------------------------

  const optionalLiftLetters = ['a', 'b', 'd', 'g', 'p', 'q', 'r', 'y'];

  group('letterFormationRegistry — optional-lift letters', () {
    // Regression guard: minRequiredStrokes == 1 for every optional-lift letter.
    // This assertion exists specifically to prevent accidental reversion to the
    // original plan that set minRequiredStrokes = 2 for b, d, g, p, q.
    for (final letter in optionalLiftLetters) {
      test('$letter: entry is non-null', () {
        expect(letterFormationRegistry[letter], isNotNull);
      });

      test('$letter: minRequiredStrokes == 1 (regression guard — scope revised treatment)', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.minRequiredStrokes, 1);
      });
    }

    // Canonical-count guard: b, d, g, p, q must have exactly two strokes in
    // their strokes list even though minRequiredStrokes == 1.  This is the
    // architectural distinction: strokes.length is the canonical count;
    // minRequiredStrokes is the scoring floor.
    for (final letter in ['b', 'd', 'g', 'p', 'q']) {
      test('$letter: strokes.length == 2 (canonical-count guard)', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes, hasLength(2));
        expect(data.canonicalStrokeCount, 2);
      });
    }

    // a: single anticlockwise oval stroke.
    test('a: has exactly one stroke', () {
      expect(letterFormationRegistry['a']!.strokes, hasLength(1));
    });

    test('a: stroke is anticlockwise starting at top', () {
      final data = letterFormationRegistry['a']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.anticlockwise);
      expect(data.strokes[0].startRegion, StrokeStartRegion.top);
    });

    // b: stem (topToBottom) + right-opening bowl (clockwise).
    test('b: stroke 1 is topToBottom starting at top', () {
      final data = letterFormationRegistry['b']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.topToBottom);
      expect(data.strokes[0].startRegion, StrokeStartRegion.top);
    });

    test('b: stroke 2 is clockwise starting at top', () {
      final data = letterFormationRegistry['b']!;
      expect(data.strokes[1].primaryDirection, StrokeDirection.clockwise);
      expect(data.strokes[1].startRegion, StrokeStartRegion.top);
    });

    // d: left-opening oval (anticlockwise) + vertical stem (topToBottom).
    test('d: stroke 1 is anticlockwise starting at top', () {
      final data = letterFormationRegistry['d']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.anticlockwise);
      expect(data.strokes[0].startRegion, StrokeStartRegion.top);
    });

    test('d: stroke 2 is topToBottom starting at top', () {
      final data = letterFormationRegistry['d']!;
      expect(data.strokes[1].primaryDirection, StrokeDirection.topToBottom);
      expect(data.strokes[1].startRegion, StrokeStartRegion.top);
    });

    // g: left-opening oval (anticlockwise) + descending tail (topToBottom).
    test('g: stroke 1 is anticlockwise starting at top', () {
      final data = letterFormationRegistry['g']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.anticlockwise);
      expect(data.strokes[0].startRegion, StrokeStartRegion.top);
    });

    test('g: stroke 2 is topToBottom starting at top', () {
      final data = letterFormationRegistry['g']!;
      expect(data.strokes[1].primaryDirection, StrokeDirection.topToBottom);
      expect(data.strokes[1].startRegion, StrokeStartRegion.top);
    });

    // p: stem (topToBottom) + right-opening bowl (clockwise).
    test('p: stroke 1 is topToBottom starting at top', () {
      final data = letterFormationRegistry['p']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.topToBottom);
      expect(data.strokes[0].startRegion, StrokeStartRegion.top);
    });

    test('p: stroke 2 is clockwise starting at top', () {
      final data = letterFormationRegistry['p']!;
      expect(data.strokes[1].primaryDirection, StrokeDirection.clockwise);
      expect(data.strokes[1].startRegion, StrokeStartRegion.top);
    });

    // q: left-opening oval (anticlockwise) + vertical stem (topToBottom).
    test('q: stroke 1 is anticlockwise starting at top', () {
      final data = letterFormationRegistry['q']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.anticlockwise);
      expect(data.strokes[0].startRegion, StrokeStartRegion.top);
    });

    test('q: stroke 2 is topToBottom starting at top', () {
      final data = letterFormationRegistry['q']!;
      expect(data.strokes[1].primaryDirection, StrokeDirection.topToBottom);
      expect(data.strokes[1].startRegion, StrokeStartRegion.top);
    });

    // r: single entry/stem stroke (topToBottom).
    test('r: has exactly one stroke', () {
      expect(letterFormationRegistry['r']!.strokes, hasLength(1));
    });

    test('r: stroke is topToBottom starting at top', () {
      final data = letterFormationRegistry['r']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.topToBottom);
      expect(data.strokes[0].startRegion, StrokeStartRegion.top);
    });

    // y: stem-plus-tail; both strokes are topToBottom (diagonal class).
    test('y: has exactly two strokes', () {
      expect(letterFormationRegistry['y']!.strokes, hasLength(2));
    });

    test('y: both strokes are topToBottom starting at top', () {
      final data = letterFormationRegistry['y']!;
      for (final stroke in data.strokes) {
        expect(stroke.primaryDirection, StrokeDirection.topToBottom);
        expect(stroke.startRegion, StrokeStartRegion.top);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Required-lift letters — table-driven tests
  //
  // Asserts that:
  //   1. Each letter has a non-null entry in the registry.
  //   2. minRequiredStrokes == 2.
  //   3. Exactly two ExpectedStrokes are present.
  //   4. Stroke directions and start regions match the scope specification.
  // ---------------------------------------------------------------------------

  group('letterFormationRegistry — required-lift letters', () {
    const requiredLiftLetters = ['f', 'i', 'j', 't', 'x'];

    for (final letter in requiredLiftLetters) {
      test('$letter: entry is non-null', () {
        expect(letterFormationRegistry[letter], isNotNull);
      });

      test('$letter: minRequiredStrokes == 2', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.minRequiredStrokes, 2);
      });

      test('$letter: has exactly two ExpectedStrokes', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes, hasLength(2));
        expect(data.canonicalStrokeCount, 2);
      });
    }

    // i and j: second stroke is dot
    for (final letter in ['i', 'j']) {
      test('$letter: stroke 1 is topToBottom starting at top', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes[0].primaryDirection, StrokeDirection.topToBottom);
        expect(data.strokes[0].startRegion, StrokeStartRegion.top);
      });

      test('$letter: stroke 2 is dot', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes[1].primaryDirection, StrokeDirection.dot);
      });
    }

    // t and f: second stroke is leftToRight starting at middle
    for (final letter in ['t', 'f']) {
      test('$letter: stroke 1 is topToBottom starting at top', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes[0].primaryDirection, StrokeDirection.topToBottom);
        expect(data.strokes[0].startRegion, StrokeStartRegion.top);
      });

      test('$letter: stroke 2 is leftToRight starting at middle', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes[1].primaryDirection, StrokeDirection.leftToRight);
        expect(data.strokes[1].startRegion, StrokeStartRegion.middle);
      });
    }

    // x: both strokes are topToBottom starting at top
    test('x: both strokes are topToBottom starting at top', () {
      final data = letterFormationRegistry['x']!;
      for (final stroke in data.strokes) {
        expect(stroke.primaryDirection, StrokeDirection.topToBottom);
        expect(stroke.startRegion, StrokeStartRegion.top);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Compound-stroke letters — h, k, m, n, u
  //
  // Asserts that:
  //   1. Each letter has a non-null entry in the registry.
  //   2. minRequiredStrokes matches the spec (2 for h/k, 1 for m/n/u).
  //   3. Stroke counts and directions are correct.
  //   4. Every compound ExpectedStroke has primaryDirection == compound and a
  //      non-empty waypoints list.
  //   5. Waypoint sequences match the scope table exactly.
  // ---------------------------------------------------------------------------

  group('letterFormationRegistry — compound-stroke letters', () {
    // -------------------------------------------------------------------------
    // n — single compound stroke
    // -------------------------------------------------------------------------
    test('n: entry is non-null', () {
      expect(letterFormationRegistry['n'], isNotNull);
    });

    test('n: minRequiredStrokes == 1', () {
      expect(letterFormationRegistry['n']!.minRequiredStrokes, 1);
    });

    test('n: has exactly one stroke', () {
      expect(letterFormationRegistry['n']!.strokes, hasLength(1));
    });

    test('n: stroke is compound starting at top', () {
      final stroke = letterFormationRegistry['n']!.strokes[0];
      expect(stroke.primaryDirection, StrokeDirection.compound);
      expect(stroke.startRegion, StrokeStartRegion.top);
    });

    test('n: compound stroke has non-empty waypoints', () {
      expect(letterFormationRegistry['n']!.strokes[0].waypoints, isNotEmpty);
    });

    test('n: waypoints are topLeft → bottomLeft → top → bottomRight', () {
      final waypoints = letterFormationRegistry['n']!.strokes[0].waypoints;
      expect(waypoints, [
        WaypointRegion.topLeft,
        WaypointRegion.bottomLeft,
        WaypointRegion.top,
        WaypointRegion.bottomRight,
      ]);
    });

    // -------------------------------------------------------------------------
    // m — single compound stroke
    // -------------------------------------------------------------------------
    test('m: entry is non-null', () {
      expect(letterFormationRegistry['m'], isNotNull);
    });

    test('m: minRequiredStrokes == 1', () {
      expect(letterFormationRegistry['m']!.minRequiredStrokes, 1);
    });

    test('m: has exactly one stroke', () {
      expect(letterFormationRegistry['m']!.strokes, hasLength(1));
    });

    test('m: stroke is compound starting at top', () {
      final stroke = letterFormationRegistry['m']!.strokes[0];
      expect(stroke.primaryDirection, StrokeDirection.compound);
      expect(stroke.startRegion, StrokeStartRegion.top);
    });

    test('m: compound stroke has non-empty waypoints', () {
      expect(letterFormationRegistry['m']!.strokes[0].waypoints, isNotEmpty);
    });

    test('m: waypoints are topLeft → bottomLeft → top → bottom → top → bottomRight', () {
      final waypoints = letterFormationRegistry['m']!.strokes[0].waypoints;
      expect(waypoints, [
        WaypointRegion.topLeft,
        WaypointRegion.bottomLeft,
        WaypointRegion.top,
        WaypointRegion.bottom,
        WaypointRegion.top,
        WaypointRegion.bottomRight,
      ]);
    });

    // -------------------------------------------------------------------------
    // u — single compound stroke
    // -------------------------------------------------------------------------
    test('u: entry is non-null', () {
      expect(letterFormationRegistry['u'], isNotNull);
    });

    test('u: minRequiredStrokes == 1', () {
      expect(letterFormationRegistry['u']!.minRequiredStrokes, 1);
    });

    test('u: has exactly one stroke', () {
      expect(letterFormationRegistry['u']!.strokes, hasLength(1));
    });

    test('u: stroke is compound starting at top', () {
      final stroke = letterFormationRegistry['u']!.strokes[0];
      expect(stroke.primaryDirection, StrokeDirection.compound);
      expect(stroke.startRegion, StrokeStartRegion.top);
    });

    test('u: compound stroke has non-empty waypoints', () {
      expect(letterFormationRegistry['u']!.strokes[0].waypoints, isNotEmpty);
    });

    test('u: waypoints are topLeft → bottomLeft → bottom → bottomRight → topRight', () {
      final waypoints = letterFormationRegistry['u']!.strokes[0].waypoints;
      expect(waypoints, [
        WaypointRegion.topLeft,
        WaypointRegion.bottomLeft,
        WaypointRegion.bottom,
        WaypointRegion.bottomRight,
        WaypointRegion.topRight,
      ]);
    });

    // -------------------------------------------------------------------------
    // h — stem (topToBottom) + compound second stroke
    // -------------------------------------------------------------------------
    test('h: entry is non-null', () {
      expect(letterFormationRegistry['h'], isNotNull);
    });

    test('h: minRequiredStrokes == 2', () {
      expect(letterFormationRegistry['h']!.minRequiredStrokes, 2);
    });

    test('h: has exactly two strokes', () {
      expect(letterFormationRegistry['h']!.strokes, hasLength(2));
    });

    test('h: stroke 1 is topToBottom starting at top', () {
      final stroke = letterFormationRegistry['h']!.strokes[0];
      expect(stroke.primaryDirection, StrokeDirection.topToBottom);
      expect(stroke.startRegion, StrokeStartRegion.top);
    });

    test('h: stroke 2 is compound starting at middle', () {
      final stroke = letterFormationRegistry['h']!.strokes[1];
      expect(stroke.primaryDirection, StrokeDirection.compound);
      expect(stroke.startRegion, StrokeStartRegion.middle);
    });

    test('h: stroke 2 has non-empty waypoints', () {
      expect(letterFormationRegistry['h']!.strokes[1].waypoints, isNotEmpty);
    });

    test('h: stroke 2 waypoints are left → top → bottomRight', () {
      final waypoints = letterFormationRegistry['h']!.strokes[1].waypoints;
      expect(waypoints, [
        WaypointRegion.left,
        WaypointRegion.top,
        WaypointRegion.bottomRight,
      ]);
    });

    // -------------------------------------------------------------------------
    // k — stem (topToBottom) + compound second stroke
    // -------------------------------------------------------------------------
    test('k: entry is non-null', () {
      expect(letterFormationRegistry['k'], isNotNull);
    });

    test('k: minRequiredStrokes == 2', () {
      expect(letterFormationRegistry['k']!.minRequiredStrokes, 2);
    });

    test('k: has exactly two strokes', () {
      expect(letterFormationRegistry['k']!.strokes, hasLength(2));
    });

    test('k: stroke 1 is topToBottom starting at top', () {
      final stroke = letterFormationRegistry['k']!.strokes[0];
      expect(stroke.primaryDirection, StrokeDirection.topToBottom);
      expect(stroke.startRegion, StrokeStartRegion.top);
    });

    test('k: stroke 2 is compound starting at top', () {
      final stroke = letterFormationRegistry['k']!.strokes[1];
      expect(stroke.primaryDirection, StrokeDirection.compound);
      expect(stroke.startRegion, StrokeStartRegion.top);
    });

    test('k: stroke 2 has non-empty waypoints', () {
      expect(letterFormationRegistry['k']!.strokes[1].waypoints, isNotEmpty);
    });

    test('k: stroke 2 waypoints are topRight → middle → bottomRight', () {
      final waypoints = letterFormationRegistry['k']!.strokes[1].waypoints;
      expect(waypoints, [
        WaypointRegion.topRight,
        WaypointRegion.middle,
        WaypointRegion.bottomRight,
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // startRect values — table-driven assertions
  //
  // Asserts that every ExpectedStroke in the registry has the exact startRect
  // agreed in the StrokeStart issue.  Coordinates are fractions of the letter's
  // tight ink bounding box (x: left→right, y: top→bottom).
  //
  // Groups (authoring convenience only — not exposed at runtime):
  //   Anticlockwise oval : x 0.50–1.00, y 0.00–0.25
  //   Stem-first         : x 0.00–0.25, y 0.00–0.15
  //   Compound stroke    : x 0.00–0.25, y 0.00–0.15
  //   Top-left           : x 0.00–0.25, y 0.00–0.15
  // ---------------------------------------------------------------------------

  group('letterFormationRegistry — startRect values', () {
    // Helper to get a stroke's startRect.
    StrokeStartRect rect(String letter, int strokeIndex) =>
        letterFormationRegistry[letter]!.strokes[strokeIndex].startRect;

    // ── Anticlockwise oval group ─────────────────────────────────────────────
    // a, c, o, s, d[0], g[0], q[0] → x 0.50–1.00, y 0.00–0.25
    const ovalRect = StrokeStartRect(minX: 0.50, maxX: 1.00, minY: 0.00, maxY: 0.25);

    for (final letter in ['a', 'c', 'o', 's']) {
      test('$letter[0]: anticlockwise oval startRect', () {
        expect(rect(letter, 0), ovalRect);
      });
    }

    test('d[0]: anticlockwise oval startRect', () {
      expect(rect('d', 0), ovalRect);
    });

    test('g[0]: anticlockwise oval startRect', () {
      expect(rect('g', 0), ovalRect);
    });

    test('q[0]: anticlockwise oval startRect', () {
      expect(rect('q', 0), ovalRect);
    });

    // ── Stem-first group ─────────────────────────────────────────────────────
    // b[0], h[0], k[0], l[0], p[0] → x 0.00–0.25, y 0.00–0.15
    const stemRect = StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15);

    for (final letter in ['b', 'l', 'p']) {
      test('$letter[0]: stem-first startRect', () {
        expect(rect(letter, 0), stemRect);
      });
    }

    test('h[0]: stem-first startRect', () {
      expect(rect('h', 0), stemRect);
    });

    test('k[0]: stem-first startRect', () {
      expect(rect('k', 0), stemRect);
    });

    // ── Compound stroke group ────────────────────────────────────────────────
    // n[0], m[0], u[0], r[0] → x 0.00–0.25, y 0.00–0.15
    // (same rect as stem-first)

    for (final letter in ['m', 'n', 'r', 'u']) {
      test('$letter[0]: compound stroke startRect', () {
        expect(rect(letter, 0), stemRect);
      });
    }

    // ── Top-left group ───────────────────────────────────────────────────────
    // v[0], z[0] → x 0.00–0.25, y 0.00–0.15  (same rect as stem-first)

    for (final letter in ['v', 'z']) {
      test('$letter[0]: top-left startRect', () {
        expect(rect(letter, 0), stemRect);
      });
    }

    // ── Per-letter overrides ─────────────────────────────────────────────────

    test('e[0]: mid-right start (0.50–1.00, 0.25–0.60)', () {
      expect(rect('e', 0),
          const StrokeStartRect(minX: 0.50, maxX: 1.00, minY: 0.25, maxY: 0.60));
    });

    test('d[1]: upper-right stem (0.75–1.00, 0.00–0.15)', () {
      expect(rect('d', 1),
          const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15));
    });

    test('f[0]: stem-first (0.00–0.25, 0.00–0.15)', () {
      expect(rect('f', 0), stemRect);
    });

    test('f[1]: crossbar left at x-height (0.00–0.20, 0.44–0.56)', () {
      expect(rect('f', 1),
          const StrokeStartRect(minX: 0.00, maxX: 0.20, minY: 0.44, maxY: 0.56));
    });

    test('t[0]: stem-first (0.00–0.25, 0.00–0.15)', () {
      expect(rect('t', 0), stemRect);
    });

    test('t[1]: crossbar just above x-height (0.00–0.20, 0.26–0.38)', () {
      expect(rect('t', 1),
          const StrokeStartRect(minX: 0.00, maxX: 0.20, minY: 0.26, maxY: 0.38));
    });

    test('h[1]: arch mid-left at x-height (0.00–0.20, 0.40–0.60)', () {
      expect(rect('h', 1),
          const StrokeStartRect(minX: 0.00, maxX: 0.20, minY: 0.40, maxY: 0.60));
    });

    test('k[1]: kick mid-right above 2/3 junction (0.60–0.90, 0.35–0.55)', () {
      expect(rect('k', 1),
          const StrokeStartRect(minX: 0.60, maxX: 0.90, minY: 0.35, maxY: 0.55));
    });

    test('w[0]: tighter x bound (0.00–0.15, 0.00–0.15)', () {
      expect(rect('w', 0),
          const StrokeStartRect(minX: 0.00, maxX: 0.15, minY: 0.00, maxY: 0.15));
    });

    test('x[0]: top-left (0.00–0.25, 0.00–0.15)', () {
      expect(rect('x', 0), stemRect);
    });

    test('x[1]: top-right mirror (0.75–1.00, 0.00–0.15)', () {
      expect(rect('x', 1),
          const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15));
    });

    test('y[0]: top-left (0.00–0.25, 0.00–0.15)', () {
      expect(rect('y', 0), stemRect);
    });

    test('y[1]: top-right mirror (0.75–1.00, 0.00–0.15)', () {
      expect(rect('y', 1),
          const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15));
    });

    test('i[0]: centred stem (0.25–0.75, 0.00–0.15)', () {
      expect(rect('i', 0),
          const StrokeStartRect(minX: 0.25, maxX: 0.75, minY: 0.00, maxY: 0.15));
    });

    test('i[1]: generous dot zone (0.15–0.85, 0.00–0.36)', () {
      expect(rect('i', 1),
          const StrokeStartRect(minX: 0.15, maxX: 0.85, minY: 0.00, maxY: 0.36));
    });

    test('j[0]: centred stem (0.25–0.75, 0.00–0.15)', () {
      expect(rect('j', 0),
          const StrokeStartRect(minX: 0.25, maxX: 0.75, minY: 0.00, maxY: 0.15));
    });

    test('j[1]: generous dot zone (0.15–0.85, 0.00–0.25)', () {
      expect(rect('j', 1),
          const StrokeStartRect(minX: 0.15, maxX: 0.85, minY: 0.00, maxY: 0.25));
    });

    // ── Unlisted second strokes (b[1], g[1], p[1], q[1]) ────────────────────
    // These strokes are not in the agreed groups/overrides table; values are
    // assigned based on the letter's geometry:
    //   b[1], p[1] — bowl re-traced from same top-left origin as stem
    //   g[1], q[1] — descender/stem starting upper-right of the oval

    test('b[1]: top-left bowl origin (0.00–0.25, 0.00–0.15)', () {
      expect(rect('b', 1), stemRect);
    });

    test('p[1]: top-left bowl origin (0.00–0.25, 0.00–0.15)', () {
      expect(rect('p', 1), stemRect);
    });

    test('g[1]: upper-right tail origin (0.75–1.00, 0.00–0.15)', () {
      expect(rect('g', 1),
          const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15));
    });

    test('q[1]: upper-right stem origin (0.75–1.00, 0.00–0.15)', () {
      expect(rect('q', 1),
          const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15));
    });
  });
}
