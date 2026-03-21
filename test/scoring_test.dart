import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'package:handwriting_mvp/app_state.dart';
import 'package:handwriting_mvp/data/letter_templates.dart';
import 'package:handwriting_mvp/models/scoring_result.dart';
import 'package:handwriting_mvp/models/stroke_data.dart';
import 'package:handwriting_mvp/services/point_resampling.dart';
import 'package:handwriting_mvp/services/scoring_service.dart';
import 'package:handwriting_mvp/services/stroke_matching_service.dart';

// Helpers -------------------------------------------------------------------

/// Build a [StrokeData] from a list of (x, y) pairs in canvas coordinates.
StrokeData _stroke(List<Offset> pts) => StrokeData(
      points: pts.map((p) => PointVector(p.dx, p.dy, 0.5)).toList(),
      width: 5.0,
      simulatePressure: true,
    );

/// A simulated canvas size for testing (300 × 360 at 1:1.2 ratio).
const _canvasSize = Size(300, 360);

/// Convert template-space offsets to canvas-space offsets for the test canvas.
/// template.x → x * 300,  template.y → (0.05 + (1-ty)*0.90) * 360
Offset _templateToCanvas(Offset t) {
  const pad = 0.05;
  const zone = 0.90;
  return Offset(
    t.dx * _canvasSize.width,
    (pad + (1.0 - t.dy) * zone) * _canvasSize.height,
  );
}

/// Generate a perfect user drawing by converting a template's strokes to
/// canvas coordinates (simulating the user tracing perfectly).
List<StrokeData> _perfectDrawing(String letter, {bool uppercase = false}) {
  final template = lookupTemplate(letter, uppercase: uppercase)!;
  return template.strokes.map((stroke) {
    final canvasPoints =
        stroke.map((p) => _templateToCanvas(p)).toList();
    return _stroke(canvasPoints);
  }).toList();
}

/// Shift every point of every stroke by (dx, dy) in canvas pixels.
List<StrokeData> _shiftDrawing(List<StrokeData> strokes, double dx, double dy) {
  return strokes.map((s) {
    return StrokeData(
      points: s.points
          .map((p) => PointVector(p.x + dx, p.y + dy, p.pressure))
          .toList(),
      width: s.width,
      simulatePressure: s.simulatePressure,
    );
  }).toList();
}

/// Scale every point of every stroke relative to the centroid.
List<StrokeData> _scaleDrawing(List<StrokeData> strokes, double factor) {
  // Find centroid of all points.
  var cx = 0.0, cy = 0.0;
  var count = 0;
  for (final s in strokes) {
    for (final p in s.points) {
      cx += p.x;
      cy += p.y;
      count++;
    }
  }
  cx /= count;
  cy /= count;

  return strokes.map((s) {
    return StrokeData(
      points: s.points
          .map((p) => PointVector(
                cx + (p.x - cx) * factor,
                cy + (p.y - cy) * factor,
                p.pressure,
              ))
          .toList(),
      width: s.width,
      simulatePressure: s.simulatePressure,
    );
  }).toList();
}

/// Add random noise to each point.
List<StrokeData> _addNoise(List<StrokeData> strokes, double maxPixels) {
  final rng = Random(42);
  return strokes.map((s) {
    return StrokeData(
      points: s.points
          .map((p) => PointVector(
                p.x + (rng.nextDouble() - 0.5) * 2 * maxPixels,
                p.y + (rng.nextDouble() - 0.5) * 2 * maxPixels,
                p.pressure,
              ))
          .toList(),
      width: s.width,
      simulatePressure: s.simulatePressure,
    );
  }).toList();
}

// Tests ---------------------------------------------------------------------

void main() {
  // ========== Point resampling ==========

  group('Point resampling', () {
    test('straight line produces equidistant points', () {
      final pts = [const Offset(0, 0), const Offset(10, 0)];
      final result = resampleEquidistant(pts, 11);
      expect(result.length, 11);
      for (var i = 0; i < 11; i++) {
        expect(result[i].dx, closeTo(i.toDouble(), 1e-6));
        expect(result[i].dy, closeTo(0.0, 1e-6));
      }
    });

    test('single point returns n copies', () {
      final result = resampleEquidistant([const Offset(5, 5)], 8);
      expect(result.length, 8);
      for (final p in result) {
        expect(p, const Offset(5, 5));
      }
    });

    test('preserves first and last point', () {
      final pts = [
        const Offset(0, 0),
        const Offset(3, 4),
        const Offset(10, 0),
      ];
      final result = resampleEquidistant(pts, 20);
      expect(result.first, pts.first);
      expect(result.last, pts.last);
    });
  });

  // ========== Stroke matching ==========

  group('Stroke matching', () {
    test('single stroke passthrough', () {
      final template = [
        [const Offset(0, 0), const Offset(1, 1)],
      ];
      final user = [
        [const Offset(0.1, 0.1), const Offset(1.1, 1.1)],
      ];
      final (tPath, uPath) =
          StrokeMatchingService.alignAndConcatenate(template, user);
      expect(tPath.length, 2);
      expect(uPath.length, 2);
    });

    test('reorders user strokes to match template order', () {
      // Template: top-left stroke then bottom-right stroke (distinct centroids)
      final template = [
        [const Offset(0.1, 0.8), const Offset(0.3, 0.9)], // top-left
        [const Offset(0.7, 0.1), const Offset(0.9, 0.2)], // bottom-right
      ];
      // User draws bottom-right first, then top-left
      final user = [
        [const Offset(0.7, 0.1), const Offset(0.9, 0.2)], // bottom-right
        [const Offset(0.1, 0.8), const Offset(0.3, 0.9)], // top-left
      ];
      final (_, uPath) =
          StrokeMatchingService.alignAndConcatenate(template, user);

      // User path should be reordered: top-left first, then bottom-right.
      expect(uPath[0], const Offset(0.1, 0.8)); // start of top-left
      expect(uPath[2], const Offset(0.7, 0.1)); // start of bottom-right
    });
  });

  // ========== Full scoring — perfect match ==========

  group('Scoring — perfect match', () {
    test('identical drawing scores 10 on all categories (beginner)', () {
      final drawing = _perfectDrawing('a');
      final result = ScoringService.score(
        userStrokes: drawing,
        template: lookupTemplate('a', uppercase: false)!,
        canvasSize: _canvasSize,
        guidelineMode: GuidelineMode.full,
        difficulty: Difficulty.beginner,
      );

      expect(result.shapeScore, 10);
      expect(result.placementScore, 10);
      expect(result.thirdScore, 10);
      expect(result.combinedScore, 10);
      expect(result.feedbackMessage, contains('Excellent'));
    });

    test('identical drawing scores 10 on advanced', () {
      final drawing = _perfectDrawing('g');
      final result = ScoringService.score(
        userStrokes: drawing,
        template: lookupTemplate('g', uppercase: false)!,
        canvasSize: _canvasSize,
        guidelineMode: GuidelineMode.full,
        difficulty: Difficulty.advanced,
      );

      expect(result.shapeScore, 10);
      expect(result.placementScore, 10);
    });
  });

  // ========== Scoring — degraded input ==========

  group('Scoring — degraded input', () {
    test('large shift lowers placement but keeps shape high', () {
      // 60px vertical shift ≈ 0.19 in template space — well past beginner threshold.
      final drawing = _shiftDrawing(_perfectDrawing('a'), 0, 60);
      final result = ScoringService.score(
        userStrokes: drawing,
        template: lookupTemplate('a', uppercase: false)!,
        canvasSize: _canvasSize,
        guidelineMode: GuidelineMode.full,
        difficulty: Difficulty.beginner,
      );

      // Shape should still be high (shift doesn't change shape).
      expect(result.shapeScore, greaterThanOrEqualTo(7));
      // Placement should be noticeably lower.
      expect(result.placementScore, lessThan(result.shapeScore));
    });

    test('scaling affects size score', () {
      final drawing = _scaleDrawing(_perfectDrawing('a'), 1.5);
      final result = ScoringService.score(
        userStrokes: drawing,
        template: lookupTemplate('a', uppercase: false)!,
        canvasSize: _canvasSize,
        guidelineMode: GuidelineMode.baselineOnly,
        difficulty: Difficulty.beginner,
      );

      expect(result.thirdScoreLabel, 'Size');
      // Size score should be lower than perfect.
      expect(result.thirdScore, lessThan(10));
    });

    test('noisy drawing scores lower than perfect on intermediate', () {
      // 50px noise on intermediate difficulty where thresholds are tighter.
      final drawing = _addNoise(_perfectDrawing('a'), 50);
      final result = ScoringService.score(
        userStrokes: drawing,
        template: lookupTemplate('a', uppercase: false)!,
        canvasSize: _canvasSize,
        guidelineMode: GuidelineMode.full,
        difficulty: Difficulty.intermediate,
      );

      // At least one category should be impacted.
      final allPerfect = result.shapeScore == 10 &&
          result.placementScore == 10 &&
          result.thirdScore == 10;
      expect(allPerfect, isFalse);
    });
  });

  // ========== Difficulty comparison ==========

  group('Difficulty levels', () {
    test('same input scores higher on beginner than advanced', () {
      final drawing = _addNoise(_perfectDrawing('b'), 12);

      final beginner = ScoringService.score(
        userStrokes: drawing,
        template: lookupTemplate('b', uppercase: false)!,
        canvasSize: _canvasSize,
        guidelineMode: GuidelineMode.full,
        difficulty: Difficulty.beginner,
      );
      final advanced = ScoringService.score(
        userStrokes: drawing,
        template: lookupTemplate('b', uppercase: false)!,
        canvasSize: _canvasSize,
        guidelineMode: GuidelineMode.full,
        difficulty: Difficulty.advanced,
      );

      expect(beginner.combinedScore, greaterThanOrEqualTo(advanced.combinedScore));
    });
  });

  // ========== Feedback messages ==========

  group('Feedback messages', () {
    test('score ranges map to correct messages', () {
      expect(ScoringResult.messageForScore(1), contains('more practice'));
      expect(ScoringResult.messageForScore(4), contains('more practice'));
      expect(ScoringResult.messageForScore(5), contains('Getting there'));
      expect(ScoringResult.messageForScore(6), contains('Getting there'));
      expect(ScoringResult.messageForScore(7), contains('Well done'));
      expect(ScoringResult.messageForScore(9), contains('Well done'));
      expect(ScoringResult.messageForScore(10), contains('Excellent'));
    });
  });

  // ========== Multi-stroke letter ==========

  group('Multi-stroke letter scoring', () {
    test('perfect t (multi-stroke) scores 10', () {
      final drawing = _perfectDrawing('t');
      final result = ScoringService.score(
        userStrokes: drawing,
        template: lookupTemplate('t', uppercase: false)!,
        canvasSize: _canvasSize,
        guidelineMode: GuidelineMode.full,
        difficulty: Difficulty.beginner,
      );
      expect(result.shapeScore, 10);
    });

    test('uppercase A (3 strokes) scores 10 on perfect drawing', () {
      final drawing = _perfectDrawing('a', uppercase: true);
      final result = ScoringService.score(
        userStrokes: drawing,
        template: lookupTemplate('a', uppercase: true)!,
        canvasSize: _canvasSize,
        guidelineMode: GuidelineMode.full,
        difficulty: Difficulty.beginner,
      );
      expect(result.shapeScore, 10);
    });
  });

  // ========== Empty input ==========

  group('Edge cases', () {
    test('empty drawing returns all 1s', () {
      final result = ScoringService.score(
        userStrokes: [],
        template: lookupTemplate('a', uppercase: false)!,
        canvasSize: _canvasSize,
        guidelineMode: GuidelineMode.full,
        difficulty: Difficulty.beginner,
      );

      expect(result.shapeScore, 1);
      expect(result.placementScore, 1);
      expect(result.thirdScore, 1);
      expect(result.combinedScore, 1);
    });
  });

  // ========== Phase 8: All 30 letter templates ==========

  const letters = ['a', 'b', 'd', 'e', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'p', 'q', 't', 'y'];

  group('All 30 templates exist', () {
    for (final letter in letters) {
      test('lowercase $letter has a template', () {
        expect(lookupTemplate(letter, uppercase: false), isNotNull);
      });
      test('uppercase ${letter.toUpperCase()} has a template', () {
        expect(lookupTemplate(letter, uppercase: true), isNotNull);
      });
    }
  });

  group('All 30 templates — perfect drawing scores 10', () {
    for (final letter in letters) {
      for (final upper in [false, true]) {
        final label = upper ? letter.toUpperCase() : letter;
        test('perfect $label scores 10 combined (beginner)', () {
          final drawing = _perfectDrawing(letter, uppercase: upper);
          final result = ScoringService.score(
            userStrokes: drawing,
            template: lookupTemplate(letter, uppercase: upper)!,
            canvasSize: _canvasSize,
            guidelineMode: GuidelineMode.full,
            difficulty: Difficulty.beginner,
          );

          expect(result.shapeScore, 10,
              reason: '$label shape should be 10');
          expect(result.placementScore, 10,
              reason: '$label placement should be 10');
          expect(result.thirdScore, 10,
              reason: '$label proportion should be 10');
          expect(result.combinedScore, 10,
              reason: '$label combined should be 10');
        });
      }
    }
  });

  group('All 30 templates — noisy drawing degrades gracefully', () {
    for (final letter in letters) {
      for (final upper in [false, true]) {
        final label = upper ? letter.toUpperCase() : letter;
        test('noisy $label still produces valid scores', () {
          final drawing = _addNoise(
            _perfectDrawing(letter, uppercase: upper),
            25,
          );
          final result = ScoringService.score(
            userStrokes: drawing,
            template: lookupTemplate(letter, uppercase: upper)!,
            canvasSize: _canvasSize,
            guidelineMode: GuidelineMode.full,
            difficulty: Difficulty.intermediate,
          );

          expect(result.shapeScore, inInclusiveRange(1, 10));
          expect(result.placementScore, inInclusiveRange(1, 10));
          expect(result.thirdScore, inInclusiveRange(1, 10));
          expect(result.combinedScore, inInclusiveRange(1, 10));
          expect(result.feedbackMessage, isNotEmpty);
        });
      }
    }
  });

  group('All 30 templates — difficulty ordering holds', () {
    for (final letter in letters) {
      test('$letter: beginner >= advanced for noisy input', () {
        final drawing = _addNoise(_perfectDrawing(letter), 15);

        final beginner = ScoringService.score(
          userStrokes: drawing,
          template: lookupTemplate(letter, uppercase: false)!,
          canvasSize: _canvasSize,
          guidelineMode: GuidelineMode.full,
          difficulty: Difficulty.beginner,
        );
        final advanced = ScoringService.score(
          userStrokes: drawing,
          template: lookupTemplate(letter, uppercase: false)!,
          canvasSize: _canvasSize,
          guidelineMode: GuidelineMode.full,
          difficulty: Difficulty.advanced,
        );

        expect(beginner.combinedScore,
            greaterThanOrEqualTo(advanced.combinedScore),
            reason: '$letter: beginner should score >= advanced');
      });
    }
  });
}
