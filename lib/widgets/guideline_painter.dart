import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/guideline_metrics.dart';
import '../utils/constants.dart';

/// Draws ruled writing guidelines on the canvas.
///
/// In [GuidelineMode.full] — four lines:
///   • Ascender (dashed, pale)
///   • X-height (solid, lighter blue)
///   • Baseline (solid, blue — always prominent)
///   • Descender (dashed, pale)
///
/// In [GuidelineMode.baselineOnly] — only the baseline.
class GuidelinePainter extends CustomPainter {
  const GuidelinePainter({required this.guidelineMode});

  final GuidelineMode guidelineMode;

  @override
  void paint(Canvas canvas, Size size) {
    final m = GuidelineMetrics(size);

    // ---- Baseline — always shown ----
    final baselinePaint = Paint()
      ..color = kBaselineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, m.baselineY),
      Offset(size.width, m.baselineY),
      baselinePaint,
    );

    if (guidelineMode != GuidelineMode.full) return;

    // ---- X-height — solid, lighter ----
    final xHeightPaint = Paint()
      ..color = kXHeightColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, m.xHeightY),
      Offset(size.width, m.xHeightY),
      xHeightPaint,
    );

    // ---- Ascender — dashed ----
    _drawDashedLine(
      canvas,
      Offset(0, m.ascenderY),
      Offset(size.width, m.ascenderY),
      Paint()
        ..color = kGuidelineColor
        ..strokeWidth = 1.0,
    );

    // ---- Descender — dashed ----
    _drawDashedLine(
      canvas,
      Offset(0, m.descenderY),
      Offset(size.width, m.descenderY),
      Paint()
        ..color = kGuidelineColor
        ..strokeWidth = 1.0,
    );
  }

  static void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashWidth = 6.0;
    const gapWidth = 4.0;
    final totalLength = (end - start).distance;
    if (totalLength == 0) return;
    final direction = (end - start) / totalLength;
    var drawn = 0.0;
    while (drawn < totalLength) {
      final dashEnd = (drawn + dashWidth).clamp(0.0, totalLength);
      canvas.drawLine(
        start + direction * drawn,
        start + direction * dashEnd,
        paint,
      );
      drawn += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(GuidelinePainter old) =>
      old.guidelineMode != guidelineMode;
}
