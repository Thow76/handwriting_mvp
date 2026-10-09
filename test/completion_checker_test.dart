import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/completion_checker.dart';
import 'package:handwriting_mvp/models/guidelines.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/score_builder.dart';
import 'package:handwriting_mvp/models/skeletonizer.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';
import 'package:handwriting_mvp/models/template_rasterizer.dart';
import 'package:handwriting_mvp/models/waypoint_section.dart';

WaypointSection _section(
  int number,
  double minX,
  double maxX, [
  double minY = 0,
  double maxY = 1,
]) => WaypointSection(
  number: number,
  rect: StrokeStartRect(minX: minX, maxX: maxX, minY: minY, maxY: maxY),
);

const _start = StrokeStartRect(minX: 0, maxX: 1, minY: 0, maxY: 1);

LetterFormationData _letter(List<List<WaypointSection>> perStroke) =>
    LetterFormationData(
      minRequiredStrokes: 1,
      strokes: [
        for (final sections in perStroke)
          ExpectedStroke(startRect: _start, sections: sections),
      ],
    );

void main() {
  final bounds = const Rect.fromLTWH(0, 0, 100, 100);

  // Three vertical bands: 1 = left, 2 = middle, 3 = right.
  final threeBands = _letter([
    [_section(1, 0, 0.33), _section(2, 0.33, 0.66), _section(3, 0.66, 1)],
  ]);

  Stroke at(double x) => Stroke([Offset(x, 50)]);

  group('CompletionChecker', () {
    test('every section entered in the wrong order is complete', () {
      final result = CompletionChecker(
        data: threeBands,
        bounds: bounds,
      ).check([at(80), at(10), at(50)]);
      expect(result.complete, isTrue);
      expect(result.missingSections, isEmpty);
    });

    test('sections spread over several strokes still count', () {
      final data = _letter([
        [_section(1, 0, 0.5)],
        [_section(2, 0.5, 1)],
      ]);
      final result = CompletionChecker(
        data: data,
        bounds: bounds,
      ).check([at(80), at(10)]);
      expect(result.complete, isTrue);
    });

    test('a section never entered is reported by number', () {
      final result = CompletionChecker(
        data: threeBands,
        bounds: bounds,
      ).check([at(10), at(80)]);
      expect(result.complete, isFalse);
      expect(result.missingSections, [2]);
    });

    test('several missing sections are listed in ascending order', () {
      final result = CompletionChecker(
        data: threeBands,
        bounds: bounds,
      ).check([at(50)]);
      expect(result.complete, isFalse);
      expect(result.missingSections, [1, 3]);
    });

    test('no strokes at all: every section is missing', () {
      final result = CompletionChecker(
        data: threeBands,
        bounds: bounds,
      ).check(const []);
      expect(result.complete, isFalse);
      expect(result.missingSections, [1, 2, 3]);
    });

    test('a segment that crosses a small section without a point in it '
        'counts as entering it', () {
      // Section 2 is only 2 px wide (x 49–51); neither end point is inside.
      final data = _letter([
        [_section(1, 0, 0.1), _section(2, 0.49, 0.51), _section(3, 0.9, 1)],
      ]);
      final jump = Stroke(const [Offset(5, 50), Offset(95, 50)]);
      final result = CompletionChecker(
        data: data,
        bounds: bounds,
      ).check([jump]);
      expect(result.complete, isTrue);
    });

    test('points of different strokes are not joined by a segment', () {
      final data = _letter([
        [_section(1, 0, 0.1), _section(2, 0.49, 0.51), _section(3, 0.9, 1)],
      ]);
      final result = CompletionChecker(
        data: data,
        bounds: bounds,
      ).check([at(5), at(95)]);
      expect(result.complete, isFalse);
      expect(result.missingSections, [2]);
    });

    test('a letter with no sections is complete', () {
      final result = CompletionChecker(
        data: _letter([[]]),
        bounds: bounds,
      ).check(const []);
      expect(result.complete, isTrue);
      expect(result.missingSections, isEmpty);
    });
  });

  group('Real Andika letters (font 180 on the 300 canvas)', () {
    const fontFamily = 'Andika';
    const fontSize = 180.0;
    const canvasSize = 300.0;
    var fontLoaded = false;

    setUpAll(() async {
      final file = File('fonts/Andika-Regular.ttf');
      if (!file.existsSync()) return;
      final bytes = file.readAsBytesSync();
      final loader = FontLoader(
        fontFamily,
      )..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
      await loader.load();
      fontLoaded = true;
    });

    // Traces the letter's centre line (its skeleton), keeping only the pixels
    // [keep] accepts, given as fractions of the tight ink bounds. Each pixel is
    // its own one-point stroke so no segment can bridge a gap.
    Future<bool?> isComplete(
      WidgetTester tester,
      String letter,
      bool Function(double rx, double ry) keep,
    ) async {
      if (!fontLoaded) return null;
      final template = (await tester.runAsync(
        () => TemplateRasterizer.rasterize(
          letter: letter,
          fontFamily: fontFamily,
          fontSize: fontSize,
          guidelines: Guidelines.fromFont(
            canvasHeight: canvasSize,
            fontFamily: fontFamily,
            fontSize: fontSize,
          ),
          canvasWidth: canvasSize,
        ),
      ))!;
      final tight = template.tightBounds ?? template.bounds;
      final skeleton = Skeletonizer.skeletonize(template.mask);
      final strokes = <Stroke>[];
      for (var row = 0; row < skeleton.length; row++) {
        for (var col = 0; col < skeleton[row].length; col++) {
          if (!skeleton[row][col]) continue;
          final p = Offset(
            template.bounds.left + col + 0.8,
            template.bounds.top + row + 0.8,
          );
          final rx = (p.dx - tight.left) / tight.width;
          final ry = (p.dy - tight.top) / tight.height;
          if (keep(rx, ry)) strokes.add(Stroke([p]));
        }
      }
      final result = buildScoreResult(
        templateResult: template,
        strokes: strokes,
        letter: letter,
      );
      return result.completion!.complete;
    }

    testWidgets('a: a full centre-line trace is complete', (tester) async {
      final done = await isComplete(tester, 'a', (_, _) => true);
      if (done == null) return markTestSkipped('Andika font did not load');
      expect(done, isTrue);
    });

    testWidgets('a: the bowl alone, with no stem, is not complete', (
      tester,
    ) async {
      final done = await isComplete(tester, 'a', (rx, _) => rx < 0.65);
      if (done == null) return markTestSkipped('Andika font did not load');
      expect(done, isFalse);
    });

    testWidgets('b: a full centre-line trace is complete', (tester) async {
      final done = await isComplete(tester, 'b', (_, _) => true);
      if (done == null) return markTestSkipped('Andika font did not load');
      expect(done, isTrue);
    });

    testWidgets('b: the stem plus the top of the bowl is not complete', (
      tester,
    ) async {
      final done = await isComplete(
        tester,
        'b',
        (rx, ry) => rx < 0.25 || ry < 0.6,
      );
      if (done == null) return markTestSkipped('Andika font did not load');
      expect(done, isFalse);
    });
  });
}
