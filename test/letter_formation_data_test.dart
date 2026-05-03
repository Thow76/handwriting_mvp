import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Serialisation round-trips — all 18 values across the three enums
  // ---------------------------------------------------------------------------

  group('StrokeDirection serialisation', () {
    const cases = {
      'topToBottom': StrokeDirection.topToBottom,
      'leftToRight': StrokeDirection.leftToRight,
      'clockwise': StrokeDirection.clockwise,
      'anticlockwise': StrokeDirection.anticlockwise,
      'compound': StrokeDirection.compound,
      'dot': StrokeDirection.dot,
    };

    for (final entry in cases.entries) {
      test('${entry.key} round-trips through .name / byName()', () {
        expect(entry.value.name, entry.key);
        expect(StrokeDirection.values.byName(entry.key), entry.value);
      });
    }

    test('byName() throws ArgumentError for unknown string', () {
      expect(
        () => StrokeDirection.values.byName('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('StrokeStartRegion serialisation', () {
    const cases = {
      'top': StrokeStartRegion.top,
      'middle': StrokeStartRegion.middle,
      'bottom': StrokeStartRegion.bottom,
    };

    for (final entry in cases.entries) {
      test('${entry.key} round-trips through .name / byName()', () {
        expect(entry.value.name, entry.key);
        expect(StrokeStartRegion.values.byName(entry.key), entry.value);
      });
    }

    test('byName() throws ArgumentError for unknown string', () {
      expect(
        () => StrokeStartRegion.values.byName('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

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
    test('can be created with compound direction and non-empty waypoints', () {
      final stroke = ExpectedStroke(
        primaryDirection: StrokeDirection.compound,
        startRegion: StrokeStartRegion.top,
        waypoints: [WaypointRegion.top, WaypointRegion.bottomLeft, WaypointRegion.top],
      );
      expect(stroke.primaryDirection, StrokeDirection.compound);
      expect(stroke.startRegion, StrokeStartRegion.top);
      expect(stroke.waypoints, [
        WaypointRegion.top,
        WaypointRegion.bottomLeft,
        WaypointRegion.top,
      ]);
    });

    test('defaults waypoints to empty list', () {
      final stroke = ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRegion: StrokeStartRegion.top,
      );
      expect(stroke.waypoints, isEmpty);
    });

    test('allows empty waypoints for non-compound direction', () {
      final stroke = ExpectedStroke(
        primaryDirection: StrokeDirection.leftToRight,
        startRegion: StrokeStartRegion.middle,
        waypoints: [],
      );
      expect(stroke.waypoints, isEmpty);
    });

    test('asserts that waypoints must be empty for non-compound directions', () {
      expect(
        () => ExpectedStroke(
          primaryDirection: StrokeDirection.topToBottom,
          startRegion: StrokeStartRegion.top,
          waypoints: [WaypointRegion.top],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts waypoints empty for leftToRight', () {
      expect(
        () => ExpectedStroke(
          primaryDirection: StrokeDirection.leftToRight,
          startRegion: StrokeStartRegion.middle,
          waypoints: [WaypointRegion.left],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts waypoints empty for dot', () {
      expect(
        () => ExpectedStroke(
          primaryDirection: StrokeDirection.dot,
          startRegion: StrokeStartRegion.top,
          waypoints: [WaypointRegion.top],
        ),
        throwsA(isA<AssertionError>()),
      );
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
            primaryDirection: StrokeDirection.topToBottom,
            startRegion: StrokeStartRegion.top,
          ),
          ExpectedStroke(
            primaryDirection: StrokeDirection.leftToRight,
            startRegion: StrokeStartRegion.middle,
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
            primaryDirection: StrokeDirection.anticlockwise,
            startRegion: StrokeStartRegion.top,
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
            primaryDirection: StrokeDirection.topToBottom,
            startRegion: StrokeStartRegion.top,
          ),
          ExpectedStroke(
            primaryDirection: StrokeDirection.dot,
            startRegion: StrokeStartRegion.top,
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
              primaryDirection: StrokeDirection.topToBottom,
              startRegion: StrokeStartRegion.top,
            ),
          ],
          minRequiredStrokes: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts that minRequiredStrokes cannot be negative', () {
      expect(
        () => LetterFormationData(
          strokes: [],
          minRequiredStrokes: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
