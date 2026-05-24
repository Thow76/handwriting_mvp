import 'package:handwriting_mvp/models/stroke_formation_enums.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';

/// Test-only mapping from the deprecated [StrokeStartRegion] to a placeholder
/// [StrokeStartRect] using the same vertical-thirds bands the registry uses
/// during the migration parallel-field period.
///
/// Used so tests that still drive expected strokes off [StrokeStartRegion] can
/// supply a consistent [StrokeStartRect] without duplicating the switch.
StrokeStartRect startRectForRegion(StrokeStartRegion region) => switch (region) {
      StrokeStartRegion.top =>
        const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
      StrokeStartRegion.middle => const StrokeStartRect(
          minX: 0.0,
          maxX: 1.0,
          minY: 1.0 / 3.0,
          maxY: 2.0 / 3.0,
        ),
      StrokeStartRegion.bottom =>
        const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 2.0 / 3.0, maxY: 1.0),
    };
