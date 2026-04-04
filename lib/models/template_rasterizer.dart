import 'dart:ui' as ui show Image, ImageByteFormat, PictureRecorder;
import 'dart:ui' show Canvas, Color, Offset, Paint, PaintingStyle, Rect, Size, TextBaseline, TextDirection;

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import 'guidelines.dart';

/// The result of rasterizing a template letter: a boolean mask
/// and the bounding box (in canvas coordinates) it was derived from.
class TemplateRasterResult {
  /// Boolean grid where `true` means the letter glyph has ink at that pixel.
  final List<List<bool>> mask;

  /// The bounding box in canvas coordinates that this mask covers.
  final Rect bounds;

  const TemplateRasterResult({required this.mask, required this.bounds});

  /// Returns the tight bounding box around actual ink pixels, in canvas
  /// coordinates. Returns `null` if the mask contains no ink.
  Rect? get inkBounds {
    int? firstInkRow;
    int? lastInkRow;

    for (var row = 0; row < mask.length; row++) {
      if (mask[row].any((pixel) => pixel)) {
        firstInkRow ??= row;
        lastInkRow = row;
      }
    }

    if (firstInkRow == null || lastInkRow == null) return null;

    return Rect.fromLTRB(
      bounds.left,
      bounds.top + firstInkRow,
      bounds.right,
      bounds.top + lastInkRow + 1,
    );
  }
}

/// Renders a reference letter to an offscreen image and converts
/// it into a boolean pixel mask.
class TemplateRasterizer {
  /// Rasterizes [letter] using the given font and positioning parameters.
  ///
  /// The letter is positioned the same way as on the drawing canvas:
  /// baseline-aligned to [guidelines] and horizontally centred within
  /// [canvasWidth].
  ///
  /// Returns a [TemplateRasterResult] containing the boolean mask and
  /// the bounding box (in canvas coordinates) that the mask covers.
  static Future<TemplateRasterResult> rasterize({
    required String letter,
    required String fontFamily,
    required double fontSize,
    required Guidelines guidelines,
    required double canvasWidth,
  }) async {
    // Lay out the letter to get its metrics.
    final textStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: const Color(0xFF000000),
      height: 1.0,
    );

    final painter = TextPainter(
      text: TextSpan(text: letter, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // Position the letter exactly as the drawing canvas does.
    final baselineOffset = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final x = (canvasWidth - painter.width) / 2;
    final y = guidelines.baseline - baselineOffset;

    // Compute the bounding box in canvas coordinates.
    final bounds = Rect.fromLTWH(x, y, painter.width, painter.height);

    // Render to an offscreen image at the bounding box size.
    final width = bounds.width.ceil();
    final height = bounds.height.ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    // Fill with transparent background.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()
        ..color = const Color(0x00000000)
        ..style = PaintingStyle.fill,
    );

    // Paint the letter at the origin of this local canvas.
    painter.paint(canvas, Offset.zero);

    final picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) {
      throw StateError('Failed to read pixel data from offscreen image');
    }

    // Convert RGBA pixel data to a boolean mask.
    // A pixel is "ink" if its alpha channel is above a threshold.
    const alphaThreshold = 10;
    final pixels = byteData.buffer.asUint8List();
    final mask = List.generate(height, (row) {
      return List.generate(width, (col) {
        final index = (row * width + col) * 4;
        final alpha = pixels[index + 3];
        return alpha > alphaThreshold;
      });
    });

    return TemplateRasterResult(mask: mask, bounds: bounds);
  }
}
