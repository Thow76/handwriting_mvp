import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/match_waypoint_sections.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';
import 'package:handwriting_mvp/models/waypoint_section.dart';

void main() {
  // 300×300 bounding box used throughout, so a fraction f maps to absolute
  // coordinate f × 300.
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  // Three disjoint sections placed along the diagonal:
  //   section 1 → top-left      abs x[0,90)   y[0,90)
  //   section 2 → centre        abs x[120,180) y[120,180)
  //   section 3 → bottom-right  abs x[210,300) y[210,300)
  final section1 = WaypointSection(
    number: 1,
    rect: const StrokeStartRect(minX: 0.0, maxX: 0.3, minY: 0.0, maxY: 0.3),
  );
  final section2 = WaypointSection(
    number: 2,
    rect: const StrokeStartRect(minX: 0.4, maxX: 0.6, minY: 0.4, maxY: 0.6),
  );
  final section3 = WaypointSection(
    number: 3,
    rect: const StrokeStartRect(minX: 0.7, maxX: 1.0, minY: 0.7, maxY: 1.0),
  );

  final sections = [section1, section2, section3];

  // ---------------------------------------------------------------------------
  // All sections hit in order — full credit
  // ---------------------------------------------------------------------------

  group('all sections hit in order', () {
    final path = [
      const Offset(10, 10),   // inside section 1
      const Offset(150, 150), // inside section 2
      const Offset(250, 250), // inside section 3
    ];

    test('hitCount equals the number of sections', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hitCount, 3);
    });

    test('all sections are reported as hits', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hits.every((h) => h.isHit), isTrue);
    });

    test('hits list length equals section count', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hits.length, sections.length);
    });

    test('hit point indices are strictly increasing', () {
      final result = matchWaypointSections(path, sections, bounds);
      final indices = result.hits.map((h) => h.hitPointIndex!).toList();
      for (var i = 1; i < indices.length; i++) {
        expect(indices[i], greaterThan(indices[i - 1]));
      }
    });

    test('hit point indices correspond to the matching points', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hits[0].hitPointIndex, 0);
      expect(result.hits[1].hitPointIndex, 1);
      expect(result.hits[2].hitPointIndex, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Scoring stops at the first break — no credit for later sections
  // ---------------------------------------------------------------------------

  group('stops at first break', () {
    // Section 1 is hit, section 2 is never visited, but section 3's rectangle
    // IS visited. Strict scoring must stop at section 2 and award no credit
    // for section 3.
    final path = [
      const Offset(10, 10),   // inside section 1
      const Offset(250, 250), // inside section 3, NOT section 2
    ];

    test('hitCount stops at the first unmatched section', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hitCount, 1);
    });

    test('section 1 is a hit', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hits[0].isHit, isTrue);
    });

    test('section 2 (the break) is a miss with no hit index', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hits[1].isHit, isFalse);
      expect(result.hits[1].hitPointIndex, isNull);
    });

    test('section 3 is not credited even though its rect was visited', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hits[2].isHit, isFalse);
      expect(result.hits[2].hitPointIndex, isNull);
    });

    test('hits list still has one entry per section', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hits.length, sections.length);
    });
  });

  // ---------------------------------------------------------------------------
  // Sequence enforcement — a later section visited before an earlier one
  // does not count
  // ---------------------------------------------------------------------------

  group('sequence enforcement', () {
    // Section 2's rect is visited first (index 0), then section 1's rect
    // (index 1). Section 1 matches at index 1; section 2 must then be hit at an
    // index AFTER 1, but its only visit was at index 0 — so it is a miss.
    final path = [
      const Offset(150, 150), // inside section 2
      const Offset(10, 10),   // inside section 1
    ];

    test('hitCount is 1 (only the in-order prefix counts)', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hitCount, 1);
    });

    test('section 1 is hit at the later index', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hits[0].isHit, isTrue);
      expect(result.hits[0].hitPointIndex, 1);
    });

    test('section 2 visited before section 1 is a miss', () {
      final result = matchWaypointSections(path, sections, bounds);
      expect(result.hits[1].isHit, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Section number order, not list order, drives evaluation
  // ---------------------------------------------------------------------------

  group('processes sections in number order', () {
    // Same three sections, but supplied in a shuffled list.
    final shuffled = [section3, section1, section2];
    final path = [
      const Offset(10, 10),   // inside section 1
      const Offset(150, 150), // inside section 2
      const Offset(250, 250), // inside section 3
    ];

    test('all sections hit regardless of list order', () {
      final result = matchWaypointSections(path, shuffled, bounds);
      expect(result.hitCount, 3);
    });

    test('hits are reported in ascending number order', () {
      final result = matchWaypointSections(path, shuffled, bounds);
      expect(result.hits.map((h) => h.section.number).toList(), [1, 2, 3]);
    });
  });

  // ---------------------------------------------------------------------------
  // Degenerate inputs
  // ---------------------------------------------------------------------------

  group('degenerate inputs', () {
    test('empty observed points yields zero hits', () {
      final result = matchWaypointSections(const [], sections, bounds);
      expect(result.hitCount, 0);
      expect(result.hits.every((h) => !h.isHit), isTrue);
    });

    test('empty sections yields zero hits and an empty breakdown', () {
      final path = [const Offset(10, 10)];
      final result = matchWaypointSections(path, const [], bounds);
      expect(result.hitCount, 0);
      expect(result.hits, isEmpty);
    });

    test('zero-width bounds yields zero hits (no point can be contained)', () {
      const zeroBounds = Rect.fromLTWH(0, 0, 0, 300);
      final path = [
        const Offset(10, 10),
        const Offset(150, 150),
        const Offset(250, 250),
      ];
      final result = matchWaypointSections(path, sections, zeroBounds);
      expect(result.hitCount, 0);
    });
  });
}
