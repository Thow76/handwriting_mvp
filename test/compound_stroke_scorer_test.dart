import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/compound_stroke_scorer.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';

void main() {
  // 300×300 bounding box used throughout. Cells are 100×100; tolerance with
  // the default fraction of 0.5 is therefore 50.
  //
  // Waypoint cell centroids inside this box:
  //   topLeft     ( 50,  50)   top    (150,  50)   topRight    (250,  50)
  //   left        ( 50, 150)   middle (150, 150)   right       (250, 150)
  //   bottomLeft  ( 50, 250)   bottom (150, 250)   bottomRight (250, 250)
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  // 'n' waypoint sequence: topLeft → bottomLeft → top → bottomRight.
  // An observed stroke that visits each centroid in order scores 4/4.
  Stroke perfectN() => Stroke(const [
        Offset(50, 50),
        Offset(50, 250),
        Offset(150, 50),
        Offset(250, 250),
      ]);

  // ---------------------------------------------------------------------------
  // Constant exposure
  // ---------------------------------------------------------------------------

  group('exposed constant', () {
    test('waypointToleranceFraction is 0.5', () {
      expect(CompoundStrokeScorer.waypointToleranceFraction, 0.5);
    });
  });

  // ---------------------------------------------------------------------------
  // 'n' — single compound stroke, perfect path → 4/4
  // ---------------------------------------------------------------------------

  group("'n' drawn with all four waypoints in order", () {
    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'n',
        data: letterFormationRegistry['n']!,
        bounds: bounds,
      );
    });

    test('overallScore is 1.0', () {
      final result = scorer.score([perfectN()]);
      expect(result.overallScore, 1.0);
    });

    test('one observation is produced', () {
      final result = scorer.score([perfectN()]);
      expect(result.observations.length, 1);
    });

    test('observation expected string lists waypoints in order', () {
      final result = scorer.score([perfectN()]);
      expect(
        result.observations.first.expected,
        'topLeft → bottomLeft → top → bottomRight',
      );
    });

    test('observation observed string lists hits in order', () {
      final result = scorer.score([perfectN()]);
      expect(
        result.observations.first.observed,
        'topLeft → bottomLeft → top → bottomRight',
      );
    });

    test('observation score is 1.0', () {
      final result = scorer.score([perfectN()]);
      expect(result.observations.first.score, 1.0);
    });

    test('observation note says all four waypoints hit', () {
      final result = scorer.score([perfectN()]);
      expect(result.observations.first.note, contains('All 4 waypoints'));
      expect(result.observations.first.note, contains('correct'));
    });

    test('summary says all compound strokes followed the path', () {
      final result = scorer.score([perfectN()]);
      expect(
        result.summary,
        'All compound strokes followed the correct path.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 'n' — arch peak in wrong cell → 3/4
  // ---------------------------------------------------------------------------

  group("'n' with arch peak missing the top cell", () {
    // Replace the 'top' centroid with a point in the middle region (180, 180),
    // which is ≈133 units from (150, 50) — outside the tolerance of 50.
    final missTopStroke = Stroke(const [
      Offset(50, 50),
      Offset(50, 250),
      Offset(180, 180),
      Offset(250, 250),
    ]);

    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'n',
        data: letterFormationRegistry['n']!,
        bounds: bounds,
      );
    });

    test('overallScore is 0.75', () {
      final result = scorer.score([missTopStroke]);
      expect(result.overallScore, 0.75);
    });

    test('observation observed string flags the missed waypoint', () {
      final result = scorer.score([missTopStroke]);
      expect(result.observations.first.observed, contains('[missed top]'));
    });

    test('observation note says 3 of 4 hit', () {
      final result = scorer.score([missTopStroke]);
      expect(result.observations.first.note, contains('3 of 4'));
    });

    test('summary indicates partial failure', () {
      final result = scorer.score([missTopStroke]);
      expect(
        result.summary,
        'One or more compound strokes did not follow the correct path.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 'n' — every waypoint missed → 0/4
  // ---------------------------------------------------------------------------

  group("'n' that misses every waypoint", () {
    // A compound stroke whose centroid lands at the centre of the bounds
    // (150, 150) so that matchStrokes still pairs it with the compound
    // expected stroke, but no individual point lies within tolerance of any
    // waypoint cell centre. Two points symmetric about the centre satisfy
    // both requirements.
    final missAllStroke = Stroke(const [
      Offset(140, 140),
      Offset(160, 160),
    ]);

    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'n',
        data: letterFormationRegistry['n']!,
        bounds: bounds,
      );
    });

    test('overallScore is 0.0', () {
      final result = scorer.score([missAllStroke]);
      expect(result.overallScore, 0.0);
    });

    test('observation note says no waypoints were hit', () {
      final result = scorer.score([missAllStroke]);
      expect(
        result.observations.first.note,
        'No waypoints were hit in the expected sequence.',
      );
    });

    test('summary says no compound strokes followed the path', () {
      final result = scorer.score([missAllStroke]);
      expect(
        result.summary,
        'No compound strokes followed the correct path.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 'h' — multi-stroke letter; the topToBottom stem is silently skipped
  //
  // 'h' has two expected strokes:
  //   stroke 0: topToBottom, startRegion = top    → expected centroid (150, 50)
  //   stroke 1: compound (left → top → bottomRight) → expected centroid (150, 150)
  //
  // Observed strokes need centroids near those expected centroids so that
  // matchStrokes assigns them correctly:
  //   stem     → Stroke([(150,10) → (150,90)])              centroid (150,  50)
  //   compound → Stroke([(50,150) → (150,50) → (250,250)])  centroid (150, 150)
  // ---------------------------------------------------------------------------

  group("'h' with correct stem and compound second stroke", () {
    final hStem = Stroke(const [Offset(150, 10), Offset(150, 90)]);
    final hCompound = Stroke(const [
      Offset(50, 150),
      Offset(150, 50),
      Offset(250, 250),
    ]);

    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'h',
        data: letterFormationRegistry['h']!,
        bounds: bounds,
      );
    });

    test('exactly one observation is produced (stem is skipped silently)', () {
      final result = scorer.score([hStem, hCompound]);
      expect(result.observations.length, 1);
    });

    test('the observation is for the compound stroke (index 1)', () {
      final result = scorer.score([hStem, hCompound]);
      expect(result.observations.first.strokeIndex, 1);
    });

    test('overallScore reflects only the compound stroke (1.0)', () {
      final result = scorer.score([hStem, hCompound]);
      expect(result.overallScore, 1.0);
    });

    test('expected string lists the compound waypoints', () {
      final result = scorer.score([hStem, hCompound]);
      expect(
        result.observations.first.expected,
        'left → top → bottomRight',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Multiple compound strokes — mean of per-stroke scores
  // ---------------------------------------------------------------------------

  group('letter with two compound strokes — overallScore is the mean', () {
    // Synthetic two-compound-stroke letter. Expected centroids must differ so
    // matchStrokes pairs them deterministically:
    //   stroke 0: waypoints [topLeft, top, topRight]       → centroid (150,  50)
    //   stroke 1: waypoints [bottomLeft, bottom, bottomRight] → centroid (150, 250)
    final data = LetterFormationData(
      minRequiredStrokes: 2,
      strokes: [
        ExpectedStroke(
          primaryDirection: StrokeDirection.compound,
          startRegion: StrokeStartRegion.top,
          startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
          waypoints: const [
            WaypointRegion.topLeft,
            WaypointRegion.top,
            WaypointRegion.topRight,
          ],
        ),
        ExpectedStroke(
          primaryDirection: StrokeDirection.compound,
          startRegion: StrokeStartRegion.bottom,
          startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 2.0 / 3.0, maxY: 1.0),
          waypoints: const [
            WaypointRegion.bottomLeft,
            WaypointRegion.bottom,
            WaypointRegion.bottomRight,
          ],
        ),
      ],
    );

    // Stroke 0: hits all 3 top-row waypoints → score 1.0.
    final strokeTopRowPerfect = Stroke(const [
      Offset(50, 50),
      Offset(150, 50),
      Offset(250, 50),
    ]);

    // Stroke 1: hits 2 of 3 bottom-row waypoints. Bounding-box centroid is
    // ((50+250)/2, (250+250)/2) = (150, 250) so it still pairs to expected[1].
    // The middle 'bottom' centroid (150, 250) is replaced with (150, 50),
    // which is 200 units away — well outside the tolerance of 50.
    final strokeBottomRowPartial = Stroke(const [
      Offset(50, 250),
      Offset(150, 50),
      Offset(250, 250),
    ]);

    test('overallScore is the mean of 1.0 and 2/3', () {
      final scorer = CompoundStrokeScorer(
        letter: 'synthetic',
        data: data,
        bounds: bounds,
      );
      final result = scorer.score([strokeTopRowPerfect, strokeBottomRowPartial]);
      // (1.0 + 2/3) / 2 = 5/6 ≈ 0.8333…
      expect(result.overallScore, closeTo(5 / 6, 1e-9));
    });

    test('two observations are produced, one per compound stroke', () {
      final scorer = CompoundStrokeScorer(
        letter: 'synthetic',
        data: data,
        bounds: bounds,
      );
      final result = scorer.score([strokeTopRowPerfect, strokeBottomRowPartial]);
      expect(result.observations.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Custom toleranceFraction is honoured
  // ---------------------------------------------------------------------------

  group('toleranceFraction parameter', () {
    // A point 40 units from the topLeft centroid (50, 50). With the default
    // fraction of 0.5 → tolerance 50 → hit. With fraction 0.3 → tolerance 30
    // → miss.
    final nearMissStroke = Stroke(const [
      Offset(90, 50),  // 40 units from topLeft
      Offset(50, 250), // bottomLeft exact
      Offset(150, 50), // top exact
      Offset(250, 250), // bottomRight exact
    ]);

    test('default tolerance gives 4/4', () {
      final scorer = CompoundStrokeScorer(
        letter: 'n',
        data: letterFormationRegistry['n']!,
        bounds: bounds,
      );
      final result = scorer.score([nearMissStroke]);
      expect(result.overallScore, 1.0);
    });

    test('tighter tolerance fraction (0.3) drops the off-centre waypoint', () {
      final scorer = CompoundStrokeScorer(
        letter: 'n',
        data: letterFormationRegistry['n']!,
        bounds: bounds,
        toleranceFraction: 0.3,
      );
      final result = scorer.score([nearMissStroke]);
      expect(result.overallScore, 0.75);
    });
  });

  // ---------------------------------------------------------------------------
  // 'm' — six-waypoint compound stroke; proportional scoring
  // ---------------------------------------------------------------------------
  //
  // 'm' waypoints: topLeft → bottomLeft → top → bottom → top → bottomRight
  //                (6 waypoints)
  //
  // Centroids in the 300×300 box:
  //   topLeft (50,50), bottomLeft (50,250), top (150,50),
  //   bottom (150,250), top (150,50) [again], bottomRight (250,250)

  group("'m' drawn with all six waypoints in order → 6/6", () {
    // Visit each centroid once in sequence; the 'top' cell is visited twice
    // as required by the waypoint list.
    final perfectM = Stroke(const [
      Offset(50, 50),   // topLeft
      Offset(50, 250),  // bottomLeft
      Offset(150, 50),  // top (first arch)
      Offset(150, 250), // bottom
      Offset(150, 50),  // top (second arch)
      Offset(250, 250), // bottomRight
    ]);

    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'm',
        data: letterFormationRegistry['m']!,
        bounds: bounds,
      );
    });

    test('overallScore is 1.0', () {
      final result = scorer.score([perfectM]);
      expect(result.overallScore, 1.0);
    });

    test('one observation is produced', () {
      final result = scorer.score([perfectM]);
      expect(result.observations.length, 1);
    });

    test('observation expected string lists all six waypoints', () {
      final result = scorer.score([perfectM]);
      expect(
        result.observations.first.expected,
        'topLeft → bottomLeft → top → bottom → top → bottomRight',
      );
    });

    test('observation observed string shows all six as hits', () {
      final result = scorer.score([perfectM]);
      expect(
        result.observations.first.observed,
        'topLeft → bottomLeft → top → bottom → top → bottomRight',
      );
    });

    test('observation score is 1.0', () {
      final result = scorer.score([perfectM]);
      expect(result.observations.first.score, 1.0);
    });
  });

  group("'m' with the second arch peak missed → 5/6", () {
    // Omit the second visit to 'top' — only 5 of 6 waypoints are hit.
    // Stroke: topLeft → bottomLeft → top → bottom → bottomRight
    // After matching bottom at index 3, the matcher scans index 4 = (250,250)
    // for the second 'top' centroid (150,50): distance ≈ 224 > tolerance 50
    // → miss. Then bottomRight matches (250,250) → hit. Score = 5/6.
    final partialM = Stroke(const [
      Offset(50, 50),   // topLeft      ✓
      Offset(50, 250),  // bottomLeft   ✓
      Offset(150, 50),  // top (first)  ✓
      Offset(150, 250), // bottom       ✓
      Offset(250, 250), // bottomRight  ✓ (second 'top' is missed)
    ]);

    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'm',
        data: letterFormationRegistry['m']!,
        bounds: bounds,
      );
    });

    test('overallScore is 5/6', () {
      final result = scorer.score([partialM]);
      expect(result.overallScore, closeTo(5 / 6, 1e-9));
    });

    test('observation observed string flags the missed second top', () {
      final result = scorer.score([partialM]);
      expect(result.observations.first.observed, contains('[missed top]'));
    });

    test('observation score is 5/6', () {
      final result = scorer.score([partialM]);
      expect(result.observations.first.score, closeTo(5 / 6, 1e-9));
    });

    test('observation note mentions 5 of 6 hit', () {
      final result = scorer.score([partialM]);
      expect(result.observations.first.note, contains('5 of 6'));
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------

  group('edge cases', () {
    test('empty observed list — overallScore 0.0, no observations', () {
      final scorer = CompoundStrokeScorer(
        letter: 'n',
        data: letterFormationRegistry['n']!,
        bounds: bounds,
      );
      final result = scorer.score([]);
      expect(result.overallScore, 0.0);
      expect(result.observations, isEmpty);
      expect(result.summary, 'No compound strokes were found to score.');
    });

    test('letter with no compound strokes — no observations, summary', () {
      // 'l' is a single topToBottom stroke; nothing for this scorer to score.
      final scorer = CompoundStrokeScorer(
        letter: 'l',
        data: letterFormationRegistry['l']!,
        bounds: bounds,
      );
      final result = scorer.score([
        Stroke(const [Offset(150, 10), Offset(150, 290)]),
      ]);
      expect(result.overallScore, 1.0);
      expect(result.observations, isEmpty);
      expect(result.summary, 'No compound strokes in this letter.');
    });

    test('extra observed strokes that do not match any expected are ignored',
        () {
      // 'n' has one expected stroke. matchStrokes is greedy and one-to-one,
      // so a second observed stroke gets matchIndex = -1 and is silently
      // skipped by the scorer.
      final scorer = CompoundStrokeScorer(
        letter: 'n',
        data: letterFormationRegistry['n']!,
        bounds: bounds,
      );
      final result = scorer.score([
        perfectN(),
        Stroke(const [Offset(0, 0), Offset(10, 10)]),
      ]);
      expect(result.observations.length, 1);
      expect(result.overallScore, 1.0);
    });

    test('compound expected stroke with empty waypoints scores 0.0', () {
      // ExpectedStroke's invariant allows compound + empty waypoints (the
      // assert is satisfied by the compound branch). Exercise the defensive
      // empty-waypoints branch in CompoundStrokeScorer.
      final data = LetterFormationData(
        minRequiredStrokes: 1,
        strokes: [
          ExpectedStroke(
            primaryDirection: StrokeDirection.compound,
            startRegion: StrokeStartRegion.top,
            startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
            waypoints: const [],
          ),
        ],
      );
      final scorer = CompoundStrokeScorer(
        letter: 'synthetic',
        data: data,
        bounds: bounds,
      );
      final result = scorer.score([
        Stroke(const [Offset(150, 150)]),
      ]);
      expect(result.overallScore, 0.0);
      expect(result.observations.length, 1);
      expect(
        result.observations.first.expected,
        'compound (no waypoints)',
      );
      expect(
        result.observations.first.note,
        contains('no waypoints defined'),
      );
    });
  });
}
