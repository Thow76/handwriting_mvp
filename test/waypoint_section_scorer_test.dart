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

  // Three sections covering different parts of the 300×300 box.
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

  // ---------------------------------------------------------------------------
  // Vacuously correct — no section-scored strokes
  // ---------------------------------------------------------------------------

  group('no section-scored strokes → vacuously correct', () {
    late WaypointSectionScorer scorer;

    setUp(() {
      scorer = WaypointSectionScorer(
        letter: 'a',
        data: LetterFormationData(
          strokes: [ExpectedStroke(startRect: someRect)],
          minRequiredStrokes: 1,
        ),
        bounds: bounds,
      );
    });

    test('overallScore is 1.0', () {
      final result = scorer.score([Stroke(const [Offset(50, 50)])]);
      expect(result.overallScore, 1.0);
    });

    test('observations is empty', () {
      final result = scorer.score([Stroke(const [Offset(50, 50)])]);
      expect(result.observations, isEmpty);
    });

    test('summary mentions no section-scored strokes', () {
      final result = scorer.score([Stroke(const [Offset(50, 50)])]);
      expect(result.summary, contains('No section-scored strokes'));
    });
  });

  // ---------------------------------------------------------------------------
  // All sections hit in order — perfect score
  // ---------------------------------------------------------------------------

  group('all sections hit in order — perfect score', () {
    late WaypointSectionScorer scorer;

    setUp(() {
      scorer = WaypointSectionScorer(
        letter: 'b',
        data: LetterFormationData(
          strokes: [
            ExpectedStroke(
              startRect: someRect,
              sections: [section1, section2, section3],
            ),
          ],
          minRequiredStrokes: 1,
        ),
        bounds: bounds,
      );
    });

    test('overallScore is 1.0', () {
      final stroke = Stroke(const [
        Offset(10, 10), // inside section 1
        Offset(150, 150), // inside section 2
        Offset(250, 250), // inside section 3
      ]);
      final result = scorer.score([stroke]);
      expect(result.overallScore, 1.0);
    });

    test('observation score is 1.0', () {
      final stroke = Stroke(const [
        Offset(10, 10),
        Offset(150, 150),
        Offset(250, 250),
      ]);
      final result = scorer.score([stroke]);
      expect(result.observations.single.score, 1.0);
    });

    test('observation note says all sections hit', () {
      final stroke = Stroke(const [
        Offset(10, 10),
        Offset(150, 150),
        Offset(250, 250),
      ]);
      final result = scorer.score([stroke]);
      expect(result.observations.single.note, contains('All 3 sections hit'));
    });

    test('summary says all followed correct path', () {
      final stroke = Stroke(const [
        Offset(10, 10),
        Offset(150, 150),
        Offset(250, 250),
      ]);
      final result = scorer.score([stroke]);
      expect(result.summary, contains('All section-scored strokes followed'));
    });
  });

  // ---------------------------------------------------------------------------
  // Partial hit — only prefix matched
  // ---------------------------------------------------------------------------

  group('partial hit — 2 of 3 sections hit', () {
    late WaypointSectionScorer scorer;

    setUp(() {
      scorer = WaypointSectionScorer(
        letter: 'c',
        data: LetterFormationData(
          strokes: [
            ExpectedStroke(
              startRect: someRect,
              sections: [section1, section2, section3],
            ),
          ],
          minRequiredStrokes: 1,
        ),
        bounds: bounds,
      );
    });

    test('overallScore is 2/3', () {
      // Hits section 1 and section 2, but not section 3.
      final stroke = Stroke(const [
        Offset(10, 10), // inside section 1
        Offset(150, 150), // inside section 2
        Offset(160, 160), // NOT inside section 3
      ]);
      final result = scorer.score([stroke]);
      expect(result.overallScore, closeTo(2.0 / 3.0, 0.001));
    });

    test('observation score is 2/3', () {
      final stroke = Stroke(const [
        Offset(10, 10),
        Offset(150, 150),
        Offset(160, 160),
      ]);
      final result = scorer.score([stroke]);
      expect(result.observations.single.score, closeTo(2.0 / 3.0, 0.001));
    });

    test('observation note says 2 of 3 hit', () {
      final stroke = Stroke(const [
        Offset(10, 10),
        Offset(150, 150),
        Offset(160, 160),
      ]);
      final result = scorer.score([stroke]);
      expect(result.observations.single.note, contains('2 of 3 sections hit'));
    });

    test('observed string shows missed section', () {
      final stroke = Stroke(const [
        Offset(10, 10),
        Offset(150, 150),
        Offset(160, 160),
      ]);
      final result = scorer.score([stroke]);
      expect(result.observations.single.observed, contains('[missed section 3]'));
    });
  });

  // ---------------------------------------------------------------------------
  // No sections hit — score 0
  // ---------------------------------------------------------------------------

  group('no sections hit — score 0', () {
    late WaypointSectionScorer scorer;

    setUp(() {
      scorer = WaypointSectionScorer(
        letter: 'd',
        data: LetterFormationData(
          strokes: [
            ExpectedStroke(
              startRect: someRect,
              sections: [section1, section2, section3],
            ),
          ],
          minRequiredStrokes: 1,
        ),
        bounds: bounds,
      );
    });

    test('overallScore is 0.0', () {
      // All points outside any section.
      final stroke = Stroke(const [
        Offset(100, 10), // between sections
        Offset(100, 100),
        Offset(100, 200),
      ]);
      final result = scorer.score([stroke]);
      expect(result.overallScore, 0.0);
    });

    test('observation note says no sections hit', () {
      final stroke = Stroke(const [
        Offset(100, 10),
        Offset(100, 100),
        Offset(100, 200),
      ]);
      final result = scorer.score([stroke]);
      expect(result.observations.single.note,
          contains('No sections were hit'));
    });

    test('summary says no strokes followed correct path', () {
      final stroke = Stroke(const [
        Offset(100, 10),
        Offset(100, 100),
        Offset(100, 200),
      ]);
      final result = scorer.score([stroke]);
      expect(result.summary,
          contains('No section-scored strokes followed'));
    });
  });

  // ---------------------------------------------------------------------------
  // Multiple section-scored strokes — overallScore is the mean
  // ---------------------------------------------------------------------------

  group('multiple section-scored strokes — overallScore is the mean', () {
    late WaypointSectionScorer scorer;

    setUp(() {
      scorer = WaypointSectionScorer(
        letter: 'e',
        data: LetterFormationData(
          strokes: [
            ExpectedStroke(
              startRect: someRect,
              sections: [section1, section2, section3],
            ),
            ExpectedStroke(
              startRect: someRect,
              sections: [section1, section2, section3],
            ),
          ],
          minRequiredStrokes: 2,
        ),
        bounds: bounds,
      );
    });

    test('first perfect, second zero → mean is 0.5', () {
      final perfect = Stroke(const [
        Offset(10, 10),
        Offset(150, 150),
        Offset(250, 250),
      ]);
      final miss = Stroke(const [
        Offset(100, 10),
        Offset(100, 100),
        Offset(100, 200),
      ]);
      final result = scorer.score([perfect, miss]);
      expect(result.overallScore, 0.5);
    });

    test('two observations produced', () {
      final s1 = Stroke(const [Offset(10, 10), Offset(150, 150), Offset(250, 250)]);
      final s2 = Stroke(const [Offset(10, 10), Offset(150, 150), Offset(250, 250)]);
      final result = scorer.score([s1, s2]);
      expect(result.observations.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Mixed strokes — only section-scored ones contribute
  // ---------------------------------------------------------------------------

  group('mixed strokes — only section-scored ones are evaluated', () {
    late WaypointSectionScorer scorer;

    setUp(() {
      scorer = WaypointSectionScorer(
        letter: 'f',
        data: LetterFormationData(
          strokes: [
            // First stroke has no sections — not section-scored.
            ExpectedStroke(startRect: someRect),
            // Second stroke is section-scored.
            ExpectedStroke(
              startRect: someRect,
              sections: [section1, section2, section3],
            ),
          ],
          minRequiredStrokes: 2,
        ),
        bounds: bounds,
      );
    });

    test('only one observation produced for the section-scored stroke', () {
      final s1 = Stroke(const [Offset(50, 50)]);
      final s2 = Stroke(const [
        Offset(10, 10),
        Offset(150, 150),
        Offset(250, 250),
      ]);
      final result = scorer.score([s1, s2]);
      expect(result.observations.length, 1);
      expect(result.observations.single.strokeIndex, 1);
    });

    test('overallScore reflects only the section-scored stroke', () {
      final s1 = Stroke(const [Offset(50, 50)]);
      final s2 = Stroke(const [
        Offset(10, 10),
        Offset(150, 150),
        Offset(250, 250),
      ]);
      final result = scorer.score([s1, s2]);
      expect(result.overallScore, 1.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Expected string format
  // ---------------------------------------------------------------------------

  group('observation expected/observed format', () {
    late WaypointSectionScorer scorer;

    setUp(() {
      scorer = WaypointSectionScorer(
        letter: 'g',
        data: LetterFormationData(
          strokes: [
            ExpectedStroke(
              startRect: someRect,
              sections: [section1, section2],
            ),
          ],
          minRequiredStrokes: 1,
        ),
        bounds: bounds,
      );
    });

    test('expected string uses section numbers', () {
      final stroke = Stroke(const [Offset(10, 10), Offset(150, 150)]);
      final result = scorer.score([stroke]);
      expect(result.observations.single.expected,
          'section 1 → section 2');
    });

    test('observed string uses section numbers for hits', () {
      final stroke = Stroke(const [Offset(10, 10), Offset(150, 150)]);
      final result = scorer.score([stroke]);
      expect(result.observations.single.observed,
          'section 1 → section 2');
    });
  });
}
