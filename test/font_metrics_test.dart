import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/guidelines.dart';
import 'package:handwriting_mvp/models/template_rasterizer.dart';

/// Measures the actual ink bounds of Comic Neue glyphs relative to the baseline.
///
/// This test rasterizes representative letters from each category and reports
/// where the ink actually sits, so we can derive correct guideline ratios.
void main() {
  const fontFamily = 'Comic Neue';
  const fontSize = 120.0;
  const canvasHeight = 600.0;
  const canvasWidth = 400.0;

  final guidelines = Guidelines.fromFont(
    canvasHeight: canvasHeight,
    fontFamily: fontFamily,
    fontSize: fontSize,
  );

  /// Finds the topmost and bottommost ink rows in the mask,
  /// then converts to canvas coordinates using the bounds offset.
  /// Returns (inkTop, inkBottom) in canvas Y coordinates.
  (double, double) findInkBounds(TemplateRasterResult result) {
    int? firstInkRow;
    int? lastInkRow;

    for (var row = 0; row < result.mask.length; row++) {
      if (result.mask[row].any((pixel) => pixel)) {
        firstInkRow ??= row;
        lastInkRow = row;
      }
    }

    if (firstInkRow == null || lastInkRow == null) {
      fail('No ink found in mask');
    }

    // Convert mask row indices to canvas Y coordinates.
    final inkTop = result.bounds.top + firstInkRow;
    final inkBottom = result.bounds.top + lastInkRow;

    return (inkTop.toDouble(), inkBottom.toDouble());
  }

  group('Font metrics measurement', () {
    // Short letters: expected between midline and baseline
    for (final letter in ['a', 'c', 'e', 'n', 'o', 's', 'u', 'x', 'z']) {
      testWidgets('short letter "$letter" ink bounds', (tester) async {
        await tester.runAsync(() async {
          final result = await TemplateRasterizer.rasterize(
            letter: letter,
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasWidth,
          );

          final (inkTop, inkBottom) = findInkBounds(result);

          // Distance above baseline (positive = above)
          final topAboveBaseline = guidelines.baseline - inkTop;
          final bottomAboveBaseline = guidelines.baseline - inkBottom;
          final topRatio = topAboveBaseline / fontSize;
          final bottomRatio = bottomAboveBaseline / fontSize;

          // ignore: avoid_print
          print('Short "$letter": '
              'inkTop=${inkTop.toStringAsFixed(1)} '
              'inkBottom=${inkBottom.toStringAsFixed(1)} '
              'topAboveBaseline=${topAboveBaseline.toStringAsFixed(1)} '
              'bottomAboveBaseline=${bottomAboveBaseline.toStringAsFixed(1)} '
              'topRatio=${topRatio.toStringAsFixed(3)} '
              'bottomRatio=${bottomRatio.toStringAsFixed(3)}');

          // Basic sanity: ink should be above the baseline
          expect(inkTop, lessThan(guidelines.baseline));
        });
      });
    }

    // Tall letters: expected between ascender line and baseline
    for (final letter in ['b', 'd', 'f', 'h', 'k', 'l', 't']) {
      testWidgets('tall letter "$letter" ink bounds', (tester) async {
        await tester.runAsync(() async {
          final result = await TemplateRasterizer.rasterize(
            letter: letter,
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasWidth,
          );

          final (inkTop, inkBottom) = findInkBounds(result);

          final topAboveBaseline = guidelines.baseline - inkTop;
          final bottomAboveBaseline = guidelines.baseline - inkBottom;
          final topRatio = topAboveBaseline / fontSize;
          final bottomRatio = bottomAboveBaseline / fontSize;

          // ignore: avoid_print
          print('Tall "$letter": '
              'inkTop=${inkTop.toStringAsFixed(1)} '
              'inkBottom=${inkBottom.toStringAsFixed(1)} '
              'topAboveBaseline=${topAboveBaseline.toStringAsFixed(1)} '
              'bottomAboveBaseline=${bottomAboveBaseline.toStringAsFixed(1)} '
              'topRatio=${topRatio.toStringAsFixed(3)} '
              'bottomRatio=${bottomRatio.toStringAsFixed(3)}');

          expect(inkTop, lessThan(guidelines.baseline));
        });
      });
    }

    // Descender letters: expected between midline and descender line
    for (final letter in ['g', 'p', 'q', 'y']) {
      testWidgets('descender letter "$letter" ink bounds', (tester) async {
        await tester.runAsync(() async {
          final result = await TemplateRasterizer.rasterize(
            letter: letter,
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasWidth,
          );

          final (inkTop, inkBottom) = findInkBounds(result);

          final topAboveBaseline = guidelines.baseline - inkTop;
          final bottomBelowBaseline = inkBottom - guidelines.baseline;
          final topRatio = topAboveBaseline / fontSize;
          final bottomRatio = bottomBelowBaseline / fontSize;

          // ignore: avoid_print
          print('Descender "$letter": '
              'inkTop=${inkTop.toStringAsFixed(1)} '
              'inkBottom=${inkBottom.toStringAsFixed(1)} '
              'topAboveBaseline=${topAboveBaseline.toStringAsFixed(1)} '
              'bottomBelowBaseline=${bottomBelowBaseline.toStringAsFixed(1)} '
              'topRatio=${topRatio.toStringAsFixed(3)} '
              'bottomRatio=${bottomRatio.toStringAsFixed(3)}');

          expect(inkBottom, greaterThan(guidelines.baseline));
        });
      });
    }

    // Special: j (tall + descender)
    testWidgets('tall+descender letter "j" ink bounds', (tester) async {
      await tester.runAsync(() async {
        final result = await TemplateRasterizer.rasterize(
          letter: 'j',
          fontFamily: fontFamily,
          fontSize: fontSize,
          guidelines: guidelines,
          canvasWidth: canvasWidth,
        );

        final (inkTop, inkBottom) = findInkBounds(result);

        final topAboveBaseline = guidelines.baseline - inkTop;
        final bottomBelowBaseline = inkBottom - guidelines.baseline;
        final topRatio = topAboveBaseline / fontSize;
        final bottomRatio = bottomBelowBaseline / fontSize;

        // ignore: avoid_print
        print('Tall+Desc "j": '
            'inkTop=${inkTop.toStringAsFixed(1)} '
            'inkBottom=${inkBottom.toStringAsFixed(1)} '
            'topAboveBaseline=${topAboveBaseline.toStringAsFixed(1)} '
            'bottomBelowBaseline=${bottomBelowBaseline.toStringAsFixed(1)} '
            'topRatio=${topRatio.toStringAsFixed(3)} '
            'bottomRatio=${bottomRatio.toStringAsFixed(3)}');

        expect(inkTop, lessThan(guidelines.baseline));
        expect(inkBottom, greaterThan(guidelines.baseline));
      });
    });

    // Special: i (dot above body)
    testWidgets('special letter "i" ink bounds', (tester) async {
      await tester.runAsync(() async {
        final result = await TemplateRasterizer.rasterize(
          letter: 'i',
          fontFamily: fontFamily,
          fontSize: fontSize,
          guidelines: guidelines,
          canvasWidth: canvasWidth,
        );

        final (inkTop, inkBottom) = findInkBounds(result);

        final topAboveBaseline = guidelines.baseline - inkTop;
        final bottomAboveBaseline = guidelines.baseline - inkBottom;
        final topRatio = topAboveBaseline / fontSize;
        final bottomRatio = bottomAboveBaseline / fontSize;

        // ignore: avoid_print
        print('Special "i": '
            'inkTop=${inkTop.toStringAsFixed(1)} '
            'inkBottom=${inkBottom.toStringAsFixed(1)} '
            'topAboveBaseline=${topAboveBaseline.toStringAsFixed(1)} '
            'bottomAboveBaseline=${bottomAboveBaseline.toStringAsFixed(1)} '
            'topRatio=${topRatio.toStringAsFixed(3)} '
            'bottomRatio=${bottomRatio.toStringAsFixed(3)}');

        expect(inkTop, lessThan(guidelines.baseline));
      });
    });
  });
}
