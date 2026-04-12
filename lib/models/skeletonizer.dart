/// Reduces a filled boolean mask to a 1-pixel-wide skeleton (centre-line)
/// using the Zhang-Suen thinning algorithm.
///
/// The skeleton preserves the topology of the original shape while
/// removing all pixels that are not part of the medial axis.
class Skeletonizer {
  /// Returns a new boolean mask containing only the skeleton pixels.
  ///
  /// Does not modify the input [mask].
  static List<List<bool>> skeletonize(List<List<bool>> mask) {
    if (mask.isEmpty || mask[0].isEmpty) return mask;

    final rows = mask.length;
    final cols = mask[0].length;

    // Deep copy the input — we iterate in-place but never touch the original.
    final grid = List.generate(
      rows,
      (r) => List<bool>.from(mask[r]),
    );

    var changed = true;
    while (changed) {
      changed = false;

      // Sub-iteration 1
      final toRemove1 = <(int, int)>[];
      for (var r = 1; r < rows - 1; r++) {
        for (var c = 1; c < cols - 1; c++) {
          if (!grid[r][c]) continue;
          if (_shouldRemoveStep1(grid, r, c)) {
            toRemove1.add((r, c));
          }
        }
      }
      for (final (r, c) in toRemove1) {
        grid[r][c] = false;
        changed = true;
      }

      // Sub-iteration 2
      final toRemove2 = <(int, int)>[];
      for (var r = 1; r < rows - 1; r++) {
        for (var c = 1; c < cols - 1; c++) {
          if (!grid[r][c]) continue;
          if (_shouldRemoveStep2(grid, r, c)) {
            toRemove2.add((r, c));
          }
        }
      }
      for (final (r, c) in toRemove2) {
        grid[r][c] = false;
        changed = true;
      }
    }

    return grid;
  }

  /// Returns the 8 neighbours of (r, c) in clockwise order starting from top:
  /// P2, P3, P4, P5, P6, P7, P8, P9
  ///
  /// ```
  /// P9 P2 P3
  /// P8 P1 P4
  /// P7 P6 P5
  /// ```
  static List<bool> _neighbors(List<List<bool>> grid, int r, int c) {
    return [
      grid[r - 1][c],     // P2 — top
      grid[r - 1][c + 1], // P3 — top-right
      grid[r][c + 1],     // P4 — right
      grid[r + 1][c + 1], // P5 — bottom-right
      grid[r + 1][c],     // P6 — bottom
      grid[r + 1][c - 1], // P7 — bottom-left
      grid[r][c - 1],     // P8 — left
      grid[r - 1][c - 1], // P9 — top-left
    ];
  }

  /// B(P1): number of non-zero neighbours.
  static int _nonZeroNeighbors(List<bool> n) {
    var count = 0;
    for (final v in n) {
      if (v) count++;
    }
    return count;
  }

  /// A(P1): number of 0→1 transitions in the ordered neighbour sequence,
  /// wrapping from the last element back to the first.
  static int _transitions(List<bool> n) {
    var count = 0;
    for (var i = 0; i < n.length; i++) {
      if (!n[i] && n[(i + 1) % n.length]) count++;
    }
    return count;
  }

  static bool _shouldRemoveStep1(List<List<bool>> grid, int r, int c) {
    final n = _neighbors(grid, r, c);
    final b = _nonZeroNeighbors(n);
    if (b < 2 || b > 6) return false;
    if (_transitions(n) != 1) return false;
    // P2 * P4 * P6 == 0 (at least one of top, right, bottom is background)
    if (n[0] && n[2] && n[4]) return false;
    // P4 * P6 * P8 == 0 (at least one of right, bottom, left is background)
    if (n[2] && n[4] && n[6]) return false;
    return true;
  }

  static bool _shouldRemoveStep2(List<List<bool>> grid, int r, int c) {
    final n = _neighbors(grid, r, c);
    final b = _nonZeroNeighbors(n);
    if (b < 2 || b > 6) return false;
    if (_transitions(n) != 1) return false;
    // P2 * P4 * P8 == 0 (at least one of top, right, left is background)
    if (n[0] && n[2] && n[6]) return false;
    // P2 * P6 * P8 == 0 (at least one of top, bottom, left is background)
    if (n[0] && n[4] && n[6]) return false;
    return true;
  }
}
