import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/anchor_builder.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/skeletonizer.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';
import 'package:handwriting_mvp/models/template_cache.dart';
import 'package:handwriting_mvp/models/waypoint_section.dart';
import 'package:handwriting_mvp/widgets/letter_canvas.dart';

StrokeStartRect _rect(double x0, double x1, double y0, double y1) =>
    StrokeStartRect(minX: x0, maxX: x1, minY: y0, maxY: y1);

void main() {
  group('buildAnchors (synthetic)', () {
    final bounds = Rect.fromLTWH(10, 20, 10, 10);

    test('snaps to nearest skeleton pixel inside the zone', () {
      final skeleton = List.generate(10, (_) => List.filled(10, false));
      skeleton[5][2] = true; // inside zone, nearest the centre
      skeleton[5][4] = true; // inside zone, further from the centre
      skeleton[9][9] = true; // outside the zone
      final data = LetterFormationData(
        minRequiredStrokes: 1,
        strokes: [
          ExpectedStroke(
            startRect: _rect(0, 0.2, 0, 0.2),
            sections: [
              WaypointSection(number: 1, rect: _rect(0.1, 0.5, 0.4, 0.6)),
            ],
          ),
        ],
      );
      final out = buildAnchors(
        data: data,
        skeleton: skeleton,
        maskOrigin: const Offset(10, 20),
        tightBounds: bounds,
      );
      expect(out.single.start, const Offset(11, 21));
      expect(out.single.sectionPoints.single, const Offset(12.5, 25.5));
    });

    test('falls back to zone centre; skips strokes without sections; '
        'orders by section number', () {
      final skeleton = List.generate(10, (_) => List.filled(10, false));
      final data = LetterFormationData(
        minRequiredStrokes: 1,
        strokes: [
          ExpectedStroke(startRect: _rect(0, 0.2, 0, 0.2)),
          ExpectedStroke(
            startRect: _rect(0, 0.2, 0, 0.2),
            sections: [
              WaypointSection(number: 2, rect: _rect(0.6, 1.0, 0.6, 1.0)),
              WaypointSection(number: 1, rect: _rect(0.0, 0.4, 0.0, 0.4)),
            ],
          ),
        ],
      );
      final out = buildAnchors(
        data: data,
        skeleton: skeleton,
        maskOrigin: const Offset(10, 20),
        tightBounds: bounds,
      );
      expect(out.length, 1);
      expect(out.single.strokeIndex, 1);
      expect(out.single.sectionPoints, const [Offset(12, 22), Offset(18, 28)]);
    });
  });

  testWidgets(
    'builds anchors for all 26 letters; point count = section count',
    (tester) async {
      await tester.runAsync(() async {
        final cache = TemplateCache();
        for (final letter in 'abcdefghijklmnopqrstuvwxyz'.split('')) {
          final data = letterFormationRegistry[letter]!;
          final result = await cache.prepare(
            letter: letter,
            fontFamily: LetterCanvas.fontFamily,
            fontSize: LetterCanvas.fontSize,
            guidelines: LetterCanvas.guidelines,
            canvasWidth: LetterCanvas.width,
          );
          final tight = result.tightBounds!;
          final anchors = buildAnchors(
            data: data,
            skeleton: Skeletonizer.skeletonize(result.mask),
            maskOrigin: result.bounds.topLeft,
            tightBounds: tight,
          );
          final withSections = [
            for (var i = 0; i < data.strokes.length; i++)
              if (data.strokes[i].sections.isNotEmpty) i,
          ];
          expect(
            anchors.map((a) => a.strokeIndex).toList(),
            withSections,
            reason: letter,
          );
          for (final a in anchors) {
            expect(
              a.sectionPoints.length,
              data.strokes[a.strokeIndex].sections.length,
              reason: letter,
            );
            for (final p in [a.start, ...a.sectionPoints]) {
              expect(
                tight.inflate(1).contains(p),
                isTrue,
                reason: '$letter $p',
              );
            }
          }
        }
      });
    },
  );
}
