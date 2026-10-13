/// Calculates what percentage of the user's drawn stroke pixels
/// fall inside the reference letter's shape.
///
/// Both masks must be the same dimensions.
/// Each inner list represents a row of pixels (true = ink present).
class PrecisionScorer {
  /// Returns a value between 0.0 and 1.0 representing the fraction
  /// of stroke pixels that overlap with reference pixels.
  ///
  /// Returns 0.0 if the stroke mask contains no active pixels.
  static double calculate({
    required List<List<bool>> referenceMask,
    required List<List<bool>> strokeMask,
  }) {
    if (referenceMask.length != strokeMask.length) {
      throw ArgumentError('Row count mismatch: '
          'reference has ${referenceMask.length}, '
          'strokes has ${strokeMask.length}');
    }

    var strokePixels = 0;
    var insidePixels = 0;

    for (var row = 0; row < referenceMask.length; row++) {
      if (referenceMask[row].length != strokeMask[row].length) {
        throw ArgumentError('Column count mismatch at row $row: '
            'reference has ${referenceMask[row].length}, '
            'strokes has ${strokeMask[row].length}');
      }

      for (var col = 0; col < referenceMask[row].length; col++) {
        if (strokeMask[row][col]) {
          strokePixels++;
          if (referenceMask[row][col]) {
            insidePixels++;
          }
        }
      }
    }

    if (strokePixels == 0) return 0.0;

    return insidePixels / strokePixels;
  }
}
