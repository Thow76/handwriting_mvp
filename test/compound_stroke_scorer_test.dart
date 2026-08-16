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

  // Inline LetterFormationData for 'n' using the legacy waypoints, since the
  // registry entry has been migrated to sections. These tests validate the
  // CompoundStrokeScorer itself against the waypoint-based path.
  final nDataWithWaypoints = LetterFormationData(
    minRequiredStrokes: 1,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.30,
          minY: 0.00,
          maxY: 0.20,
        ),
        waypoints: [
          WaypointRegion.topLeft,
          WaypointRegion.bottomLeft,
          WaypointRegion.top,
          WaypointRegion.bottomRight,
        ],
      ),
    ],
  );

  // Inline LetterFormationData for 'f' using the legacy waypoints, since the
  // registry entry has been migrated to sections. These tests validate the
  // CompoundStrokeScorer itself against the waypoint-based path.
  final fDataWithWaypoints = LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.55,
          maxX: 1.00,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.25,
          maxY: 0.40,
        ),
        waypoints: const [WaypointRegion.left, WaypointRegion.right],
      ),
    ],
  );

  // Inline LetterFormationData for 'h' using the legacy waypoints, since the
  // registry entry has been migrated to sections. These tests validate the
  // CompoundStrokeScorer itself against the waypoint-based path.
  final hDataWithWaypoints = LetterFormationData(
    minRequiredStrokes: 2,
    strokes: [
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.25,
          minY: 0.00,
          maxY: 0.15,
        ),
        waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
      ),
      ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.00,
          maxX: 0.30,
          minY: 0.40,
          maxY: 0.60,
        ),
        waypoints: const [
          WaypointRegion.left,
          WaypointRegion.top,
          WaypointRegion.bottomRight,
        ],
      ),
    ],
  );

  Stroke topLeftToBottomRightDiagonal() =>
      Stroke(const [Offset(50, 50), Offset(250, 250)]);

  Stroke topRightToBottomLeftDiagonal() =>
      Stroke(const [Offset(250, 50), Offset(50, 250)]);

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
        data: nDataWithWaypoints,
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
        'All waypoint-scored strokes followed the correct path.',
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
        data: nDataWithWaypoints,
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
        'One or more waypoint-scored strokes did not follow the correct path.',
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
    final missAllStroke = Stroke(const [Offset(140, 140), Offset(160, 160)]);

    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'n',
        data: nDataWithWaypoints,
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
        'No waypoint-scored strokes followed the correct path.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 'h' — multi-stroke letter; stem and compound stroke are both waypoint-scored
  //
  // The registry entry for 'h' has been migrated to sections (see
  // hDataWithWaypoints above), so this group uses inline legacy waypoint data
  // to validate the CompoundStrokeScorer itself against a waypoint-based path.
  //
  // 'h' has two expected strokes:
  //   stroke 0: topToBottom, startRect (0.00–0.25, 0.00–0.15)
  //             → expected centroid (37.5, 22.5) in 300×300 box
  //   stroke 1: compound (left → top → bottomRight)
  //             → expected centroid (150, 150) via waypoint average
  //
  // Observed strokes need centroids near those expected centroids so that
  // matchStrokes assigns them correctly:
  //   stem     → Stroke([(10,10) → (65,35)])               centroid (37.5, 22.5)
  //   compound → Stroke([(50,150) → (150,50) → (250,250)]) centroid (150, 150)
  // ---------------------------------------------------------------------------

  group("'h' with correct stem and compound second stroke", () {
    // Bounding box: x=[10,65], y=[10,35] → centroid (37.5, 22.5) near
    // the stem startRect centroid for 'h' stroke 0.
    final hStem = Stroke(const [Offset(10, 10), Offset(65, 35)]);
    final hCompound = Stroke(const [
      Offset(50, 150),
      Offset(150, 50),
      Offset(250, 250),
    ]);

    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'h',
        data: hDataWithWaypoints,
        bounds: bounds,
      );
    });

    test('two observations are produced (stem + compound)', () {
      final result = scorer.score([hStem, hCompound]);
      expect(result.observations.length, 2);
    });

    test('the first observation is for the stem stroke (index 0)', () {
      final result = scorer.score([hStem, hCompound]);
      expect(result.observations.first.strokeIndex, 0);
      expect(result.observations.first.expected, 'top → bottom');
    });

    test('the second observation is for the compound stroke (index 1)', () {
      final result = scorer.score([hStem, hCompound]);
      expect(result.observations[1].strokeIndex, 1);
      expect(result.observations[1].expected, 'left → top → bottomRight');
    });

    test('overallScore is the mean of stem and compound scores', () {
      final result = scorer.score([hStem, hCompound]);
      expect(result.overallScore, 0.5);
    });

    test('compound observation expected string lists compound waypoints', () {
      final result = scorer.score([hStem, hCompound]);
      expect(result.observations[1].expected, 'left → top → bottomRight');
    });
  });

  group("'t' crossbar waypoint direction", () {
    final tStem = Stroke(const [Offset(150, 50), Offset(150, 250)]);
    final leftToRightCrossbar = Stroke(const [
      Offset(50, 150),
      Offset(250, 150),
    ]);
    final rightToLeftCrossbar = Stroke(const [
      Offset(190, 150),
      Offset(110, 150),
    ]);

    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 't',
        data: letterFormationRegistry['t']!,
        bounds: bounds,
      );
    });

    test('left-to-right crossbar scores 1.0', () {
      final result = scorer.score([tStem, leftToRightCrossbar]);
      expect(result.observations[1].score, 1.0);
    });

    test('right-to-left crossbar scores 0.0', () {
      final result = scorer.score([tStem, rightToLeftCrossbar]);
      expect(result.observations[1].score, 0.0);
    });
  });

  group("'f' crossbar waypoint direction", () {
    // 'f' has the same stem (topToBottom, [top, bottom]) + crossbar
    // (leftToRight, [left, right]) structure as 't'. The stem runs vertically
    // through the middle column; the crossbar runs horizontally through the
    // middle row, hitting the left and right cell centroids in order.
    final fStem = Stroke(const [Offset(150, 50), Offset(150, 250)]);
    final leftToRightCrossbar = Stroke(const [
      Offset(50, 150),
      Offset(250, 150),
    ]);
    final rightToLeftCrossbar = Stroke(const [
      Offset(190, 150),
      Offset(110, 150),
    ]);

    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'f',
        data: fDataWithWaypoints,
        bounds: bounds,
      );
    });

    test('left-to-right crossbar scores 1.0', () {
      final result = scorer.score([fStem, leftToRightCrossbar]);
      expect(result.observations[1].score, 1.0);
    });

    test('right-to-left crossbar scores 0.0', () {
      final result = scorer.score([fStem, rightToLeftCrossbar]);
      expect(result.observations[1].score, 0.0);
    });
  });

  group("'v' diagonal waypoint direction", () {
    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'v',
        data: letterFormationRegistry['v']!,
        bounds: bounds,
      );
    });

    test('top-left to bottom-right scores 1.0', () {
      final result = scorer.score([topLeftToBottomRightDiagonal()]);
      expect(result.observations.single.score, 1.0);
    });

    test('top-right to bottom-left scores 0.0', () {
      final result = scorer.score([topRightToBottomLeftDiagonal()]);
      expect(result.observations.single.score, 0.0);
    });
  });

  group("'x' diagonal waypoint direction", () {
    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'x',
        data: letterFormationRegistry['x']!,
        bounds: bounds,
      );
    });

    test('correct diagonals score 1.0 for both strokes', () {
      final result = scorer.score([
        topLeftToBottomRightDiagonal(),
        topRightToBottomLeftDiagonal(),
      ]);
      expect(result.overallScore, 1.0);
      expect(result.observations[0].score, 1.0);
      expect(result.observations[1].score, 1.0);
    });

    test('opposite diagonals score 0.0 for both strokes', () {
      final result = scorer.score([
        topRightToBottomLeftDiagonal(),
        topLeftToBottomRightDiagonal(),
      ]);
      expect(result.overallScore, 0.0);
      expect(result.observations[0].score, 0.0);
      expect(result.observations[1].score, 0.0);
    });
  });

  group("'z' horizontal waypoint direction", () {
    final leftToRightStroke = Stroke(const [Offset(50, 150), Offset(250, 150)]);
    final rightToLeftStroke = Stroke(const [
      Offset(190, 150),
      Offset(110, 150),
    ]);

    late CompoundStrokeScorer scorer;

    setUp(() {
      scorer = CompoundStrokeScorer(
        letter: 'z',
        data: letterFormationRegistry['z']!,
        bounds: bounds,
      );
    });

    test('left-to-right scores 1.0', () {
      final result = scorer.score([leftToRightStroke]);
      expect(result.observations.single.score, 1.0);
    });

    test('right-to-left scores 0.0', () {
      final result = scorer.score([rightToLeftStroke]);
      expect(result.observations.single.score, 0.0);
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
          startRect: const StrokeStartRect(
            minX: 0.0,
            maxX: 1.0,
            minY: 0.0,
            maxY: 1.0 / 3.0,
          ),
          waypoints: const [
            WaypointRegion.topLeft,
            WaypointRegion.top,
            WaypointRegion.topRight,
          ],
        ),
        ExpectedStroke(
          startRect: const StrokeStartRect(
            minX: 0.0,
            maxX: 1.0,
            minY: 2.0 / 3.0,
            maxY: 1.0,
          ),
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
      final result = scorer.score([
        strokeTopRowPerfect,
        strokeBottomRowPartial,
      ]);
      // (1.0 + 2/3) / 2 = 5/6 ≈ 0.8333…
      expect(result.overallScore, closeTo(5 / 6, 1e-9));
    });

    group('non-compound expected stroke with waypoints', () {
      final data = LetterFormationData(
        minRequiredStrokes: 1,
        strokes: [
          ExpectedStroke(
            startRect: const StrokeStartRect(
              minX: 0.0,
              maxX: 1.0,
              minY: 0.0,
              maxY: 1.0 / 3.0,
            ),
            waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
          ),
        ],
      );

      final verticalStroke = Stroke(const [Offset(150, 50), Offset(150, 250)]);

      test(
        'is scored via waypoints for a straight top-to-bottom stroke',
        () {
          final scorer = CompoundStrokeScorer(
            letter: 'synthetic',
            data: data,
            bounds: bounds,
          );
          final result = scorer.score([verticalStroke]);
          expect(result.overallScore, 1.0);
          expect(result.observations.single.expected, 'top → bottom');
          expect(result.observations.single.observed, 'top → bottom');
        },
      );
    });

    test('two observations are produced, one per compound stroke', () {
      final scorer = CompoundStrokeScorer(
        letter: 'synthetic',
        data: data,
        bounds: bounds,
      );
      final result = scorer.score([
        strokeTopRowPerfect,
        strokeBottomRowPartial,
      ]);
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
      Offset(90, 50), // 40 units from topLeft
      Offset(50, 250), // bottomLeft exact
      Offset(150, 50), // top exact
      Offset(250, 250), // bottomRight exact
    ]);

    test('default tolerance gives 4/4', () {
      final scorer = CompoundStrokeScorer(
        letter: 'n',
        data: nDataWithWaypoints,
        bounds: bounds,
      );
      final result = scorer.score([nearMissStroke]);
      expect(result.overallScore, 1.0);
    });

    test('tighter tolerance fraction (0.3) drops the off-centre waypoint', () {
      final scorer = CompoundStrokeScorer(
        letter: 'n',
        data: nDataWithWaypoints,
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
      Offset(50, 50), // topLeft
      Offset(50, 250), // bottomLeft
      Offset(150, 50), // top (first arch)
      Offset(150, 250), // bottom
      Offset(150, 50), // top (second arch)
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
      Offset(50, 50), // topLeft      ✓
      Offset(50, 250), // bottomLeft   ✓
      Offset(150, 50), // top (first)  ✓
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
        data: nDataWithWaypoints,
        bounds: bounds,
      );
      final result = scorer.score([]);
      expect(result.overallScore, 0.0);
      expect(result.observations, isEmpty);
      expect(result.summary, 'No waypoint-scored strokes were found to score.');
    });

    test('letter with waypoint-scored stem — one observation, summary', () {
      // 'l' uses top → bottom waypoints, so this scorer applies.
      final scorer = CompoundStrokeScorer(
        letter: 'l',
        data: letterFormationRegistry['l']!,
        bounds: bounds,
      );
      final result = scorer.score([
        Stroke(const [Offset(150, 10), Offset(150, 290)]),
      ]);
      expect(result.overallScore, 1.0);
      expect(result.observations.length, 1);
      expect(
        result.summary,
        'All waypoint-scored strokes followed the correct path.',
      );
    });

    test(
      'extra observed strokes that do not match any expected are ignored',
      () {
        // 'n' has one expected stroke. matchStrokes is greedy and one-to-one,
        // so a second observed stroke gets matchIndex = -1 and is silently
        // skipped by the scorer.
        final scorer = CompoundStrokeScorer(
          letter: 'n',
          data: nDataWithWaypoints,
          bounds: bounds,
        );
        final result = scorer.score([
          perfectN(),
          Stroke(const [Offset(0, 0), Offset(10, 10)]),
        ]);
        expect(result.observations.length, 1);
        expect(result.overallScore, 1.0);
      },
    );

    test('compound expected stroke with empty waypoints is not scored', () {
      final data = LetterFormationData(
        minRequiredStrokes: 1,
        strokes: [
          ExpectedStroke(
            startRect: const StrokeStartRect(
              minX: 0.0,
              maxX: 1.0,
              minY: 0.0,
              maxY: 1.0 / 3.0,
            ),
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
      expect(result.overallScore, 1.0);
      expect(result.observations, isEmpty);
      expect(result.summary, 'No waypoint-scored strokes in this letter.');
    });

    group(
      'mixed letter: compound+empty is skipped, topToBottom+waypoints is waypoint-scored',
      () {
        // Stroke 0: compound direction, no waypoints.
        //   → skipped in the loop (waypoints.isEmpty) — contributes nothing.
        // Stroke 1: topToBottom direction, waypoints [top, bottom].
        //   → routed to CompoundStrokeScorer and scored via waypoint matching.
        // Observed[i] is paired to expected[i] by order (matchStrokes is
        // order-based), so observed stroke 1 hits both centroids → 2/2.
        final data = LetterFormationData(
          minRequiredStrokes: 2,
          strokes: [
            ExpectedStroke(
              startRect: const StrokeStartRect(
                minX: 0.0,
                maxX: 0.5,
                minY: 0.0,
                maxY: 1.0 / 3.0,
              ),
              waypoints: const [],
            ),
            ExpectedStroke(
              startRect: const StrokeStartRect(
                minX: 0.5,
                maxX: 1.0,
                minY: 0.0,
                maxY: 1.0 / 3.0,
              ),
              waypoints: const [WaypointRegion.top, WaypointRegion.bottom],
            ),
          ],
        );

        // Observed stroke 0: matched to compound+empty; content irrelevant as
        // the scorer skips it.
        final anyStroke = Stroke(const [Offset(50, 50)]);
        // Observed stroke 1: matched to topToBottom+waypoints; hits both
        // top (150,50) and bottom (150,250) centroids exactly.
        final waypointStroke = Stroke(const [
          Offset(150, 50),
          Offset(150, 250),
        ]);

        late CompoundStrokeScorer scorer;

        setUp(() {
          scorer = CompoundStrokeScorer(
            letter: 'synthetic',
            data: data,
            bounds: bounds,
          );
        });

        test(
          'produces exactly one observation — only the waypoint stroke is scored',
          () {
            final result = scorer.score([anyStroke, waypointStroke]);
            expect(result.observations.length, 1);
            expect(result.observations.single.expected, 'top → bottom');
          },
        );

        test(
          'overallScore reflects only the waypoint stroke — compound+empty does not count',
          () {
            final result = scorer.score([anyStroke, waypointStroke]);
            expect(result.overallScore, 1.0);
          },
        );
      },
    );
  });
}
