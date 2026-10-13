/// Calculates what percentage of a reference letter's pixels
/// are covered by the user's drawn strokes.
///
/// Both masks must be the same dimensions.
/// Each inner list represents a row of pixels (true = ink present).
class CoverageScorer {
  /// Returns a value between 0.0 and 1.0 representing the fraction
  /// of reference pixels that are covered by stroke pixels.
  ///
  /// Returns 0.0 if the reference mask contains no active pixels.
  static double calculate({
    required List<List<bool>> referenceMask,
    required List<List<bool>> strokeMask,
  }) {
    if (referenceMask.length != strokeMask.length) {
      throw ArgumentError('Row count mismatch: '
          'reference has ${referenceMask.length}, '
          'strokes has ${strokeMask.length}');
    }

    var referencePixels = 0;
    var coveredPixels = 0;

    for (var row = 0; row < referenceMask.length; row++) {
      if (referenceMask[row].length != strokeMask[row].length) {
        throw ArgumentError('Column count mismatch at row $row: '
            'reference has ${referenceMask[row].length}, '
            'strokes has ${strokeMask[row].length}');
      }

      for (var col = 0; col < referenceMask[row].length; col++) {
        if (referenceMask[row][col]) {
          referencePixels++;
          if (strokeMask[row][col]) {
            coveredPixels++;
          }
        }
      }
    }

    if (referencePixels == 0) return 0.0;

    return coveredPixels / referencePixels;
  }
}
