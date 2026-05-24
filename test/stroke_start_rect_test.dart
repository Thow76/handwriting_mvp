import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';

void main() {
  // Shared 200×300 bounds used across most tests.
  const bounds = Rect.fromLTWH(10, 20, 200, 300);

  // A typical well-formed rectangle covering the upper-left quarter.
  const rect = StrokeStartRect(minX: 0.0, maxX: 0.5, minY: 0.0, maxY: 0.5);

  // ── Construction ────────────────────────────────────────────────────────────

  group('StrokeStartRect construction', () {
    test('creates successfully with valid fractions', () {
      const r = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.8);
      expect(r.minX, 0.1);
      expect(r.maxX, 0.9);
      expect(r.minY, 0.2);
      expect(r.maxY, 0.8);
    });

    test('allows boundary fractions 0.0 and 1.0', () {
      const r = StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0);
      expect(r.minX, 0.0);
      expect(r.maxX, 1.0);
    });
  });

  // ── Constructor validation ───────────────────────────────────────────────────

  group('StrokeStartRect validation', () {
    test('asserts when minX < 0.0', () {
      expect(
        () => StrokeStartRect(minX: -0.1, maxX: 0.5, minY: 0.0, maxY: 0.5),
        throwsAssertionError,
      );
    });

    test('asserts when maxX > 1.0', () {
      expect(
        () => StrokeStartRect(minX: 0.5, maxX: 1.1, minY: 0.0, maxY: 0.5),
        throwsAssertionError,
      );
    });

    test('asserts when minX == maxX (inverted/degenerate X)', () {
      expect(
        () => StrokeStartRect(minX: 0.5, maxX: 0.5, minY: 0.0, maxY: 0.5),
        throwsAssertionError,
      );
    });

    test('asserts when minX > maxX (inverted X)', () {
      expect(
        () => StrokeStartRect(minX: 0.8, maxX: 0.2, minY: 0.0, maxY: 0.5),
        throwsAssertionError,
      );
    });

    test('asserts when minY < 0.0', () {
      expect(
        () => StrokeStartRect(minX: 0.0, maxX: 0.5, minY: -0.1, maxY: 0.5),
        throwsAssertionError,
      );
    });

    test('asserts when maxY > 1.0', () {
      expect(
        () => StrokeStartRect(minX: 0.0, maxX: 0.5, minY: 0.5, maxY: 1.1),
        throwsAssertionError,
      );
    });

    test('asserts when minY == maxY (degenerate Y)', () {
      expect(
        () => StrokeStartRect(minX: 0.0, maxX: 0.5, minY: 0.4, maxY: 0.4),
        throwsAssertionError,
      );
    });

    test('asserts when minY > maxY (inverted Y)', () {
      expect(
        () => StrokeStartRect(minX: 0.0, maxX: 0.5, minY: 0.9, maxY: 0.1),
        throwsAssertionError,
      );
    });
  });

  // ── contains – interior points ───────────────────────────────────────────────

  group('contains – interior', () {
    // bounds = Rect.fromLTWH(10, 20, 200, 300)
    // rect covers fractions x:[0.0, 0.5), y:[0.0, 0.5)
    // In absolute coords that is x:[10, 110), y:[20, 170)

    test('point strictly inside the rectangle returns true', () {
      // Absolute (60, 95) → relative (0.25, 0.25): inside.
      expect(rect.contains(const Offset(60, 95), bounds), isTrue);
    });

    test('point in the opposite quadrant (bottom-right) returns false', () {
      // Absolute (160, 245) → relative (0.75, 0.75): outside.
      expect(rect.contains(const Offset(160, 245), bounds), isFalse);
    });
  });

  // ── contains – edge inclusion/exclusion ─────────────────────────────────────

  group('contains – min edges (inclusive)', () {
    test('point exactly on minX edge is inside', () {
      // Absolute (10, 95) → relative x = 0.0 (= minX), y = 0.25.
      expect(rect.contains(const Offset(10, 95), bounds), isTrue);
    });

    test('point exactly on minY edge is inside', () {
      // Absolute (60, 20) → relative x = 0.25, y = 0.0 (= minY).
      expect(rect.contains(const Offset(60, 20), bounds), isTrue);
    });

    test('point on both min edges (top-left corner) is inside', () {
      // Absolute (10, 20) → relative (0.0, 0.0).
      expect(rect.contains(const Offset(10, 20), bounds), isTrue);
    });
  });

  group('contains – max edges (exclusive)', () {
    test('point exactly on maxX edge is outside', () {
      // Absolute (110, 95) → relative x = 0.5 (= maxX), y = 0.25.
      expect(rect.contains(const Offset(110, 95), bounds), isFalse);
    });

    test('point exactly on maxY edge is outside', () {
      // Absolute (60, 170) → relative x = 0.25, y = 0.5 (= maxY).
      expect(rect.contains(const Offset(60, 170), bounds), isFalse);
    });

    test('point on both max edges (bottom-right corner) is outside', () {
      // Absolute (110, 170) → relative (0.5, 0.5).
      expect(rect.contains(const Offset(110, 170), bounds), isFalse);
    });
  });

  // ── contains – outside in each direction ────────────────────────────────────

  group('contains – outside in each direction', () {
    test('point to the left of minX is outside', () {
      // Absolute (9, 95) → relative x < 0: outside left.
      expect(rect.contains(const Offset(9, 95), bounds), isFalse);
    });

    test('point to the right of maxX is outside', () {
      // Absolute (111, 95) → relative x > 0.5: outside right.
      expect(rect.contains(const Offset(111, 95), bounds), isFalse);
    });

    test('point above minY is outside', () {
      // Absolute (60, 19) → relative y < 0: outside top.
      expect(rect.contains(const Offset(60, 19), bounds), isFalse);
    });

    test('point below maxY is outside', () {
      // Absolute (60, 171) → relative y > 0.5: outside bottom.
      expect(rect.contains(const Offset(60, 171), bounds), isFalse);
    });
  });

  // ── contains – degenerate bounds tolerance ──────────────────────────────────

  group('contains – degenerate bounds', () {
    test('zero-width bounds returns false (no division by zero)', () {
      const zeroBounds = Rect.fromLTWH(10, 20, 0, 300);
      expect(rect.contains(const Offset(10, 95), zeroBounds), isFalse);
    });

    test('zero-height bounds returns false (no division by zero)', () {
      const zeroBounds = Rect.fromLTWH(10, 20, 200, 0);
      expect(rect.contains(const Offset(60, 20), zeroBounds), isFalse);
    });
  });

  // ── Equality and hashCode ────────────────────────────────────────────────────

  group('equality and hashCode', () {
    test('two rects with identical fields are equal', () {
      const a = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.8);
      const b = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.8);
      expect(a, equals(b));
    });

    test('two equal rects have the same hashCode', () {
      const a = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.8);
      const b = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.8);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('rects with different minX are not equal', () {
      const a = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.8);
      const b = StrokeStartRect(minX: 0.2, maxX: 0.9, minY: 0.2, maxY: 0.8);
      expect(a, isNot(equals(b)));
    });

    test('rects with different maxX are not equal', () {
      const a = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.8);
      const b = StrokeStartRect(minX: 0.1, maxX: 0.8, minY: 0.2, maxY: 0.8);
      expect(a, isNot(equals(b)));
    });

    test('rects with different minY are not equal', () {
      const a = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.8);
      const b = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.3, maxY: 0.8);
      expect(a, isNot(equals(b)));
    });

    test('rects with different maxY are not equal', () {
      const a = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.8);
      const b = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.7);
      expect(a, isNot(equals(b)));
    });

    test('a rect is equal to itself', () {
      const a = StrokeStartRect(minX: 0.1, maxX: 0.9, minY: 0.2, maxY: 0.8);
      expect(a, equals(a));
    });
  });
}
