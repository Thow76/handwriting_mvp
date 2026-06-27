import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';
import 'package:handwriting_mvp/models/waypoint_section.dart';
import 'package:handwriting_mvp/models/waypoint_section_scorer.dart';

void main() {
  // A 300×300 bounding box for all tests.
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  // A generic start rect covering the full width and top third.
  const someRect =
      StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0);

  // Four disjoint corner sections, numbered as one ordered letter path.
  //   1 top-left      centre (45, 45)
  //   2 top-right     centre (255, 45)
  //   3 bottom-right  centre (255, 255)
  //   4 bottom-left   centre (45, 255)
  final s1 = WaypointSection(
    number: 1,
    rect: const StrokeStartRect(minX: 0.0, maxX: 0.3, minY: 0.0, maxY: 0.3),
  );
  final s2 = WaypointSection(
    number: 2,
    rect: const StrokeStartRect(minX: 0.7, maxX: 1.0, minY: 0.0, maxY: 0.3),
  );
  final s3 = WaypointSection(
    number: 3,
    rect: const StrokeStartRect(minX: 0.7, maxX: 1.0, minY: 0.7, maxY: 1.0),
  );
  final s4 = WaypointSection(
    number: 4,
    rect: const StrokeStartRect(minX: 0.0, maxX: 0.3, minY: 0.7, maxY: 1.0),
  );

  // A single-stroke letter carrying the whole 4-section path.
  WaypointSectionScorer singleStrokeScorer() => WaypointSectionScorer(
        letter: 'x',
        data: LetterFormationData(
          strokes: [ExpectedStroke(startRect: someRect, sections: [s1, s2, s3, s4])],
          minRequiredStrokes: 1,
        ),
        bounds: bounds,
      );

  // ---------------------------------------------------------------------------
  // No sections → vacuously correct
  // ---------------------------------------------------------------------------

  group('no sections → vacuously correct', () {
    final scorer = WaypointSectionScorer(
      letter: 'a',
      data: LetterFormationData(
        strokes: [ExpectedStroke(startRect: someRect)],
        minRequiredStrokes: 1,
      ),
      bounds: bounds,
    );

    test('overallScore is 1.0', () {
      expect(scorer.score([Stroke(const [Offset(50, 50)])]).overallScore, 1.0);
    });

    test('observations is empty', () {
      expect(scorer.score([Stroke(const [Offset(50, 50)])]).observations,
          isEmpty);
    });

    test('summary mentions no section-scored path', () {
      expect(scorer.score([Stroke(const [Offset(50, 50)])]).summary,
          contains('No section-scored path'));
    });
  });

  // ---------------------------------------------------------------------------
  // Whole path completed in order → 1.0
  // ---------------------------------------------------------------------------

  group('full path in order → 1.0', () {
    final fullPath = Stroke(const [
      Offset(45, 45), // section 1
      Offset(255, 45), // section 2
      Offset(255, 255), // section 3
      Offset(45, 255), // section 4
    ]);

    test('overallScore is 1.0', () {
      expect(singleStrokeScorer().score([fullPath]).overallScore, 1.0);
    });

    test('observation note says all sections hit', () {
      expect(singleStrokeScorer().score([fullPath]).observations.single.note,
          contains('All 4 sections hit'));
    });

    test('summary says the path followed the correct sequence', () {
      expect(singleStrokeScorer().score([fullPath]).summary,
          contains('followed the correct section sequence'));
    });
  });

  // ---------------------------------------------------------------------------
  // Incomplete / out-of-order → 0.0 (no partial credit)
  // ---------------------------------------------------------------------------

  group('incomplete path → 0.0', () {
    // Hits sections 1 and 2, then never reaches 3 or 4.
    final partial = Stroke(const [
      Offset(45, 45), // section 1
      Offset(255, 45), // section 2
      Offset(150, 150), // centre — in no section
    ]);

    test('overallScore is 0.0 (no credit for the in-order prefix)', () {
      expect(singleStrokeScorer().score([partial]).overallScore, 0.0);
    });

    test('observation note says 2 of 4 hit', () {
      expect(singleStrokeScorer().score([partial]).observations.single.note,
          contains('2 of 4 sections hit'));
    });

    test('observed string shows the first missed section', () {
      expect(singleStrokeScorer().score([partial]).observations.single.observed,
          contains('[missed section 3]'));
    });
  });

  group('no sections hit → 0.0', () {
    final miss = Stroke(const [Offset(150, 150), Offset(150, 160)]);

    test('overallScore is 0.0', () {
      expect(singleStrokeScorer().score([miss]).overallScore, 0.0);
    });

    test('summary says the path did not follow the sequence', () {
      expect(singleStrokeScorer().score([miss]).summary,
          contains('did not follow the correct section sequence'));
    });
  });

  // ---------------------------------------------------------------------------
  // One path across multiple strokes — lift and no-lift score identically
  // ---------------------------------------------------------------------------

  group('one path across strokes (lift vs no-lift)', () {
    // Sections split across two expected strokes, but one ordered path 1→4.
    WaypointSectionScorer twoStrokeScorer() => WaypointSectionScorer(
          letter: 'b',
          data: LetterFormationData(
            strokes: [
              ExpectedStroke(startRect: someRect, sections: [s1, s2]),
              ExpectedStroke(startRect: someRect, sections: [s3, s4]),
            ],
            minRequiredStrokes: 1,
          ),
          bounds: bounds,
        );

    final firstHalf = Stroke(const [Offset(45, 45), Offset(255, 45)]); // 1, 2
    final secondHalf = Stroke(const [Offset(255, 255), Offset(45, 255)]); // 3, 4
    final connected = Stroke(const [
      Offset(45, 45),
      Offset(255, 45),
      Offset(255, 255),
      Offset(45, 255),
    ]);

    test('drawn as two strokes in order → 1.0', () {
      expect(twoStrokeScorer().score([firstHalf, secondHalf]).overallScore, 1.0);
    });

    test('drawn as one connected stroke → 1.0 (identical to lifted)', () {
      expect(twoStrokeScorer().score([connected]).overallScore, 1.0);
    });

    test('only the first stroke drawn → 0.0 (rest of the path missing)', () {
      expect(twoStrokeScorer().score([firstHalf]).overallScore, 0.0);
    });

    test('strokes drawn in the wrong order → 0.0', () {
      expect(twoStrokeScorer().score([secondHalf, firstHalf]).overallScore, 0.0);
    });

    test('exactly one observation regardless of stroke count', () {
      expect(twoStrokeScorer().score([firstHalf, secondHalf]).observations.length,
          1);
    });
  });

  // ---------------------------------------------------------------------------
  // Observation expected/observed format
  // ---------------------------------------------------------------------------

  group('observation expected/observed format', () {
    final scorer = WaypointSectionScorer(
      letter: 'g',
      data: LetterFormationData(
        strokes: [ExpectedStroke(startRect: someRect, sections: [s1, s2])],
        minRequiredStrokes: 1,
      ),
      bounds: bounds,
    );
    final stroke = Stroke(const [Offset(45, 45), Offset(255, 45)]);

    test('expected string uses section numbers', () {
      expect(scorer.score([stroke]).observations.single.expected,
          'section 1 → section 2');
    });

    test('observed string uses section numbers for hits', () {
      expect(scorer.score([stroke]).observations.single.observed,
          'section 1 → section 2');
    });
  });
}
