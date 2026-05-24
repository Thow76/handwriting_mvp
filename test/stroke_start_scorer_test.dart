import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';
import 'package:handwriting_mvp/models/stroke_start_scorer.dart';

void main() {
  // 300×300 bounding box.  Vertical thirds:
  //   top    y =   0 – 100  (first-point centroid  y =  50)
  //   middle y = 100 – 200  (first-point centroid  y = 150)
  //   bottom y = 200 – 300  (first-point centroid  y = 250)
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  group('StrokeStartScorer', () {
    // ── Constructor validation ───────────────────────────────────────────────

    group('constructor', () {
      test('throws ArgumentError when an expected stroke has startRegion bottom',
          () {
        final badData = LetterFormationData(
          minRequiredStrokes: 1,
          strokes: [
            ExpectedStroke(
              primaryDirection: StrokeDirection.topToBottom,
              startRegion: StrokeStartRegion.bottom,
              startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 2.0 / 3.0, maxY: 1.0),
            ),
          ],
        );

        expect(
          () => StrokeStartScorer(letter: 'x', data: badData, bounds: bounds),
          throwsArgumentError,
        );
      });

      test('error message identifies the offending letter and stroke index', () {
        final badData = LetterFormationData(
          minRequiredStrokes: 1,
          strokes: [
            ExpectedStroke(
              primaryDirection: StrokeDirection.topToBottom,
              startRegion: StrokeStartRegion.bottom,
              startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 2.0 / 3.0, maxY: 1.0),
            ),
          ],
        );

        expect(
          () => StrokeStartScorer(letter: 'z', data: badData, bounds: bounds),
          throwsA(
            isA<ArgumentError>()
                .having(
                  (e) => e.message,
                  'message contains letter',
                  contains('"z"'),
                )
                .having(
                  (e) => e.message,
                  'message contains stroke index',
                  contains('stroke 0'),
                ),
          ),
        );
      });

      test('throws on second stroke with startRegion bottom, not first', () {
        final badData = LetterFormationData(
          minRequiredStrokes: 2,
          strokes: [
            ExpectedStroke(
              primaryDirection: StrokeDirection.topToBottom,
              startRegion: StrokeStartRegion.top,
              startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
            ),
            ExpectedStroke(
              primaryDirection: StrokeDirection.leftToRight,
              startRegion: StrokeStartRegion.bottom,
              startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 2.0 / 3.0, maxY: 1.0),
            ),
          ],
        );

        expect(
          () => StrokeStartScorer(letter: 'q', data: badData, bounds: bounds),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message contains stroke 1',
              contains('stroke 1'),
            ),
          ),
        );
      });

      test('accepts data with top and middle start regions without throwing',
          () {
        final goodData = letterFormationRegistry['t']!;
        expect(
          () =>
              StrokeStartScorer(letter: 't', data: goodData, bounds: bounds),
          returnsNormally,
        );
      });
    });

    // ── Correct 'n' ─────────────────────────────────────────────────────────
    //
    // 'n' is a single compound stroke with startRegion = top.
    // The compound waypoints have centroid ≈ (125, 150), so any single
    // observed stroke will match it.

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
        // First point at (50, 50) — top third (y < 100).
        final observed = [
          Stroke([const Offset(50, 50), const Offset(250, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.overallScore, 1.0);
      });

      test('one observation is produced', () {
        final observed = [
          Stroke([const Offset(50, 50), const Offset(250, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations.length, 1);
      });

      test('observation expected and observed are both "top"', () {
        final observed = [
          Stroke([const Offset(50, 50), const Offset(250, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[0].expected, 'top');
        expect(result.observations[0].observed, 'top');
        expect(result.observations[0].score, 1.0);
      });

      test('note says correct', () {
        final observed = [
          Stroke([const Offset(50, 50), const Offset(250, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[0].note, 'Started in the top region — correct.');
      });

      test('summary is the all-correct sentence', () {
        final observed = [
          Stroke([const Offset(50, 50), const Offset(250, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.summary, 'All strokes started in the right place.');
      });
    });

    // ── Reversed 'n' ────────────────────────────────────────────────────────
    //
    // Learner draws the compound stroke starting at bottom-right instead of
    // top-left.  Expected = top, observed = bottom → opposite mismatch → 0.0.

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
        // First point at (280, 280) — bottom third (y > 200).
        final observed = [
          Stroke([const Offset(280, 280), const Offset(50, 50)]),
        ];
        final result = scorer.score(observed);
        expect(result.overallScore, 0.0);
      });

      test('observation expected = "top", observed = "bottom"', () {
        final observed = [
          Stroke([const Offset(280, 280), const Offset(50, 50)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[0].expected, 'top');
        expect(result.observations[0].observed, 'bottom');
        expect(result.observations[0].score, 0.0);
      });

      test('note describes the error', () {
        final observed = [
          Stroke([const Offset(280, 280), const Offset(50, 50)]),
        ];
        final result = scorer.score(observed);
        expect(
          result.observations[0].note,
          'Started at the bottom; should start at the top.',
        );
      });

      test('summary suggests correct start region', () {
        final observed = [
          Stroke([const Offset(280, 280), const Offset(50, 50)]),
        ];
        final result = scorer.score(observed);
        expect(result.summary, contains('wrong place'));
        expect(result.summary, contains('top'));
      });
    });

    // ── 't' with crossbar starting in middle (correct) ───────────────────────
    //
    // 't' has two expected strokes:
    //   stroke 0: startRegion = top    → centroid (150, 50)
    //   stroke 1: startRegion = middle → centroid (150, 150)

    group("'t' crossbar starting in middle (correct)", () {
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
          // Stem: centroid (150, 50), first point in top region.
          Stroke([const Offset(150, 10), const Offset(150, 90)]),
          // Crossbar: centroid (150, 150), first point in middle region.
          Stroke([const Offset(0, 150), const Offset(300, 150)]),
        ];
        final result = scorer.score(observed);
        expect(result.overallScore, 1.0);
      });

      test('two observations are produced', () {
        final observed = [
          Stroke([const Offset(150, 10), const Offset(150, 90)]),
          Stroke([const Offset(0, 150), const Offset(300, 150)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations.length, 2);
      });

      test('stroke 0 observation: expected = "top", observed = "top"', () {
        final observed = [
          Stroke([const Offset(150, 10), const Offset(150, 90)]),
          Stroke([const Offset(0, 150), const Offset(300, 150)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[0].expected, 'top');
        expect(result.observations[0].observed, 'top');
        expect(result.observations[0].score, 1.0);
      });

      test('stroke 1 observation: expected = "middle", observed = "middle"',
          () {
        final observed = [
          Stroke([const Offset(150, 10), const Offset(150, 90)]),
          Stroke([const Offset(0, 150), const Offset(300, 150)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[1].expected, 'middle');
        expect(result.observations[1].observed, 'middle');
        expect(result.observations[1].score, 1.0);
      });

      test('summary is the all-correct sentence', () {
        final observed = [
          Stroke([const Offset(150, 10), const Offset(150, 90)]),
          Stroke([const Offset(0, 150), const Offset(300, 150)]),
        ];
        final result = scorer.score(observed);
        expect(result.summary, 'All strokes started in the right place.');
      });
    });

    // ── 't' with crossbar starting at top (adjacent mismatch → 0.5) ─────────
    //
    // Crossbar (expected middle) starts in the top region.
    // Expected = middle, observed = top → adjacent mismatch → 0.5.
    // Overall = (1.0 + 0.5) / 2 = 0.75.

    group("'t' crossbar starting at top (adjacent mismatch)", () {
      late StrokeStartScorer scorer;

      setUp(() {
        scorer = StrokeStartScorer(
          letter: 't',
          data: letterFormationRegistry['t']!,
          bounds: bounds,
        );
      });

      test('overallScore is 0.75', () {
        final observed = [
          // Stem: centroid (150, 50), first point in top.
          Stroke([const Offset(150, 10), const Offset(150, 90)]),
          // Crossbar: centroid (150, 150) to match expected[1], but first
          // point at (0, 50) lands in the top region.
          Stroke([const Offset(0, 50), const Offset(300, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.overallScore, closeTo(0.75, 1e-9));
      });

      test('crossbar observation: expected = "middle", observed = "top", score = 0.5',
          () {
        final observed = [
          Stroke([const Offset(150, 10), const Offset(150, 90)]),
          Stroke([const Offset(0, 50), const Offset(300, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.observations[1].expected, 'middle');
        expect(result.observations[1].observed, 'top');
        expect(result.observations[1].score, 0.5);
      });

      test('summary mentions the wrong place and expected region', () {
        final observed = [
          Stroke([const Offset(150, 10), const Offset(150, 90)]),
          Stroke([const Offset(0, 50), const Offset(300, 250)]),
        ];
        final result = scorer.score(observed);
        expect(result.summary, contains('wrong place'));
        expect(result.summary, contains('middle'));
      });
    });

    // ── Tight-rect band contract ─────────────────────────────────────────────
    //
    // The scorer divides the rect it is given into vertical thirds.  These
    // tests pass a tight rect (height = 60, thirdH = 20) and verify that:
    //
    //   • A first point 5 px below the tight rect's top falls in the TOP band.
    //   • A first point 25 px below the tight rect's top falls in the MIDDLE band.
    //
    // The corresponding loose rect would have height = 120 with its top 20 px
    // above the tight rect's top (thirdH = 40).  Because the scorer derives
    // thresholds solely from the rect it receives, handing it the tight rect
    // produces the correct classification.  Any regression that accidentally
    // passed a taller rect would change the thresholds and could cause the
    // 25 px point to be classified as top instead of middle.

    group('tight-rect band contract', () {
      // Single-stroke formation data: one anticlockwise stroke starting at top.
      final tightData = LetterFormationData(
        minRequiredStrokes: 1,
        strokes: [
          ExpectedStroke(
            primaryDirection: StrokeDirection.anticlockwise,
            startRegion: StrokeStartRegion.top,
            startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
          ),
        ],
      );

      // Tight rect: height = 60 → thirdH = 20.
      // Loose rect would be: top = tightBounds.top − 20, height = 120 → thirdH = 40.
      const tightBounds = Rect.fromLTWH(0, 0, 100, 60);

      // Expected centroid for the single top-region stroke:
      //   cx = 50, cy = 0 + 20 * 0.5 = 10.
      // Both strokes below keep their bounding-box centroid at (50, 10) so
      // the matcher always assigns the observed stroke to expected stroke 0.

      test('first point 5 px below tight top → classified as top', () {
        // Centroid: min_y = 5, max_y = 15 → mid = 10.  Centroid = (50, 10) ✓
        final stroke = Stroke([const Offset(50, 5), const Offset(50, 15)]);
        final scorer = StrokeStartScorer(
          letter: 'a',
          data: tightData,
          bounds: tightBounds,
        );
        final result = scorer.score([stroke]);
        expect(result.observations.length, 1);
        expect(
          result.observations[0].observed,
          'top',
          reason: 'dy = 5, thirdH = 20: 5 < 20 → top band',
        );
        expect(result.overallScore, 1.0);
      });

      test('first point 25 px below tight top → classified as middle', () {
        // Centroid: min_y = -5, max_y = 25 → mid = 10.  Centroid = (50, 10) ✓
        final stroke = Stroke([const Offset(50, 25), const Offset(50, -5)]);
        final scorer = StrokeStartScorer(
          letter: 'a',
          data: tightData,
          bounds: tightBounds,
        );
        final result = scorer.score([stroke]);
        expect(result.observations.length, 1);
        expect(
          result.observations[0].observed,
          'middle',
          reason: 'dy = 25, thirdH = 20: 20 ≤ 25 < 40 → middle band',
        );
        expect(result.overallScore, 0.5);
      });
    });

    // ── Scoring table edge cases ─────────────────────────────────────────────

    group('scoring table', () {
      // Use a minimal LetterFormationData with a single top-expected stroke.
      LetterFormationData singleStrokeData(StrokeStartRegion region) =>
          LetterFormationData(
            minRequiredStrokes: 1,
            strokes: [
              ExpectedStroke(
                primaryDirection: StrokeDirection.topToBottom,
                startRegion: region,
                startRect: switch (region) {
                  StrokeStartRegion.top =>
                    const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
                  StrokeStartRegion.middle =>
                    const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 1.0 / 3.0, maxY: 2.0 / 3.0),
                  StrokeStartRegion.bottom =>
                    const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 2.0 / 3.0, maxY: 1.0),
                },
              ),
            ],
          );

      // A stroke whose bounding-box centroid is at (150, 50) and whose first
      // point is in the specified region.
      Stroke strokeStartingIn(StrokeStartRegion region) {
        final firstY = switch (region) {
          StrokeStartRegion.top => 50.0,
          StrokeStartRegion.middle => 150.0,
          StrokeStartRegion.bottom => 250.0,
        };
        // Keep centroid at (150, 50) so it always matches the expected stroke.
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

      test('top expected, middle observed → 0.5', () {
        final scorer = StrokeStartScorer(
          letter: 'a',
          data: singleStrokeData(StrokeStartRegion.top),
          bounds: bounds,
        );
        final result =
            scorer.score([strokeStartingIn(StrokeStartRegion.middle)]);
        expect(result.overallScore, 0.5);
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

      test('middle expected, top observed → 0.5', () {
        final scorer = StrokeStartScorer(
          letter: 't',
          data: singleStrokeData(StrokeStartRegion.middle),
          bounds: bounds,
        );
        final result =
            scorer.score([strokeStartingIn(StrokeStartRegion.top)]);
        expect(result.overallScore, 0.5);
      });

      test('middle expected, bottom observed → 0.5', () {
        final scorer = StrokeStartScorer(
          letter: 't',
          data: singleStrokeData(StrokeStartRegion.middle),
          bounds: bounds,
        );
        final result =
            scorer.score([strokeStartingIn(StrokeStartRegion.bottom)]);
        expect(result.overallScore, 0.5);
      });
    });
  });
}
