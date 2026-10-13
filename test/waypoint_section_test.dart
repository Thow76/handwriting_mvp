import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';
import 'package:handwriting_mvp/models/waypoint_section.dart';

void main() {
  // Shared 200×300 bounds used across the contains tests.
  const bounds = Rect.fromLTWH(10, 20, 200, 300);

  // A typical section rectangle covering the upper-left quarter.
  const rect = StrokeStartRect(minX: 0.0, maxX: 0.5, minY: 0.0, maxY: 0.5);

  // ── Construction ────────────────────────────────────────────────────────────

  group('WaypointSection construction', () {
    test('creates successfully with a valid number and rect', () {
      final s = WaypointSection(number: 2, rect: rect);
      expect(s.number, 2);
      expect(s.rect, rect);
    });

    test('allows the minimum number of 1', () {
      final s = WaypointSection(number: 1, rect: rect);
      expect(s.number, 1);
    });
  });

  // ── Constructor validation ───────────────────────────────────────────────────

  group('WaypointSection validation', () {
    test('asserts when number == 0', () {
      expect(
        () => WaypointSection(number: 0, rect: rect),
        throwsAssertionError,
      );
    });

    test('asserts when number is negative', () {
      expect(
        () => WaypointSection(number: -1, rect: rect),
        throwsAssertionError,
      );
    });
  });

  // ── contains – delegates to the underlying rect ──────────────────────────────

  group('contains – delegation to rect', () {
    // bounds = Rect.fromLTWH(10, 20, 200, 300)
    // rect covers fractions x:[0.0, 0.5), y:[0.0, 0.5)
    // In absolute coords that is x:[10, 110), y:[20, 170)

    test('point strictly inside returns true', () {
      final section = WaypointSection(number: 1, rect: rect);
      // Absolute (60, 95) → relative (0.25, 0.25): inside.
      expect(section.contains(const Offset(60, 95), bounds), isTrue);
    });

    test('point in the opposite quadrant returns false', () {
      final section = WaypointSection(number: 1, rect: rect);
      // Absolute (160, 245) → relative (0.75, 0.75): outside.
      expect(section.contains(const Offset(160, 245), bounds), isFalse);
    });

    test('point on a min edge is inside (inclusive)', () {
      final section = WaypointSection(number: 1, rect: rect);
      // Absolute (10, 95) → relative x = 0.0 (= minX): inside.
      expect(section.contains(const Offset(10, 95), bounds), isTrue);
    });

    test('point on a max edge is outside (exclusive)', () {
      final section = WaypointSection(number: 1, rect: rect);
      // Absolute (110, 95) → relative x = 0.5 (= maxX): outside.
      expect(section.contains(const Offset(110, 95), bounds), isFalse);
    });

    test('zero-width bounds returns false (no division by zero)', () {
      final section = WaypointSection(number: 1, rect: rect);
      const zeroBounds = Rect.fromLTWH(10, 20, 0, 300);
      expect(section.contains(const Offset(10, 95), zeroBounds), isFalse);
    });
  });

  // ── Equality and hashCode ────────────────────────────────────────────────────

  group('equality and hashCode', () {
    test('two sections with identical number and rect are equal', () {
      final a = WaypointSection(number: 3, rect: rect);
      final b = WaypointSection(number: 3, rect: rect);
      expect(a, equals(b));
    });

    test('two equal sections have the same hashCode', () {
      final a = WaypointSection(number: 3, rect: rect);
      final b = WaypointSection(number: 3, rect: rect);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('sections with different numbers are not equal', () {
      final a = WaypointSection(number: 1, rect: rect);
      final b = WaypointSection(number: 2, rect: rect);
      expect(a, isNot(equals(b)));
    });

    test('sections with different rects are not equal', () {
      const otherRect =
          StrokeStartRect(minX: 0.5, maxX: 1.0, minY: 0.5, maxY: 1.0);
      final a = WaypointSection(number: 1, rect: rect);
      final b = WaypointSection(number: 1, rect: otherRect);
      expect(a, isNot(equals(b)));
    });

    test('a section is equal to itself', () {
      final a = WaypointSection(number: 1, rect: rect);
      expect(a, equals(a));
    });
  });
}
