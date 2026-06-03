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
  /// Andika ratios (proportion of em/fontSize, from per-glyph bounding boxes):
  ///   x-height ≈ 0.493, ascender ≈ 0.685, descender ≈ 0.193
  factory Guidelines.fromFont({
    required double canvasHeight,
    required String fontFamily,
    double fontSize = 120.0,
  }) {
    // Andika metrics as proportions of fontSize.
    // These come from per-glyph bounding boxes in the font's glyf table.
    // Short letters (a,c,e,o,s): yMax ≈ 493, tall letters (b,d,h,k,l): yMax ≈ 681,
    // descenders (g,p,q,y): yMin ≈ -193 (average of -188,-198,-186,-200).
    const xHeightRatio = 0.493;
    const ascenderRatio = 0.685;
    const descenderRatio = 0.193;

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
