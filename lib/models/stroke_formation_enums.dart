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
