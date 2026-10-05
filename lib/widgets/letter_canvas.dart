import 'package:flutter/material.dart';

import '../models/guidelines.dart';
import '../models/stroke.dart';
import '../theme/app_theme.dart';

/// The drawing surface used by the Practice flow's Guide screen: guidelines,
/// an optional ghost model letter, and the learner's strokes.
///
/// The surface has a fixed size so the screen can score against exactly the
/// geometry that was painted (see [guidelines] and [width]).
class LetterCanvas extends StatelessWidget {
  const LetterCanvas({
    super.key,
    required this.letter,
    required this.strokes,
    required this.showModel,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
  });

  static const double size = 300;
  static const String fontFamily = 'Andika';
  static const double fontSize = 180;

  /// The guideline positions inside the canvas.
  static Guidelines get guidelines => Guidelines.fromFont(
    canvasHeight: size,
    fontFamily: fontFamily,
    fontSize: fontSize,
  );

  /// The canvas width, as the template rasterizer expects it.
  static const double width = size;

  final String letter;
  final List<Stroke> strokes;
  final bool showModel;
  final ValueChanged<Offset> onStrokeStart;
  final ValueChanged<Offset> onStrokeUpdate;
  final VoidCallback onStrokeEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        label: 'Letter $letter',
        child: GestureDetector(
          key: const Key('letterCanvas'),
          onPanStart: (d) => onStrokeStart(d.localPosition),
          onPanUpdate: (d) => onStrokeUpdate(d.localPosition),
          onPanEnd: (_) => onStrokeEnd(),
          child: CustomPaint(
            size: const Size.square(size),
            painter: _LetterCanvasPainter(
              strokes: strokes,
              letter: letter,
              showModel: showModel,
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterCanvasPainter extends CustomPainter {
  _LetterCanvasPainter({
    required this.strokes,
    required this.letter,
    required this.showModel,
  });

  final List<Stroke> strokes;
  final String letter;
  final bool showModel;

  @override
  void paint(Canvas canvas, Size size) {
    final g = LetterCanvas.guidelines;
    // Board: 20/260 side margins on the guide lines.
    final left = size.width * 20 / 260;
    final right = size.width * 240 / 260;

    final dashed = Paint()
      ..color = AppColors.guideline
      ..strokeWidth = 1.5;
    _dashedLine(canvas, Offset(left, g.ascenderLine), right, dashed);
    _dashedLine(canvas, Offset(left, g.midline), right, dashed);
    canvas.drawLine(
      Offset(left, g.baseline),
      Offset(right, g.baseline),
      Paint()
        ..color = AppColors.baseline
        ..strokeWidth = 2,
    );

    if (showModel) {
      final painter = TextPainter(
        text: TextSpan(
          text: letter,
          style: const TextStyle(
            fontFamily: LetterCanvas.fontFamily,
            fontSize: LetterCanvas.fontSize,
            color: AppColors.letterGhost,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final baselineOffset = painter.computeDistanceToActualBaseline(
        TextBaseline.alphabetic,
      );
      painter.paint(
        canvas,
        Offset((size.width - painter.width) / 2, g.baseline - baselineOffset),
      );
    }

    final ink = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, ink);
    }
  }

  void _dashedLine(Canvas canvas, Offset start, double endX, Paint paint) {
    const dash = 3.0;
    const gap = 4.0;
    var x = start.dx;
    while (x < endX) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset((x + dash).clamp(0, endX), start.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _LetterCanvasPainter old) => true;
}
