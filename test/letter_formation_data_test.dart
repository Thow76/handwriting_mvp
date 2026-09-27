import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';
import 'package:handwriting_mvp/models/waypoint_section.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ExpectedStroke
  // ---------------------------------------------------------------------------

  group('ExpectedStroke', () {
    test('defaults sections to empty list', () {
      final stroke = ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.0,
          maxX: 1.0,
          minY: 0.0,
          maxY: 1.0 / 3.0,
        ),
      );
      expect(stroke.sections, isEmpty);
    });

    test('can be created with non-empty sections', () {
      final stroke = ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.0,
          maxX: 1.0,
          minY: 0.0,
          maxY: 1.0 / 3.0,
        ),
        sections: [
          WaypointSection(
            number: 1,
            rect: const StrokeStartRect(
              minX: 0.0,
              maxX: 0.5,
              minY: 0.0,
              maxY: 0.5,
            ),
          ),
          WaypointSection(
            number: 2,
            rect: const StrokeStartRect(
              minX: 0.5,
              maxX: 1.0,
              minY: 0.5,
              maxY: 1.0,
            ),
          ),
        ],
      );
      expect(stroke.sections.length, 2);
      expect(stroke.sections[0].number, 1);
      expect(stroke.sections[1].number, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // LetterFormationData
  // ---------------------------------------------------------------------------

  group('LetterFormationData', () {
    test('canonicalStrokeCount equals strokes.length', () {
      final data = LetterFormationData(
        strokes: [
          ExpectedStroke(
            startRect: const StrokeStartRect(
              minX: 0.0,
              maxX: 1.0,
              minY: 0.0,
              maxY: 1.0 / 3.0,
            ),
          ),
          ExpectedStroke(
            startRect: const StrokeStartRect(
              minX: 0.0,
              maxX: 1.0,
              minY: 1.0 / 3.0,
              maxY: 2.0 / 3.0,
            ),
          ),
        ],
        minRequiredStrokes: 1,
      );
      expect(data.canonicalStrokeCount, 2);
      expect(data.strokes.length, 2);
    });

    test('accepts minRequiredStrokes == 1', () {
      final data = LetterFormationData(
        strokes: [
          ExpectedStroke(
            startRect: const StrokeStartRect(
              minX: 0.0,
              maxX: 1.0,
              minY: 0.0,
              maxY: 1.0 / 3.0,
            ),
          ),
        ],
        minRequiredStrokes: 1,
      );
      expect(data.minRequiredStrokes, 1);
    });

    test('accepts minRequiredStrokes > 1', () {
      final data = LetterFormationData(
        strokes: [
          ExpectedStroke(
            startRect: const StrokeStartRect(
              minX: 0.0,
              maxX: 1.0,
              minY: 0.0,
              maxY: 1.0 / 3.0,
            ),
          ),
          ExpectedStroke(
            startRect: const StrokeStartRect(
              minX: 0.0,
              maxX: 1.0,
              minY: 0.0,
              maxY: 1.0 / 3.0,
            ),
          ),
        ],
        minRequiredStrokes: 2,
      );
      expect(data.minRequiredStrokes, 2);
    });

    test('asserts that minRequiredStrokes must be >= 1', () {
      expect(
        () => LetterFormationData(
          strokes: [
            ExpectedStroke(
              startRect: const StrokeStartRect(
                minX: 0.0,
                maxX: 1.0,
                minY: 0.0,
                maxY: 1.0 / 3.0,
              ),
            ),
          ],
          minRequiredStrokes: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts that minRequiredStrokes cannot be negative', () {
      expect(
        () => LetterFormationData(strokes: [], minRequiredStrokes: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
