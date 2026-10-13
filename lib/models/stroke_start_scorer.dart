import 'dart:developer' show log; // TEMP: remove after f diagnosis
import 'dart:ui' show Offset, Rect;

import 'formation_score.dart';
import 'letter_formation_data.dart';
import 'stroke.dart';
import 'stroke_matcher.dart';
import 'stroke_start_rect.dart';

/// Scores how closely the observed strokes' first points match the expected
/// start rectangles defined by [LetterFormationData].
///
/// Each observed stroke's first point is tested against the matched
/// [ExpectedStroke.startRect] using [StrokeStartRect.contains]. The scoring
/// is a hard cliff: inside the rectangle → 1.0, outside → 0.0. No partial
/// credit or adjacency taper is applied.
///
/// Edge convention: [StrokeStartRect.contains] is inclusive on the minimum
/// edges (`minX`, `minY`) and exclusive on the maximum edges (`maxX`, `maxY`),
/// matching the convention documented in [StrokeStartRect].
///
/// The [FormationScore.overallScore] is the mean across all matched,
/// non-empty observed strokes.
class StrokeStartScorer {
  /// The letter being scored. Used in error messages.
  final String letter;

  /// The expected formation data for the letter.
  final LetterFormationData data;

  /// The tight bounding box of the letter template.
  ///
  /// Used for spatial stroke matching and to convert absolute coordinates
  /// into bounds-relative fractions for [StrokeStartRect.contains].
  final Rect bounds;

  /// Creates a [StrokeStartScorer].
  StrokeStartScorer({
    required this.letter,
    required this.data,
    required this.bounds,
  });

  /// Scores [observed] strokes against the expected start rectangles.
  ///
  /// Returns a [FormationScore] containing:
  /// - [FormationScore.overallScore]: mean of per-stroke scores.
  /// - [FormationScore.observations]: one [StrokeObservation] per matched,
  ///   non-empty observed stroke.
  /// - [FormationScore.summary]: a learner-facing summary sentence.
  FormationScore score(List<Stroke> observed) {
    final matchIndices = matchStrokes(observed, data.strokes, bounds);
    final observations = <StrokeObservation>[];

    for (var i = 0; i < observed.length; i++) {
      final expectedIndex = matchIndices[i];
      if (expectedIndex == -1) continue;

      final stroke = observed[i];
      if (stroke.points.isEmpty) continue;

      final firstPoint = stroke.points.first;
      final startRect = data.strokes[expectedIndex].startRect;
      final strokeScore = startRect.contains(firstPoint, bounds) ? 1.0 : 0.0;
    observations.add(StrokeObservation(
        strokeIndex: i,
        expected: _rectLabel(startRect),
        observed: _pointLabel(firstPoint, bounds),
        score: strokeScore,
        note: _buildNote(startRect, firstPoint, bounds),
      ));
    }

    final overallScore = observations.isEmpty
        ? 0.0
        : observations.map((o) => o.score).reduce((a, b) => a + b) /
            observations.length;

    return FormationScore(
      overallScore: overallScore,
      observations: observations,
      summary: _buildSummary(observations),
    );
  }

  /// Formats a [StrokeStartRect] as a compact percentage range string.
  ///
  /// Example: `StrokeStartRect(minX: 0.5, maxX: 1.0, minY: 0.0, maxY: 0.25)`
  /// → `"x 50–100%, y 0–25%"`.
  static String _rectLabel(StrokeStartRect rect) {
    final x0 = (rect.minX * 100).round();
    final x1 = (rect.maxX * 100).round();
    final y0 = (rect.minY * 100).round();
    final y1 = (rect.maxY * 100).round();
    return 'x $x0–$x1%, y $y0–$y1%';
  }

  /// Formats a first-point as bounds-relative percentage coordinates.
  ///
  /// Example: `Offset(186, 114)` in a 300×300 bounds → `"(62%, 38%)"`.
  static String _pointLabel(Offset point, Rect bounds) {
    final rx = ((point.dx - bounds.left) / bounds.width * 100).round();
    final ry = ((point.dy - bounds.top) / bounds.height * 100).round();
    return '($rx%, $ry%)';
  }

  /// Returns a learner-readable note for one stroke.
  ///
  /// On success: `"Started in the right place."`
  /// On failure: a directional hint such as
  /// `"Started bottom-right; should start in the top-left area."`.
  static String _buildNote(
      StrokeStartRect rect, Offset firstPoint, Rect bounds) {
    if (rect.contains(firstPoint, bounds)) {
      return 'Started in the right place.';
    }

    final rx = (firstPoint.dx - bounds.left) / bounds.width;
    final ry = (firstPoint.dy - bounds.top) / bounds.height;

    // Direction of where the user started, relative to the expected rect centre.
    final cx = (rect.minX + rect.maxX) / 2.0;
    final cy = (rect.minY + rect.maxY) / 2.0;
    final startedDir = _directionLabel(rx - cx, ry - cy);

    // Direction of the expected rect centre within the template.
    final expectedDir = _directionLabel(cx - 0.5, cy - 0.5);

    final startedPart =
        startedDir.isEmpty ? 'Started near the centre' : 'Started $startedDir';
    final expectedPart =
        expectedDir.isEmpty ? 'the centre' : 'the $expectedDir area';

    return '$startedPart; should start in $expectedPart.';
  }

  /// Returns a directional label such as `"top-left"`, `"bottom"`, or `""`.
  ///
  /// An empty string means the offset is near zero in both axes.
  static String _directionLabel(double dx, double dy) {
    const threshold = 0.05;
    final v = dy < -threshold ? 'top' : (dy > threshold ? 'bottom' : '');
    final h = dx < -threshold ? 'left' : (dx > threshold ? 'right' : '');
    if (v.isEmpty && h.isEmpty) return '';
    if (v.isEmpty) return h;
    if (h.isEmpty) return v;
    return '$v-$h';
  }

  /// Builds a learner-facing summary from all [observations].
  String _buildSummary(List<StrokeObservation> observations) {
    if (observations.isEmpty) {
      return 'No strokes were examined.';
    }
    if (observations.every((o) => o.score == 1.0)) {
      return 'All strokes started in the right place.';
    }
    final wrong = observations.firstWhere((o) => o.score < 1.0);
    return 'A stroke started in the wrong place — should start in ${wrong.expected}.';
  }
}
