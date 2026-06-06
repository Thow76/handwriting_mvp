import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';

// These tests lock each enum's full public surface — both the exact set of
// values and their declaration order — in a single assertion. Order is pinned
// deliberately: downstream serialisation may use `EnumName.values.byName()`
// or `.index`, and per-letter data files will list values by name, so a silent
// reorder or rename should fail loudly here. If a value is intentionally added,
// removed, or reordered, update the expected list and the scope document
// together.
void main() {
  group('WaypointRegion', () {
    test('has the expected values in declaration order', () {
      expect(WaypointRegion.values, const [
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
