import 'dart:ui' show Offset;

class Stroke {
  final List<Offset> points;

  Stroke([List<Offset>? points]) : points = points ?? [];

  void addPoint(Offset point) {
    points.add(point);
  }
}
