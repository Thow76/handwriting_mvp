import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';

void main() {
  group('StrokeDirection', () {
    test('has exactly six values', () {
      expect(StrokeDirection.values.length, 6);
    });

    test('contains topToBottom', () {
      expect(StrokeDirection.values, contains(StrokeDirection.topToBottom));
    });

    test('contains leftToRight', () {
      expect(StrokeDirection.values, contains(StrokeDirection.leftToRight));
    });

    test('contains clockwise', () {
      expect(StrokeDirection.values, contains(StrokeDirection.clockwise));
    });

    test('contains anticlockwise', () {
      expect(StrokeDirection.values, contains(StrokeDirection.anticlockwise));
    });

    test('contains compound', () {
      expect(StrokeDirection.values, contains(StrokeDirection.compound));
    });

    test('contains dot', () {
      expect(StrokeDirection.values, contains(StrokeDirection.dot));
    });

    test('values are in declaration order', () {
      expect(StrokeDirection.values, [
        StrokeDirection.topToBottom,
        StrokeDirection.leftToRight,
        StrokeDirection.clockwise,
        StrokeDirection.anticlockwise,
        StrokeDirection.compound,
        StrokeDirection.dot,
      ]);
    });
  });

  group('StrokeStartRegion', () {
    test('has exactly three values', () {
      expect(StrokeStartRegion.values.length, 3);
    });

    test('contains top', () {
      expect(StrokeStartRegion.values, contains(StrokeStartRegion.top));
    });

    test('contains middle', () {
      expect(StrokeStartRegion.values, contains(StrokeStartRegion.middle));
    });

    test('contains bottom', () {
      expect(StrokeStartRegion.values, contains(StrokeStartRegion.bottom));
    });

    test('values are in declaration order', () {
      expect(StrokeStartRegion.values, [
        StrokeStartRegion.top,
        StrokeStartRegion.middle,
        StrokeStartRegion.bottom,
      ]);
    });
  });

  group('WaypointRegion', () {
    test('has exactly nine values', () {
      expect(WaypointRegion.values.length, 9);
    });

    test('contains topLeft', () {
      expect(WaypointRegion.values, contains(WaypointRegion.topLeft));
    });

    test('contains top', () {
      expect(WaypointRegion.values, contains(WaypointRegion.top));
    });

    test('contains topRight', () {
      expect(WaypointRegion.values, contains(WaypointRegion.topRight));
    });

    test('contains left', () {
      expect(WaypointRegion.values, contains(WaypointRegion.left));
    });

    test('contains middle', () {
      expect(WaypointRegion.values, contains(WaypointRegion.middle));
    });

    test('contains right', () {
      expect(WaypointRegion.values, contains(WaypointRegion.right));
    });

    test('contains bottomLeft', () {
      expect(WaypointRegion.values, contains(WaypointRegion.bottomLeft));
    });

    test('contains bottom', () {
      expect(WaypointRegion.values, contains(WaypointRegion.bottom));
    });

    test('contains bottomRight', () {
      expect(WaypointRegion.values, contains(WaypointRegion.bottomRight));
    });

    test('values are in declaration order', () {
      expect(WaypointRegion.values, [
        WaypointRegion.topLeft,
        WaypointRegion.top,
        WaypointRegion.topRight,
        WaypointRegion.left,
        WaypointRegion.middle,
        WaypointRegion.right,
        WaypointRegion.bottomLeft,
        WaypointRegion.bottom,
        WaypointRegion.bottomRight,
      ]);
    });
  });
}
