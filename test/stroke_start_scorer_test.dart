import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';
import 'package:handwriting_mvp/models/stroke_start_scorer.dart';

import 'helpers/start_rect_for_region.dart';

void main() {
  // 300×300 bounding box used throughout.
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  group('StrokeStartScorer', () {
    // ── Constructor ──────────────────────────────────────────────────────────

    group('constructor', () {
      test('accepts any data without throwing', () {
        // The constructor no longer validates startRegion — any data is accepted.
        final data = LetterFormationData(
          minRequiredStrokes: 1,
          strokes: [
            ExpectedStroke(
              primaryDirection: StrokeDirection.topToBottom,
              startRegion: StrokeStartRegion.bottom,
              startRect: const StrokeStartRect(
                  minX: 0.0, maxX: 1.0, minY: 2.0 / 3.0, maxY: 1.0),
            ),
          ],
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
    // startRect: minX=0, maxX=0.25, minY=0, maxY=0.15
    //   → in 300×300 bounds: x ∈ [0, 75), y ∈ [0, 45)
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
        expect(result.observations[0].expected, 'x 0–25%, y 0–15%');
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
        expect(result.observations[0].expected, 'x 0–25%, y 0–15%');
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
    //   stroke 0: stem,    startRect minX=0, maxX=0.25, minY=0,    maxY=0.15
    //   stroke 1: crossbar startRect minX=0, maxX=0.20, minY=0.26, maxY=0.38
    //
    // Correct strokes:
    //   observed[0]: first (20, 20)  → rx=7%,  ry=7%  → inside stem rect
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
          // Stem: centroid (150, 50), first point inside stem rect.
          Stroke([const Offset(20, 20), const Offset(280, 80)]),
          // Crossbar: centroid (150, 150), first point inside crossbar rect.
          Stroke([const Offset(20, 90), const Offset(280, 210)]),
        ];
        final result = scorer.score(observed);
        expect(result.overallScore, 1.0);
      });

      test('two observations are produced', () {
        final observed = [
          Stroke([const Offset(20, 20), const Offset(280, 80)]),
          Stroke([const Offset(20, 90), const Offset(280, 210)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations.length, 2);
      });

      test('stroke 0 observation: correct stem rect and point', () {
        final observed = [
          Stroke([const Offset(20, 20), const Offset(280, 80)]),
          Stroke([const Offset(20, 90), const Offset(280, 210)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[0].expected, 'x 0–25%, y 0–15%');
        expect(result.observations[0].observed, '(7%, 7%)');
        expect(result.observations[0].score, 1.0);
      });

      test('stroke 1 observation: correct crossbar rect and point', () {
        final observed = [
          Stroke([const Offset(20, 20), const Offset(280, 80)]),
          Stroke([const Offset(20, 90), const Offset(280, 210)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[1].expected, 'x 0–20%, y 26–38%');
        expect(result.observations[1].observed, '(7%, 30%)');
        expect(result.observations[1].score, 1.0);
      });

      test('summary is the all-correct sentence', () {
        final observed = [
          Stroke([const Offset(20, 20), const Offset(280, 80)]),
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
          // Stem: centroid (150, 50), first point inside stem rect.
          Stroke([const Offset(20, 20), const Offset(280, 80)]),
          // Crossbar: centroid (150, 150), first point above crossbar rect.
          Stroke([const Offset(10, 50), const Offset(290, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.overallScore, closeTo(0.5, 1e-9));
      });

      test('crossbar observation: outside rect → score = 0.0', () {
        final observed = [
          Stroke([const Offset(20, 20), const Offset(280, 80)]),
          Stroke([const Offset(10, 50), const Offset(290, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[1].expected, 'x 0–20%, y 26–38%');
        expect(result.observations[1].score, 0.0);
      });

      test('summary mentions the wrong place', () {
        final observed = [
          Stroke([const Offset(20, 20), const Offset(280, 80)]),
          Stroke([const Offset(10, 50), const Offset(290, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.summary, contains('wrong place'));
      });
    });

    // ── Hard-cliff scoring table ─────────────────────────────────────────────
    //
    // Verifies the binary inside/outside scoring with no partial credit.
    // Uses full-width vertical bands via startRectForRegion so that only the
    // vertical position determines membership.

    group('hard-cliff scoring table', () {
      // Single-stroke formation data using a full-width band for the given region.
      LetterFormationData singleStrokeData(StrokeStartRegion region) =>
          LetterFormationData(
            minRequiredStrokes: 1,
            strokes: [
              ExpectedStroke(
                primaryDirection: StrokeDirection.topToBottom,
                startRegion: region,
                startRect: startRectForRegion(region),
              ),
            ],
          );

      // A stroke whose first point is in the specified region's y-band and
      // whose bounding-box centroid stays at (150, 50) so it always matches.
      Stroke strokeStartingIn(StrokeStartRegion region) {
        final firstY = switch (region) {
          StrokeStartRegion.top => 50.0,
          StrokeStartRegion.middle => 150.0,
          StrokeStartRegion.bottom => 250.0,
        };
        return Stroke([Offset(150, firstY), const Offset(150, 50)]);
      }

      test('top expected, top observed → 1.0', () {
        final scorer = StrokeStartScorer(
          letter: 'a',
          data: singleStrokeData(StrokeStartRegion.top),
          bounds: bounds,
        );
        final result =
            scorer.score([strokeStartingIn(StrokeStartRegion.top)]);
        expect(result.overallScore, 1.0);
      });

      test('top expected, middle observed → 0.0 (hard cliff, no partial credit)',
          () {
        final scorer = StrokeStartScorer(
          letter: 'a',
          data: singleStrokeData(StrokeStartRegion.top),
          bounds: bounds,
        );
        final result =
            scorer.score([strokeStartingIn(StrokeStartRegion.middle)]);
        expect(result.overallScore, 0.0);
      });

      test('top expected, bottom observed → 0.0', () {
        final scorer = StrokeStartScorer(
          letter: 'a',
          data: singleStrokeData(StrokeStartRegion.top),
          bounds: bounds,
        );
        final result =
            scorer.score([strokeStartingIn(StrokeStartRegion.bottom)]);
        expect(result.overallScore, 0.0);
      });

      test('middle expected, middle observed → 1.0', () {
        final scorer = StrokeStartScorer(
          letter: 't',
          data: singleStrokeData(StrokeStartRegion.middle),
          bounds: bounds,
        );
        final result =
            scorer.score([strokeStartingIn(StrokeStartRegion.middle)]);
        expect(result.overallScore, 1.0);
      });

      test('middle expected, top observed → 0.0 (hard cliff, no partial credit)',
          () {
        final scorer = StrokeStartScorer(
          letter: 't',
          data: singleStrokeData(StrokeStartRegion.middle),
          bounds: bounds,
        );
        final result =
            scorer.score([strokeStartingIn(StrokeStartRegion.top)]);
        expect(result.overallScore, 0.0);
      });

      test(
          'middle expected, bottom observed → 0.0 (hard cliff, no partial credit)',
          () {
        final scorer = StrokeStartScorer(
          letter: 't',
          data: singleStrokeData(StrokeStartRegion.middle),
          bounds: bounds,
        );
        final result =
            scorer.score([strokeStartingIn(StrokeStartRegion.bottom)]);
        expect(result.overallScore, 0.0);
      });
    });
  });
}
