import 'dart:math' show pi, cos, sin;
import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_direction_scorer.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';

void main() {
  // 300×300 bounding box, consistent with other scorer tests.
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  // ---------------------------------------------------------------------------
  // Helper constructors
  // ---------------------------------------------------------------------------

  /// A circular stroke drawn clockwise in screen coordinates.
  ///
  /// Starts at the top of the circle and steps clockwise:
  /// top → right → bottom → left → top.
  /// Using the shoelace formula with Y-down coords, positive signed area
  /// → clockwise.
  Stroke clockwiseCircle({double cx = 150, double cy = 150, double r = 100}) {
    const steps = 32;
    final pts = <Offset>[];
    for (var k = 0; k <= steps; k++) {
      final angle = -pi / 2 + (2 * pi * k / steps);
      pts.add(Offset(cx + r * cos(angle), cy + r * sin(angle)));
    }
    return Stroke(pts);
  }

  /// A circular stroke drawn anticlockwise in screen coordinates.
  Stroke anticlockwiseCircle({
    double cx = 150,
    double cy = 150,
    double r = 100,
  }) {
    const steps = 32;
    final pts = <Offset>[];
    for (var k = 0; k <= steps; k++) {
      final angle = -pi / 2 - (2 * pi * k / steps);
      pts.add(Offset(cx + r * cos(angle), cy + r * sin(angle)));
    }
    return Stroke(pts);
  }

  /// A vertical stroke drawn top to bottom.
  Stroke topToBottomStroke({double x = 150}) =>
      Stroke([Offset(x, 10), Offset(x, 290)]);

  /// A vertical stroke drawn bottom to top.
  Stroke bottomToTopStroke({double x = 150}) =>
      Stroke([Offset(x, 290), Offset(x, 10)]);

  /// A horizontal stroke drawn left to right.
  Stroke leftToRightStroke({double y = 150}) =>
      Stroke([Offset(10, y), Offset(290, y)]);

  /// A horizontal stroke drawn right to left.
  Stroke rightToLeftStroke({double y = 150}) =>
      Stroke([Offset(290, y), Offset(10, y)]);

  // ---------------------------------------------------------------------------
  // Helper data factories
  // ---------------------------------------------------------------------------

  /// Creates a single-stroke [LetterFormationData] with the given direction.
  LetterFormationData singleStrokeData(StrokeDirection dir) =>
      LetterFormationData(
        minRequiredStrokes: 1,
        strokes: [
          ExpectedStroke(
            primaryDirection: dir,
            startRect: const StrokeStartRect(
              minX: 0.0,
              maxX: 1.0,
              minY: 0.0,
              maxY: 1.0 / 3.0,
            ),
          ),
        ],
      );

  // ---------------------------------------------------------------------------
  // Circular strokes
  // ---------------------------------------------------------------------------

  group('circular strokes', () {
    group('clockwise stroke against expected anticlockwise', () {
      late StrokeDirectionScorer scorer;

      setUp(() {
        scorer = StrokeDirectionScorer(
          letter: 'synthetic',
          data: singleStrokeData(StrokeDirection.anticlockwise),
          bounds: bounds,
        );
      });

      test('overallScore is 0.0', () {
        final result = scorer.score([clockwiseCircle()]);
        expect(result.overallScore, 0.0);
      });

      test('one observation is produced', () {
        final result = scorer.score([clockwiseCircle()]);
        expect(result.observations.length, 1);
      });

      test('observation expected is "anticlockwise"', () {
        final result = scorer.score([clockwiseCircle()]);
        expect(result.observations.first.expected, 'anticlockwise');
      });

      test('observation observed is "clockwise"', () {
        final result = scorer.score([clockwiseCircle()]);
        expect(result.observations.first.observed, 'clockwise');
      });

      test('observation score is 0.0', () {
        final result = scorer.score([clockwiseCircle()]);
        expect(result.observations.first.score, 0.0);
      });

      test('note mentions clockwise and anticlockwise', () {
        final result = scorer.score([clockwiseCircle()]);
        expect(result.observations.first.note, contains('clockwise'));
        expect(result.observations.first.note, contains('anticlockwise'));
      });
    });

    group('anticlockwise stroke against expected anticlockwise', () {
      late StrokeDirectionScorer scorer;

      setUp(() {
        scorer = StrokeDirectionScorer(
          letter: 'synthetic',
          data: singleStrokeData(StrokeDirection.anticlockwise),
          bounds: bounds,
        );
      });

      test('overallScore is 1.0', () {
        final result = scorer.score([anticlockwiseCircle()]);
        expect(result.overallScore, 1.0);
      });

      test('observation score is 1.0', () {
        final result = scorer.score([anticlockwiseCircle()]);
        expect(result.observations.first.score, 1.0);
      });

      test('note contains "correct"', () {
        final result = scorer.score([anticlockwiseCircle()]);
        expect(result.observations.first.note, contains('correct'));
      });
    });

    group('clockwise stroke against expected clockwise', () {
      test('overallScore is 1.0', () {
        final scorer = StrokeDirectionScorer(
          letter: 'b',
          data: singleStrokeData(StrokeDirection.clockwise),
          bounds: bounds,
        );
        final result = scorer.score([clockwiseCircle()]);
        expect(result.overallScore, 1.0);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Linear strokes
  // ---------------------------------------------------------------------------

  group('linear strokes', () {
    group('rightToLeft against expected leftToRight', () {
      late StrokeDirectionScorer scorer;

      setUp(() {
        scorer = StrokeDirectionScorer(
          letter: 't',
          data: singleStrokeData(StrokeDirection.leftToRight),
          bounds: bounds,
        );
      });

      test('overallScore is 0.0', () {
        final result = scorer.score([rightToLeftStroke()]);
        expect(result.overallScore, 0.0);
      });

      test('observation observed is "rightToLeft"', () {
        final result = scorer.score([rightToLeftStroke()]);
        expect(result.observations.first.observed, 'rightToLeft');
      });

      test('observation score is 0.0', () {
        final result = scorer.score([rightToLeftStroke()]);
        expect(result.observations.first.score, 0.0);
      });

      test('note mentions left to right and right to left', () {
        final result = scorer.score([rightToLeftStroke()]);
        expect(result.observations.first.note, contains('right to left'));
        expect(result.observations.first.note, contains('left to right'));
      });
    });

    group('leftToRight against expected leftToRight', () {
      test('overallScore is 1.0', () {
        final scorer = StrokeDirectionScorer(
          letter: 't',
          data: singleStrokeData(StrokeDirection.leftToRight),
          bounds: bounds,
        );
        final result = scorer.score([leftToRightStroke()]);
        expect(result.overallScore, 1.0);
      });
    });

    group('bottomToTop against expected topToBottom', () {
      test('overallScore is 0.0', () {
        final scorer = StrokeDirectionScorer(
          letter: 'l',
          data: singleStrokeData(StrokeDirection.topToBottom),
          bounds: bounds,
        );
        final result = scorer.score([bottomToTopStroke()]);
        expect(result.overallScore, 0.0);
      });
    });

    group('topToBottom against expected topToBottom', () {
      test('overallScore is 1.0', () {
        final scorer = StrokeDirectionScorer(
          letter: 'l',
          data: singleStrokeData(StrokeDirection.topToBottom),
          bounds: bounds,
        );
        final result = scorer.score([topToBottomStroke()]);
        expect(result.overallScore, 1.0);
      });
    });

    group('topToBottom against expected leftToRight — other mismatch', () {
      test('overallScore is 0.5', () {
        final scorer = StrokeDirectionScorer(
          letter: 't',
          data: singleStrokeData(StrokeDirection.leftToRight),
          bounds: bounds,
        );
        final result = scorer.score([topToBottomStroke()]);
        expect(result.overallScore, 0.5);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Multi-stroke 't' — stem topToBottom + crossbar leftToRight
  //
  // 't' has two expected strokes:
  //   stroke 0: topToBottom → expected centroid (150, 50)
  //   stroke 1: leftToRight → expected centroid (150, 150)
  //
  // Observed strokes must have bounding-box centroids in matching regions
  // so that spatial matching assigns them correctly:
  //   stem     → Stroke([(150,10)→(150,90)])  centroid (150,  50) → top
  //   crossbar → Stroke([(  0,150)→(300,150)]) centroid (150, 150) → middle
  // ---------------------------------------------------------------------------

  group("'t' with correctly drawn stem and crossbar", () {
    late StrokeDirectionScorer scorer;

    setUp(() {
      scorer = StrokeDirectionScorer(
        letter: 't',
        data: letterFormationRegistry['t']!,
        bounds: bounds,
      );
    });

    // Strokes with centroids that match the expected region centroids for 't'.
    final tStem = Stroke([
      const Offset(150, 10),
      const Offset(150, 90),
    ]); // centroid (150,  50)
    final tCrossbar = Stroke([
      const Offset(0, 150),
      const Offset(300, 150),
    ]); // centroid (150, 150)

    test('overallScore is 1.0', () {
      final result = scorer.score([tStem, tCrossbar]);
      expect(result.overallScore, 1.0);
    });

    test('two observations are produced', () {
      final result = scorer.score([tStem, tCrossbar]);
      expect(result.observations.length, 2);
    });

    test('stem is skipped and crossbar scores 1.0', () {
      final result = scorer.score([tStem, tCrossbar]);
      expect(result.observations[0].note, contains('CompoundStrokeScorer'));
      expect(result.observations[0].score, 0.0);
      expect(result.observations[1].score, 1.0);
    });

    test('summary indicates all strokes correct', () {
      final result = scorer.score([tStem, tCrossbar]);
      expect(result.summary, contains('correct'));
    });
  });

  // ---------------------------------------------------------------------------
  // Compound 'n' — skipped, no contribution to overall score
  // ---------------------------------------------------------------------------

  group("compound 'n' — skipped strokes", () {
    late StrokeDirectionScorer scorer;

    setUp(() {
      scorer = StrokeDirectionScorer(
        letter: 'n',
        data: letterFormationRegistry['n']!,
        bounds: bounds,
      );
    });

    group('non-compound stroke with waypoints — skipped', () {
      final data = LetterFormationData(
        minRequiredStrokes: 1,
        strokes: [
          ExpectedStroke(
            primaryDirection: StrokeDirection.topToBottom,
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

      final observed = [
        Stroke([const Offset(150, 10), const Offset(150, 290)]),
      ];

      test('stroke is skipped for CompoundStrokeScorer', () {
        final scorer = StrokeDirectionScorer(
          letter: 'synthetic',
          data: data,
          bounds: bounds,
        );
        final result = scorer.score(observed);
        expect(
          result.observations.single.note,
          contains('CompoundStrokeScorer'),
        );
      });

      test('overallScore excludes the waypoint-scored stroke', () {
        final scorer = StrokeDirectionScorer(
          letter: 'synthetic',
          data: data,
          bounds: bounds,
        );
        final result = scorer.score(observed);
        expect(result.overallScore, 0.0);
        expect(result.summary, contains('No direction-scored strokes'));
      });
    });

    // A compound stroke for 'n' following roughly its waypoint regions:
    // topLeft → bottomLeft → top → bottomRight within the 300×300 bounds.
    final nStroke = Stroke([
      const Offset(50, 10), // topLeft area
      const Offset(50, 250), // bottomLeft area
      const Offset(150, 10), // top area
      const Offset(250, 250), // bottomRight area
    ]);

    test('overallScore is 0.0 (no scorable strokes)', () {
      final result = scorer.score([nStroke]);
      expect(result.overallScore, 0.0);
    });

    test('one observation is produced', () {
      final result = scorer.score([nStroke]);
      expect(result.observations.length, 1);
    });

    test('observation note contains "skipped"', () {
      final result = scorer.score([nStroke]);
      expect(result.observations.first.note, contains('skipped'));
    });

    test('observation note references CompoundStrokeScorer', () {
      final result = scorer.score([nStroke]);
      expect(result.observations.first.note, contains('CompoundStrokeScorer'));
    });
  });

  // ---------------------------------------------------------------------------
  // Dot strokes — skipped, handled by StrokeBreakCounter
  // ---------------------------------------------------------------------------

  group('dot stroke — skipped', () {
    test('dot stroke is recorded with skipped note', () {
      final scorer = StrokeDirectionScorer(
        letter: 'i',
        data: letterFormationRegistry['i']!,
        bounds: bounds,
      );

      // Two strokes: stem (top-to-bottom) + dot.
      final observed = [
        topToBottomStroke(),
        Stroke([const Offset(150, 10)]),
      ];
      final result = scorer.score(observed);

      final dotObs = result.observations.firstWhere(
        (o) => o.note.contains('StrokeBreakCounter'),
      );
      expect(dotObs.note, contains('skipped'));
    });

    test('dot stroke does not count toward overall score', () {
      final scorer = StrokeDirectionScorer(
        letter: 'i',
        data: letterFormationRegistry['i']!,
        bounds: bounds,
      );

      // Stem and dot are both skipped for this scorer.
      final observed = [
        topToBottomStroke(),
        Stroke([const Offset(150, 10)]),
      ];
      final result = scorer.score(observed);
      expect(result.overallScore, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------

  group('edge cases', () {
    test('empty stroke list returns overallScore 0.0', () {
      final scorer = StrokeDirectionScorer(
        letter: 'o',
        data: letterFormationRegistry['o']!,
        bounds: bounds,
      );
      final result = scorer.score([]);
      expect(result.overallScore, 0.0);
    });

    test('empty stroke returns overallScore 0.0 and no observation', () {
      final scorer = StrokeDirectionScorer(
        letter: 'o',
        data: letterFormationRegistry['o']!,
        bounds: bounds,
      );
      final result = scorer.score([Stroke([])]);
      expect(result.overallScore, 0.0);
      expect(result.observations, isEmpty);
    });

    test('summary when no scorable strokes', () {
      final scorer = StrokeDirectionScorer(
        letter: 'n',
        data: letterFormationRegistry['n']!,
        bounds: bounds,
      );
      final result = scorer.score([
        Stroke([const Offset(50, 10), const Offset(250, 250)]),
      ]);
      expect(result.summary, contains('No direction-scored strokes'));
    });
  });
}
