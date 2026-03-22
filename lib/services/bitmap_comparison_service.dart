import 'dart:ui';

/// Bitmap-based coverage comparison for shape scoring.
///
/// After Procrustes alignment (both point sets centred at origin, unit-scaled,
/// optimally rotated), this service rasterises both paths onto a small pixel
/// grid and measures how much of the user's ink overlaps the template's ink.
///
/// This replaces the flawed arc-length coverage ratio, which couldn't
/// distinguish "drew half the letter" from "drew the whole letter but smaller."
///
/// The template is rendered with a configurable stroke thickness that controls
/// difficulty-based leniency (thicker = more forgiving).
class BitmapComparisonService {
  const BitmapComparisonService._();

  /// Grid resolution.  64×64 = 4096 cells — fast and sufficient for
  /// letter-level coverage detection.
  static const int _gridSize = 64;

  /// Padding fraction around the points when mapping to the grid.
  /// Ensures strokes near the edge don't clip.
  static const double _padding = 0.10;

  /// Template stroke thickness per difficulty (in grid pixels).
  /// Wider = more forgiving (user ink can be further from template centre
  /// and still count as overlapping).
  static const Map<String, double> templateThickness = {
    'beginner': 8.0,
    'intermediate': 5.0,
    'advanced': 3.0,
  };

  /// User stroke thickness (always thin — represents actual ink).
  static const double _userThickness = 1.5;

  /// Computes bitmap coverage: what fraction of the user's ink overlaps
  /// the template's ink zone.
  ///
  /// [alignedTemplate] and [alignedUser] are the Procrustes-aligned point
  /// sequences (centred at origin, unit-scaled, optimally rotated).
  ///
  /// Returns a [BitmapCoverageResult] with:
  ///   - `coverage`: fraction of user pixels that overlap template pixels (0–1)
  ///   - `templateFill`: fraction of template pixels covered by user (0–1)
  ///   - `userPixelCount`: total user ink pixels
  ///   - `overlapCount`: pixels present in both
  static BitmapCoverageResult compare({
    required List<Offset> alignedTemplate,
    required List<Offset> alignedUser,
    required String difficulty,
  }) {
    final tThick = templateThickness[difficulty] ?? 5.0;

    // 1. Find bounding box of ALL points (both sets) to define the viewport.
    final allPoints = [...alignedTemplate, ...alignedUser];
    if (allPoints.isEmpty) {
      return const BitmapCoverageResult(
        coverage: 0.0,
        templateFill: 0.0,
        userPixelCount: 0,
        overlapCount: 0,
        templatePixelCount: 0,
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
    // Use the larger dimension to maintain aspect ratio on the grid.
    final cx = (minX + maxX) / 2.0;
    final cy = (minY + maxY) / 2.0;
    final halfPadded = padded / 2.0;
    final vpMinX = cx - halfPadded;
    final vpMinY = cy - halfPadded;

    // Guard against degenerate (zero-range) inputs.
    if (padded < 1e-10) {
      return const BitmapCoverageResult(
        coverage: 0.0,
        templateFill: 0.0,
        userPixelCount: 0,
        overlapCount: 0,
        templatePixelCount: 0,
      );
    }

    final scale = _gridSize / padded;

    // 2. Rasterise template path (thick stroke).
    final templateGrid = _createGrid();
    _rasterisePath(templateGrid, alignedTemplate, vpMinX, vpMinY, scale, tThick);

    // 3. Rasterise user path (thin stroke).
    final userGrid = _createGrid();
    _rasterisePath(userGrid, alignedUser, vpMinX, vpMinY, scale, _userThickness);

    // 4. Count pixels.
    var templatePixelCount = 0;
    var userPixelCount = 0;
    var overlapCount = 0;

    for (var y = 0; y < _gridSize; y++) {
      for (var x = 0; x < _gridSize; x++) {
        final tPx = templateGrid[y][x];
        final uPx = userGrid[y][x];
        if (tPx) templatePixelCount++;
        if (uPx) userPixelCount++;
        if (tPx && uPx) overlapCount++;
      }
    }

    // coverage = what fraction of user ink lands on template ink
    final coverage =
        userPixelCount > 0 ? overlapCount / userPixelCount : 0.0;

    // templateFill = what fraction of template ink is covered by user ink
    // This is the completeness measure — low means the user missed parts.
    final templateFill =
        templatePixelCount > 0 ? overlapCount / templatePixelCount : 0.0;

    return BitmapCoverageResult(
      coverage: coverage,
      templateFill: templateFill,
      userPixelCount: userPixelCount,
      overlapCount: overlapCount,
      templatePixelCount: templatePixelCount,
    );
  }

  // ===========================================================================
  // Rasterisation (Bresenham with thickness)
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
  /// Uses stamp-along-line approach: stamp a circle at each point and at
  /// interpolated positions along each segment to avoid gaps.
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
        final (prevGx, prevGy) = _toGrid(points[i - 1], vpMinX, vpMinY, scale);
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

/// Result of bitmap coverage comparison.
class BitmapCoverageResult {
  const BitmapCoverageResult({
    required this.coverage,
    required this.templateFill,
    required this.userPixelCount,
    required this.overlapCount,
    required this.templatePixelCount,
  });

  /// Fraction of user ink pixels that overlap template ink (0.0–1.0).
  /// High = user drew within the template shape.
  /// Low = user drew outside the template (wrong shape or position post-alignment).
  final double coverage;

  /// Fraction of template ink pixels covered by user ink (0.0–1.0).
  /// High = user drew the whole letter.
  /// Low = user only drew a fragment (e.g., just the tail of 'q').
  final double templateFill;

  /// Total number of user ink pixels on the grid.
  final int userPixelCount;

  /// Pixels present in both template and user grids.
  final int overlapCount;

  /// Total number of template ink pixels on the grid.
  final int templatePixelCount;
}
