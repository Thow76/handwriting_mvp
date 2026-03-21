import 'package:flutter/material.dart';

import '../models/guideline_metrics.dart';
import '../models/letter_template.dart';

/// Renders a [LetterTemplate] as a semi-transparent reference stroke on the
/// canvas.  Uses smooth quadratic Bézier interpolation through the template
/// control points.
class TemplatePainter extends CustomPainter {
  const TemplatePainter({
    required this.template,
    this.strokeWidth = 3.0,
    this.opacity = 0.25,
  });

  final LetterTemplate template;

  /// Visual width of the rendered template stroke (dp).
  final double strokeWidth;

  /// Opacity of the template stroke (0.0 – 1.0).
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = GuidelineMetrics(size);
    final paint = Paint()
      ..color = Color.fromRGBO(0, 0, 0, opacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in template.strokes) {
      if (stroke.length < 2) continue;

      final pts = stroke.map((p) => metrics.templateToCanvas(p)).toList();
      final path = _smoothPath(pts);
      canvas.drawPath(path, paint);
    }
  }

  /// Build a smooth path through [pts] using quadratic Bézier segments
  /// through successive midpoints.
  static Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);

    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
      return path;
    }

    // First segment: straight to midpoint of first two points.
    var mid = _midpoint(pts[0], pts[1]);
    path.lineTo(mid.dx, mid.dy);

    // Middle segments: quadratic Bézier with each original point as control.
    for (var i = 1; i < pts.length - 1; i++) {
      mid = _midpoint(pts[i], pts[i + 1]);
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }

    // Last segment: straight to final point.
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  static Offset _midpoint(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

  @override
  bool shouldRepaint(TemplatePainter old) =>
      old.template != template ||
      old.strokeWidth != strokeWidth ||
      old.opacity != opacity;
}
