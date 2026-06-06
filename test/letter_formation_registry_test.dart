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
    const topLeftToBottomRight = [
      WaypointRegion.topLeft,
      WaypointRegion.bottomRight,
    ];

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
    }

    for (final letter in ['v', 'w']) {
      test('$letter: waypoints are topLeft → bottomRight', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes.first.waypoints, topLeftToBottomRight);
      });
    }

    test('z: waypoints are left → right', () {
      final data = letterFormationRegistry['z']!;
      expect(data.strokes.first.waypoints, [
        WaypointRegion.left,
        WaypointRegion.right,
      ]);
    });
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

  const optionalLiftLetters = ['a', 'b', 'd', 'g', 'p', 'q', 'y'];

  group('letterFormationRegistry — optional-lift letters', () {
    const anticlockwiseOvalWaypoints = [
      WaypointRegion.topRight,
      WaypointRegion.left,
      WaypointRegion.bottom,
      WaypointRegion.right,
    ];
    const clockwiseBowlWaypoints = [
      WaypointRegion.topRight,
      WaypointRegion.right,
      WaypointRegion.bottom,
      WaypointRegion.left,
    ];

    // Regression guard: minRequiredStrokes == 1 for every optional-lift letter.
    // This assertion exists specifically to prevent accidental reversion to the
    // original plan that set minRequiredStrokes = 2 for b, d, g, p, q.
    for (final letter in optionalLiftLetters) {
      test('$letter: entry is non-null', () {
        expect(letterFormationRegistry[letter], isNotNull);
      });

      test(
        '$letter: minRequiredStrokes == 1 (regression guard — scope revised treatment)',
        () {
          final data = letterFormationRegistry[letter]!;
          expect(data.minRequiredStrokes, 1);
        },
      );
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
    });

    // b: stem (topToBottom) + right-opening bowl (clockwise).
    test('b: stroke 1 is topToBottom starting at top', () {
      final data = letterFormationRegistry['b']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.topToBottom);
    });

    test('b: stroke 2 is clockwise starting at top', () {
      final data = letterFormationRegistry['b']!;
      expect(data.strokes[1].primaryDirection, StrokeDirection.clockwise);
    });

    // d: vertical stem (topToBottom) first, then left-opening oval (anticlockwise).
    // Stroke order corrected per design doc: stem[0] before bowl[1].
    test('d: stroke 1 is topToBottom starting at top', () {
      final data = letterFormationRegistry['d']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.topToBottom);
    });

    test('d: stroke 2 is anticlockwise starting at top', () {
      final data = letterFormationRegistry['d']!;
      expect(data.strokes[1].primaryDirection, StrokeDirection.anticlockwise);
    });

    // g: left-opening oval (anticlockwise) + descending tail (topToBottom).
    test('g: stroke 1 is anticlockwise starting at top', () {
      final data = letterFormationRegistry['g']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.anticlockwise);
    });

    test('g: stroke 2 is topToBottom starting at top', () {
      final data = letterFormationRegistry['g']!;
      expect(data.strokes[1].primaryDirection, StrokeDirection.topToBottom);
    });

    // p: stem (topToBottom) + right-opening bowl (clockwise).
    test('p: stroke 1 is topToBottom starting at top', () {
      final data = letterFormationRegistry['p']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.topToBottom);
    });

    test('p: stroke 2 is clockwise starting at top', () {
      final data = letterFormationRegistry['p']!;
      expect(data.strokes[1].primaryDirection, StrokeDirection.clockwise);
    });

    // q: left-opening oval (anticlockwise) + vertical stem (topToBottom).
    test('q: stroke 1 is anticlockwise starting at top', () {
      final data = letterFormationRegistry['q']!;
      expect(data.strokes[0].primaryDirection, StrokeDirection.anticlockwise);
    });

    test('q: stroke 2 is topToBottom starting at top', () {
      final data = letterFormationRegistry['q']!;
      expect(data.strokes[1].primaryDirection, StrokeDirection.topToBottom);
    });

    for (final entry in {
      'a': 0,
      'c': 0,
      'e': 0,
      'o': 0,
      'd': 1,
      'g': 0,
      'q': 0,
    }.entries) {
      test(
        '${entry.key}[${entry.value}]: anticlockwise oval waypoints are topRight → left → bottom → right',
        () {
          final stroke =
              letterFormationRegistry[entry.key]!.strokes[entry.value];
          expect(stroke.waypoints, anticlockwiseOvalWaypoints);
        },
      );
    }

    for (final entry in {'b': 1, 'p': 1}.entries) {
      test(
        '${entry.key}[${entry.value}]: clockwise bowl waypoints are topRight → right → bottom → left',
        () {
          final stroke =
              letterFormationRegistry[entry.key]!.strokes[entry.value];
          expect(stroke.waypoints, clockwiseBowlWaypoints);
        },
      );
    }

    // r: redesigned as two-stroke (stem + arch) — moved to compound-stroke group.

    // y: stem-plus-tail; both strokes are topToBottom with distinct diagonals.
    test('y: has exactly two strokes', () {
      expect(letterFormationRegistry['y']!.strokes, hasLength(2));
    });

    test('y: both strokes are topToBottom starting at top', () {
      final data = letterFormationRegistry['y']!;
      for (final stroke in data.strokes) {
        expect(stroke.primaryDirection, StrokeDirection.topToBottom);
      }
    });

    test('y: stroke 1 waypoints are topLeft → bottomRight', () {
      final data = letterFormationRegistry['y']!;
      expect(data.strokes[0].waypoints, [
        WaypointRegion.topLeft,
        WaypointRegion.bottomRight,
      ]);
    });

    test('y: stroke 2 waypoints are topRight → bottomLeft', () {
      final data = letterFormationRegistry['y']!;
      expect(data.strokes[1].waypoints, [
        WaypointRegion.topRight,
        WaypointRegion.bottomLeft,
      ]);
    });
  });

  group('letterFormationRegistry — top-to-bottom stem waypoint migration', () {
    const stemWaypoints = [WaypointRegion.top, WaypointRegion.bottom];
    const stemStrokes = {
      'b': 0,
      'd': 0,
      'f': 0,
      'g': 1,
      'h': 0,
      'i': 0,
      'j': 0,
      'k': 0,
      'l': 0,
      'p': 0,
      'q': 1,
      'r': 0,
      't': 0,
    };

    for (final entry in stemStrokes.entries) {
      test('${entry.key}[${entry.value}]: waypoints are top → bottom', () {
        final stroke = letterFormationRegistry[entry.key]!.strokes[entry.value];
        expect(stroke.waypoints, stemWaypoints);
      });
    }
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
      });

      test('$letter: stroke 2 is leftToRight starting at middle', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes[1].primaryDirection, StrokeDirection.leftToRight);
      });

      test('$letter: stroke 2 waypoints are left → right', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes[1].waypoints, [
          WaypointRegion.left,
          WaypointRegion.right,
        ]);
      });
    }

    // x: both strokes are topToBottom starting at top
    test('x: both strokes are topToBottom starting at top', () {
      final data = letterFormationRegistry['x']!;
      for (final stroke in data.strokes) {
        expect(stroke.primaryDirection, StrokeDirection.topToBottom);
      }
    });

    test('x: stroke 1 waypoints are topLeft → bottomRight', () {
      final data = letterFormationRegistry['x']!;
      expect(data.strokes[0].waypoints, [
        WaypointRegion.topLeft,
        WaypointRegion.bottomRight,
      ]);
    });

    test('x: stroke 2 waypoints are topRight → bottomLeft', () {
      final data = letterFormationRegistry['x']!;
      expect(data.strokes[1].waypoints, [
        WaypointRegion.topRight,
        WaypointRegion.bottomLeft,
      ]);
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
    });

    test('m: compound stroke has non-empty waypoints', () {
      expect(letterFormationRegistry['m']!.strokes[0].waypoints, isNotEmpty);
    });

    test(
      'm: waypoints are topLeft → bottomLeft → top → bottom → top → bottomRight',
      () {
        final waypoints = letterFormationRegistry['m']!.strokes[0].waypoints;
        expect(waypoints, [
          WaypointRegion.topLeft,
          WaypointRegion.bottomLeft,
          WaypointRegion.top,
          WaypointRegion.bottom,
          WaypointRegion.top,
          WaypointRegion.bottomRight,
        ]);
      },
    );

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
    });

    test('u: compound stroke has non-empty waypoints', () {
      expect(letterFormationRegistry['u']!.strokes[0].waypoints, isNotEmpty);
    });

    test(
      'u: waypoints are topLeft → bottomLeft → bottom → bottomRight → topRight',
      () {
        final waypoints = letterFormationRegistry['u']!.strokes[0].waypoints;
        expect(waypoints, [
          WaypointRegion.topLeft,
          WaypointRegion.bottomLeft,
          WaypointRegion.bottom,
          WaypointRegion.bottomRight,
          WaypointRegion.topRight,
        ]);
      },
    );

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
    });

    test('h: stroke 2 is compound starting at middle', () {
      final stroke = letterFormationRegistry['h']!.strokes[1];
      expect(stroke.primaryDirection, StrokeDirection.compound);
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
    });

    test('k: stroke 2 is compound starting at top', () {
      final stroke = letterFormationRegistry['k']!.strokes[1];
      expect(stroke.primaryDirection, StrokeDirection.compound);
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

    // -------------------------------------------------------------------------
    // r — stem (topToBottom) + compound arch stroke
    // -------------------------------------------------------------------------
    test('r: entry is non-null', () {
      expect(letterFormationRegistry['r'], isNotNull);
    });

    test('r: minRequiredStrokes == 2', () {
      expect(letterFormationRegistry['r']!.minRequiredStrokes, 2);
    });

    test('r: has exactly two strokes', () {
      expect(letterFormationRegistry['r']!.strokes, hasLength(2));
    });

    test('r: stroke 1 is topToBottom (stem)', () {
      final stroke = letterFormationRegistry['r']!.strokes[0];
      expect(stroke.primaryDirection, StrokeDirection.topToBottom);
    });

    test('r: stroke 2 is compound (arch)', () {
      final stroke = letterFormationRegistry['r']!.strokes[1];
      expect(stroke.primaryDirection, StrokeDirection.compound);
    });

    test('r: stroke 2 has non-empty waypoints', () {
      expect(letterFormationRegistry['r']!.strokes[1].waypoints, isNotEmpty);
    });

    test('r: stroke 2 waypoints are left → topRight', () {
      final waypoints = letterFormationRegistry['r']!.strokes[1].waypoints;
      expect(waypoints, [WaypointRegion.left, WaypointRegion.topRight]);
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
  //   Anticlockwise oval : x 0.55–0.95, y 0.00–0.25
  //   Stem-first         : x 0.00–0.25, y 0.00–0.15
  //   Compound stroke    : x 0.00–0.25, y 0.00–0.15
  //   Top-left           : x 0.00–0.25, y 0.00–0.15
  // ---------------------------------------------------------------------------

  group('letterFormationRegistry — startRect values', () {
    // Helper to get a stroke's startRect.
    StrokeStartRect rect(String letter, int strokeIndex) =>
        letterFormationRegistry[letter]!.strokes[strokeIndex].startRect;

    // ── Anticlockwise oval group ─────────────────────────────────────────────
    // a, c, o, s, g[0], q[0] → x 0.55–0.95, y 0.00–0.25
    const ovalRect = StrokeStartRect(
      minX: 0.55,
      maxX: 0.95,
      minY: 0.00,
      maxY: 0.25,
    );

    for (final letter in ['a', 'c', 'o', 's']) {
      test('$letter[0]: anticlockwise oval startRect', () {
        expect(rect(letter, 0), ovalRect);
      });
    }

    test('d[0]: upper-right stem startRect (0.75–1.00, 0.00–0.15)', () {
      expect(
        rect('d', 0),
        const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15),
      );
    });

    test(
      'g[0]: oval start at top-right of bowl, top at bounds (0.65–0.85, 0.00–0.15)',
      () {
        expect(
          rect('g', 0),
          const StrokeStartRect(minX: 0.65, maxX: 0.85, minY: 0.00, maxY: 0.15),
        );
      },
    );

    test('q[0]: oval start — tighter than standard (0.68–0.95, 0.00–0.15)', () {
      expect(
        rect('q', 0),
        const StrokeStartRect(minX: 0.68, maxX: 0.95, minY: 0.00, maxY: 0.15),
      );
    });

    // ── Stem-first group ─────────────────────────────────────────────────────
    // b[0], h[0], k[0], l[0], p[0] → x 0.00–0.25, y 0.00–0.15
    const stemRect = StrokeStartRect(
      minX: 0.00,
      maxX: 0.25,
      minY: 0.00,
      maxY: 0.15,
    );

    for (final letter in ['b', 'p']) {
      test('$letter[0]: stem-first startRect', () {
        expect(rect(letter, 0), stemRect);
      });
    }

    test('l[0]: full-width stem top (0.00–1.00, 0.00–0.15)', () {
      expect(
        rect('l', 0),
        const StrokeStartRect(minX: 0.00, maxX: 1.00, minY: 0.00, maxY: 0.15),
      );
    });

    test('h[0]: stem-first startRect', () {
      expect(rect('h', 0), stemRect);
    });

    test('k[0]: stem-first startRect', () {
      expect(rect('k', 0), stemRect);
    });

    // ── Compound stroke group ────────────────────────────────────────────────
    // r[0] → x 0.00–0.25, y 0.00–0.15 (same rect as stem-first)
    // m[0], n[0], u[0] have widened startRects — tested individually below.

    test('r[0]: stem-first startRect', () {
      expect(rect('r', 0), stemRect);
    });

    // ── Top-left group ───────────────────────────────────────────────────────
    // v[0], z[0] → x 0.00–0.25, y 0.00–0.15  (same rect as stem-first)

    for (final letter in ['v', 'z']) {
      test('$letter[0]: top-left startRect', () {
        expect(rect(letter, 0), stemRect);
      });
    }

    // ── Per-letter overrides ─────────────────────────────────────────────────

    test('e[0]: mid-left tongue start (0.00–0.25, 0.40–0.60)', () {
      expect(
        rect('e', 0),
        const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.40, maxY: 0.60),
      );
    });

    test('d[1]: mid-right bowl (0.70–1.00, 0.40–0.60)', () {
      expect(
        rect('d', 1),
        const StrokeStartRect(minX: 0.70, maxX: 1.00, minY: 0.40, maxY: 0.60),
      );
    });

    test('f[0]: hook top, right half (0.55–1.00, 0.00–0.15)', () {
      expect(
        rect('f', 0),
        const StrokeStartRect(minX: 0.55, maxX: 1.00, minY: 0.00, maxY: 0.15),
      );
    });

    test('f[1]: crossbar at midline, widened x (0.00–0.25, 0.25–0.40)', () {
      expect(
        rect('f', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.25, maxY: 0.40),
      );
    });

    test(
      't[0]: mid-upper stem recentred and widened (0.35–0.65, 0.00–0.15)',
      () {
        expect(
          rect('t', 0),
          const StrokeStartRect(minX: 0.35, maxX: 0.65, minY: 0.00, maxY: 0.15),
        );
      },
    );

    test('t[1]: crossbar just above x-height (0.00–0.24, 0.26–0.38)', () {
      expect(
        rect('t', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.24, minY: 0.26, maxY: 0.38),
      );
    });

    test('h[1]: arch mid-left at x-height (0.00–0.30, 0.40–0.60)', () {
      expect(
        rect('h', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.40, maxY: 0.60),
      );
    });

    test('k[1]: kick mid-right above 2/3 junction (0.60–0.90, 0.35–0.55)', () {
      expect(
        rect('k', 1),
        const StrokeStartRect(minX: 0.60, maxX: 0.90, minY: 0.35, maxY: 0.55),
      );
    });

    test('r[1]: arch mid-left at x-height (0.00–0.30, 0.40–0.60)', () {
      expect(
        rect('r', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.40, maxY: 0.60),
      );
    });

    test('w[0]: wider x bound (0.00–0.25, 0.00–0.15)', () {
      expect(
        rect('w', 0),
        const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      );
    });

    test('x[0]: top-left (0.00–0.25, 0.00–0.15)', () {
      expect(rect('x', 0), stemRect);
    });

    test('x[1]: top-right mirror (0.75–1.00, 0.00–0.15)', () {
      expect(
        rect('x', 1),
        const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15),
      );
    });

    test('y[0]: top-left (0.00–0.25, 0.00–0.15)', () {
      expect(rect('y', 0), stemRect);
    });

    test('y[1]: top-right mirror (0.75–1.00, 0.00–0.15)', () {
      expect(
        rect('y', 1),
        const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15),
      );
    });

    test('i[0]: centred stem, top at stem body (0.25–0.75, 0.30–0.45)', () {
      expect(
        rect('i', 0),
        const StrokeStartRect(minX: 0.25, maxX: 0.75, minY: 0.30, maxY: 0.45),
      );
    });

    test('i[1]: dot only, trimmed to dot extent (0.15–0.85, 0.00–0.20)', () {
      expect(
        rect('i', 1),
        const StrokeStartRect(minX: 0.15, maxX: 0.85, minY: 0.00, maxY: 0.20),
      );
    });

    test('j[0]: centred stem below dot (0.25–0.75, 0.22–0.33)', () {
      expect(
        rect('j', 0),
        const StrokeStartRect(minX: 0.25, maxX: 0.75, minY: 0.22, maxY: 0.33),
      );
    });

    test('j[1]: generous dot zone (0.15–0.85, 0.00–0.25)', () {
      expect(
        rect('j', 1),
        const StrokeStartRect(minX: 0.15, maxX: 0.85, minY: 0.00, maxY: 0.25),
      );
    });

    // ── Confirmed second strokes (b[1], p[1], g[1], q[1]) ───────────────────
    // Design-review-confirmed rectangles (see issue #87). These replaced the
    // PR #86 placeholders (stem-first / upper-right defaults) once the
    // pedagogical start zones for the bowl/link/tail second strokes were
    // agreed.

    test('b[1]: mid-left bowl at x-height (0.00–0.30, 0.40–0.60)', () {
      expect(
        rect('b', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.40, maxY: 0.60),
      );
    });

    test('p[1]: bowl starts at top of bounds (0.00–0.30, 0.00–0.15)', () {
      expect(
        rect('p', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.15),
      );
    });

    test(
      'g[1]: tail start at top-right shoulder, widened right (0.74–0.99, 0.02–0.17)',
      () {
        expect(
          rect('g', 1),
          const StrokeStartRect(minX: 0.74, maxX: 0.99, minY: 0.02, maxY: 0.17),
        );
      },
    );

    test(
      'q[1]: far-right descender at top of bounds (0.87–1.00, 0.00–0.15)',
      () {
        expect(
          rect('q', 1),
          const StrokeStartRect(minX: 0.87, maxX: 1.00, minY: 0.00, maxY: 0.15),
        );
      },
    );

    // ── Widened compound starts (m[0], n[0], u[0]) ───────────────────────────

    test('m[0]: widened compound start (0.00–0.30, 0.00–0.20)', () {
      expect(
        rect('m', 0),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.20),
      );
    });

    test('n[0]: widened compound start (0.00–0.30, 0.00–0.20)', () {
      expect(
        rect('n', 0),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.20),
      );
    });

    test('u[0]: widened compound start (0.00–0.30, 0.00–0.15)', () {
      expect(
        rect('u', 0),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.15),
      );
    });
  });
}
