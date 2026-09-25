import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';
import 'package:handwriting_mvp/models/waypoint_section.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Single-stroke letters — table-driven lookup tests
  //
  // Asserts that:
  //   1. Each letter has a non-null entry in the registry.
  //   2. minRequiredStrokes == 1.
  //   3. Exactly one ExpectedStroke is present.
  // ---------------------------------------------------------------------------

  const singleStrokeLetters = ['c', 'e', 'l', 'o', 's', 'v', 'w', 'z'];

  group('letterFormationRegistry — single-stroke letters', () {
    for (final letter in singleStrokeLetters) {
      test('$letter: entry is non-null', () {
        expect(letterFormationRegistry[letter], isNotNull);
      });

      test('$letter: minRequiredStrokes == 1', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.minRequiredStrokes, 1);
      });

      test('$letter: has exactly one ExpectedStroke', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes, hasLength(1));
        expect(data.canonicalStrokeCount, 1);
      });
    }

    // v, w, z, s are now section-scored (approved zone review designs) —
    // see docs/zone_review/REVIEW.md. Each replaces its former waypoints
    // list with a bespoke numbered sections list on its single stroke.

    test('v: sections are 4 bespoke rectangles covering the diagonal V', () {
      final sections = letterFormationRegistry['v']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(minX: 0, maxX: 0.5, minY: 0, maxY: 0.5),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(minX: 0, maxX: 0.5, minY: 0.5, maxY: 1),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(minX: 0.5, maxX: 1, minY: 0.5, maxY: 1),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(minX: 0.5, maxX: 1, minY: 0, maxY: 0.5),
        ),
      ]);
    });

    test('v: waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['v']!.strokes[0].waypoints, isEmpty);
    });

    test('w: sections are 5 bespoke rectangles covering the double diagonal',
        () {
      final sections = letterFormationRegistry['w']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect:
              const StrokeStartRect(minX: 0, maxX: 0.2, minY: 0, maxY: 0.5),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0.2, maxX: 0.4, minY: 0.5, maxY: 1),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0.4, maxX: 0.6, minY: 0, maxY: 0.5),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.6, maxX: 0.8, minY: 0.5, maxY: 1),
        ),
        WaypointSection(
          number: 5,
          rect:
              const StrokeStartRect(minX: 0.8, maxX: 1, minY: 0, maxY: 0.5),
        ),
      ]);
    });

    test('w: waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['w']!.strokes[0].waypoints, isEmpty);
    });

    test('z: sections are 5 bespoke rectangles (top bar → diagonal → base bar)',
        () {
      final sections = letterFormationRegistry['z']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1 / 3, minY: 0, maxY: 1 / 3),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 2 / 3, maxX: 1, minY: 0, maxY: 1 / 3),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 1 / 3, maxX: 2 / 3, minY: 1 / 3, maxY: 2 / 3),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1 / 3, minY: 2 / 3, maxY: 1),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 2 / 3, maxX: 1, minY: 2 / 3, maxY: 1),
        ),
      ]);
    });

    test('z: waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['z']!.strokes[0].waypoints, isEmpty);
    });

    test(
        's: sections are 6 bespoke rectangles (2 columns x 3 rows quadrant '
        'grid; interim placeholder)', () {
      final sections = letterFormationRegistry['s']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0.5, maxX: 1, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.5, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.5, minY: 0.35, maxY: 0.65),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.5, maxX: 1, minY: 0.35, maxY: 0.65),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0.5, maxX: 1, minY: 0.65, maxY: 1),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.5, minY: 0.65, maxY: 1),
        ),
      ]);
    });

    test('s: waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['s']!.strokes[0].waypoints, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Optional-lift oval-and-bowl letters — a, b, d, g, p, q, r, y
  //
  // All entries have minRequiredStrokes = 1.  Connected (one-stroke) and
  // separated (multi-stroke) formations are both correct; the scoring floor
  // is 1, not the canonical stroke count.
  //
  // For b, d, g, p, q the strokes list has two entries (canonical separated
  // form) so the scorers have the right structure while minRequiredStrokes
  // stays at 1.  The strokes.length == 2 assertions below are the regression
  // guard for this architectural distinction from the scope's revised
  // stroke-count treatment.
  // ---------------------------------------------------------------------------

  const optionalLiftLetters = ['a', 'b', 'd', 'g', 'p', 'q', 'y'];

  group('letterFormationRegistry — optional-lift letters', () {
    // Regression guard: minRequiredStrokes == 1 for every optional-lift letter.
    // This assertion exists specifically to prevent accidental reversion to the
    // original plan that set minRequiredStrokes = 2 for b, d, g, p, q.
    for (final letter in optionalLiftLetters) {
      test('$letter: entry is non-null', () {
        expect(letterFormationRegistry[letter], isNotNull);
      });

      test(
        '$letter: minRequiredStrokes == 1 (regression guard — scope revised treatment)',
        () {
          final data = letterFormationRegistry[letter]!;
          expect(data.minRequiredStrokes, 1);
        },
      );
    }

    // Canonical-count guard: b, d, g, p, q must have exactly two strokes in
    // their strokes list even though minRequiredStrokes == 1.  This is the
    // architectural distinction: strokes.length is the canonical count;
    // minRequiredStrokes is the scoring floor.
    for (final letter in ['b', 'd', 'g', 'p', 'q']) {
      test('$letter: strokes.length == 2 (canonical-count guard)', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes, hasLength(2));
        expect(data.canonicalStrokeCount, 2);
      });
    }

    // a: single oval stroke with sections (migrated from waypoints).
    test('a: has exactly one stroke', () {
      expect(letterFormationRegistry['a']!.strokes, hasLength(1));
    });

    test('a: compound stroke has non-empty sections', () {
      expect(letterFormationRegistry['a']!.strokes[0].sections, isNotEmpty);
    });

    test(
        'a: sections are 6 bespoke rectangles covering the anticlockwise '
        'oval and stem (3 columns x 2 rows)', () {
      final sections = letterFormationRegistry['a']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
            minX: 0.38,
            maxX: 0.72,
            minY: 0,
            maxY: 0.5,
          ),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
            minX: 0,
            maxX: 0.38,
            minY: 0,
            maxY: 0.5,
          ),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
            minX: 0,
            maxX: 0.38,
            minY: 0.5,
            maxY: 1,
          ),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
            minX: 0.38,
            maxX: 0.72,
            minY: 0.5,
            maxY: 1,
          ),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
            minX: 0.72,
            maxX: 1,
            minY: 0,
            maxY: 0.5,
          ),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
            minX: 0.72,
            maxX: 1,
            minY: 0.5,
            maxY: 1,
          ),
        ),
      ]);
    });

    test('a: waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['a']!.strokes[0].waypoints, isEmpty);
    });

    // c: single open-arc stroke with sections (migrated from waypoints).
    test('c: has exactly one stroke', () {
      expect(letterFormationRegistry['c']!.strokes, hasLength(1));
    });

    test('c: compound stroke has non-empty sections', () {
      expect(letterFormationRegistry['c']!.strokes[0].sections, isNotEmpty);
    });

    test('c: sections are 5 bespoke rectangles covering the open anticlockwise arc '
        '(2 columns x 3 rows)', () {
      final sections = letterFormationRegistry['c']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(minX: 0.5, maxX: 1, minY: 0, maxY: 0.3),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(minX: 0, maxX: 0.5, minY: 0, maxY: 0.3),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.5, minY: 0.3, maxY: 0.7),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(minX: 0, maxX: 0.5, minY: 0.7, maxY: 1),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(minX: 0.5, maxX: 1, minY: 0.7, maxY: 1),
        ),
      ]);
    });

    test('c: waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['c']!.strokes[0].waypoints, isEmpty);
    });

    // e: single stroke with sections (migrated from waypoints). Starts
    // mid-left and forms the horizontal tongue before curving anticlockwise
    // around the bowl to an open terminal, so its sections are bespoke —
    // not copied from a/c/o. Measured against the real Andika glyph (see
    // scripts/measure_e_glyph.py) after the original agent-authored design
    // (PR #141) proved unreachable and scored 0% on every correct e — see
    // issue #149.
    test('e: has exactly one stroke', () {
      expect(letterFormationRegistry['e']!.strokes, hasLength(1));
    });

    test('e: compound stroke has non-empty sections', () {
      expect(letterFormationRegistry['e']!.strokes[0].sections, isNotEmpty);
    });

    test(
        'e: sections are 9 bespoke rectangles (3 columns x 3 rows — '
        'crossbar row, top sweep, bottom curve)', () {
      final sections = letterFormationRegistry['e']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.33, minY: 0.37, maxY: 0.52),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0.33, maxX: 0.67, minY: 0.37, maxY: 0.52),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0.67, maxX: 1, minY: 0.37, maxY: 0.52),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.67, maxX: 1, minY: 0, maxY: 0.37),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0.33, maxX: 0.67, minY: 0, maxY: 0.37),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.33, minY: 0, maxY: 0.37),
        ),
        WaypointSection(
          number: 7,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.33, minY: 0.52, maxY: 1),
        ),
        WaypointSection(
          number: 8,
          rect: const StrokeStartRect(
              minX: 0.33, maxX: 0.67, minY: 0.52, maxY: 1),
        ),
        WaypointSection(
          number: 9,
          rect: const StrokeStartRect(
              minX: 0.67, maxX: 1, minY: 0.52, maxY: 1),
        ),
      ]);
    });

    test('e: waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['e']!.strokes[0].waypoints, isEmpty);
    });

    // o: single oval stroke, 6 bespoke sections (3 columns x 2 rows,
    // anticlockwise from the top).
    test('o[0]: sections are 6 bespoke rectangles (anticlockwise oval)', () {
      final sections = letterFormationRegistry['o']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0.33, maxX: 0.67, minY: 0, maxY: 0.5),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.33, minY: 0, maxY: 0.5),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.33, minY: 0.5, maxY: 1),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.33, maxX: 0.67, minY: 0.5, maxY: 1),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0.67, maxX: 1, minY: 0.5, maxY: 1),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
              minX: 0.67, maxX: 1, minY: 0, maxY: 0.5),
        ),
      ]);
    });

    // q[0]: oval — 4 bespoke sections (top-right → top-left → bottom-left →
    // bottom-right); q[1] (descender) is covered in the compound-stroke group.
    test('q[0]: sections are 4 bespoke rectangles (anticlockwise oval)', () {
      final sections = letterFormationRegistry['q']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0.38, maxX: 0.75, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.38, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.38, minY: 0.35, maxY: 0.7),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.38, maxX: 0.75, minY: 0.35, maxY: 0.7),
        ),
      ]);
    });

    // p[1]: bowl — 4 bespoke sections numbered 4-7, continuing the letter
    // path after the stem (p[0]).
    test(
        'p[1]: bowl sections are 4 bespoke rectangles numbered 4-7 '
        '(clockwise right-opening)', () {
      final sections = letterFormationRegistry['p']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.25, maxX: 0.62, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0.62, maxX: 1, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
              minX: 0.62, maxX: 1, minY: 0.35, maxY: 0.7),
        ),
        WaypointSection(
          number: 7,
          rect: const StrokeStartRect(
              minX: 0.25, maxX: 0.62, minY: 0.35, maxY: 0.7),
        ),
      ]);
    });

    // r: redesigned as two-stroke (stem + arch) — moved to compound-stroke group.

    // y: stem-plus-tail; two strokes, now section-scored.
    test('y: has exactly two strokes', () {
      expect(letterFormationRegistry['y']!.strokes, hasLength(2));
    });

    test('y: stroke 1 sections are 2 bespoke rectangles (short arm)', () {
      final sections = letterFormationRegistry['y']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1 / 3, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 1 / 3, maxX: 2 / 3, minY: 0.35, maxY: 0.65),
        ),
      ]);
    });

    test(
        'y: stroke 2 sections are 3 bespoke rectangles numbered 3-5 (tail, '
        'continuing the letter path after the short arm)', () {
      final sections = letterFormationRegistry['y']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 2 / 3, maxX: 1, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 1 / 3, maxX: 2 / 3, minY: 0.65, maxY: 1),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1 / 3, minY: 0.65, maxY: 1),
        ),
      ]);
    });

    // g: single continuous stroke reading (bowl anticlockwise, up the right
    // side, down the descender, hook left) — all 8 sections are numbered on
    // the first ExpectedStroke (stroke 0); the second ExpectedStroke exists
    // only to give the scorer the canonical separated (stem + bowl) start
    // rect and carries no sections of its own. See
    // docs/zone_review/REVIEW.md for the approved design.
    test('g: bowl+descender stroke has non-empty sections', () {
      expect(letterFormationRegistry['g']!.strokes[0].sections, isNotEmpty);
    });

    test('g: first stroke has no waypoints', () {
      expect(letterFormationRegistry['g']!.strokes[0].waypoints, isEmpty);
    });

    test(
        'g: sections are 8 bespoke rectangles, all on the first stroke '
        '(bowl → up the right side → descender → hook)', () {
      final sections = letterFormationRegistry['g']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0.39, maxX: 0.72, minY: 0, maxY: 0.33),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.39, minY: 0, maxY: 0.33),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.39, minY: 0.33, maxY: 0.65),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.39, maxX: 0.72, minY: 0.33, maxY: 0.65),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0.72, maxX: 1, minY: 0.12, maxY: 0.33),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
              minX: 0.72, maxX: 1, minY: 0.33, maxY: 0.65),
        ),
        WaypointSection(
          number: 7,
          rect: const StrokeStartRect(
              minX: 0.39, maxX: 1, minY: 0.65, maxY: 1),
        ),
        WaypointSection(
          number: 8,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.39, minY: 0.65, maxY: 1),
        ),
      ]);
    });

    test('g: second stroke has no sections (all zones are on the first)', () {
      expect(letterFormationRegistry['g']!.strokes[1].sections, isEmpty);
    });

    test('g: second stroke has no waypoints', () {
      expect(letterFormationRegistry['g']!.strokes[1].waypoints, isEmpty);
    });
  });

  group('letterFormationRegistry — top-to-bottom stem section migration', () {
    // These strokes used to carry a plain top → bottom waypoints pair; each
    // now carries a bespoke numbered sections list from the approved zone
    // review (docs/zone_review/REVIEW.md). Every stroke here still has an
    // empty waypoints list.

    for (final entry in {'i': 0, 'j': 0, 'k': 0, 'l': 0, 'p': 0, 'q': 1, 'r': 0, 't': 0}
        .entries) {
      test('${entry.key}[${entry.value}]: waypoints list is empty (migrated to sections)',
          () {
        final stroke = letterFormationRegistry[entry.key]!.strokes[entry.value];
        expect(stroke.waypoints, isEmpty);
      });
    }

    test('i[0]: sections are 2 bespoke rectangles (stem, top to bottom)', () {
      final sections = letterFormationRegistry['i']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1, minY: 0.24, maxY: 0.62),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1, minY: 0.62, maxY: 1),
        ),
      ]);
    });

    test(
        'j[0]: sections are 3 bespoke rectangles (stem, then the hook '
        'curling left at the bottom)', () {
      final sections = letterFormationRegistry['j']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0.45, maxX: 1, minY: 0.18, maxY: 0.65),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0.45, maxX: 1, minY: 0.65, maxY: 1),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.45, minY: 0.65, maxY: 1),
        ),
      ]);
    });

    test('k[0]: sections are 3 bespoke rectangles (stem, top to bottom)', () {
      final sections = letterFormationRegistry['k']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.28, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.28, minY: 0.35, maxY: 0.68),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.28, minY: 0.68, maxY: 1),
        ),
      ]);
    });

    test('l[0]: sections are 3 bespoke rectangles (straight down)', () {
      final sections = letterFormationRegistry['l']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1, minY: 0.35, maxY: 0.7),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1, minY: 0.7, maxY: 1),
        ),
      ]);
    });

    test('p[0]: sections are 3 bespoke rectangles (stem, below the line)', () {
      final sections = letterFormationRegistry['p']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.25, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.25, minY: 0.35, maxY: 0.7),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.25, minY: 0.7, maxY: 1),
        ),
      ]);
    });

    test(
        'q[1]: sections are 3 bespoke rectangles numbered 5-7 (descender, '
        'continuing the letter path after the oval)', () {
      final sections = letterFormationRegistry['q']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0.75, maxX: 1, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
              minX: 0.75, maxX: 1, minY: 0.35, maxY: 0.7),
        ),
        WaypointSection(
          number: 7,
          rect: const StrokeStartRect(
              minX: 0.75, maxX: 1, minY: 0.7, maxY: 1),
        ),
      ]);
    });

    test('r[0]: sections are 2 bespoke rectangles (stem, top to bottom)', () {
      final sections = letterFormationRegistry['r']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.32, minY: 0, maxY: 0.4),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.32, minY: 0.4, maxY: 1),
        ),
      ]);
    });

    test(
        't[0]: sections are 4 bespoke rectangles (stem, curving right at '
        'the foot)', () {
      final sections = letterFormationRegistry['t']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0.28, maxX: 0.58, minY: 0, maxY: 0.4),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0.28, maxX: 0.58, minY: 0.4, maxY: 0.78),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0.28, maxX: 0.58, minY: 0.78, maxY: 1),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.58, maxX: 1, minY: 0.78, maxY: 1),
        ),
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // Required-lift letters — table-driven tests
  //
  // Asserts that:
  //   1. Each letter has a non-null entry in the registry.
  //   2. minRequiredStrokes == 2.
  //   3. Exactly two ExpectedStrokes are present.
  //   4. Waypoint sequences and start regions match the scope specification.
  // ---------------------------------------------------------------------------

  group('letterFormationRegistry — required-lift letters', () {
    const requiredLiftLetters = ['f', 'i', 'j', 't', 'x'];

    for (final letter in requiredLiftLetters) {
      test('$letter: entry is non-null', () {
        expect(letterFormationRegistry[letter], isNotNull);
      });

      test('$letter: minRequiredStrokes == 2', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.minRequiredStrokes, 2);
      });

      test('$letter: has exactly two ExpectedStrokes', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes, hasLength(2));
        expect(data.canonicalStrokeCount, 2);
      });
    }

    // i and j: second stroke is a dot (empty waypoints, scored on presence)
    for (final letter in ['i', 'j']) {
      test('$letter: stroke 2 (dot) has empty waypoints', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes[1].waypoints, isEmpty);
      });
    }

    // t: second stroke is the crossbar, now section-scored (waypoints empty).
    test('t: stroke 2 waypoints list is empty (migrated to sections)', () {
      final data = letterFormationRegistry['t']!;
      expect(data.strokes[1].waypoints, isEmpty);
    });

    test(
        't: stroke 2 (crossbar) sections are 2 bespoke rectangles numbered '
        '5-6, continuing the letter path after the stem', () {
      final sections = letterFormationRegistry['t']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.28, minY: 0, maxY: 0.4),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
              minX: 0.58, maxX: 1, minY: 0, maxY: 0.4),
        ),
      ]);
    });

    // f: two section-scored strokes (curved stem + crossbar). Migrated from
    // waypoints — see docs/waypoint_section_definitions.md for the design.
    test('f: stem stroke has non-empty sections', () {
      expect(letterFormationRegistry['f']!.strokes[0].sections, isNotEmpty);
    });

    test('f: stem stroke has no waypoints', () {
      expect(letterFormationRegistry['f']!.strokes[0].waypoints, isEmpty);
    });

    test(
        'f: stem sections are 3 bespoke rectangles (hook top-right → hook '
        'meets stem → stem body)', () {
      final sections = letterFormationRegistry['f']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
            minX: 0.46,
            maxX: 1.00,
            minY: 0.00,
            maxY: 0.30,
          ),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
            minX: 0.26,
            maxX: 0.46,
            minY: 0.00,
            maxY: 0.30,
          ),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
            minX: 0.26,
            maxX: 0.46,
            minY: 0.30,
            maxY: 1.00,
          ),
        ),
      ]);
    });

    test('f: crossbar stroke has non-empty sections', () {
      expect(letterFormationRegistry['f']!.strokes[1].sections, isNotEmpty);
    });

    test('f: crossbar stroke has no waypoints', () {
      expect(letterFormationRegistry['f']!.strokes[1].waypoints, isEmpty);
    });

    test(
        'f: crossbar sections are 2 bespoke rectangles numbered 4–5 (left → '
        'right, continuing the letter path after the stem)', () {
      final sections = letterFormationRegistry['f']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
            minX: 0.00,
            maxX: 0.26,
            minY: 0.30,
            maxY: 1.00,
          ),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
            minX: 0.46,
            maxX: 1.00,
            minY: 0.30,
            maxY: 1.00,
          ),
        ),
      ]);
    });

    test('x: waypoints lists are empty on both strokes (migrated to sections)',
        () {
      final data = letterFormationRegistry['x']!;
      expect(data.strokes[0].waypoints, isEmpty);
      expect(data.strokes[1].waypoints, isEmpty);
    });

    test(
        'x: stroke 1 sections are 3 bespoke rectangles (top-left through '
        'the middle to bottom-right)', () {
      final sections = letterFormationRegistry['x']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1 / 3, minY: 0, maxY: 1 / 3),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 1 / 3, maxX: 2 / 3, minY: 1 / 3, maxY: 2 / 3),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 2 / 3, maxX: 1, minY: 2 / 3, maxY: 1),
        ),
      ]);
    });

    test(
        'x: stroke 2 sections are 2 bespoke rectangles numbered 4-5 '
        '(top-right to bottom-left)', () {
      final sections = letterFormationRegistry['x']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 2 / 3, maxX: 1, minY: 0, maxY: 1 / 3),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0, maxX: 1 / 3, minY: 2 / 3, maxY: 1),
        ),
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // Compound-stroke letters — h, k, m, n, u
  //
  // Asserts that:
  //   1. Each letter has a non-null entry in the registry.
  //   2. minRequiredStrokes matches the spec (2 for h/k, 1 for m/n/u).
  //   3. Stroke counts are correct.
  //   4. h and n have been migrated to bespoke numbered sections; k, m, and u
  //      still carry a non-empty waypoints list whose sequence matches the
  //      scope table exactly.
  // ---------------------------------------------------------------------------

  group('letterFormationRegistry — compound-stroke letters', () {
    // -------------------------------------------------------------------------
    // n — single compound stroke
    // -------------------------------------------------------------------------
    test('n: entry is non-null', () {
      expect(letterFormationRegistry['n'], isNotNull);
    });

    test('n: minRequiredStrokes == 1', () {
      expect(letterFormationRegistry['n']!.minRequiredStrokes, 1);
    });

    test('n: has exactly one stroke', () {
      expect(letterFormationRegistry['n']!.strokes, hasLength(1));
    });

    test('n: compound stroke has non-empty sections', () {
      expect(letterFormationRegistry['n']!.strokes[0].sections, isNotEmpty);
    });

    test('n: sections are 4 bespoke rectangles covering the n path', () {
      final sections = letterFormationRegistry['n']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
            minX: 0.00,
            maxX: 0.33,
            minY: 0.00,
            maxY: 0.33,
          ),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
            minX: 0.00,
            maxX: 0.33,
            minY: 0.67,
            maxY: 1.00,
          ),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
            minX: 0.33,
            maxX: 0.67,
            minY: 0.00,
            maxY: 0.33,
          ),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
            minX: 0.67,
            maxX: 1.00,
            minY: 0.67,
            maxY: 1.00,
          ),
        ),
      ]);
    });

    // -------------------------------------------------------------------------
    // b — two section-scored strokes (stem + bowl)
    // -------------------------------------------------------------------------
    test('b: stem stroke has non-empty sections', () {
      expect(letterFormationRegistry['b']!.strokes[0].sections, isNotEmpty);
    });

    test('b: stem stroke has no waypoints', () {
      expect(letterFormationRegistry['b']!.strokes[0].waypoints, isEmpty);
    });

    test(
        'b: stem sections are 3 bespoke rectangles (top → middle → bottom '
        'of the stem)', () {
      final sections = letterFormationRegistry['b']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.25, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.25, minY: 0.35, maxY: 0.67),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.25, minY: 0.67, maxY: 1),
        ),
      ]);
    });

    test('b: bowl stroke has non-empty sections', () {
      expect(letterFormationRegistry['b']!.strokes[1].sections, isNotEmpty);
    });

    test('b: bowl stroke has no waypoints', () {
      expect(letterFormationRegistry['b']!.strokes[1].waypoints, isEmpty);
    });

    test('b: bowl sections are 4 bespoke rectangles numbered 4–7 (clockwise '
        'right-opening, continuing the letter path after the stem)', () {
      final sections = letterFormationRegistry['b']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.25, maxX: 0.62, minY: 0.35, maxY: 0.67),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0.62, maxX: 1, minY: 0.35, maxY: 0.67),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
              minX: 0.62, maxX: 1, minY: 0.67, maxY: 1),
        ),
        WaypointSection(
          number: 7,
          rect: const StrokeStartRect(
              minX: 0.25, maxX: 0.62, minY: 0.67, maxY: 1),
        ),
      ]);
    });

    // -------------------------------------------------------------------------
    // d — two section-scored strokes (stem + bowl); horizontal mirror of b
    // -------------------------------------------------------------------------
    test('d: stem stroke has non-empty sections', () {
      expect(letterFormationRegistry['d']!.strokes[0].sections, isNotEmpty);
    });

    test('d: stem stroke has no waypoints', () {
      expect(letterFormationRegistry['d']!.strokes[0].waypoints, isEmpty);
    });

    test(
        'd: stem sections are 3 bespoke rectangles (top → middle → bottom '
        'of the stem)', () {
      final sections = letterFormationRegistry['d']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
              minX: 0.72, maxX: 1, minY: 0, maxY: 0.35),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
              minX: 0.72, maxX: 1, minY: 0.35, maxY: 0.67),
        ),
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0.72, maxX: 1, minY: 0.67, maxY: 1),
        ),
      ]);
    });

    test('d: bowl stroke has non-empty sections', () {
      expect(letterFormationRegistry['d']!.strokes[1].sections, isNotEmpty);
    });

    test('d: bowl stroke has no waypoints', () {
      expect(letterFormationRegistry['d']!.strokes[1].waypoints, isEmpty);
    });

    test('d: bowl sections are 4 bespoke rectangles numbered 4–7 (anticlockwise '
        'left-opening, continuing the letter path after the stem)', () {
      final sections = letterFormationRegistry['d']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.38, maxX: 0.72, minY: 0.35, maxY: 0.67),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.38, minY: 0.35, maxY: 0.67),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
              minX: 0, maxX: 0.38, minY: 0.67, maxY: 1),
        ),
        WaypointSection(
          number: 7,
          rect: const StrokeStartRect(
              minX: 0.38, maxX: 0.72, minY: 0.67, maxY: 1),
        ),
      ]);
    });

    // -------------------------------------------------------------------------
    // m — single compound stroke
    // -------------------------------------------------------------------------
    test('m: entry is non-null', () {
      expect(letterFormationRegistry['m'], isNotNull);
    });

    test('m: minRequiredStrokes == 1', () {
      expect(letterFormationRegistry['m']!.minRequiredStrokes, 1);
    });

    test('m: has exactly one stroke', () {
      expect(letterFormationRegistry['m']!.strokes, hasLength(1));
    });

    test('m: compound stroke has non-empty sections', () {
      expect(letterFormationRegistry['m']!.strokes[0].sections, isNotEmpty);
    });

    test('m: waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['m']!.strokes[0].waypoints, isEmpty);
    });

    test(
      'm: sections are 6 bespoke rectangles (down, up-and-over first arch, '
      'down, up-and-over second arch, down)',
      () {
        final sections = letterFormationRegistry['m']!.strokes[0].sections;
        expect(sections, [
          WaypointSection(
            number: 1,
            rect:
                const StrokeStartRect(minX: 0, maxX: 0.3, minY: 0, maxY: 0.4),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
                minX: 0, maxX: 0.3, minY: 0.4, maxY: 1),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
                minX: 0.3, maxX: 0.68, minY: 0, maxY: 0.4),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
                minX: 0.3, maxX: 0.68, minY: 0.4, maxY: 1),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
                minX: 0.68, maxX: 1, minY: 0, maxY: 0.4),
          ),
          WaypointSection(
            number: 6,
            rect: const StrokeStartRect(
                minX: 0.68, maxX: 1, minY: 0.4, maxY: 1),
          ),
        ]);
      },
    );

    // -------------------------------------------------------------------------
    // u — single compound stroke
    // -------------------------------------------------------------------------
    test('u: entry is non-null', () {
      expect(letterFormationRegistry['u'], isNotNull);
    });

    test('u: minRequiredStrokes == 1', () {
      expect(letterFormationRegistry['u']!.minRequiredStrokes, 1);
    });

    test('u: has exactly one stroke', () {
      expect(letterFormationRegistry['u']!.strokes, hasLength(1));
    });

    test('u: compound stroke has non-empty sections', () {
      expect(letterFormationRegistry['u']!.strokes[0].sections, isNotEmpty);
    });

    test('u: waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['u']!.strokes[0].waypoints, isEmpty);
    });

    test(
      'u: sections are 5 bespoke rectangles (down the left, round the '
      'bottom, up the right)',
      () {
        final sections = letterFormationRegistry['u']!.strokes[0].sections;
        expect(sections, [
          WaypointSection(
            number: 1,
            rect:
                const StrokeStartRect(minX: 0, maxX: 0.3, minY: 0, maxY: 0.5),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
                minX: 0, maxX: 0.3, minY: 0.5, maxY: 1),
          ),
          WaypointSection(
            number: 3,
            rect: const StrokeStartRect(
                minX: 0.3, maxX: 0.68, minY: 0.5, maxY: 1),
          ),
          WaypointSection(
            number: 4,
            rect: const StrokeStartRect(
                minX: 0.68, maxX: 1, minY: 0.5, maxY: 1),
          ),
          WaypointSection(
            number: 5,
            rect: const StrokeStartRect(
                minX: 0.68, maxX: 1, minY: 0, maxY: 0.5),
          ),
        ]);
      },
    );

    // -------------------------------------------------------------------------
    // h — two section-scored strokes (stem + arch)
    // -------------------------------------------------------------------------
    test('h: entry is non-null', () {
      expect(letterFormationRegistry['h'], isNotNull);
    });

    test('h: minRequiredStrokes == 2', () {
      expect(letterFormationRegistry['h']!.minRequiredStrokes, 2);
    });

    test('h: has exactly two strokes', () {
      expect(letterFormationRegistry['h']!.strokes, hasLength(2));
    });

    test('h: stem stroke has non-empty sections', () {
      expect(letterFormationRegistry['h']!.strokes[0].sections, isNotEmpty);
    });

    test('h: stem stroke has no waypoints', () {
      expect(letterFormationRegistry['h']!.strokes[0].waypoints, isEmpty);
    });

    test(
        'h: stem sections are 2 bespoke rectangles (top → bottom), with a '
        'short bottom row forcing the stem to reach the baseline', () {
      final sections = letterFormationRegistry['h']!.strokes[0].sections;
      expect(sections, [
        WaypointSection(
          number: 1,
          rect: const StrokeStartRect(
            minX: 0.00,
            maxX: 0.22,
            minY: 0.00,
            maxY: 0.82,
          ),
        ),
        WaypointSection(
          number: 2,
          rect: const StrokeStartRect(
            minX: 0.00,
            maxX: 0.22,
            minY: 0.82,
            maxY: 1.00,
          ),
        ),
      ]);
    });

    test('h: arch stroke has non-empty sections', () {
      expect(letterFormationRegistry['h']!.strokes[1].sections, isNotEmpty);
    });

    test('h: arch stroke has no waypoints', () {
      expect(letterFormationRegistry['h']!.strokes[1].waypoints, isEmpty);
    });

    test(
        'h: arch sections are 3 bespoke rectangles numbered 3-5 (peak, right '
        'leg, then a short bottom row forcing the right leg to reach the '
        'baseline)', () {
      final sections = letterFormationRegistry['h']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
            minX: 0.22,
            maxX: 1.00,
            minY: 0.00,
            maxY: 0.50,
          ),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
            minX: 0.22,
            maxX: 1.00,
            minY: 0.50,
            maxY: 0.82,
          ),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
            minX: 0.22,
            maxX: 1.00,
            minY: 0.82,
            maxY: 1.00,
          ),
        ),
      ]);
    });

    // -------------------------------------------------------------------------
    // k — stem (topToBottom) + compound second stroke
    // -------------------------------------------------------------------------
    test('k: entry is non-null', () {
      expect(letterFormationRegistry['k'], isNotNull);
    });

    test('k: minRequiredStrokes == 2', () {
      expect(letterFormationRegistry['k']!.minRequiredStrokes, 2);
    });

    test('k: has exactly two strokes', () {
      expect(letterFormationRegistry['k']!.strokes, hasLength(2));
    });

    test('k: stroke 2 waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['k']!.strokes[1].waypoints, isEmpty);
    });

    test(
        'k: stroke 2 sections are 4 bespoke rectangles numbered 4-7 (in from '
        'the upper right to the stem, then out to the lower right)', () {
      final sections = letterFormationRegistry['k']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.62, maxX: 1, minY: 0.35, maxY: 0.68),
        ),
        WaypointSection(
          number: 5,
          rect: const StrokeStartRect(
              minX: 0.28, maxX: 0.62, minY: 0.35, maxY: 0.68),
        ),
        WaypointSection(
          number: 6,
          rect: const StrokeStartRect(
              minX: 0.28, maxX: 0.62, minY: 0.68, maxY: 1),
        ),
        WaypointSection(
          number: 7,
          rect: const StrokeStartRect(
              minX: 0.62, maxX: 1, minY: 0.68, maxY: 1),
        ),
      ]);
    });

    // -------------------------------------------------------------------------
    // r — stem (topToBottom) + compound arch stroke
    // -------------------------------------------------------------------------
    test('r: entry is non-null', () {
      expect(letterFormationRegistry['r'], isNotNull);
    });

    test('r: minRequiredStrokes == 2', () {
      expect(letterFormationRegistry['r']!.minRequiredStrokes, 2);
    });

    test('r: has exactly two strokes', () {
      expect(letterFormationRegistry['r']!.strokes, hasLength(2));
    });

    test('r: stroke 2 waypoints list is empty (migrated to sections)', () {
      expect(letterFormationRegistry['r']!.strokes[1].waypoints, isEmpty);
    });

    test(
        'r: stroke 2 sections are 2 bespoke rectangles numbered 3-4 (the '
        'shoulder, up out of the stem and over to the right)', () {
      final sections = letterFormationRegistry['r']!.strokes[1].sections;
      expect(sections, [
        WaypointSection(
          number: 3,
          rect: const StrokeStartRect(
              minX: 0.32, maxX: 0.68, minY: 0, maxY: 0.4),
        ),
        WaypointSection(
          number: 4,
          rect: const StrokeStartRect(
              minX: 0.68, maxX: 1, minY: 0, maxY: 0.4),
        ),
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // startRect values — table-driven assertions
  //
  // Asserts that every ExpectedStroke in the registry has the exact startRect
  // agreed in the StrokeStart issue.  Coordinates are fractions of the letter's
  // tight ink bounding box (x: left→right, y: top→bottom).
  //
  // Groups (authoring convenience only — not exposed at runtime):
  //   Anticlockwise oval : x 0.55–0.95, y 0.00–0.25
  //   Stem-first         : x 0.00–0.25, y 0.00–0.15
  //   Compound stroke    : x 0.00–0.25, y 0.00–0.15
  //   Top-left           : x 0.00–0.25, y 0.00–0.15
  // ---------------------------------------------------------------------------

  group('letterFormationRegistry — startRect values', () {
    // Helper to get a stroke's startRect.
    StrokeStartRect rect(String letter, int strokeIndex) =>
        letterFormationRegistry[letter]!.strokes[strokeIndex].startRect;

    // ── Anticlockwise oval group ─────────────────────────────────────────────
    // a, c, o, s, g[0], q[0] → x 0.55–0.95, y 0.00–0.25
    const ovalRect = StrokeStartRect(
      minX: 0.55,
      maxX: 0.95,
      minY: 0.00,
      maxY: 0.25,
    );

    for (final letter in ['a', 'c', 'o', 's']) {
      test('$letter[0]: anticlockwise oval startRect', () {
        expect(rect(letter, 0), ovalRect);
      });
    }

    test('d[0]: upper-right stem startRect (0.75–1.00, 0.00–0.15)', () {
      expect(
        rect('d', 0),
        const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15),
      );
    });

    test(
      'g[0]: oval start at top-right of bowl, top at bounds (0.65–0.85, 0.00–0.15)',
      () {
        expect(
          rect('g', 0),
          const StrokeStartRect(minX: 0.65, maxX: 0.85, minY: 0.00, maxY: 0.15),
        );
      },
    );

    test('q[0]: oval start — tighter than standard (0.68–0.95, 0.00–0.15)', () {
      expect(
        rect('q', 0),
        const StrokeStartRect(minX: 0.68, maxX: 0.95, minY: 0.00, maxY: 0.15),
      );
    });

    // ── Stem-first group ─────────────────────────────────────────────────────
    // b[0], h[0], k[0], l[0], p[0] → x 0.00–0.25, y 0.00–0.15
    const stemRect = StrokeStartRect(
      minX: 0.00,
      maxX: 0.25,
      minY: 0.00,
      maxY: 0.15,
    );

    for (final letter in ['b', 'p']) {
      test('$letter[0]: stem-first startRect', () {
        expect(rect(letter, 0), stemRect);
      });
    }

    test('l[0]: full-width stem top (0.00–1.00, 0.00–0.15)', () {
      expect(
        rect('l', 0),
        const StrokeStartRect(minX: 0.00, maxX: 1.00, minY: 0.00, maxY: 0.15),
      );
    });

    test('h[0]: stem-first startRect', () {
      expect(rect('h', 0), stemRect);
    });

    test('k[0]: stem-first startRect', () {
      expect(rect('k', 0), stemRect);
    });

    // ── Compound stroke group ────────────────────────────────────────────────
    // r[0] → x 0.00–0.25, y 0.00–0.15 (same rect as stem-first)
    // m[0], n[0], u[0] have widened startRects — tested individually below.

    test('r[0]: stem-first startRect', () {
      expect(rect('r', 0), stemRect);
    });

    // ── Top-left group ───────────────────────────────────────────────────────
    // v[0], z[0] → x 0.00–0.25, y 0.00–0.15  (same rect as stem-first)

    for (final letter in ['v', 'z']) {
      test('$letter[0]: top-left startRect', () {
        expect(rect(letter, 0), stemRect);
      });
    }

    // ── Per-letter overrides ─────────────────────────────────────────────────

    test('e[0]: mid-left tongue start (0.00–0.25, 0.40–0.60)', () {
      expect(
        rect('e', 0),
        const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.40, maxY: 0.60),
      );
    });

    test('d[1]: mid-right bowl (0.70–1.00, 0.40–0.60)', () {
      expect(
        rect('d', 1),
        const StrokeStartRect(minX: 0.70, maxX: 1.00, minY: 0.40, maxY: 0.60),
      );
    });

    test('f[0]: hook top, right half (0.55–1.00, 0.00–0.15)', () {
      expect(
        rect('f', 0),
        const StrokeStartRect(minX: 0.55, maxX: 1.00, minY: 0.00, maxY: 0.15),
      );
    });

    test('f[1]: crossbar at midline, widened x (0.00–0.25, 0.25–0.40)', () {
      expect(
        rect('f', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.25, maxY: 0.40),
      );
    });

    test(
      't[0]: mid-upper stem recentred and widened (0.35–0.65, 0.00–0.15)',
      () {
        expect(
          rect('t', 0),
          const StrokeStartRect(minX: 0.35, maxX: 0.65, minY: 0.00, maxY: 0.15),
        );
      },
    );

    test('t[1]: crossbar just above x-height (0.00–0.24, 0.26–0.38)', () {
      expect(
        rect('t', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.24, minY: 0.26, maxY: 0.38),
      );
    });

    test('h[1]: arch mid-left at x-height (0.00–0.30, 0.40–0.60)', () {
      expect(
        rect('h', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.40, maxY: 0.60),
      );
    });

    test('k[1]: kick mid-right above 2/3 junction (0.60–0.90, 0.35–0.55)', () {
      expect(
        rect('k', 1),
        const StrokeStartRect(minX: 0.60, maxX: 0.90, minY: 0.35, maxY: 0.55),
      );
    });

    test('r[1]: arch mid-left at x-height (0.00–0.30, 0.40–0.60)', () {
      expect(
        rect('r', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.40, maxY: 0.60),
      );
    });

    test('w[0]: wider x bound (0.00–0.25, 0.00–0.15)', () {
      expect(
        rect('w', 0),
        const StrokeStartRect(minX: 0.00, maxX: 0.25, minY: 0.00, maxY: 0.15),
      );
    });

    test('x[0]: top-left (0.00–0.25, 0.00–0.15)', () {
      expect(rect('x', 0), stemRect);
    });

    test('x[1]: top-right mirror (0.75–1.00, 0.00–0.15)', () {
      expect(
        rect('x', 1),
        const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15),
      );
    });

    test('y[0]: top-left (0.00–0.25, 0.00–0.15)', () {
      expect(rect('y', 0), stemRect);
    });

    test('y[1]: top-right mirror (0.75–1.00, 0.00–0.15)', () {
      expect(
        rect('y', 1),
        const StrokeStartRect(minX: 0.75, maxX: 1.00, minY: 0.00, maxY: 0.15),
      );
    });

    test('i[0]: centred stem, top at stem body (0.25–0.75, 0.30–0.45)', () {
      expect(
        rect('i', 0),
        const StrokeStartRect(minX: 0.25, maxX: 0.75, minY: 0.30, maxY: 0.45),
      );
    });

    test('i[1]: dot only, trimmed to dot extent (0.15–0.85, 0.00–0.20)', () {
      expect(
        rect('i', 1),
        const StrokeStartRect(minX: 0.15, maxX: 0.85, minY: 0.00, maxY: 0.20),
      );
    });

    test('j[0]: centred stem below dot (0.25–0.75, 0.22–0.33)', () {
      expect(
        rect('j', 0),
        const StrokeStartRect(minX: 0.25, maxX: 0.75, minY: 0.22, maxY: 0.33),
      );
    });

    test('j[1]: generous dot zone (0.15–0.85, 0.00–0.25)', () {
      expect(
        rect('j', 1),
        const StrokeStartRect(minX: 0.15, maxX: 0.85, minY: 0.00, maxY: 0.25),
      );
    });

    // ── Confirmed second strokes (b[1], p[1], g[1], q[1]) ───────────────────
    // Design-review-confirmed rectangles (see issue #87). These replaced the
    // PR #86 placeholders (stem-first / upper-right defaults) once the
    // pedagogical start zones for the bowl/link/tail second strokes were
    // agreed.

    test('b[1]: mid-left bowl at x-height (0.00–0.30, 0.40–0.60)', () {
      expect(
        rect('b', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.40, maxY: 0.60),
      );
    });

    test('p[1]: bowl starts at top of bounds (0.00–0.30, 0.00–0.15)', () {
      expect(
        rect('p', 1),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.15),
      );
    });

    test(
      'g[1]: tail start at top-right shoulder, widened right (0.74–0.99, 0.02–0.17)',
      () {
        expect(
          rect('g', 1),
          const StrokeStartRect(minX: 0.74, maxX: 0.99, minY: 0.02, maxY: 0.17),
        );
      },
    );

    test(
      'q[1]: far-right descender at top of bounds (0.87–1.00, 0.00–0.15)',
      () {
        expect(
          rect('q', 1),
          const StrokeStartRect(minX: 0.87, maxX: 1.00, minY: 0.00, maxY: 0.15),
        );
      },
    );

    // ── Widened compound starts (m[0], n[0], u[0]) ───────────────────────────

    test('m[0]: widened compound start (0.00–0.30, 0.00–0.20)', () {
      expect(
        rect('m', 0),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.20),
      );
    });

    test('n[0]: widened compound start (0.00–0.30, 0.00–0.20)', () {
      expect(
        rect('n', 0),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.20),
      );
    });

    test('u[0]: widened compound start (0.00–0.30, 0.00–0.15)', () {
      expect(
        rect('u', 0),
        const StrokeStartRect(minX: 0.00, maxX: 0.30, minY: 0.00, maxY: 0.15),
      );
    });
  });
}
