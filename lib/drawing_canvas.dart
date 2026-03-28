import 'package:flutter/material.dart';
import 'models/stroke.dart';
import 'models/guidelines.dart';

const _letters = 'abcdefghijklmnopqrstuvwxyz';
const _fontFamily = 'Comic Sans MS';
const _fontSize = 120.0;

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;
  int _letterIndex = 0;

  String get _currentLetter => _letters[_letterIndex];

  void _onPanStart(DragStartDetails details) {
    final stroke = Stroke();
    stroke.addPoint(details.localPosition);
    setState(() {
      _currentStroke = stroke;
      _strokes.add(stroke);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _currentStroke?.addPoint(details.localPosition);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null) {
      debugPrint(
        'Stroke complete: ${_currentStroke!.points.length} points, '
        'x: ${_currentStroke!.points.map((p) => p.dx.toStringAsFixed(1)).reduce((a, b) => a.compareTo(b) < 0 ? a : b)}'
        '–${_currentStroke!.points.map((p) => p.dx.toStringAsFixed(1)).reduce((a, b) => a.compareTo(b) > 0 ? a : b)}, '
        'y: ${_currentStroke!.points.map((p) => p.dy.toStringAsFixed(1)).reduce((a, b) => a.compareTo(b) < 0 ? a : b)}'
        '–${_currentStroke!.points.map((p) => p.dy.toStringAsFixed(1)).reduce((a, b) => a.compareTo(b) > 0 ? a : b)}',
      );
    }
    _currentStroke = null;
  }

  void _clear() {
    setState(() {
      _strokes.clear();
    });
  }

  void _previousLetter() {
    setState(() {
      _letterIndex = (_letterIndex - 1) % _letters.length;
      _strokes.clear();
    });
  }

  void _nextLetter() {
    setState(() {
      _letterIndex = (_letterIndex + 1) % _letters.length;
      _strokes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handwriting MVP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
            onPressed: _clear,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final guidelines = Guidelines.fromFont(
                  canvasHeight: constraints.maxHeight,
                  fontFamily: _fontFamily,
                  fontSize: _fontSize,
                );
                return GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: _CanvasPainter(
                      strokes: _strokes,
                      guidelines: guidelines,
                      letter: _currentLetter,
                      canvasWidth: constraints.maxWidth,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
          _LetterNav(
            letter: _currentLetter,
            onPrevious: _previousLetter,
            onNext: _nextLetter,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Letter navigation bar
// ---------------------------------------------------------------------------

class _LetterNav extends StatelessWidget {
  final String letter;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _LetterNav({
    required this.letter,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
            ),
            Text(
              letter,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Canvas painter — guidelines, reference letter, then user strokes
// ---------------------------------------------------------------------------

class _CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Guidelines guidelines;
  final String letter;
  final double canvasWidth;

  _CanvasPainter({
    required this.strokes,
    required this.guidelines,
    required this.letter,
    required this.canvasWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintGuidelines(canvas, size);
    _paintReferenceLetter(canvas, size);
    _paintStrokes(canvas);
  }

  void _paintGuidelines(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.0;

    // Ascender line — light dashed feel (solid for now, lightest)
    paint.color = Colors.grey.shade300;
    canvas.drawLine(
      Offset(0, guidelines.ascenderLine),
      Offset(size.width, guidelines.ascenderLine),
      paint,
    );

    // Midline — dashed line marking the top of short lowercase letters
    paint.color = Colors.blue.shade200;
    _drawDashedLine(
      canvas,
      Offset(0, guidelines.midline),
      Offset(size.width, guidelines.midline),
      paint,
    );

    // Baseline — the primary reference line, most visible
    paint.color = Colors.blue.shade400;
    paint.strokeWidth = 2.0;
    canvas.drawLine(
      Offset(0, guidelines.baseline),
      Offset(size.width, guidelines.baseline),
      paint,
    );

    // Descender line
    paint.color = Colors.grey.shade300;
    paint.strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, guidelines.descenderLine),
      Offset(size.width, guidelines.descenderLine),
      paint,
    );
  }

  void _paintReferenceLetter(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize,
      color: Colors.grey.shade300,
      height: 1.0,
    );

    final span = TextSpan(text: letter, style: textStyle);
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();

    // Align the letter so its baseline sits on the guidelines baseline
    // and it is horizontally centered.
    final baselineOffset = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final x = (canvasWidth - painter.width) / 2;
    final y = guidelines.baseline - baselineOffset;

    painter.paint(canvas, Offset(x, y));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 6.0,
    double gapWidth = 4.0,
  }) {
    final totalLength = (end - start).distance;
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

  void _paintStrokes(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.black
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
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
