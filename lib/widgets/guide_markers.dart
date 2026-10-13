import 'package:flutter/material.dart';

import '../models/anchor_builder.dart';
import '../models/scoring_level.dart';
import '../theme/app_theme.dart';

/// Whether [level] shows any guide markers on the Guide screen.
bool levelShowsMarkers(ScoringLevel level) => level != ScoringLevel.shapeOnly;

/// Paints the guide markers for [level] over the model letter.
///
/// Level 1: nothing. Level 2: a dot at each stroke start. Level 3: the dots
/// plus an arrowed line through each stroke's anchors. Level 4: numbered dots
/// in stroke order (no line).
void paintGuideMarkers(
  Canvas canvas,
  List<StrokeAnchors> anchors,
  ScoringLevel level,
) {
  if (!levelShowsMarkers(level)) return;

  if (level == ScoringLevel.shapeStartAndPath) {
    for (final stroke in anchors) {
      _paintArrowedLine(canvas, [stroke.start, ...stroke.sectionPoints]);
    }
  }

  for (var i = 0; i < anchors.length; i++) {
    final start = anchors[i].start;
    if (level == ScoringLevel.full) {
      _paintNumberedDot(canvas, start, i + 1);
    } else {
      canvas.drawCircle(start, 6, Paint()..color = AppColors.accent);
    }
  }
}

/// Points sampled along the Catmull-Rom spline through [points].
List<Offset> splineSamples(List<Offset> points, {int perSegment = 12}) {
  if (points.length < 2) return List.of(points);
  // CatmullRomSpline needs four points; pad short lists with midpoints of
  // the first segment, which leaves the curve passing through every anchor.
  final controls = List.of(points);
  while (controls.length < 4) {
    controls.insert(1, Offset.lerp(controls[0], controls[1], 0.5)!);
  }
  final spline = CatmullRomSpline(controls);
  final steps = perSegment * (points.length - 1);
  return [for (var i = 0; i <= steps; i++) spline.transform(i / steps)];
}

void _paintArrowedLine(Canvas canvas, List<Offset> points) {
  final samples = splineSamples(points);
  if (samples.length < 2) return;
  final paint = Paint()
    ..color = AppColors.accent.withValues(alpha: 0.7)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  final path = Path()..moveTo(samples.first.dx, samples.first.dy);
  for (final p in samples.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(path, paint);

  // Arrowhead at the end, pointing along the last bit of the line.
  final tip = samples.last;
  var from = samples[samples.length - 2];
  for (var i = samples.length - 2; i >= 0; i--) {
    from = samples[i];
    if ((tip - from).distance >= 4) break;
  }
  final d = tip - from;
  if (d.distance == 0) return;
  final dir = d / d.distance;
  final side = Offset(-dir.dy, dir.dx);
  final head = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(
      tip.dx - dir.dx * 10 + side.dx * 5,
      tip.dy - dir.dy * 10 + side.dy * 5,
    )
    ..lineTo(
      tip.dx - dir.dx * 10 - side.dx * 5,
      tip.dy - dir.dy * 10 - side.dy * 5,
    )
    ..close();
  canvas.drawPath(head, Paint()..color = AppColors.accent);
}

void _paintNumberedDot(Canvas canvas, Offset centre, int number) {
  canvas.drawCircle(centre, 11, Paint()..color = AppColors.accent);
  final text = TextPainter(
    text: TextSpan(
      text: '$number',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  text.paint(canvas, centre - Offset(text.width / 2, text.height / 2));
}
