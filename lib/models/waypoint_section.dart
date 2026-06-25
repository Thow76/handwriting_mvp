import 'dart:ui' show Offset, Rect;

import 'stroke_start_rect.dart';

/// A single numbered section of a letter's expected waypoint path.
///
/// Replaces the shared 3×3 [WaypointRegion] grid with a bespoke, per-letter
/// rectangle. Each section carries a 1-based [number] giving its position in the
/// strictly-sequential order the learner must hit, and a [rect] giving its
/// bounding box as fractions of the letter's tight ink bounds.
///
/// Geometry is delegated to [StrokeStartRect]: [rect] uses the same fractional
/// coordinate convention and edge rules (inclusive on min edges, exclusive on
/// max edges).
class WaypointSection {
  /// The 1-based position of this section in the sequential waypoint order.
  ///
  /// Must be ≥ 1.
  final int number;

  /// The bounding rectangle of this section, as bounds-relative fractions.
  final StrokeStartRect rect;

  /// Creates a [WaypointSection].
  ///
  /// Asserts that [number] is at least 1.
  WaypointSection({required this.number, required this.rect})
    : assert(number >= 1, 'number must be at least 1');

  /// Returns `true` if [point] falls inside this section given the letter's
  /// tight ink [bounds]. Delegates to [StrokeStartRect.contains].
  bool contains(Offset point, Rect bounds) => rect.contains(point, bounds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaypointSection &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          rect == other.rect;

  @override
  int get hashCode => Object.hash(number, rect);
}
