import 'dart:ui' show Offset, Rect;

/// An immutable target start zone for a single stroke, expressed as a
/// bounds-relative rectangle.
///
/// All four fields are fractions of the letter's tight ink bounding box in the
/// range `[0.0, 1.0]`, where `(0, 0)` is the top-left corner of the bounding
/// box and `(1, 1)` is the bottom-right corner.
///
/// Authoring uses percentages (0–100) converted to fractions before
/// constructing this type.
///
/// ## Edge convention
///
/// [contains] is **inclusive on the minimum edges** (`minX`, `minY`) and
/// **exclusive on the maximum edges** (`maxX`, `maxY`), so that adjacent
/// rectangles that share an edge do not double-count the boundary point.
class StrokeStartRect {
  /// The left edge of the target zone as a fraction of the bounds width.
  ///
  /// Must satisfy `0.0 <= minX < maxX <= 1.0`.
  final double minX;

  /// The right edge of the target zone as a fraction of the bounds width.
  ///
  /// Must satisfy `0.0 <= minX < maxX <= 1.0`.
  final double maxX;

  /// The top edge of the target zone as a fraction of the bounds height.
  ///
  /// Must satisfy `0.0 <= minY < maxY <= 1.0`.
  final double minY;

  /// The bottom edge of the target zone as a fraction of the bounds height.
  ///
  /// Must satisfy `0.0 <= minY < maxY <= 1.0`.
  final double maxY;

  /// Creates a [StrokeStartRect].
  ///
  /// Asserts that all fractions are in `[0.0, 1.0]` and that `minX < maxX`
  /// and `minY < maxY`.
  const StrokeStartRect({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  }) : assert(minX >= 0.0, 'minX must be >= 0.0'),
       assert(maxX <= 1.0, 'maxX must be <= 1.0'),
       assert(minX < maxX, 'minX must be < maxX'),
       assert(minY >= 0.0, 'minY must be >= 0.0'),
       assert(maxY <= 1.0, 'maxY must be <= 1.0'),
       assert(minY < maxY, 'minY must be < maxY');

  /// Returns `true` if [point] falls inside this target zone given the
  /// letter's tight ink [bounds].
  ///
  /// The [point] is first mapped into bounds-relative space (i.e. as a
  /// fraction of [bounds.width] and [bounds.height] respectively), then tested
  /// against [minX], [maxX], [minY], [maxY].
  ///
  /// Edge convention: **inclusive on the minimum edges** (`minX`, `minY`),
  /// **exclusive on the maximum edges** (`maxX`, `maxY`).
  bool contains(Offset point, Rect bounds) {
    if (bounds.width == 0 || bounds.height == 0) return false;
    final rx = (point.dx - bounds.left) / bounds.width;
    final ry = (point.dy - bounds.top) / bounds.height;
    return rx >= minX && rx < maxX && ry >= minY && ry < maxY;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeStartRect &&
          runtimeType == other.runtimeType &&
          minX == other.minX &&
          maxX == other.maxX &&
          minY == other.minY &&
          maxY == other.maxY;

  @override
  int get hashCode => Object.hash(minX, maxX, minY, maxY);
}
