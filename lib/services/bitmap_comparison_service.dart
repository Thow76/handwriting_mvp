import 'dart:ui';

/// Bitmap-based shape comparison using IoU (Intersection over Union).
///
/// After Procrustes alignment (both point sets centred at origin, unit-scaled,
/// optimally rotated), this service rasterises both paths onto a small pixel
/// grid at the **same thickness** and measures how much they overlap.
///
/// Same thickness is critical: it ensures a well-drawn complete letter
/// produces high IoU, a fragment produces low IoU (template pixels in the
/// union but not the intersection), and ink outside the template also
/// produces low IoU (user pixels in the union but not the intersection).
///
/// The shared thickness controls difficulty-based leniency:
///   - Beginner: thick strokes = wide tolerance, wobble forgiven
///   - Advanced: thin strokes = tight tolerance, precision required
class BitmapComparisonService {
  const BitmapComparisonService._();

  /// Grid resolution.  64×64 = 4096 cells — fast and sufficient for
  /// letter-level shape comparison.
  static const int _gridSize = 64;

  /// Padding fraction around the points when mapping to the grid.
  /// Ensures strokes near the edge don't clip.
  static const double _padding = 0.10;

  /// Stroke thickness per difficulty (in grid pixels).
  /// Both template and user are rendered at this same thickness.
  /// Wider = more forgiving (shapes overlap even with wobble).
  static const Map<String, double> strokeThickness = {
    'beginner': 8.0,
    'intermediate': 5.0,
    'advanced': 3.0,
  };

  /// Computes bitmap IoU (Intersection over Union) between two
  /// Procrustes-aligned paths rendered at the same stroke thickness.
  ///
  /// [alignedTemplate] and [alignedUser] are the Procrustes-aligned point
  /// sequences (centred at origin, unit-scaled, optimally rotated).
  ///
  /// Returns a [BitmapComparisonResult] with IoU and pixel counts.
  static BitmapComparisonResult compare({
    required List<Offset> alignedTemplate,
    required List<Offset> alignedUser,
    required String difficulty,
  }) {
    final thickness = strokeThickness[difficulty] ?? 5.0;

    // 1. Find bounding box of ALL points (both sets) to define the viewport.
    final allPoints = [...alignedTemplate, ...alignedUser];
    if (allPoints.isEmpty) {
      return const BitmapComparisonResult(
        iou: 0.0,
        intersectionCount: 0,
        unionCount: 0,
        templatePixelCount: 0,
        userPixelCount: 0,
      );
    }

    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in allPoints) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }

    // Add padding so edge strokes aren't clipped.
    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final range = rangeX > rangeY ? rangeX : rangeY;
    final padded = range * (1.0 + 2.0 * _padding);
    final cx = (minX + maxX) / 2.0;
    final cy = (minY + maxY) / 2.0;
    final halfPadded = padded / 2.0;
    final vpMinX = cx - halfPadded;
    final vpMinY = cy - halfPadded;

    // Guard against degenerate (zero-range) inputs.
    if (padded < 1e-10) {
      return const BitmapComparisonResult(
        iou: 0.0,
        intersectionCount: 0,
        unionCount: 0,
        templatePixelCount: 0,
        userPixelCount: 0,
      );
    }

    final scale = _gridSize / padded;

    // 2. Rasterise both paths at the SAME thickness.
    final templateGrid = _createGrid();
    _rasterisePath(
        templateGrid, alignedTemplate, vpMinX, vpMinY, scale, thickness);

    final userGrid = _createGrid();
    _rasterisePath(userGrid, alignedUser, vpMinX, vpMinY, scale, thickness);

    // 3. Count pixels: intersection and union.
    var templatePixelCount = 0;
    var userPixelCount = 0;
    var intersectionCount = 0;
    var unionCount = 0;

    for (var y = 0; y < _gridSize; y++) {
      for (var x = 0; x < _gridSize; x++) {
        final tPx = templateGrid[y][x];
        final uPx = userGrid[y][x];
        if (tPx) templatePixelCount++;
        if (uPx) userPixelCount++;
        if (tPx && uPx) intersectionCount++;
        if (tPx || uPx) unionCount++;
      }
    }

    // IoU = intersection / union.  1.0 = perfect overlap, 0.0 = no overlap.
    final iou = unionCount > 0 ? intersectionCount / unionCount : 0.0;

    return BitmapComparisonResult(
      iou: iou,
      intersectionCount: intersectionCount,
      unionCount: unionCount,
      templatePixelCount: templatePixelCount,
      userPixelCount: userPixelCount,
    );
  }

  // ===========================================================================
  // Rasterisation (stamp-along-line with thickness)
  // ===========================================================================

  static List<List<bool>> _createGrid() =>
      List.generate(_gridSize, (_) => List.filled(_gridSize, false));

  /// Map a point from aligned coordinate space to grid coordinates.
  static (int, int) _toGrid(
      Offset p, double vpMinX, double vpMinY, double scale) {
    final gx = ((p.dx - vpMinX) * scale).round().clamp(0, _gridSize - 1);
    final gy = ((p.dy - vpMinY) * scale).round().clamp(0, _gridSize - 1);
    return (gx, gy);
  }

  /// Draw a filled circle (brush stamp) at (cx, cy) with the given radius.
  static void _stamp(List<List<bool>> grid, int cx, int cy, double radius) {
    final r = radius.ceil();
    final r2 = radius * radius;
    for (var dy = -r; dy <= r; dy++) {
      for (var dx = -r; dx <= r; dx++) {
        if (dx * dx + dy * dy <= r2) {
          final px = cx + dx;
          final py = cy + dy;
          if (px >= 0 && px < _gridSize && py >= 0 && py < _gridSize) {
            grid[py][px] = true;
          }
        }
      }
    }
  }

  /// Rasterise a polyline onto the grid with the given stroke thickness.
  /// Stamps a circle at each point and interpolates between consecutive
  /// points to avoid gaps.
  static void _rasterisePath(
    List<List<bool>> grid,
    List<Offset> points,
    double vpMinX,
    double vpMinY,
    double scale,
    double thickness,
  ) {
    if (points.isEmpty) return;

    final radius = thickness / 2.0;

    for (var i = 0; i < points.length; i++) {
      final (gx, gy) = _toGrid(points[i], vpMinX, vpMinY, scale);
      _stamp(grid, gx, gy, radius);

      if (i > 0) {
        // Interpolate between consecutive points to fill gaps.
        final (prevGx, prevGy) =
            _toGrid(points[i - 1], vpMinX, vpMinY, scale);
        final dx = gx - prevGx;
        final dy = gy - prevGy;
        final steps = dx.abs() > dy.abs() ? dx.abs() : dy.abs();
        if (steps > 1) {
          for (var s = 1; s < steps; s++) {
            final t = s / steps;
            final ix = (prevGx + dx * t).round();
            final iy = (prevGy + dy * t).round();
            _stamp(grid, ix, iy, radius);
          }
        }
      }
    }
  }
}

/// Result of bitmap IoU comparison.
class BitmapComparisonResult {
  const BitmapComparisonResult({
    required this.iou,
    required this.intersectionCount,
    required this.unionCount,
    required this.templatePixelCount,
    required this.userPixelCount,
  });

  /// Intersection over Union (0.0–1.0).
  /// 1.0 = shapes overlap perfectly.
  /// 0.0 = no overlap at all.
  /// Low when: user drew a fragment (template pixels in union, not intersection),
  /// or user drew outside the template (user pixels in union, not intersection).
  final double iou;

  /// Pixels present in BOTH template and user grids.
  final int intersectionCount;

  /// Pixels present in EITHER template or user grid (or both).
  final int unionCount;

  /// Total template ink pixels on the grid.
  final int templatePixelCount;

  /// Total user ink pixels on the grid.
  final int userPixelCount;
}
