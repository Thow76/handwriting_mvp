import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/guidelines.dart';
import 'package:handwriting_mvp/models/template_rasterizer.dart';

void main() {
  const fontFamily = 'Roboto'; // available in Flutter test environment
  const fontSize = 120.0;
  const canvasWidth = 400.0;
  const canvasHeight = 300.0;

  late Guidelines guidelines;

  setUp(() {
    guidelines = Guidelines.fromFont(
      canvasHeight: canvasHeight,
      fontFamily: fontFamily,
      fontSize: fontSize,
    );
  });

  group('TemplateRasterizer', () {
    testWidgets('returns a non-empty mask for letter "a"', (tester) async {
      final result = await tester.runAsync(() => TemplateRasterizer.rasterize(
            letter: 'a',
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasWidth,
          ));

      expect(result, isNotNull);
      expect(result!.mask.isNotEmpty, isTrue);
      expect(result.mask.first.isNotEmpty, isTrue);

      // The mask should contain some true pixels — the letter has ink.
      final hasInk = result.mask.any((row) => row.any((cell) => cell));
      expect(hasInk, isTrue);
    });

    testWidgets('mask dimensions match bounds', (tester) async {
      final result = await tester.runAsync(() => TemplateRasterizer.rasterize(
            letter: 'a',
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasWidth,
          ));

      expect(result!.mask.length, result.bounds.height.ceil());
      expect(result.mask.first.length, result.bounds.width.ceil());
    });

    testWidgets('bounds are within canvas area', (tester) async {
      final result = await tester.runAsync(() => TemplateRasterizer.rasterize(
            letter: 'a',
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasWidth,
          ));

      expect(result!.bounds.left, greaterThanOrEqualTo(0));
      expect(result.bounds.top, greaterThanOrEqualTo(0));
      expect(result.bounds.right, lessThanOrEqualTo(canvasWidth));
    });

    testWidgets('bounds are horizontally centred', (tester) async {
      final result = await tester.runAsync(() => TemplateRasterizer.rasterize(
            letter: 'a',
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasWidth,
          ));

      final centre = (result!.bounds.left + result.bounds.right) / 2;
      // Should be roughly centred within canvas width.
      expect(centre, closeTo(canvasWidth / 2, canvasWidth * 0.1));
    });

    testWidgets('different font sizes produce different grid sizes',
        (tester) async {
      final resultSmall =
          await tester.runAsync(() => TemplateRasterizer.rasterize(
                letter: 'a',
                fontFamily: fontFamily,
                fontSize: 60.0,
                guidelines: guidelines,
                canvasWidth: canvasWidth,
              ));
      final resultLarge =
          await tester.runAsync(() => TemplateRasterizer.rasterize(
                letter: 'a',
                fontFamily: fontFamily,
                fontSize: 120.0,
                guidelines: guidelines,
                canvasWidth: canvasWidth,
              ));

      // Larger font should produce a larger mask.
      final smallPixels = resultSmall!.mask.length * resultSmall.mask.first.length;
      final largePixels = resultLarge!.mask.length * resultLarge.mask.first.length;
      expect(largePixels, greaterThan(smallPixels));
    });

    testWidgets('tall letter "h" has bounds reaching above midline',
        (tester) async {
      final result = await tester.runAsync(() => TemplateRasterizer.rasterize(
            letter: 'h',
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasWidth,
          ));

      // 'h' has an ascender — its top should be above the midline.
      expect(result!.bounds.top, lessThan(guidelines.midline));
    });

    testWidgets('descender letter "g" has bounds reaching below baseline',
        (tester) async {
      final result = await tester.runAsync(() => TemplateRasterizer.rasterize(
            letter: 'g',
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasWidth,
          ));

      // 'g' has a descender — its bottom should extend below the baseline.
      expect(result!.bounds.bottom, greaterThan(guidelines.baseline));
    });

    testWidgets('mask contains ink pixels', (tester) async {
      final result = await tester.runAsync(() => TemplateRasterizer.rasterize(
            letter: 'a',
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasWidth,
          ));

      // The mask must contain some ink — verifies the rendering pipeline
      // actually produced pixel data.
      final inkPixels = result!.mask.expand((r) => r).where((c) => c).length;
      expect(inkPixels, greaterThan(0));
    });
  });
}
