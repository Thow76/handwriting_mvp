import 'dart:ui';

/// Resample a polyline to exactly [n] equidistant points.
///
/// The first and last points of the result coincide with the first and last
/// points of [points].  Intermediate points are linearly interpolated along
/// the original path at uniform arc-length intervals.
///
/// Edge cases:
///   • Empty input → [n] copies of [Offset.zero].
///   • Single point → [n] copies of that point.
///   • Zero-length path (all points coincident) → [n] copies of the first point.
List<Offset> resampleEquidistant(List<Offset> points, int n) {
  assert(n >= 2, 'Resampling requires at least 2 output points');

  if (points.isEmpty) return List.filled(n, Offset.zero);
  if (points.length == 1) return List.filled(n, points[0]);

  // Cumulative arc-length at each input point.
  final cumLen = <double>[0.0];
  for (var i = 1; i < points.length; i++) {
    cumLen.add(cumLen.last + (points[i] - points[i - 1]).distance);
  }
  final totalLen = cumLen.last;
  if (totalLen < 1e-10) return List.filled(n, points[0]);

  final spacing = totalLen / (n - 1);
  final result = <Offset>[points.first];

  var j = 1; // index into input points
  for (var i = 1; i < n - 1; i++) {
    final target = i * spacing;
    // Advance j until cumLen[j] >= target.
    while (j < points.length - 1 && cumLen[j] < target) {
      j++;
    }
    final segLen = cumLen[j] - cumLen[j - 1];
    final t = segLen > 0 ? (target - cumLen[j - 1]) / segLen : 0.0;
    result.add(Offset.lerp(points[j - 1], points[j], t)!);
  }

  result.add(points.last);
  return result;
}
