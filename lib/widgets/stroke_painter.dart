import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import '../models/stroke_data.dart';
import '../utils/constants.dart';

/// Renders completed strokes and an optional in-progress stroke using
/// perfect_freehand for smooth, pressure-aware outlines.
class StrokePainter extends CustomPainter {
  const StrokePainter({
    required this.completedStrokes,
    this.currentPoints,
    this.currentWidth = 5.0,
    this.currentSimulatePressure = true,
    this.strokeColor = kStrokeColor,
  });

  final List<StrokeData> completedStrokes;

  /// Points being drawn right now (null when no active stroke).
  final List<PointVector>? currentPoints;
  final double currentWidth;
  final bool currentSimulatePressure;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw all completed strokes.
    for (final stroke in completedStrokes) {
      _drawStroke(
        canvas,
        paint,
        stroke.points,
        stroke.width,
        stroke.simulatePressure,
        isComplete: true,
      );
    }

    // Draw the stroke currently being drawn.
    if (currentPoints != null && currentPoints!.isNotEmpty) {
      _drawStroke(
        canvas,
        paint,
        currentPoints!,
        currentWidth,
        currentSimulatePressure,
        isComplete: false,
      );
    }
  }

  void _drawStroke(
    Canvas canvas,
    Paint paint,
    List<PointVector> points,
    double width,
    bool simulatePressure, {
    required bool isComplete,
  }) {
    if (points.isEmpty) return;

    final outlinePoints = getStroke(
      points,
      options: StrokeOptions(
        size: width,
        thinning: 0.6,
        smoothing: 0.5,
        streamline: 0.4,
        simulatePressure: simulatePressure,
        isComplete: isComplete,
      ),
    );

    if (outlinePoints.isEmpty) return;

    final path = Path();
    path.moveTo(outlinePoints[0].dx, outlinePoints[0].dy);
    for (var i = 1; i < outlinePoints.length; i++) {
      path.lineTo(outlinePoints[i].dx, outlinePoints[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(StrokePainter oldDelegate) {
    return oldDelegate.completedStrokes != completedStrokes ||
        oldDelegate.currentPoints != currentPoints ||
        oldDelegate.currentWidth != currentWidth ||
        oldDelegate.strokeColor != strokeColor;
  }
}
