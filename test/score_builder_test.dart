import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/score_builder.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/template_rasterizer.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a [rows]×[cols] all-false mask.  Formation scorers only consult
/// [TemplateRasterResult.bounds] for coordinate arithmetic; the actual pixel
/// values are not needed for these tests.
TemplateRasterResult _blankTemplate(int rows, int cols) {
  final mask = List.generate(rows, (_) => List.filled(cols, false));
  return TemplateRasterResult(
    mask: mask,
    bounds: Rect.fromLTWH(0, 0, cols.toDouble(), rows.toDouble()),
  );
}

void main() {
  // 90×90 template — matches the size used in score_integrator_test.dart for
  // formation-scoring tests, so the same stroke coordinates apply here.
  final template90 = _blankTemplate(90, 90);

  // ---------------------------------------------------------------------------
  // Regression: formation fields must survive the ScoreIntegrator → ScoreResult
  // hand-off performed by buildScoreResult.
  //
  // If any of the four formation assignments is dropped from buildScoreResult,
  // the corresponding expect below will fail, catching the regression before
  // it reaches manual QA.
  // ---------------------------------------------------------------------------

  group('buildScoreResult — formation field propagation', () {
    test('all four formation fields are non-null for letter n (has formation data)', () {
      // n has a single compound stroke; these waypoints visit the expected
      // centroids in a 90×90 grid (3×3 cells of 30 px each).
      final stroke = Stroke(const [
        Offset(15, 15), // topLeft centroid
        Offset(15, 75), // bottomLeft centroid
        Offset(45, 15), // top centroid
        Offset(75, 75), // bottomRight centroid
      ]);

      final result = buildScoreResult(
        templateResult: template90,
        strokes: [stroke],
        letter: 'n',
      );

      expect(result.strokeStart, isNotNull,
          reason: 'strokeStart must be propagated from ScoreIntegrator');
      expect(result.strokeDirection, isNotNull,
          reason: 'strokeDirection must be propagated from ScoreIntegrator');
      expect(result.compoundStroke, isNotNull,
          reason: 'compoundStroke must be propagated from ScoreIntegrator');
      expect(result.strokeBreak, isNotNull,
          reason: 'strokeBreak must be propagated from ScoreIntegrator');
    });

    test('all four formation fields are non-null for letter o (has formation data)', () {
      // o expects an anticlockwise stroke.
      final stroke = Stroke(const [
        Offset(45, 5),  // top
        Offset(5, 45),  // left
        Offset(45, 85), // bottom
        Offset(85, 45), // right
      ]);

      final result = buildScoreResult(
        templateResult: template90,
        strokes: [stroke],
        letter: 'o',
      );

      expect(result.strokeStart, isNotNull,
          reason: 'strokeStart must be propagated from ScoreIntegrator');
      expect(result.strokeDirection, isNotNull,
          reason: 'strokeDirection must be propagated from ScoreIntegrator');
      expect(result.compoundStroke, isNotNull,
          reason: 'compoundStroke must be propagated from ScoreIntegrator');
      expect(result.strokeBreak, isNotNull,
          reason: 'strokeBreak must be propagated from ScoreIntegrator');
    });
  });

  // ---------------------------------------------------------------------------
  // Smoke tests: bitmap and placement scores are plausible after the refactor.
  // ---------------------------------------------------------------------------

  group('buildScoreResult — bitmap and placement scores', () {
    test('bitmap scores are in the valid 0.0–1.0 range', () {
      final stroke = Stroke(const [Offset(15, 15), Offset(15, 75)]);

      final result = buildScoreResult(
        templateResult: template90,
        strokes: [stroke],
        letter: 'n',
      );

      expect(result.coverage, inInclusiveRange(0.0, 1.0));
      expect(result.precision, inInclusiveRange(0.0, 1.0));
      expect(result.efficiency, inInclusiveRange(0.0, 1.0));
    });

    test('placement is 0.0 when template has no ink pixels (inkBounds is null)', () {
      // The all-false mask has no ink → inkBounds returns null → placement
      // stays at its default value of 0.0.
      final stroke = Stroke(const [Offset(15, 15)]);

      final result = buildScoreResult(
        templateResult: template90,
        strokes: [stroke],
        letter: 'n',
      );

      expect(result.placement, 0.0);
    });
  });
}
