import 'dart:ui' show Offset, Rect;

import 'stroke.dart';

/// Converts user-drawn strokes into a boolean pixel mask,
/// mapped into the coordinate space defined by a bounding box.
///
/// The bounding box (from the template glyph) determines which
/// region of canvas space is captured and the dimensions of the
/// output grid. Stroke points outside the bounds are discarded.
class StrokeRasterizer {
  /// Rasterizes [strokes] into a boolean grid.
  ///
  /// - [bounds]: the rectangle (in canvas coordinates) that defines
  ///   the region of interest and the grid dimensions.
  /// - [strokes]: the user's drawn strokes to rasterize.
  /// - [strokeWidth]: the width of each stroke in canvas pixels.
  ///
  /// Returns a `List<List<bool>>` with `bounds.height.ceil()` rows
  /// and `bounds.width.ceil()` columns. A cell is `true` if any
  /// stroke pixel falls on it.
  static List<List<bool>> rasterize({
    required Rect bounds,
    required List<Stroke> strokes,
    double strokeWidth = 3.0,
  }) {
    final gridHeight = bounds.height.ceil();
    final gridWidth = bounds.width.ceil();

    final grid = List.generate(
      gridHeight,
      (_) => List.filled(gridWidth, false),
    );

    final radius = strokeWidth / 2;

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      // Mark the first point.
      _stamp(grid, stroke.points.first, bounds, radius);

      // Walk between consecutive points, marking along the way.
      for (var i = 1; i < stroke.points.length; i++) {
        _walkLine(grid, stroke.points[i - 1], stroke.points[i], bounds, radius);
      }
    }

    return grid;
  }

  /// Marks all grid cells within [radius] of [point] as true.
  static void _stamp(
    List<List<bool>> grid,
    Offset point,
    Rect bounds,
    double radius,
  ) {
    final gridHeight = grid.length;
    final gridWidth = grid.first.length;

    // Map from canvas space to grid space.
    final cx = point.dx - bounds.left;
    final cy = point.dy - bounds.top;

    final rCeil = radius.ceil();
    final startRow = (cy - rCeil).floor().clamp(0, gridHeight - 1);
    final endRow = (cy + rCeil).floor().clamp(0, gridHeight - 1);
    final startCol = (cx - rCeil).floor().clamp(0, gridWidth - 1);
    final endCol = (cx + rCeil).floor().clamp(0, gridWidth - 1);

    final radiusSq = radius * radius;

    for (var row = startRow; row <= endRow; row++) {
      for (var col = startCol; col <= endCol; col++) {
        // Closest point in the cell [col, col+1) × [row, row+1) to (cx, cy).
        final nearestX = cx.clamp(col.toDouble(), col + 1.0);
        final nearestY = cy.clamp(row.toDouble(), row + 1.0);
        final dx = nearestX - cx;
        final dy = nearestY - cy;
        if (dx * dx + dy * dy < radiusSq) {
          grid[row][col] = true;
        }
      }
    }
  }

  /// Walks from [from] to [to] in small steps, stamping along the way.
  static void _walkLine(
    List<List<bool>> grid,
    Offset from,
    Offset to,
    Rect bounds,
    double radius,
  ) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = (dx * dx + dy * dy);
    if (distance == 0) return;

    final dist = distance > 0 ? (dx * dx + dy * dy) : 0.0;
    final length = dist > 0 ? _sqrt(dist) : 0.0;

    // Step in increments of ~0.5 pixels for smooth coverage.
    final steps = (length * 2).ceil();
    if (steps == 0) return;

    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final point = Offset(
        from.dx + dx * t,
        from.dy + dy * t,
      );
      _stamp(grid, point, bounds, radius);
    }
  }

  /// Simple square-root using Newton's method (avoids dart:math import).
  static double _sqrt(double value) {
    if (value <= 0) return 0;
    var guess = value / 2;
    for (var i = 0; i < 20; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }
}
