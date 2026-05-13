import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/template_rasterizer.dart';

void main() {
  group('TemplateRasterResult.tightBounds', () {
    test('returns null for empty mask', () {
      final mask = List.generate(10, (_) => List.filled(10, false));
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(50, 100, 10, 10),
      );

      expect(result.tightBounds, isNull);
    });

    // Thin letter ('i' / 'l'): ink only in a narrow central column range.
    // tightBounds.width should be much smaller than inkBounds.width.
    test('thin letter — tightBounds width is much smaller than inkBounds width', () {
      // 10-column mask; ink only in columns 4–5 (width 2 of 10).
      final mask = List.generate(10, (row) {
        return List.generate(10, (col) => row >= 1 && row <= 8 && col >= 4 && col <= 5);
      });
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(20, 10, 10, 10),
      );

      final tb = result.tightBounds;
      final ib = result.inkBounds;
      expect(tb, isNotNull);
      expect(ib, isNotNull);

      // inkBounds preserves full horizontal extent of bounds.
      expect(ib!.left, 20.0);
      expect(ib.right, 30.0);
      expect(ib.width, 10.0);

      // tightBounds is column-tight: columns 4–5 → left=24, right=26.
      expect(tb!.left, 24.0);
      expect(tb.right, 26.0);
      expect(tb.width, lessThan(ib.width / 2));
    });

    // Wide letter ('m' / 'w'): ink spans almost all columns.
    // tightBounds.width should be similar to inkBounds.width.
    test('wide letter — tightBounds width is similar to inkBounds width', () {
      // 10-column mask; ink in columns 0–9 (full width).
      final mask = List.generate(10, (row) {
        return List.generate(10, (col) => row >= 2 && row <= 7);
      });
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(5, 10, 10, 10),
      );

      final tb = result.tightBounds;
      final ib = result.inkBounds;
      expect(tb, isNotNull);
      expect(ib, isNotNull);

      // Both should span the full 10-column range.
      expect(tb!.left, 5.0);
      expect(tb.right, 15.0);
      expect(tb.width, closeTo(ib!.width, 1.0));
    });

    // Letter with descender ('g' / 'p'): ink rows extend below a mid-point.
    // The vertical extent (top / bottom) should be preserved in tightBounds.
    test('letter with descender — vertical extent is preserved', () {
      // Rows 0–9; ink from row 0 (cap-height) down to row 9 (descender).
      final mask = List.generate(10, (row) {
        return List.generate(10, (col) => col >= 3 && col <= 7);
      });
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(0, 50, 10, 10),
      );

      final tb = result.tightBounds;
      expect(tb, isNotNull);

      // Full vertical extent: rows 0–9 → top=50, bottom=60.
      expect(tb!.top, 50.0);
      expect(tb.bottom, 60.0);

      // Horizontal: columns 3–7 → left=3, right=8.
      expect(tb.left, 3.0);
      expect(tb.right, 8.0);
    });

    test('single ink pixel — tightBounds is a 1×1 rect', () {
      final mask = List.generate(5, (row) {
        return List.generate(5, (col) => row == 2 && col == 3);
      });
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(10, 20, 5, 5),
      );

      final tb = result.tightBounds;
      expect(tb, isNotNull);
      expect(tb!.left, 13.0);
      expect(tb.right, 14.0);
      expect(tb.top, 22.0);
      expect(tb.bottom, 23.0);
      expect(tb.width, 1.0);
      expect(tb.height, 1.0);
    });

    test('tightBounds and inkBounds have the same vertical extent', () {
      // Ink in rows 3–6, columns 2–5.
      final mask = List.generate(10, (row) {
        return List.generate(10, (col) => row >= 3 && row <= 6 && col >= 2 && col <= 5);
      });
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
      );

      final tb = result.tightBounds;
      final ib = result.inkBounds;
      expect(tb, isNotNull);
      expect(ib, isNotNull);

      expect(tb!.top, ib!.top);
      expect(tb.bottom, ib.bottom);
    });

    // ── Regression guard: inkBounds vs tightBounds axis contracts ────────────
    //
    // inkBounds must be tight on the y-axis only (full mask width preserved).
    // tightBounds must be tight on BOTH axes.
    //
    // This test would catch any regression where tightBounds loses its
    // horizontal tightness (reverting to the full-width inkBounds behaviour)
    // or where inkBounds inadvertently becomes column-tight.
    test('inkBounds is y-axis-tight with full width; tightBounds is tight on both axes', () {
      // 10×10 mask: ink occupies rows 3–7, cols 2–6 (all indices 0-based).
      // bounds origin is (0, 0) so canvas coords equal mask indices directly.
      final mask = List.generate(10, (row) {
        return List.generate(10, (col) => row >= 3 && row <= 7 && col >= 2 && col <= 6);
      });
      final result = TemplateRasterResult(
        mask: mask,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
      );

      final ib = result.inkBounds;
      final tb = result.tightBounds;
      expect(ib, isNotNull, reason: 'mask has ink so inkBounds must be non-null');
      expect(tb, isNotNull, reason: 'mask has ink so tightBounds must be non-null');

      // inkBounds: row-tight on y-axis (firstInkRow=3, lastInkRow=7 → bottom=8),
      // but inherits the full mask width on the x-axis.
      expect(ib!.top, 3.0, reason: 'inkBounds.top must equal the first ink row');
      expect(ib.bottom, 8.0, reason: 'inkBounds.bottom must equal lastInkRow + 1');
      expect(ib.left, 0.0, reason: 'inkBounds.left must equal bounds.left (full width)');
      expect(ib.right, 10.0, reason: 'inkBounds.right must equal bounds.right (full width)');

      // tightBounds: tight on both axes (col 2 → left=2, col 6 → right=7).
      expect(tb!.top, 3.0, reason: 'tightBounds.top must equal the first ink row');
      expect(tb.bottom, 8.0, reason: 'tightBounds.bottom must equal lastInkRow + 1');
      expect(tb.left, 2.0, reason: 'tightBounds.left must equal the first ink column');
      expect(tb.right, 7.0, reason: 'tightBounds.right must equal lastInkCol + 1');
    });
  });
}
