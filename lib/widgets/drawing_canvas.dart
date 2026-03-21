import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import '../models/stroke_data.dart';
import 'stroke_painter.dart';

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Manages stroke state for [DrawingCanvas].
///
/// Expose this to parent widgets that need to:
///   • call [undo] / [clear]
///   • read [strokes] for scoring
class DrawingCanvasController extends ChangeNotifier {
  final List<StrokeData> _strokes = [];

  // Mutable list — appended to on every pointer move for performance.
  final List<PointVector> _currentPoints = [];
  double _currentWidth = 5.0;
  bool _currentSimulatePressure = true;

  List<StrokeData> get strokes => List.unmodifiable(_strokes);
  List<PointVector> get currentPoints => List.unmodifiable(_currentPoints);
  double get currentWidth => _currentWidth;
  bool get currentSimulatePressure => _currentSimulatePressure;
  bool get hasStrokes => _strokes.isNotEmpty;

  void _startStroke(Offset position, double pressure, double width, bool simulatePressure) {
    _currentPoints.clear();
    _currentWidth = width;
    _currentSimulatePressure = simulatePressure;
    _currentPoints.add(PointVector(position.dx, position.dy, pressure));
    notifyListeners();
  }

  void _addPoint(Offset position, double pressure) {
    if (_currentPoints.isEmpty) return;
    _currentPoints.add(PointVector(position.dx, position.dy, pressure));
    notifyListeners();
  }

  void _endStroke() {
    if (_currentPoints.isEmpty) return;
    _strokes.add(StrokeData(
      points: List.of(_currentPoints),
      width: _currentWidth,
      simulatePressure: _currentSimulatePressure,
    ));
    _currentPoints.clear();
    notifyListeners();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    _currentPoints.clear();
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A drawing surface that captures pointer input and renders strokes via
/// [StrokePainter] + perfect_freehand.
///
/// Supply a [DrawingCanvasController] to control undo/clear from outside,
/// and read back completed [StrokeData] for scoring.
/// Signature for a custom painter that replaces the default [StrokePainter].
typedef StrokePainterBuilder = CustomPainter Function({
  required List<StrokeData> completedStrokes,
  required List<PointVector>? currentPoints,
  required double currentWidth,
  required bool currentSimulatePressure,
});

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.controller,
    required this.strokeWidth,
    required this.simulatePressure,
    this.strokeColor = const Color(0xFF1A1A2E),
    this.backgroundColor = Colors.white,
    this.painterBuilder,
  });

  final DrawingCanvasController controller;

  /// Active stroke width (driven by input mode + width preset in AppState).
  final double strokeWidth;

  /// True = finger mode (no real pressure data), false = stylus mode.
  final bool simulatePressure;

  final Color strokeColor;
  final Color backgroundColor;

  /// If provided, replaces the default [StrokePainter].
  /// Used by trace mode to render colour-coded feedback strokes.
  final StrokePainterBuilder? painterBuilder;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  // Normalise stylus pressure: report 0.5 when hardware gives 0 (not touching).
  double _normalisePressure(double raw, bool isStylus) {
    if (!isStylus) return 0.5; // ignored when simulatePressure = true
    // Some devices report 0.0 on first contact — clamp to a sensible minimum.
    return raw.clamp(0.05, 1.0);
  }

  void _onPointerDown(PointerDownEvent event) {
    final pressure = _normalisePressure(event.pressure, !widget.simulatePressure);
    widget.controller._startStroke(
      event.localPosition,
      pressure,
      widget.strokeWidth,
      widget.simulatePressure,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    final pressure = _normalisePressure(event.pressure, !widget.simulatePressure);
    widget.controller._addPoint(event.localPosition, pressure);
  }

  void _onPointerUp(PointerUpEvent event) {
    widget.controller._endStroke();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    widget.controller._endStroke();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      // HitTestBehavior.opaque ensures we receive all pointer events even over
      // transparent areas of the canvas.
      behavior: HitTestBehavior.opaque,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (_, child) {
            final strokes = widget.controller.strokes;
            final current = widget.controller.currentPoints.isEmpty
                ? null
                : widget.controller.currentPoints;
            final width = widget.controller.currentWidth;
            final simPressure = widget.controller.currentSimulatePressure;

            final painter = widget.painterBuilder != null
                ? widget.painterBuilder!(
                    completedStrokes: strokes,
                    currentPoints: current,
                    currentWidth: width,
                    currentSimulatePressure: simPressure,
                  )
                : StrokePainter(
                    completedStrokes: strokes,
                    currentPoints: current,
                    currentWidth: width,
                    currentSimulatePressure: simPressure,
                    strokeColor: widget.strokeColor,
                  );

            return CustomPaint(
              foregroundPainter: painter,
              child: SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}
