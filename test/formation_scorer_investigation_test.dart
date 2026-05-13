import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/compound_stroke_scorer.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_direction_scorer.dart';
import 'package:handwriting_mvp/models/stroke_matcher.dart';
import 'package:handwriting_mvp/models/stroke_start_scorer.dart';

// ---------------------------------------------------------------------------
// Part 4/4 of the bounds-bug investigation series.
//
// These tests empirically verify matcher pairing and Path/Direction scorer
// behaviour after the tight-bounds fix, for the letters f, t, i, j, n, m,
// u, h, and k.
//
// All tests use a 300×300 tight-bounds rect.  Waypoint cell centroids within
// this grid:
//
//   topLeft(50,50)   top(150,50)   topRight(250,50)
//   left(50,150)     middle(150,150) right(250,150)
//   bottomLeft(50,250) bottom(150,250) bottomRight(250,250)
//
// Expected-stroke centroids derived by matchStrokes (non-compound):
//   startRegion=top    → (cx, bounds.top + thirdH×0.5) = (150,  50)
//   startRegion=middle → (cx, bounds.top + thirdH×1.5) = (150, 150)
//
// Default waypoint tolerance = 0.5 × min(cellW, cellH) = 0.5 × 100 = 50.
// ---------------------------------------------------------------------------

void main() {
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  // ── 'f' — stem (topToBottom/top) + crossbar (leftToRight/middle) ─────────
  //
  // exp[0]: topToBottom, startRegion=top    → centroid (150,  50)
  // exp[1]: leftToRight, startRegion=middle → centroid (150, 150)
  //
  // FINDING: When the stem's bounding-box centroid falls in the middle third
  // (as it does for a full-height stem spanning y=10–250), the greedy
  // nearest-centroid matcher assigns it to exp[1] (crossbar) rather than
  // exp[0] (stem).  This mis-pairing causes incorrect start and direction
  // observations even for a correctly drawn 'f'.
  //
  // A short stem whose centroid stays in the top third produces the correct
  // pairing [0, 1].

  group("'f' — short stem (centroid in top third) — correct pairing", () {
    // Stem: (150,20)→(150,80).  Centroid y = (20+80)/2 = 50 → top third.
    // Crossbar: (50,150)→(250,150).  Centroid y = 150 → middle third.
    final fStemShort = Stroke([Offset(150, 20), Offset(150, 80)]);
    final fCrossbar = Stroke([Offset(50, 150), Offset(250, 150)]);

    final fData = letterFormationRegistry['f']!;

    test('matchStrokes produces [0, 1] — stem→exp[0], crossbar→exp[1]', () {
      final result = matchStrokes([fStemShort, fCrossbar], fData.strokes, bounds);
      expect(result, [0, 1],
          reason: 'Short stem centroid (150,50) is closest to exp[0] centroid '
              '(150,50); crossbar centroid (150,150) is closest to exp[1] '
              'centroid (150,150).');
    });

    test('start scorer overall = 1.0 (both strokes start in expected regions)',
        () {
      final scorer =
          StrokeStartScorer(letter: 'f', data: fData, bounds: bounds);
      final result = scorer.score([fStemShort, fCrossbar]);
      expect(result.overallScore, 1.0);
    });

    test('direction scorer overall = 1.0 (both drawn in expected directions)',
        () {
      final scorer =
          StrokeDirectionScorer(letter: 'f', data: fData, bounds: bounds);
      final result = scorer.score([fStemShort, fCrossbar]);
      expect(result.overallScore, 1.0);
    });
  });

  group(
      "'f' — full-height stem (centroid in middle third) — "
      'mis-pairing (known limitation)', () {
    // Stem: (150,10)→(150,250).  Centroid y = (10+250)/2 = 130 → middle third.
    //   dist² to exp[0] (150,50) = 80² = 6 400
    //   dist² to exp[1] (150,150) = 20² =   400   ← closer → stem→exp[1]
    // Crossbar: (50,150)→(250,150).  Centroid (150,150) → only exp[0] left.
    final fStemFull = Stroke([Offset(150, 10), Offset(150, 250)]);
    final fCrossbar = Stroke([Offset(50, 150), Offset(250, 150)]);

    final fData = letterFormationRegistry['f']!;

    test('matchStrokes produces [1, 0] — stem mis-paired to crossbar expected',
        () {
      final result = matchStrokes([fStemFull, fCrossbar], fData.strokes, bounds);
      expect(result, [1, 0],
          reason: 'Full-height stem centroid (150,130) is closer to exp[1] '
              'centroid (150,150) than to exp[0] centroid (150,50), causing '
              'the stem to claim the crossbar expected stroke.');
    });

    test(
        'start scorer overall = 0.5 — mis-pairing reverses the expected '
        'regions: stem is evaluated against middle expected, crossbar against '
        'top expected', () {
      // Stem (matched exp[1]=middle): first pt y=10 → top → adjacent 0.5.
      // Crossbar (matched exp[0]=top): first pt y=150 → middle → adjacent 0.5.
      final scorer =
          StrokeStartScorer(letter: 'f', data: fData, bounds: bounds);
      final result = scorer.score([fStemFull, fCrossbar]);
      expect(result.overallScore, 0.5,
          reason: 'The mis-pairing causes both strokes to be evaluated against '
              'the wrong expected start regions, producing two adjacent-'
              'mismatch scores of 0.5 each.');
    });

    test(
        'direction scorer overall = 0.5 — mis-pairing assigns wrong direction '
        'expectations to both strokes', () {
      // Stem (matched exp[1]=leftToRight): drawn topToBottom → score 0.5.
      // Crossbar (matched exp[0]=topToBottom): drawn leftToRight → score 0.5.
      final scorer =
          StrokeDirectionScorer(letter: 'f', data: fData, bounds: bounds);
      final result = scorer.score([fStemFull, fCrossbar]);
      expect(result.overallScore, 0.5,
          reason: 'A correctly drawn full-height f scores 0.5 on direction '
              'due to the centroid mis-pairing, not due to a real direction '
              'error.');
    });
  });

  group(
      "'f' — both strokes starting in top region — "
      "'locked 75%' start-score scenario", () {
    // Crossbar drawn at y=50 (top region), not the expected middle.
    // Stem: (150,10)→(150,250).  Centroid y=130 → middle third → exp[1].
    // Crossbar: (50,50)→(250,50).  Centroid y=50 → top third → exp[0].
    //
    // After matching: stem→exp[1](middle), crossbar→exp[0](top).
    // Start scorer:
    //   stem   first pt y=10 → top vs exp[1] middle → 0.5 (adjacent)
    //   crossbar first pt y=50 → top vs exp[0] top   → 1.0
    // Overall = 0.75.
    //
    // NOTE: with a CORRECT pairing (stem→exp[0], crossbar→exp[1]) the score
    // would also be 0.75 (stem top/top=1.0, crossbar top/middle=0.5).  The
    // total is identical; only the per-stroke observations differ.  The
    // tight-bounds fix therefore does not change the 75% total but does affect
    // which stroke is identified as the culprit in the observations table.
    final fStemFull = Stroke([Offset(150, 10), Offset(150, 250)]);
    final fCrossbarAtTop = Stroke([Offset(50, 50), Offset(250, 50)]);

    final fData = letterFormationRegistry['f']!;

    test('matchStrokes produces [1, 0] — stem→exp[1], crossbar→exp[0]', () {
      final result =
          matchStrokes([fStemFull, fCrossbarAtTop], fData.strokes, bounds);
      expect(result, [1, 0]);
    });

    test('start scorer overall = 0.75', () {
      final scorer =
          StrokeStartScorer(letter: 'f', data: fData, bounds: bounds);
      final result = scorer.score([fStemFull, fCrossbarAtTop]);
      expect(result.overallScore, closeTo(0.75, 1e-9));
    });

    test(
        'stem observation says expected=middle, observed=top (mis-pairing '
        'blames the stem instead of the crossbar)', () {
      final scorer =
          StrokeStartScorer(letter: 'f', data: fData, bounds: bounds);
      final result = scorer.score([fStemFull, fCrossbarAtTop]);
      // obs[0] = stem (matched exp[1]=middle)
      expect(result.observations[0].expected, 'middle');
      expect(result.observations[0].observed, 'top');
    });
  });

  // ── 't' — same structural pattern as 'f' ─────────────────────────────────
  //
  // exp[0]: topToBottom, startRegion=top    → centroid (150, 50)
  // exp[1]: leftToRight, startRegion=middle → centroid (150, 150)
  //
  // FINDING: Identical centroid geometry to 'f'.  Full-height stem causes
  // the same mis-pairing as in 'f'.

  group("'t' — short stem — correct pairing", () {
    final tStemShort = Stroke([Offset(150, 20), Offset(150, 80)]);
    final tCrossbar = Stroke([Offset(50, 150), Offset(250, 150)]);

    final tData = letterFormationRegistry['t']!;

    test('matchStrokes produces [0, 1]', () {
      final result = matchStrokes([tStemShort, tCrossbar], tData.strokes, bounds);
      expect(result, [0, 1]);
    });

    test('start scorer overall = 1.0', () {
      final scorer =
          StrokeStartScorer(letter: 't', data: tData, bounds: bounds);
      final result = scorer.score([tStemShort, tCrossbar]);
      expect(result.overallScore, 1.0);
    });

    test('direction scorer overall = 1.0', () {
      final scorer =
          StrokeDirectionScorer(letter: 't', data: tData, bounds: bounds);
      final result = scorer.score([tStemShort, tCrossbar]);
      expect(result.overallScore, 1.0);
    });
  });

  group("'t' — full-height stem — same mis-pairing as 'f'", () {
    final tStemFull = Stroke([Offset(150, 10), Offset(150, 250)]);
    final tCrossbar = Stroke([Offset(50, 150), Offset(250, 150)]);

    final tData = letterFormationRegistry['t']!;

    test('matchStrokes produces [1, 0] — same centroid geometry as f', () {
      final result = matchStrokes([tStemFull, tCrossbar], tData.strokes, bounds);
      expect(result, [1, 0]);
    });

    test('start scorer overall = 0.5 (same as full-height f)', () {
      final scorer =
          StrokeStartScorer(letter: 't', data: tData, bounds: bounds);
      final result = scorer.score([tStemFull, tCrossbar]);
      expect(result.overallScore, 0.5);
    });

    test('direction scorer overall = 0.5 (same as full-height f)', () {
      final scorer =
          StrokeDirectionScorer(letter: 't', data: tData, bounds: bounds);
      final result = scorer.score([tStemFull, tCrossbar]);
      expect(result.overallScore, 0.5);
    });
  });

  // ── 'i' — stem (topToBottom/top) + dot (dot/top) ─────────────────────────
  //
  // exp[0]: topToBottom, startRegion=top → centroid (150, 50)
  // exp[1]: dot,          startRegion=top → centroid (150, 50)
  //
  // FINDING: Both expected centroids are IDENTICAL at (150, 50), so the
  // greedy matcher cannot spatially discriminate between them.  Whichever
  // observed stroke is processed first always claims exp[0].  However,
  // since both expected strokes share startRegion=top, the start scorer
  // gives 1.0 regardless of which observed stroke is assigned to which
  // expected stroke.

  group("'i' — stem drawn first, then dot", () {
    // Stem: (150,10)→(150,250).  Centroid (150,130).
    //   dist² to exp[0](150,50) = 80² = 6400.
    //   dist² to exp[1](150,50) = 6400.  TIE → exp[0] claimed (first in loop).
    // Dot: (150,18)→(150,22).  Centroid (150,20) → only exp[1].
    final iStem = Stroke([Offset(150, 10), Offset(150, 250)]);
    final iDot = Stroke([Offset(150, 18), Offset(150, 22)]);

    final iData = letterFormationRegistry['i']!;

    test('matchStrokes — stem claims exp[0] on distance tie', () {
      final result = matchStrokes([iStem, iDot], iData.strokes, bounds);
      expect(result, [0, 1],
          reason: 'Both expected centroids are at (150,50). The first observed '
              'stroke (stem) wins the tie and claims exp[0].');
    });

    test(
        'start scorer overall = 1.0 — both expected strokes have startRegion=top; '
        'pairing order does not affect the score', () {
      final scorer =
          StrokeStartScorer(letter: 'i', data: iData, bounds: bounds);
      final result = scorer.score([iStem, iDot]);
      expect(result.overallScore, 1.0);
    });
  });

  group("'i' — dot drawn first, then stem", () {
    // Dot drawn first still claims exp[0] (tied distance, first wins).
    final iDotFirst = Stroke([Offset(150, 18), Offset(150, 22)]);
    final iStemSecond = Stroke([Offset(150, 10), Offset(150, 250)]);

    final iData = letterFormationRegistry['i']!;

    test('matchStrokes — dot claims exp[0] regardless of spatial position', () {
      final result =
          matchStrokes([iDotFirst, iStemSecond], iData.strokes, bounds);
      expect(result, [0, 1],
          reason: 'When the dot is observed first it claims exp[0] '
              '(topToBottom), and the stem is forced to exp[1] (dot).  The '
              'matcher cannot discriminate because the expected centroids are '
              'identical.');
    });

    test(
        'start scorer overall = 1.0 — unaffected by pairing order because '
        'both expected strokes share startRegion=top', () {
      final scorer =
          StrokeStartScorer(letter: 'i', data: iData, bounds: bounds);
      final result = scorer.score([iDotFirst, iStemSecond]);
      expect(result.overallScore, 1.0);
    });
  });

  // ── 'j' — identical structure to 'i' ─────────────────────────────────────

  group("'j' — same centroid geometry as 'i'", () {
    final jStem = Stroke([Offset(150, 10), Offset(150, 250)]);
    final jDot = Stroke([Offset(150, 18), Offset(150, 22)]);

    final jData = letterFormationRegistry['j']!;

    test(
        'matchStrokes — first observed stroke always claims exp[0] '
        '(identical expected centroids)', () {
      final result = matchStrokes([jStem, jDot], jData.strokes, bounds);
      expect(result, [0, 1]);
    });

    test('start scorer overall = 1.0', () {
      final scorer =
          StrokeStartScorer(letter: 'j', data: jData, bounds: bounds);
      final result = scorer.score([jStem, jDot]);
      expect(result.overallScore, 1.0);
    });
  });

  // ── 'n' — single compound stroke ─────────────────────────────────────────
  //
  // Waypoints: topLeft(50,50) → bottomLeft(50,250) → top(150,50) → bottomRight(250,250)
  //
  // FINDING (issue #43 evaluation): The tight-bounds fix does NOT resolve
  // the reversed-n 25% bug.  The 0.25 score arises because the reversed path
  // visits the first waypoint (topLeft) only at its very last point, leaving
  // no remaining points to match the other three.  This is an algorithmic
  // property of matchWaypoints, independent of the bounds rect used.

  group("'n' — correct path (topLeft→bottomLeft→top→bottomRight) → 1.0", () {
    // Points exactly at waypoint centroids in order.
    final correctN = Stroke([
      Offset(50, 50),   // topLeft
      Offset(50, 250),  // bottomLeft
      Offset(150, 50),  // top
      Offset(250, 250), // bottomRight
    ]);

    final nData = letterFormationRegistry['n']!;

    test('compound scorer overall = 1.0', () {
      final scorer =
          CompoundStrokeScorer(letter: 'n', data: nData, bounds: bounds);
      final result = scorer.score([correctN]);
      expect(result.overallScore, 1.0);
    });

    test('start scorer overall = 1.0 (first point in top region)', () {
      final scorer =
          StrokeStartScorer(letter: 'n', data: nData, bounds: bounds);
      final result = scorer.score([correctN]);
      expect(result.overallScore, 1.0);
    });
  });

  group(
      "'n' — reversed path (bottomRight→top→bottomLeft→topLeft) — "
      'issue #43: bounds fix does not resolve 25% score', () {
    // Reversed path: visits waypoints in the wrong order.
    // matchWaypoints scans from the start for topLeft(50,50):
    //   idx=0 (250,250): dist=283 > 50 → skip
    //   idx=1 (150,50):  dist=100 > 50 → skip
    //   idx=2 (50,250):  dist=200 > 50 → skip
    //   idx=3 (50,50):   dist=0 ≤ 50 → HIT topLeft at idx=3 (last point!)
    // After hitting topLeft, remaining waypoints have no points after idx=3
    // → all MISS.
    // Score: 1/4 = 0.25.  This is unchanged by the tight-bounds fix.
    final reversedN = Stroke([
      Offset(250, 250), // bottomRight (expected 4th)
      Offset(150, 50),  // top (expected 3rd)
      Offset(50, 250),  // bottomLeft (expected 2nd)
      Offset(50, 50),   // topLeft (expected 1st — hit at last position)
    ]);

    final nData = letterFormationRegistry['n']!;

    test(
        'compound scorer overall = 0.25 (1/4 waypoints hit — '
        'topLeft only, found at the last point)', () {
      final scorer =
          CompoundStrokeScorer(letter: 'n', data: nData, bounds: bounds);
      final result = scorer.score([reversedN]);
      expect(result.overallScore, closeTo(0.25, 1e-9),
          reason: 'The reversed path ends at topLeft, which is the first '
              'expected waypoint.  Only 1 of 4 waypoints is hit because the '
              'remaining 3 have no observed points after the topLeft hit.');
    });

    test('start scorer overall = 0.0 — reversed n starts at bottom', () {
      final scorer =
          StrokeStartScorer(letter: 'n', data: nData, bounds: bounds);
      final result = scorer.score([reversedN]);
      expect(result.overallScore, 0.0,
          reason: 'First point (250,250) is in the bottom third; expected top '
              '→ opposite mismatch → 0.0.');
    });

    test(
        'observation expected=top, observed=bottom for the reversed stroke',
        () {
      final scorer =
          StrokeStartScorer(letter: 'n', data: nData, bounds: bounds);
      final result = scorer.score([reversedN]);
      expect(result.observations.first.expected, 'top');
      expect(result.observations.first.observed, 'bottom');
    });

    test(
        'compound observation shows topLeft as hit, others as missed', () {
      final scorer =
          CompoundStrokeScorer(letter: 'n', data: nData, bounds: bounds);
      final result = scorer.score([reversedN]);
      // The observed string lists every waypoint; misses are wrapped in
      // "[missed …]".  Only topLeft should appear without the miss marker.
      final observed = result.observations.first.observed;
      expect(observed, contains('topLeft'),
          reason: 'topLeft was the single hit');
      expect(observed, contains('[missed bottomLeft]'),
          reason: 'bottomLeft had no remaining points after the topLeft hit');
      expect(observed, contains('[missed top]'));
      expect(observed, contains('[missed bottomRight]'));
    });
  });

  // ── 'm' — single compound stroke ─────────────────────────────────────────
  //
  // Waypoints: topLeft→bottomLeft→top→bottom→top→bottomRight (6 waypoints)
  //
  // FINDING: Correct path scores 1.0.  Path score responds predictably.

  group("'m' — perfect path visiting all 6 waypoints in order → 1.0", () {
    // Visit each centroid exactly; 'top' (150,50) appears at both idx=2 and
    // idx=4 to satisfy the repeated waypoint.
    final perfectM = Stroke([
      Offset(50, 50),   // topLeft
      Offset(50, 250),  // bottomLeft
      Offset(150, 50),  // top (1st arch peak)
      Offset(150, 250), // bottom
      Offset(150, 50),  // top (2nd arch peak)
      Offset(250, 250), // bottomRight
    ]);

    final mData = letterFormationRegistry['m']!;

    test('compound scorer overall = 1.0', () {
      final scorer =
          CompoundStrokeScorer(letter: 'm', data: mData, bounds: bounds);
      final result = scorer.score([perfectM]);
      expect(result.overallScore, 1.0);
    });

    test('start scorer overall = 1.0', () {
      final scorer =
          StrokeStartScorer(letter: 'm', data: mData, bounds: bounds);
      final result = scorer.score([perfectM]);
      expect(result.overallScore, 1.0);
    });
  });

  group("'m' — path missing the second arch peak → 5/6", () {
    // Omit the second visit to 'top'; the last waypoint (bottomRight) is
    // still hit but the second 'top' is missed.
    final partialM = Stroke([
      Offset(50, 50),   // topLeft     ✓
      Offset(50, 250),  // bottomLeft  ✓
      Offset(150, 50),  // top (1st)   ✓
      Offset(150, 250), // bottom      ✓
      Offset(250, 250), // bottomRight ✓  (2nd top skipped → bottomRight still reachable)
    ]);

    final mData = letterFormationRegistry['m']!;

    test('compound scorer overall ≈ 5/6', () {
      final scorer =
          CompoundStrokeScorer(letter: 'm', data: mData, bounds: bounds);
      final result = scorer.score([partialM]);
      expect(result.overallScore, closeTo(5 / 6, 1e-9));
    });
  });

  // ── 'u' — single compound stroke ─────────────────────────────────────────
  //
  // Waypoints: topLeft→bottomLeft→bottom→bottomRight→topRight (5 waypoints)

  group("'u' — perfect path visiting all 5 waypoints in order → 1.0", () {
    final perfectU = Stroke([
      Offset(50, 50),   // topLeft
      Offset(50, 250),  // bottomLeft
      Offset(150, 250), // bottom
      Offset(250, 250), // bottomRight
      Offset(250, 50),  // topRight
    ]);

    final uData = letterFormationRegistry['u']!;

    test('compound scorer overall = 1.0', () {
      final scorer =
          CompoundStrokeScorer(letter: 'u', data: uData, bounds: bounds);
      final result = scorer.score([perfectU]);
      expect(result.overallScore, 1.0);
    });

    test('start scorer overall = 1.0', () {
      final scorer =
          StrokeStartScorer(letter: 'u', data: uData, bounds: bounds);
      final result = scorer.score([perfectU]);
      expect(result.overallScore, 1.0);
    });
  });

  group("'u' — reversed path (topRight→bottomRight→bottom→bottomLeft→topLeft) → low score",
      () {
    final reversedU = Stroke([
      Offset(250, 50),  // topRight (expected 5th)
      Offset(250, 250), // bottomRight (expected 4th)
      Offset(150, 250), // bottom (expected 3rd)
      Offset(50, 250),  // bottomLeft (expected 2nd)
      Offset(50, 50),   // topLeft (expected 1st — hit at last position)
    ]);

    final uData = letterFormationRegistry['u']!;

    test('compound scorer overall = 0.2 (1/5 — only topLeft hit at the end)',
        () {
      final scorer =
          CompoundStrokeScorer(letter: 'u', data: uData, bounds: bounds);
      final result = scorer.score([reversedU]);
      expect(result.overallScore, closeTo(1 / 5, 1e-9),
          reason: 'Reversed u path ends at topLeft, the first expected '
              'waypoint.  Only 1/5 waypoints is hit.');
    });
  });

  // ── 'h' — stem (topToBottom/top) + compound arch (middle) ────────────────
  //
  // exp[0]: topToBottom, startRegion=top    → centroid (150, 50)
  // exp[1]: compound,    startRegion=middle → centroid average of
  //         left(50,150) + top(150,50) + bottomRight(250,250) = (150, 150)
  //
  // FINDING: A short stem (centroid y=45) correctly pairs with exp[0].
  // A full-height stem (centroid y=140, closer to exp[1] at y=150 than
  // exp[0] at y=50) causes the same centroid mis-pairing seen in 'f' and 't'.

  group("'h' — short stem + arch — correct pairing", () {
    // Stem: (150,20)→(150,80).  Centroid (150,50) → exp[0].
    // Arch visits left(50,150)→top(150,50)→bottomRight(250,250).
    //   Arch centroid: (150,150) → exp[1].
    final hStemShort = Stroke([Offset(150, 20), Offset(150, 80)]);
    final hArch = Stroke([
      Offset(50, 150),  // left
      Offset(150, 50),  // top
      Offset(250, 250), // bottomRight
    ]);

    final hData = letterFormationRegistry['h']!;

    test('matchStrokes produces [0, 1] — correct pairing', () {
      final result = matchStrokes([hStemShort, hArch], hData.strokes, bounds);
      expect(result, [0, 1]);
    });

    test('compound scorer overall = 1.0 (arch visits all 3 waypoints)', () {
      final scorer =
          CompoundStrokeScorer(letter: 'h', data: hData, bounds: bounds);
      final result = scorer.score([hStemShort, hArch]);
      expect(result.overallScore, 1.0);
    });

    test('start scorer overall = 1.0', () {
      // Stem (→exp[0] top): first pt y=20 → top → 1.0.
      // Arch (→exp[1] middle): first pt y=150 → middle → 1.0.
      final scorer =
          StrokeStartScorer(letter: 'h', data: hData, bounds: bounds);
      final result = scorer.score([hStemShort, hArch]);
      expect(result.overallScore, 1.0);
    });
  });

  group("'h' — full-height stem + arch — mis-pairing", () {
    // Stem: (150,10)→(150,270).  Centroid y=140.
    //   dist² to exp[0](150,50) = 90² = 8100
    //   dist² to exp[1](150,150) = 10² =  100  ← closer → stem→exp[1]
    final hStemFull = Stroke([Offset(150, 10), Offset(150, 270)]);
    final hArch = Stroke([
      Offset(50, 150),
      Offset(150, 50),
      Offset(250, 250),
    ]);

    final hData = letterFormationRegistry['h']!;

    test('matchStrokes produces [1, 0] — stem mis-paired to compound expected',
        () {
      final result = matchStrokes([hStemFull, hArch], hData.strokes, bounds);
      expect(result, [1, 0]);
    });

    test(
        'compound scorer overall ≈ 1/3 — stem evaluated against compound '
        'waypoints: only the top waypoint is within tolerance', () {
      // Stem path (150,10)→(150,270) evaluated against [left, top, bottomRight]:
      //   left(50,150): closest stem pt is (150,270) at dist≈156 > 50 → MISS
      //   top(150,50):  closest stem pt is (150,10) at dist=40 ≤ 50  → HIT
      //   bottomRight(250,250): (150,270) at dist≈102 > 50             → MISS
      // Score: 1/3.
      final scorer =
          CompoundStrokeScorer(letter: 'h', data: hData, bounds: bounds);
      final result = scorer.score([hStemFull, hArch]);
      expect(result.overallScore, closeTo(1 / 3, 1e-9));
    });

    test('start scorer overall = 0.5 (both strokes evaluate against swapped '
        'expected regions)', () {
      final scorer =
          StrokeStartScorer(letter: 'h', data: hData, bounds: bounds);
      final result = scorer.score([hStemFull, hArch]);
      expect(result.overallScore, 0.5);
    });
  });

  // ── 'k' — stem (topToBottom/top) + compound kick (top) ───────────────────
  //
  // exp[0]: topToBottom, startRegion=top → centroid (150, 50)
  // exp[1]: compound, startRegion=top,
  //         waypoints [topRight(250,50), middle(150,150), bottomRight(250,250)]
  //         → centroid (216.7, 150)
  //
  // FINDING: When the stem is drawn on the LEFT side (x≈50), its centroid at
  // (50, 140) is closer to exp[0] (150, 50) than to exp[1] (216.7, 150),
  // producing correct pairing.  When the stem is drawn down the centre
  // (x=150), its centroid at (150, 140) is closer to exp[1], causing
  // mis-pairing analogous to 'f', 't', and 'h'.

  group("'k' — left-side stem + kick — correct pairing", () {
    // Stem: (50,10)→(50,270).  Centroid (50,140).
    //   dist² to exp[0](150,50)  = 100²+90² = 18100
    //   dist² to exp[1](216.7,150) = 166.7²+10² ≈ 27890  ← farther → exp[0]
    // Kick: (250,50)→(150,150)→(250,250).  Centroid ≈ (216.7, 150) → exp[1].
    final kStemLeft = Stroke([Offset(50, 10), Offset(50, 270)]);
    final kKick = Stroke([
      Offset(250, 50),  // topRight
      Offset(150, 150), // middle
      Offset(250, 250), // bottomRight
    ]);

    final kData = letterFormationRegistry['k']!;

    test('matchStrokes produces [0, 1] — stem→exp[0], kick→exp[1]', () {
      final result = matchStrokes([kStemLeft, kKick], kData.strokes, bounds);
      expect(result, [0, 1]);
    });

    test('compound scorer overall = 1.0 (kick visits all 3 waypoints)', () {
      final scorer =
          CompoundStrokeScorer(letter: 'k', data: kData, bounds: bounds);
      final result = scorer.score([kStemLeft, kKick]);
      expect(result.overallScore, 1.0);
    });

    test('start scorer overall = 1.0', () {
      // Stem (→exp[0] top): first pt y=10 → top → 1.0.
      // Kick (→exp[1] top): first pt y=50 → top → 1.0.
      final scorer =
          StrokeStartScorer(letter: 'k', data: kData, bounds: bounds);
      final result = scorer.score([kStemLeft, kKick]);
      expect(result.overallScore, 1.0);
    });
  });

  group("'k' — centre stem + kick — mis-pairing", () {
    // Stem: (150,10)→(150,270).  Centroid (150,140).
    //   dist² to exp[0](150,50)  = 90²   = 8100
    //   dist² to exp[1](216.7,150) ≈ 66.7²+10² ≈ 4549 ← closer → exp[1]
    final kStemCentre = Stroke([Offset(150, 10), Offset(150, 270)]);
    final kKick = Stroke([
      Offset(250, 50),
      Offset(150, 150),
      Offset(250, 250),
    ]);

    final kData = letterFormationRegistry['k']!;

    test('matchStrokes produces [1, 0] — centre stem mis-paired to kick expected',
        () {
      final result =
          matchStrokes([kStemCentre, kKick], kData.strokes, bounds);
      expect(result, [1, 0]);
    });

    test(
        'compound scorer overall = 0.0 — stem does not visit kick waypoints',
        () {
      // Stem (150,10)→(150,270) evaluated against
      //   [topRight(250,50), middle(150,150), bottomRight(250,250)]:
      //   topRight(250,50): closest pt (150,10), dist≈107 > 50 → MISS
      //   middle(150,150):  closest pt (150,10) dist=140 or (150,270) dist=120, both > 50 → MISS
      //   bottomRight(250,250): closest pt (150,270), dist≈102 > 50 → MISS
      // Score: 0/3 = 0.0.
      final scorer =
          CompoundStrokeScorer(letter: 'k', data: kData, bounds: bounds);
      final result = scorer.score([kStemCentre, kKick]);
      expect(result.overallScore, 0.0,
          reason: 'Centre stem evaluated against kick waypoints scores 0/3 '
              'because all kick waypoints are more than 50 px from any stem '
              'point.');
    });
  });
}
