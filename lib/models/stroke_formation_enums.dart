/// The primary direction of a single expected stroke.
///
/// Implements the StrokeDirection enum specified in the
/// "Revised Data Model › StrokeDirection enum" section of
/// stroke_formation_scope.md.
enum StrokeDirection {
  /// Vertical strokes and diagonals — always drawn top-to-bottom.
  topToBottom,

  /// Horizontal strokes (e.g. crossbars on t and f) — always drawn
  /// left-to-right.
  leftToRight,

  /// Right-opening bowls on stems (b, p) — drawn clockwise.
  clockwise,

  /// Closed and left-opening ovals (o, c, a, d, g, q, e) — drawn
  /// anticlockwise.
  anticlockwise,

  /// Strokes whose direction cannot be captured by a single axis
  /// (n, m, u, and the second stroke of h and k). Scored via waypoint
  /// sequence rather than direction.
  compound,

  /// Dots on i and j — scored on presence, not direction.
  dot,
}

/// A cell in the 3×3 grid overlaid on the letter's bounding box, used to
/// specify waypoints for compound strokes.
///
/// Implements the WaypointRegion enum specified in the
/// "Revised Data Model › WaypointRegion enum" section of
/// stroke_formation_scope.md.
enum WaypointRegion {
  /// Top-left cell of the 3×3 grid.
  topLeft,

  /// Top-centre cell of the 3×3 grid.
  top,

  /// Top-right cell of the 3×3 grid.
  topRight,

  /// Middle-left cell of the 3×3 grid.
  left,

  /// Centre cell of the 3×3 grid.
  middle,

  /// Middle-right cell of the 3×3 grid.
  right,

  /// Bottom-left cell of the 3×3 grid.
  bottomLeft,

  /// Bottom-centre cell of the 3×3 grid.
  bottom,

  /// Bottom-right cell of the 3×3 grid.
  bottomRight,
}
