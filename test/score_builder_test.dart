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

/// Builds a [rows]×[cols] mask with ink set on every pixel in the row range
/// [inkFirstRow, inkLastRow] (inclusive, 0-based), across all columns.
///
/// The bounds origin is (0, 0), so canvas coordinates equal mask indices.
/// This produces a [TemplateRasterResult] whose [TemplateRasterResult.tightBounds]
/// differs from [TemplateRasterResult.bounds] whenever [inkFirstRow] > 0 or
/// [inkLastRow] < [rows] - 1.
TemplateRasterResult _inkTemplate({
  required int rows,
  required int cols,
  required int inkFirstRow,
  required int inkLastRow,
}) {
  final mask = List.generate(rows, (row) {
    return List.generate(cols, (_) => row >= inkFirstRow && row <= inkLastRow);
  });
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

  // ---------------------------------------------------------------------------
  // Regression: StrokeStartScorer receives tightBounds, not the loose bounds.
  //
  // Before the fix, buildScoreResult passed templateResult.bounds (the full
  // TextPainter layout rect) as formationBounds to ScoreIntegrator.  For a
  // short letter like 'a', bounds is much taller than the actual ink, so the
  // vertical-thirds thresholds were too wide: a stroke correctly starting at
  // the visual top of the ink (tight.top) could fall in the MIDDLE third of
  // the loose bounds, yielding score 0.5 instead of 1.0.
  //
  // These tests use synthetic templates whose tightBounds differs from bounds,
  // letting us assert the correct score with the fixed code and document what
  // the broken code would have returned.
  // ---------------------------------------------------------------------------

  group('buildScoreResult — tight bounds passed to StrokeStartScorer', () {
    // ── Short letter ('a') ───────────────────────────────────────────────────
    //
    // Template: 100×120 bounds; ink occupies only rows 60–119 (the lower
    // half), simulating a short x-height letter that sits on the baseline.
    //
    //   tightBounds : top=60, height=60, thirdH=20
    //   bounds      : top= 0, height=120, thirdH=40   (loose rect, pre-fix)
    //
    // Stroke: first point at y=60 (= tightBounds.top).
    //   With tightBounds: dy = 0  < 20 → TOP  → score 1.0  ← expected (post-fix)
    //   With loose bounds: dy = 60; 40 ≤ 60 < 80 → MIDDLE → score 0.5  ← pre-fix failure
    //
    // This test would have failed before the fix because the scorer received
    // the loose bounds and classified the visually-correct top start as middle.
    test("short letter 'a': stroke at tight top → StrokeStartScorer score is 1.0", () {
      // Ink in rows 60–119 of a 120-row template; all 100 columns have ink.
      // tightBounds = Rect(left=0, top=60, right=100, bottom=120).
      final template = _inkTemplate(
        rows: 120,
        cols: 100,
        inkFirstRow: 60,
        inkLastRow: 119,
      );

      // Expected centroid for 'a' (startRegion=top) with tightBounds:
      //   cx = 50, cy = 60 + 20 * 0.5 = 70.
      // Stroke centroid: min_y=60, max_y=80 → mid=70.  Centroid = (50, 70) ✓
      final stroke = Stroke(const [Offset(50, 60), Offset(50, 80)]);

      final result = buildScoreResult(
        templateResult: template,
        strokes: [stroke],
        letter: 'a',
      );

      expect(result.strokeStart, isNotNull,
          reason: 'strokeStart must be non-null for letter a');
      expect(
        result.strokeStart!.overallScore,
        1.0,
        reason: 'stroke starts at tightBounds.top: dy=0 < thirdH=20 → top → score 1.0',
      );
    });

    // ── Tall letter ('b') ───────────────────────────────────────────────────
    //
    // Template: 100×120 bounds; ink occupies rows 0–119 (full height),
    // simulating a tall ascender letter.
    //
    //   tightBounds : top=0, height=120, thirdH=40
    //   Bottom third of tightBounds starts at y=80.
    //
    // Stroke: first point at y=90 (bottom third of tightBounds).
    //   dy = 90, thirdH = 40; 90 ≥ 80 → BOTTOM.
    //   Expected startRegion for 'b' stroke 0 is top; observed is bottom
    //   → opposite mismatch → score 0.0 < 1.0.
    //
    // Stroke centroid is kept at (50, 20) (≈ expected top-region centroid) so
    // the stroke is correctly matched to expected stroke 0 by the matcher.
    test("tall letter 'b': stroke at bottom of tight bounds → StrokeStartScorer score < 1.0", () {
      // Ink in all 120 rows; tightBounds equals bounds (top=0, height=120).
      final template = _inkTemplate(
        rows: 120,
        cols: 100,
        inkFirstRow: 0,
        inkLastRow: 119,
      );

      // First point at y=90 → bottom third.
      // Centroid: min_y = -50, max_y = 90 → mid = 20.  Centroid = (50, 20).
      // Expected centroid for 'b' stroke 0 (startRegion=top, tightBounds):
      //   cy = 0 + 40 * 0.5 = 20.  Distance = 0 → certain match. ✓
      final stroke = Stroke(const [Offset(50, 90), Offset(50, -50)]);

      final result = buildScoreResult(
        templateResult: template,
        strokes: [stroke],
        letter: 'b',
      );

      expect(result.strokeStart, isNotNull,
          reason: 'strokeStart must be non-null for letter b');
      expect(
        result.strokeStart!.overallScore,
        lessThan(1.0),
        reason: 'stroke starts in bottom third (dy=90 ≥ 80): '
            'expected top, observed bottom → score 0.0',
      );
    });
  });
}
