import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/template_rasterizer.dart';

void main() {
  group('TemplateRasterResult.inkBounds', () {
    test('returns ink bounds within the mask', () {
      // 10x10 mask with ink in rows 2-7 (canvas coords: 102-107)
      final mask = List.generate(10, (row) {
        return List.generate(10, (col) => row >= 2 && row <= 7 && col >= 3 && col <= 6);
      });
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(50, 100, 10, 10),
      );

      final inkBounds = result.inkBounds;
      expect(inkBounds, isNotNull);
      expect(inkBounds!.top, 102.0); // bounds.top + firstInkRow
      expect(inkBounds.bottom, 108.0); // bounds.top + lastInkRow + 1
    });

    test('returns null for empty mask', () {
      final mask = List.generate(10, (_) => List.filled(10, false));
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(50, 100, 10, 10),
      );

      expect(result.inkBounds, isNull);
    });

    test('single ink row', () {
      final mask = List.generate(10, (row) {
        return List.generate(10, (col) => row == 5);
      });
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
      );

      final inkBounds = result.inkBounds;
      expect(inkBounds, isNotNull);
      expect(inkBounds!.top, 5.0);
      expect(inkBounds.bottom, 6.0);
    });

    test('ink at top and bottom edges', () {
      final mask = List.generate(10, (row) {
        return List.generate(10, (col) => row == 0 || row == 9);
      });
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(20, 30, 10, 10),
      );

      final inkBounds = result.inkBounds;
      expect(inkBounds, isNotNull);
      expect(inkBounds!.top, 30.0);
      expect(inkBounds.bottom, 40.0);
    });

    test('preserves horizontal bounds from original', () {
      final mask = List.generate(10, (row) {
        return List.generate(10, (col) => row >= 3 && row <= 6);
      });
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(50, 100, 10, 10),
      );

      final inkBounds = result.inkBounds;
      expect(inkBounds, isNotNull);
      expect(inkBounds!.left, 50.0);
      expect(inkBounds.right, 60.0);
    });
  });
}
