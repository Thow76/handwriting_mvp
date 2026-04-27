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

/// The vertical region of the letter's bounding box in which a stroke's
/// first point is expected to land.
///
/// Implements the StrokeStartRegion enum specified in the
/// "Revised Data Model › StrokeStartRegion enum" section of
/// stroke_formation_scope.md.
///
/// The bounding box is divided into vertical thirds only (no horizontal
/// subdivision in this release — see the Expansion Path subsection of the
/// scope document).
enum StrokeStartRegion {
  /// Upper third of the letter's bounding box. Expected start for almost
  /// every stroke (stems, ovals, diagonals, dots).
  top,

  /// Middle third of the letter's bounding box. Expected start for the
  /// crossbar on t and f.
  middle,

  /// Lower third of the letter's bounding box. Not used as an expected value
  /// — appears only as an observed error.
  bottom,
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
