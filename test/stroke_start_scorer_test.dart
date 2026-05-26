import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart'
    show StrokeDirection;
import 'package:handwriting_mvp/models/stroke_start_rect.dart';
import 'package:handwriting_mvp/models/stroke_start_scorer.dart';

void main() {
  // 300×300 bounding box used throughout.
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  // ── Helpers ──────────────────────────────────────────────────────────────────

  // Creates a stroke whose bounding-box centroid is at (150, 50) — in the
  // top third of a 300×300 bounds — so [matchStrokes] always assigns it to
  // the first expected stroke (which defaults to a top-region centroid).
  //
  // Works for first.dy in [0, 100].
  Stroke strokeWithFirst(Offset first) =>
      Stroke([first, Offset(300 - first.dx, 100 - first.dy)]);

  // Creates a single-stroke [LetterFormationData] whose expected first point
  // must fall inside [rect].  The startRect centroid determines where
  // [matchStrokes] places the expected centroid.
  LetterFormationData singleStrokeData(StrokeStartRect rect) =>
      LetterFormationData(
        minRequiredStrokes: 1,
        strokes: [
          ExpectedStroke(
            primaryDirection: StrokeDirection.topToBottom,
            startRect: rect,
          ),
        ],
      );

  group('StrokeStartScorer', () {
    // ── Constructor ──────────────────────────────────────────────────────────

    group('constructor', () {
      test('accepts custom single-stroke data without throwing', () {
        final data = singleStrokeData(
          const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0),
        );
        expect(
          () => StrokeStartScorer(letter: 'x', data: data, bounds: bounds),
          returnsNormally,
        );
      });

      test('accepts registry data without throwing', () {
        final goodData = letterFormationRegistry['t']!;
        expect(
          () => StrokeStartScorer(letter: 't', data: goodData, bounds: bounds),
          returnsNormally,
        );
      });
    });

    // ── Correct 'n' ─────────────────────────────────────────────────────────
    //
    // 'n' is a single compound stroke.
    // startRect: minX=0, maxX=0.30, minY=0, maxY=0.20
    //   → in 300×300 bounds: x ∈ [0, 90), y ∈ [0, 60)
    //
    // Correct first point: (30, 30) → rx=10%, ry=10% → inside rect → 1.0

    group("correct 'n'", () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'n',
          data: letterFormationRegistry['n']!,
          bounds: bounds,
        );
      });

      test('overallScore is 1.0', () {
        // First point at (30, 30) — inside n's startRect (x:0–75, y:0–45).
        final observed = [
          Stroke([const Offset(30, 30), const Offset(250, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.overallScore, 1.0);
      });

      test('one observation is produced', () {
        final observed = [
          Stroke([const Offset(30, 30), const Offset(250, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations.length, 1);
      });

      test('observation expected is rect label, observed is point label', () {
        final observed = [
          Stroke([const Offset(30, 30), const Offset(250, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[0].expected, 'x 0–30%, y 0–20%');
        expect(result.observations[0].observed, '(10%, 10%)');
        expect(result.observations[0].score, 1.0);
      });

      test('note says started in the right place', () {
        final observed = [
          Stroke([const Offset(30, 30), const Offset(250, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[0].note, 'Started in the right place.');
      });

      test('summary is the all-correct sentence', () {
        final observed = [
          Stroke([const Offset(30, 30), const Offset(250, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.summary, 'All strokes started in the right place.');
      });
    });

    // ── Reversed 'n' ────────────────────────────────────────────────────────
    //
    // Learner draws the compound stroke starting at bottom-right.
    // First point (280, 280) → rx=93%, ry=93% → outside rect → 0.0.

    group("reversed 'n' (start at bottom-right)", () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'n',
          data: letterFormationRegistry['n']!,
          bounds: bounds,
        );
      });

      test('overallScore is 0.0', () {
        // First point at (280, 280) — well outside n's startRect.
        final observed = [
          Stroke([const Offset(280, 280), const Offset(50, 50)]),
        ];
        final result = scorer.score(observed);
        expect(result.overallScore, 0.0);
      });

      test('observation expected is rect label, observed is point label', () {
        final observed = [
          Stroke([const Offset(280, 280), const Offset(50, 50)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[0].expected, 'x 0–30%, y 0–20%');
        expect(result.observations[0].observed, '(93%, 93%)');
        expect(result.observations[0].score, 0.0);
      });

      test('note gives a directional hint', () {
        final observed = [
          Stroke([const Offset(280, 280), const Offset(50, 50)]),
        ];
        final result = scorer.score(observed);
        // Observed point is bottom-right relative to the expected rect centre;
        // expected rect centre is top-left relative to the template midpoint.
        expect(
          result.observations[0].note,
          'Started bottom-right; should start in the top-left area.',
        );
      });

      test('summary mentions the wrong place', () {
        final observed = [
          Stroke([const Offset(280, 280), const Offset(50, 50)]),
        ];
        final result = scorer.score(observed);
        expect(result.summary, contains('wrong place'));
      });
    });

    // ── 't' with both strokes starting correctly ─────────────────────────────
    //
    // 't' has two expected strokes:
    //   stroke 0: stem,    startRect minX=0.35, maxX=0.65, minY=0,    maxY=0.15
    //   stroke 1: crossbar startRect minX=0,    maxX=0.24, minY=0.26, maxY=0.38
    //
    // Correct strokes:
    //   observed[0]: first (120, 20) → rx=40%, ry=7%  → inside stem rect
    //   observed[1]: first (20, 90)  → rx=7%,  ry=30% → inside crossbar rect

    group("'t' both strokes starting correctly", () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 't',
          data: letterFormationRegistry['t']!,
          bounds: bounds,
        );
      });

      test('overallScore is 1.0', () {
        final observed = [
          // Stem: centroid (200, 50), first point inside stem rect.
          Stroke([const Offset(120, 20), const Offset(280, 80)]),
          // Crossbar: centroid (150, 150), first point inside crossbar rect.
          Stroke([const Offset(20, 90), const Offset(280, 210)]),
        ];
        final result = scorer.score(observed);
        expect(result.overallScore, 1.0);
      });

      test('two observations are produced', () {
        final observed = [
          Stroke([const Offset(120, 20), const Offset(280, 80)]),
          Stroke([const Offset(20, 90), const Offset(280, 210)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations.length, 2);
      });

      test('stroke 0 observation: correct stem rect and point', () {
        final observed = [
          Stroke([const Offset(120, 20), const Offset(280, 80)]),
          Stroke([const Offset(20, 90), const Offset(280, 210)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[0].expected, 'x 35–65%, y 0–15%');
        expect(result.observations[0].observed, '(40%, 7%)');
        expect(result.observations[0].score, 1.0);
      });

      test('stroke 1 observation: correct crossbar rect and point', () {
        final observed = [
          Stroke([const Offset(120, 20), const Offset(280, 80)]),
          Stroke([const Offset(20, 90), const Offset(280, 210)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[1].expected, 'x 0–24%, y 26–38%');
        expect(result.observations[1].observed, '(7%, 30%)');
        expect(result.observations[1].score, 1.0);
      });

      test('summary is the all-correct sentence', () {
        final observed = [
          Stroke([const Offset(120, 20), const Offset(280, 80)]),
          Stroke([const Offset(20, 90), const Offset(280, 210)]),
        ];
        final result = scorer.score(observed);
        expect(result.summary, 'All strokes started in the right place.');
      });
    });

    // ── 't' with crossbar starting in wrong place (hard cliff → 0.0) ─────────
    //
    // Stem correct, crossbar first point outside its startRect.
    // Expected crossbar score = 0.0; overall = (1.0 + 0.0) / 2 = 0.5.

    group("'t' crossbar starting in wrong place", () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 't',
          data: letterFormationRegistry['t']!,
          bounds: bounds,
        );
      });

      test('overallScore is 0.5', () {
        final observed = [
          // Stem: centroid (200, 50), first point inside stem rect.
          Stroke([const Offset(120, 20), const Offset(280, 80)]),
          // Crossbar: centroid (150, 150), first point above crossbar rect.
          Stroke([const Offset(10, 50), const Offset(290, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.overallScore, closeTo(0.5, 1e-9));
      });

      test('crossbar observation: outside rect → score = 0.0', () {
        final observed = [
          Stroke([const Offset(120, 20), const Offset(280, 80)]),
          Stroke([const Offset(10, 50), const Offset(290, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[1].expected, 'x 0–24%, y 26–38%');
        expect(result.observations[1].score, 0.0);
      });

      test('summary mentions the wrong place', () {
        final observed = [
          Stroke([const Offset(120, 20), const Offset(280, 80)]),
          Stroke([const Offset(10, 50), const Offset(290, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.summary, contains('wrong place'));
      });
    });

    // ── Inside-rect → 1.0 ────────────────────────────────────────────────────
    //
    // Uses 'n' startRect: minX=0, maxX=0.30, minY=0, maxY=0.20.
    // → in 300×300: x ∈ [0, 90), y ∈ [0, 60).

    group('inside-rect → 1.0', () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'n',
          data: letterFormationRegistry['n']!,
          bounds: bounds,
        );
      });

      test('first point at centre of startRect → 1.0', () {
        // Centre: x = (0 + 75) / 2 = 37, y = (0 + 45) / 2 = 22.
        final result = scorer.score([strokeWithFirst(const Offset(37, 22))]);
        expect(result.overallScore, 1.0);
      });

      test('first point just inside left edge (x=1, rx≈0.3%) → 1.0', () {
        final result = scorer.score([strokeWithFirst(const Offset(1, 22))]);
        expect(result.overallScore, 1.0);
      });

      test('first point just inside right edge (x=74, rx≈24.7%) → 1.0', () {
        // rx = 74 / 300 ≈ 0.247 < 0.25 → inside.
        final result = scorer.score([strokeWithFirst(const Offset(74, 22))]);
        expect(result.overallScore, 1.0);
      });

      test('first point just inside top edge (y=1, ry≈0.3%) → 1.0', () {
        final result = scorer.score([strokeWithFirst(const Offset(37, 1))]);
        expect(result.overallScore, 1.0);
      });

      test('first point just inside bottom edge (y=44, ry≈14.7%) → 1.0', () {
        // ry = 44 / 300 ≈ 0.147 < 0.15 → inside.
        final result = scorer.score([strokeWithFirst(const Offset(37, 44))]);
        expect(result.overallScore, 1.0);
      });
    });

    // ── Outside-rect → 0.0 ───────────────────────────────────────────────────
    //
    // Uses 'n' startRect: minX=0, maxX=0.30, minY=0, maxY=0.20.
    // → in 300×300: x ∈ [0, 90), y ∈ [0, 60).

    group('outside-rect → 0.0', () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'n',
          data: letterFormationRegistry['n']!,
          bounds: bounds,
        );
      });

      test('first point just outside right edge (x=90, rx=30%) → 0.0', () {
        // rx = 90 / 300 = 0.30 = maxX → outside (exclusive upper bound).
        final result = scorer.score([strokeWithFirst(const Offset(90, 22))]);
        expect(result.overallScore, 0.0);
      });

      test('first point just outside bottom edge (y=60, ry=20%) → 0.0', () {
        // ry = 60 / 300 = 0.20 = maxY → outside (exclusive upper bound).
        final result = scorer.score([strokeWithFirst(const Offset(37, 60))]);
        expect(result.overallScore, 0.0);
      });

      test('first point in completely different quadrant (bottom-right) → 0.0',
          () {
        final result = scorer.score([
          Stroke([const Offset(280, 280), const Offset(50, 50)]),
        ]);
        expect(result.overallScore, 0.0);
      });
    });

    // ── Mean across strokes ───────────────────────────────────────────────────
    //
    // Uses 't' (two expected strokes):
    //   stem    startRect: x ∈ [105, 195), y ∈ [0,  45)
    //   crossbar startRect: x ∈ [0,   72), y ∈ [78, 114)
    //
    // overallScore is the mean of per-stroke scores.

    group('mean across strokes', () {
      test('all strokes inside → 1.0', () {
        final scorer = StrokeStartScorer(
          letter: 't',
          data: letterFormationRegistry['t']!,
          bounds: bounds,
        );
        final result = scorer.score([
          // Stem: centroid (200, 50), first inside stem rect.
          Stroke([const Offset(120, 20), const Offset(280, 80)]),
          // Crossbar: centroid (150, 150), first inside crossbar rect.
          Stroke([const Offset(20, 90), const Offset(280, 210)]),
        ]);
        expect(result.overallScore, 1.0);
      });

      test('all strokes outside → 0.0', () {
        final scorer = StrokeStartScorer(
          letter: 't',
          data: letterFormationRegistry['t']!,
          bounds: bounds,
        );
        // Stem stroke:    centroid (150, 50),  first outside stem rect.
        // Crossbar stroke: centroid (150, 150), first outside crossbar rect.
        final result = scorer.score([
          Stroke([const Offset(200, 20), const Offset(100, 80)]),
          Stroke([const Offset(200, 200), const Offset(100, 100)]),
        ]);
        expect(result.overallScore, 0.0);
      });

      test('one inside, one outside → 0.5', () {
        final scorer = StrokeStartScorer(
          letter: 't',
          data: letterFormationRegistry['t']!,
          bounds: bounds,
        );
        final result = scorer.score([
          // Stem: inside stem rect (first at (120, 20) → rx=40%, ry=7%).
          Stroke([const Offset(120, 20), const Offset(280, 80)]),
          // Crossbar: first point above crossbar rect → outside.
          Stroke([const Offset(10, 50), const Offset(290, 250)]),
        ]);
        expect(result.overallScore, closeTo(0.5, 1e-9));
      });
    });

    // ── Edge convention ───────────────────────────────────────────────────────
    //
    // Mirrors StrokeStartRect.contains: inclusive on the minimum edges
    // (minX, minY) and exclusive on the maximum edges (maxX, maxY).
    //
    // Uses 'n' startRect: minX=0.0, maxX=0.30, minY=0.0, maxY=0.20.
    // → in 300×300: x ∈ [0, 90), y ∈ [0, 60).

    group('edge convention', () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'n',
          data: letterFormationRegistry['n']!,
          bounds: bounds,
        );
      });

      test('point at minX=0 (inclusive left edge) → 1.0', () {
        final result = scorer.score([strokeWithFirst(const Offset(0, 22))]);
        expect(result.overallScore, 1.0);
      });

      test('point at minY=0 (inclusive top edge) → 1.0', () {
        final result = scorer.score([strokeWithFirst(const Offset(37, 0))]);
        expect(result.overallScore, 1.0);
      });

      test('point at maxX (x=90, rx=0.30, exclusive right edge) → 0.0', () {
        // rx = 90 / 300 = 0.30 = maxX → NOT inside (exclusive).
        final result = scorer.score([strokeWithFirst(const Offset(90, 22))]);
        expect(result.overallScore, 0.0);
      });

      test('point at maxY (y=60, ry=0.20, exclusive bottom edge) → 0.0', () {
        // ry = 60 / 300 = 0.20 = maxY → NOT inside (exclusive).
        final result = scorer.score([strokeWithFirst(const Offset(37, 60))]);
        expect(result.overallScore, 0.0);
      });
    });

    // ── 'v' regression: top-left startRect check fires ───────────────────────
    //
    // 'v' startRect: minX=0.00, maxX=0.25, minY=0.00, maxY=0.15
    //   → in 300×300 bounds: x ∈ [0, 75), y ∈ [0, 45)
    //
    // Regression for: StrokeStart rectangle check not firing for v (and other
    // top-left letters: w, z, x, y).
    // History: v/w/z/x/y originally used the StrokeStartRegion.top enum, which
    // was retired in 9df244e. StartRects assigned during PRs #94/#101 corrected
    // the bounds; these tests guard against regression.

    group("'v' top-left startRect check fires", () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'v',
          data: letterFormationRegistry['v']!,
          bounds: bounds,
        );
      });

      test('stroke starting inside top-left rect → overallScore 1.0', () {
        // First point (37, 22): rx≈12%, ry≈7% — inside x [0,25%), y [0,15%).
        final result = scorer.score([strokeWithFirst(const Offset(37, 22))]);
        expect(result.overallScore, 1.0);
      });

      test('stroke starting outside rect to the right → overallScore 0.0', () {
        // First point (200, 10): rx≈67% — outside x [0,25%).
        final result = scorer.score([strokeWithFirst(const Offset(200, 10))]);
        expect(result.overallScore, 0.0);
      });

      test('stroke starting below rect → overallScore 0.0', () {
        // First point (37, 60): ry=20% — outside y [0,15%).
        final result = scorer.score([strokeWithFirst(const Offset(37, 60))]);
        expect(result.overallScore, 0.0);
      });

      test('observation reports correct rect label', () {
        final result = scorer.score([strokeWithFirst(const Offset(37, 22))]);
        expect(result.observations[0].expected, 'x 0–25%, y 0–15%');
      });
    });

    // ── 'z' regression: same top-left rect as 'v' ────────────────────────────
    //
    // 'z' startRect: minX=0.00, maxX=0.25, minY=0.00, maxY=0.15 (same as 'v').

    group("'z' top-left startRect check fires", () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'z',
          data: letterFormationRegistry['z']!,
          bounds: bounds,
        );
      });

      test('stroke starting inside top-left rect → overallScore 1.0', () {
        final result = scorer.score([strokeWithFirst(const Offset(37, 22))]);
        expect(result.overallScore, 1.0);
      });

      test('stroke starting outside rect to the right → overallScore 0.0', () {
        // First point (200, 10): rx≈67% — outside x [0,25%).
        final result = scorer.score([strokeWithFirst(const Offset(200, 10))]);
        expect(result.overallScore, 0.0);
      });
    });

    // ── 'w' regression: same top-left rect as 'v' / 'z' ──────────────────────
    //
    // 'w' startRect: minX=0.00, maxX=0.25, minY=0.00, maxY=0.15. PR #101's
    // manual sweep widened this from 0.00–0.15 to 0.00–0.25.

    group("'w' top-left startRect check fires", () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'w',
          data: letterFormationRegistry['w']!,
          bounds: bounds,
        );
      });

      test('stroke starting inside top-left rect → overallScore 1.0', () {
        final result = scorer.score([strokeWithFirst(const Offset(37, 22))]);
        expect(result.overallScore, 1.0);
      });

      test('stroke starting outside rect to the right → overallScore 0.0', () {
        // First point (200, 10): rx≈67% — outside x [0,25%).
        final result = scorer.score([strokeWithFirst(const Offset(200, 10))]);
        expect(result.overallScore, 0.0);
      });
    });

    // ── 'x' regression: two top-corner startRects both fire ──────────────────
    //
    // 'x' has two expected strokes:
    //   stroke 0: startRect x [0,25%),  y [0,15%) — top-left,  centroid (37.5, 22.5)
    //   stroke 1: startRect x [75,100%), y [0,15%) — top-right, centroid (262.5, 22.5)
    //
    // Each test stroke is constructed so its bounding-box centroid is
    // unambiguously closer to one expected centroid than the other, so
    // [matchStrokes] does not depend on equidistant-tiebreak behaviour.
    //
    //   Stroke 0 "inside":  [(37,22), (40,80)]  → centroid (38.5, 51)  → expected 0
    //   Stroke 0 "outside": [(200,10), (0,50)]  → centroid (100, 30)  → expected 0
    //   Stroke 1 "inside":  [(250,5), (275,95)] → centroid (262.5, 50) → expected 1
    //   Stroke 1 "outside": [(100,5), (295,95)] → centroid (197.5, 50) → expected 1

    group("'x' both top-corner startRects fire", () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'x',
          data: letterFormationRegistry['x']!,
          bounds: bounds,
        );
      });

      test('both strokes starting in correct rects → overallScore 1.0', () {
        final result = scorer.score([
          Stroke([const Offset(37, 22), const Offset(40, 80)]), // expected 0, inside top-left
          Stroke([const Offset(250, 5), const Offset(275, 95)]), // expected 1, inside top-right
        ]);
        expect(result.overallScore, 1.0);
      });

      test('stroke 0 starts outside its rect → overallScore 0.5', () {
        // Centroid (100,30) → expected 0; first (200,10): rx≈67%, outside.
        final result = scorer.score([
          Stroke([const Offset(200, 10), const Offset(0, 50)]), // expected 0, outside
          Stroke([const Offset(250, 5), const Offset(275, 95)]), // expected 1, inside
        ]);
        expect(result.overallScore, closeTo(0.5, 1e-9));
      });

      test('stroke 1 starts outside its rect → overallScore 0.5', () {
        // Centroid (197.5,50) → expected 1; first (100,5): rx≈33%, outside.
        final result = scorer.score([
          Stroke([const Offset(37, 22), const Offset(40, 80)]), // expected 0, inside
          Stroke([const Offset(100, 5), const Offset(295, 95)]), // expected 1, outside
        ]);
        expect(result.overallScore, closeTo(0.5, 1e-9));
      });

      test('both strokes starting outside their rects → overallScore 0.0', () {
        final result = scorer.score([
          Stroke([const Offset(200, 10), const Offset(0, 50)]), // expected 0, outside
          Stroke([const Offset(100, 5), const Offset(295, 95)]), // expected 1, outside
        ]);
        expect(result.overallScore, 0.0);
      });
    });

    // ── 'y' regression: two top-corner startRects both fire ──────────────────
    //
    // 'y' has the same expected startRects as 'x' but minRequiredStrokes=1.
    // [StrokeStartScorer.score] does not consult minRequiredStrokes, so these
    // tests execute the same scorer paths as the 'x' tests above. They are
    // kept as a guard against future divergence (e.g. if 'y' ever moves to a
    // different rect, or if scoring starts to honour minRequiredStrokes).

    group("'y' both top-corner startRects fire", () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'y',
          data: letterFormationRegistry['y']!,
          bounds: bounds,
        );
      });

      test('both strokes starting in correct rects → overallScore 1.0', () {
        final result = scorer.score([
          Stroke([const Offset(37, 22), const Offset(40, 80)]),
          Stroke([const Offset(250, 5), const Offset(275, 95)]),
        ]);
        expect(result.overallScore, 1.0);
      });

      test('stroke 0 starts outside its rect → overallScore 0.5', () {
        final result = scorer.score([
          Stroke([const Offset(200, 10), const Offset(0, 50)]), // expected 0, outside
          Stroke([const Offset(250, 5), const Offset(275, 95)]), // expected 1, inside
        ]);
        expect(result.overallScore, closeTo(0.5, 1e-9));
      });

      test('stroke 1 starts outside its rect → overallScore 0.5', () {
        final result = scorer.score([
          Stroke([const Offset(37, 22), const Offset(40, 80)]), // expected 0, inside
          Stroke([const Offset(100, 5), const Offset(295, 95)]), // expected 1, outside
        ]);
        expect(result.overallScore, closeTo(0.5, 1e-9));
      });

      test('both strokes starting outside their rects → overallScore 0.0', () {
        final result = scorer.score([
          Stroke([const Offset(200, 10), const Offset(0, 50)]), // expected 0, outside
          Stroke([const Offset(100, 5), const Offset(295, 95)]), // expected 1, outside
        ]);
        expect(result.overallScore, 0.0);
      });
    });

    // ── Empty / unmatched strokes ─────────────────────────────────────────────

    group('empty / unmatched strokes', () {
      test('empty observed list → overallScore 0.0 and empty observations', () {
        final scorer = StrokeStartScorer(
          letter: 'n',
          data: letterFormationRegistry['n']!,
          bounds: bounds,
        );
        final result = scorer.score([]);
        expect(result.overallScore, 0.0);
        expect(result.observations, isEmpty);
      });

      test(
          'extra observed stroke (matchStrokes returns -1) → skipped, '
          'produces only one observation', () {
        // 'n' has 1 expected stroke; providing 2 observed means the 2nd is unmatched.
        final scorer = StrokeStartScorer(
          letter: 'n',
          data: letterFormationRegistry['n']!,
          bounds: bounds,
        );
        final result = scorer.score([
          Stroke([const Offset(30, 30), const Offset(250, 250)]),
          Stroke([const Offset(30, 30), const Offset(250, 250)]),
        ]);
        expect(result.observations.length, 1);
      });

      test('stroke with zero points → skipped, no observation produced', () {
        final scorer = StrokeStartScorer(
          letter: 'n',
          data: letterFormationRegistry['n']!,
          bounds: bounds,
        );
        final result = scorer.score([Stroke([])]);
        expect(result.observations, isEmpty);
        expect(result.overallScore, 0.0);
      });
    });

    // ── Observation payload ───────────────────────────────────────────────────
    //
    // Verifies the structure of each StrokeObservation.
    // Uses 'n' startRect: minX=0, maxX=0.30, minY=0, maxY=0.20.

    group('observation payload', () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 'n',
          data: letterFormationRegistry['n']!,
          bounds: bounds,
        );
      });

      test('expected describes the rect bounds as a percentage range', () {
        // n's startRect: x 0–30%, y 0–20%.
        final result = scorer.score([strokeWithFirst(const Offset(30, 30))]);
        expect(result.observations[0].expected, 'x 0–30%, y 0–20%');
      });

      test('observed describes the first point in relative percentage coords',
          () {
        // (30, 30) in 300×300 → rx = 10%, ry = 10%.
        final result = scorer.score([strokeWithFirst(const Offset(30, 30))]);
        expect(result.observations[0].observed, '(10%, 10%)');
      });

      test('note is "Started in the right place." when inside rect', () {
        final result = scorer.score([strokeWithFirst(const Offset(30, 30))]);
        expect(result.observations[0].note, 'Started in the right place.');
      });

      test('note differs from success when outside rect', () {
        final result = scorer.score([
          Stroke([const Offset(280, 280), const Offset(50, 50)]),
        ]);
        expect(
          result.observations[0].note,
          isNot('Started in the right place.'),
        );
        expect(result.observations[0].note, isNotEmpty);
      });
    });
  });
}
