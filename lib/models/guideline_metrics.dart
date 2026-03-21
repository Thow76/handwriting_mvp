import 'dart:ui';

import '../utils/constants.dart';

/// Converts between **template coordinate space** (y-up, 0 = descender,
/// 1 = top of zone) and **canvas pixel space** (y-down, 0 = top of widget).
///
/// Also exposes pixel Y-positions of each guideline for a given canvas size.
class GuidelineMetrics {
  const GuidelineMetrics(this.canvasSize);

  final Size canvasSize;

  // 5 % padding top and bottom; the active writing zone is 90 % of height.
  static const double _pad = kCanvasPad;
  static const double _zone = 1.0 - 2 * _pad; // 0.90

  // ---- Guideline Y-positions in canvas pixels ----

  double get ascenderY => _tyToCanvas(kTemplateAscender);
  double get capHeightY => _tyToCanvas(kTemplateCapHeight);
  double get xHeightY => _tyToCanvas(kTemplateXHeight);
  double get baselineY => _tyToCanvas(kTemplateBaseline);
  double get descenderY => _tyToCanvas(kTemplateDescender);

  // ---- Coordinate conversion ----

  /// Template point → canvas pixel.
  Offset templateToCanvas(Offset t) => Offset(
        t.dx * canvasSize.width,
        _tyToCanvas(t.dy),
      );

  /// Canvas pixel → template point.
  Offset canvasToTemplate(Offset c) => Offset(
        c.dx / canvasSize.width,
        1.0 - (c.dy / canvasSize.height - _pad) / _zone,
      );

  // Internal: template-y to canvas-y.
  double _tyToCanvas(double ty) =>
      (_pad + (1.0 - ty) * _zone) * canvasSize.height;
}
