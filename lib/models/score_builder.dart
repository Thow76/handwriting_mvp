import 'placement_scorer.dart';
import 'score_integrator.dart';
import 'score_result.dart';
import 'stroke.dart';
import 'template_rasterizer.dart';

/// Combines bitmap scoring (via [ScoreIntegrator]) and placement scoring (via
/// [PlacementScorer]) for a completed handwriting attempt.
///
/// This pure function encapsulates the computation that `_runScoring` in
/// `DrawingCanvas` performs, allowing the integration between
/// [ScoreIntegrator.score] and the [ScoreResult] handed to `ScoreDisplay` to
/// be exercised by unit tests without touching `setState`.
///
/// [templateResult] is the pre-rasterized reference template for [letter].
/// [strokes] are the user's observed strokes in canvas coordinates.
/// [letter] is the target letter; formation scoring is applied using the
/// authored formation data for that letter.
ScoreResult buildScoreResult({
  required TemplateRasterResult templateResult,
  required List<Stroke> strokes,
  required String letter,
}) {
  final bitmapResult = ScoreIntegrator.score(
    referenceMask: templateResult.mask,
    bounds: templateResult.bounds,
    strokes: strokes,
    strokeWidth: 3.0,
    letter: letter,
  );

  var placement = 0.0;
  final inkBounds = templateResult.inkBounds;
  if (inkBounds != null && strokes.isNotEmpty) {
    placement = PlacementScorer.score(
      expectedTop: inkBounds.top,
      expectedBottom: inkBounds.bottom,
      strokes: strokes,
    );
  }

  return ScoreResult(
    coverage: bitmapResult.coverage,
    precision: bitmapResult.precision,
    placement: placement,
    efficiency: bitmapResult.efficiency,
    strokeStart: bitmapResult.strokeStart,
    strokeDirection: bitmapResult.strokeDirection,
    compoundStroke: bitmapResult.compoundStroke,
    strokeBreak: bitmapResult.strokeBreak,
  );
}
