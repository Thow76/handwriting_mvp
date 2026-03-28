import 'package:flutter/material.dart';
import 'models/stroke.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;

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
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: _StrokePainter(_strokes),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<Stroke> strokes;

  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}
