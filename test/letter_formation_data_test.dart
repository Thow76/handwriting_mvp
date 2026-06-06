import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';

void main() {
  group('WaypointRegion serialisation', () {
    const cases = {
      'topLeft': WaypointRegion.topLeft,
      'top': WaypointRegion.top,
      'topRight': WaypointRegion.topRight,
      'left': WaypointRegion.left,
      'middle': WaypointRegion.middle,
      'right': WaypointRegion.right,
      'bottomLeft': WaypointRegion.bottomLeft,
      'bottom': WaypointRegion.bottom,
      'bottomRight': WaypointRegion.bottomRight,
    };

    for (final entry in cases.entries) {
      test('${entry.key} round-trips through .name / byName()', () {
        expect(entry.value.name, entry.key);
        expect(WaypointRegion.values.byName(entry.key), entry.value);
      });
    }

    test('byName() throws ArgumentError for unknown string', () {
      expect(
        () => WaypointRegion.values.byName('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // ExpectedStroke
  // ---------------------------------------------------------------------------

  group('ExpectedStroke', () {
    test('can be created with non-empty waypoints', () {
      final stroke = ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.0,
          maxX: 1.0,
          minY: 0.0,
          maxY: 1.0 / 3.0,
        ),
        waypoints: [
          WaypointRegion.top,
          WaypointRegion.bottomLeft,
          WaypointRegion.top,
        ],
      );
      expect(stroke.waypoints, [
        WaypointRegion.top,
        WaypointRegion.bottomLeft,
        WaypointRegion.top,
      ]);
    });

    test('defaults waypoints to empty list', () {
      final stroke = ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.0,
          maxX: 1.0,
          minY: 0.0,
          maxY: 1.0 / 3.0,
        ),
      );
      expect(stroke.waypoints, isEmpty);
    });

    test('allows explicitly empty waypoints', () {
      final stroke = ExpectedStroke(
        startRect: const StrokeStartRect(
          minX: 0.0,
          maxX: 1.0,
          minY: 1.0 / 3.0,
          maxY: 2.0 / 3.0,
        ),
        waypoints: [],
      );
      expect(stroke.waypoints, isEmpty);
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
