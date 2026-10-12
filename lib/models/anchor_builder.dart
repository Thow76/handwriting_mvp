import 'dart:ui' show Offset, Rect;

import 'letter_formation_data.dart';
import 'stroke_start_rect.dart';

/// The guide-marker anchor points for one stroke of a letter, in canvas
/// coordinates.
class StrokeAnchors {
  /// Index of the stroke within [LetterFormationData.strokes].
  final int strokeIndex;

  /// Centre of the stroke's start rectangle.
  final Offset start;

  /// One point per section, in section-number order.
  final List<Offset> sectionPoints;

  const StrokeAnchors({
    required this.strokeIndex,
    required this.start,
    required this.sectionPoints,
  });
}

/// Builds the anchor points that later guide markers are drawn from.
///
/// For every stroke that has sections, returns the start point (centre of the
/// start rectangle) and one point per section in number order. Each section
/// point is the skeleton pixel inside that section that lies closest to the
/// section's centre; if the skeleton has no pixel in the section, the
/// section's centre is used instead. Strokes with no sections are skipped.
///
/// [skeleton] is a one-pixel-wide skeleton whose top-left pixel sits at
/// [maskOrigin] in canvas coordinates. [tightBounds] is the letter's tight ink
/// box in canvas coordinates, which the fractional rectangles refer to.
List<StrokeAnchors> buildAnchors({
  required LetterFormationData data,
  required List<List<bool>> skeleton,
  required Offset maskOrigin,
  required Rect tightBounds,
}) {
  final anchors = <StrokeAnchors>[];
  for (var i = 0; i < data.strokes.length; i++) {
    final stroke = data.strokes[i];
    if (stroke.sections.isEmpty) continue;

    final ordered = [...stroke.sections]
      ..sort((a, b) => a.number.compareTo(b.number));

    anchors.add(
      StrokeAnchors(
        strokeIndex: i,
        start: _centre(stroke.startRect, tightBounds),
        sectionPoints: [
          for (final section in ordered)
            _snap(section.rect, skeleton, maskOrigin, tightBounds),
        ],
      ),
    );
  }
  return anchors;
}

Offset _centre(StrokeStartRect rect, Rect bounds) => Offset(
  bounds.left + (rect.minX + rect.maxX) / 2 * bounds.width,
  bounds.top + (rect.minY + rect.maxY) / 2 * bounds.height,
);

Offset _snap(
  StrokeStartRect rect,
  List<List<bool>> skeleton,
  Offset origin,
  Rect bounds,
) {
  final centre = _centre(rect, bounds);
  Offset? best;
  var bestDistance = double.infinity;
  for (var r = 0; r < skeleton.length; r++) {
    final row = skeleton[r];
    for (var c = 0; c < row.length; c++) {
      if (!row[c]) continue;
      final pixel = Offset(origin.dx + c + 0.5, origin.dy + r + 0.5);
      if (!rect.contains(pixel, bounds)) continue;
      final d = (pixel - centre).distanceSquared;
      if (d < bestDistance) {
        bestDistance = d;
        best = pixel;
      }
    }
  }
  return best ?? centre;
}
