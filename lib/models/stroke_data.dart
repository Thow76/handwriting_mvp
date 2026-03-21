import 'package:perfect_freehand/perfect_freehand.dart';

/// A completed stroke — immutable once the user lifts their finger/stylus.
class StrokeData {
  const StrokeData({
    required this.points,
    required this.width,
    required this.simulatePressure,
  });

  /// Raw input points captured from the Listener widget.
  final List<PointVector> points;

  /// Stroke width passed to perfect_freehand (varies by input mode + preset).
  final double width;

  /// True for finger input (no real pressure), false for stylus.
  final bool simulatePressure;
}
