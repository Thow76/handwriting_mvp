import 'dart:ui';

import '../app_state.dart';
import '../models/guideline_metrics.dart';
import '../models/letter_template.dart';
import '../models/scoring_result.dart';
import '../models/stroke_data.dart';

/// Scores a user's drawing against a letter template.
///
/// All geometric comparison happens in **template coordinate space**
/// (x ∈ [0,1], y ∈ [0,1]).  Canvas-pixel user strokes are converted via
/// [GuidelineMetrics.canvasToTemplate] before any analysis.
///
/// REBUILD IN PROGRESS — Step 1: Procrustes only for shape scoring.
class ScoringService {
  const ScoringService._();

  /// Entry point — returns a fully-populated [ScoringResult].
  static ScoringResult score({
    required List<StrokeData> userStrokes,
    required LetterTemplate template,
    required Size canvasSize,
    required GuidelineMode guidelineMode,
    required Difficulty difficulty,
  }) {
    // Guard: if user drew nothing, return minimum scores.
    if (userStrokes.isEmpty ||
        userStrokes.every((s) => s.points.isEmpty)) {
      return _emptyResult(guidelineMode);
    }

    // TODO: Step 1 — Procrustes shape scoring
    // TODO: Step 2 — Bitmap IoU completeness
    // TODO: Placement scoring
    // TODO: Proportion / Size scoring

    // Stub: return all 1s until scoring is rebuilt.
    final thirdLabel =
        guidelineMode == GuidelineMode.full ? 'Proportion' : 'Size';
    return ScoringResult(
      shapeScore: 1,
      placementScore: 1,
      thirdScore: 1,
      thirdScoreLabel: thirdLabel,
      combinedScore: 1,
      feedbackMessage: ScoringResult.messageForScore(1),
    );
  }

  static ScoringResult _emptyResult(GuidelineMode guidelineMode) {
    final label =
        guidelineMode == GuidelineMode.full ? 'Proportion' : 'Size';
    return ScoringResult(
      shapeScore: 1,
      placementScore: 1,
      thirdScore: 1,
      thirdScoreLabel: label,
      combinedScore: 1,
      feedbackMessage: ScoringResult.messageForScore(1),
    );
  }
}
