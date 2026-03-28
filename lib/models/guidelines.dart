/// Defines the vertical positions of handwriting guidelines within a given height.
///
/// The four lines divide the writing area into three zones:
/// - Ascender zone: ascenderLine → midline (for tall letters like h, b, d)
/// - x-height zone: midline → baseline (where most lowercase letters live)
/// - Descender zone: baseline → descenderLine (for letters like g, p, y)
class Guidelines {
  final double ascenderLine;
  final double midline;
  final double baseline;
  final double descenderLine;

  const Guidelines({
    required this.ascenderLine,
    required this.midline,
    required this.baseline,
    required this.descenderLine,
  });

  /// Creates guidelines by measuring the font's actual baseline and applying
  /// known typographic ratios for [fontFamily], centered within [canvasHeight].
  ///
  /// Comic Sans MS ratios (proportion of em/fontSize):
  ///   x-height ≈ 0.54, ascender ≈ 0.93, descender ≈ 0.25
  factory Guidelines.fromFont({
    required double canvasHeight,
    required String fontFamily,
    double fontSize = 120.0,
  }) {
    // Known Comic Sans MS metrics as proportions of fontSize.
    // These come from the font's OS/2 table values.
    const xHeightRatio = 0.54;
    const ascenderRatio = 0.93;
    const descenderRatio = 0.25;

    final xHeight = fontSize * xHeightRatio;
    final ascenderHeight = fontSize * ascenderRatio;
    final descenderDepth = fontSize * descenderRatio;

    final totalHeight = ascenderHeight + descenderDepth;
    final baseline = (canvasHeight - totalHeight) / 2 + ascenderHeight;

    return Guidelines(
      ascenderLine: baseline - ascenderHeight,
      midline: baseline - xHeight,
      baseline: baseline,
      descenderLine: baseline + descenderDepth,
    );
  }

  /// The distance from midline to baseline — the core letter height.
  double get xHeight => baseline - midline;
}
