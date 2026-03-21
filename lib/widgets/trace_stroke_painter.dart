import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import '../models/stroke_data.dart';
import '../services/trace_feedback_service.dart';

/// Renders user strokes with colour-coded trace feedback.
///
/// Each drawn point is classified by [TraceFeedbackService] as green (on),
/// orange (near), or red (off).  Contiguous same-colour point runs are
/// rendered as separate stroke segments via perfect_freehand.
class TraceStrokePainter extends CustomPainter {
  const TraceStrokePainter({
    required this.completedStrokes,
    required this.feedbackService,
    this.currentPoints,
    this.currentWidth = 5.0,
    this.currentSimulatePressure = true,
  });

  final List<StrokeData> completedStrokes;
  final TraceFeedbackService feedbackService;
  final List<PointVector>? currentPoints;
  final double currentWidth;
  final bool currentSimulatePressure;

  @override
  void paint(Canvas canvas, Size size) {
    // Completed strokes.
    for (final stroke in completedStrokes) {
      _drawColored(
        canvas,
        stroke.points,
        stroke.width,
        stroke.simulatePressure,
        isComplete: true,
      );
    }
    // In-progress stroke.
    if (currentPoints != null && currentPoints!.isNotEmpty) {
      _drawColored(
        canvas,
        currentPoints!,
        currentWidth,
        currentSimulatePressure,
        isComplete: false,
      );
    }
  }

  /// Classify every point, split into same-colour runs, render each run.
  void _drawColored(
    Canvas canvas,
    List<PointVector> points,
    double width,
    bool simulatePressure, {
    required bool isComplete,
  }) {
    if (points.isEmpty) return;

    // Classify all points.
    final zones = points
        .map((p) => feedbackService.classify(Offset(p.x, p.y)))
        .toList();

    // Split into contiguous same-zone runs and render.
    var segStart = 0;
    for (var i = 1; i <= zones.length; i++) {
      if (i == zones.length || zones[i] != zones[segStart]) {
        // Segment [segStart, i).
        // Overlap by 1 point at each boundary for continuity.
        final start = segStart > 0 ? segStart - 1 : segStart;
        final end = (i < points.length ? i + 1 : i).clamp(0, points.length);
        final segPoints = points.sublist(start, end);

        final color = TraceFeedbackService.colorForZone(zones[segStart]);
        final segIsComplete = isComplete && i == zones.length;

        _renderSegment(canvas, segPoints, width, simulatePressure, color,
            isComplete: segIsComplete);

        segStart = i;
      }
    }
  }

  void _renderSegment(
    Canvas canvas,
    List<PointVector> points,
    double width,
    bool simulatePressure,
    Color color, {
    required bool isComplete,
  }) {
    if (points.isEmpty) return;

    final outline = getStroke(
      points,
      options: StrokeOptions(
        size: width,
        thinning: 0.0, // Uniform width — avoids taper artefacts at boundaries
        smoothing: 0.5,
        streamline: 0.4,
        simulatePressure: simulatePressure,
        isComplete: isComplete,
      ),
    );

    if (outline.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()..moveTo(outline[0].dx, outline[0].dy);
    for (var i = 1; i < outline.length; i++) {
      path.lineTo(outline[i].dx, outline[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TraceStrokePainter old) {
    return old.completedStrokes != completedStrokes ||
        old.currentPoints != currentPoints ||
        old.currentWidth != currentWidth ||
        old.feedbackService != feedbackService;
  }
}
