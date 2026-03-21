import 'dart:ui';

import '../models/guideline_metrics.dart';
import '../models/letter_template.dart';
import '../utils/constants.dart';

/// How close a drawn point is to the template path.
enum TraceZone { on, near, off }

/// Computes real-time colour feedback for trace mode.
///
/// For each user-drawn point, finds the minimum distance to the nearest
/// template path segment and classifies it:
///   • [TraceZone.on]   — within half the template width  → green
///   • [TraceZone.near] — within the full template width  → orange
///   • [TraceZone.off]  — beyond                          → red
class TraceFeedbackService {
  TraceFeedbackService({
    required LetterTemplate template,
    required Size canvasSize,
    required this.templateWidth,
  }) {
    final metrics = GuidelineMetrics(canvasSize);
    _canvasStrokes = template.strokes
        .map((stroke) =>
            stroke.map((p) => metrics.templateToCanvas(p)).toList())
        .toList();
  }

  /// Tolerance zone width in canvas pixels.
  final double templateWidth;

  /// Template strokes pre-converted to canvas pixel coordinates.
  late final List<List<Offset>> _canvasStrokes;

  /// Classify a single point (in canvas pixel coordinates).
  TraceZone classify(Offset point) {
    final dist = _minDistanceToTemplate(point);
    if (dist <= templateWidth / 2) return TraceZone.on;
    if (dist <= templateWidth) return TraceZone.near;
    return TraceZone.off;
  }

  /// Map a zone to its display colour.
  static Color colorForZone(TraceZone zone) {
    switch (zone) {
      case TraceZone.on:
        return kTraceOnColor;
      case TraceZone.near:
        return kTraceNearColor;
      case TraceZone.off:
        return kTraceOffColor;
    }
  }

  /// Shortest distance from [point] to any segment of any template stroke.
  double _minDistanceToTemplate(Offset point) {
    var minDist = double.infinity;
    for (final stroke in _canvasStrokes) {
      for (var i = 0; i < stroke.length - 1; i++) {
        final d = _pointToSegmentDist(point, stroke[i], stroke[i + 1]);
        if (d < minDist) minDist = d;
      }
      // Also check distance to each control point (in case the stroke is a
      // single point, e.g. a dot for the letter 'j').
      if (stroke.length == 1) {
        final d = (point - stroke[0]).distance;
        if (d < minDist) minDist = d;
      }
    }
    return minDist;
  }

  /// Perpendicular distance from point [p] to line segment [a]→[b].
  static double _pointToSegmentDist(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLenSq < 1e-10) return (p - a).distance; // degenerate segment
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq).clamp(0.0, 1.0);
    final closest = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - closest).distance;
  }
}
