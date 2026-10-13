import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/anchor_builder.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/scoring_level.dart';
import 'package:handwriting_mvp/models/skeletonizer.dart';
import 'package:handwriting_mvp/models/template_cache.dart';
import 'package:handwriting_mvp/theme/app_theme.dart';
import 'package:handwriting_mvp/widgets/guide_markers.dart';
import 'package:handwriting_mvp/widgets/letter_canvas.dart';

const _anchors = [
  StrokeAnchors(
    strokeIndex: 0,
    start: Offset(50, 60),
    sectionPoints: [Offset(100, 120), Offset(150, 200)],
  ),
  StrokeAnchors(
    strokeIndex: 1,
    start: Offset(200, 60),
    sectionPoints: [Offset(220, 150)],
  ),
];

Future<List<StrokeAnchors>> _anchorsFor(String letter) async {
  final result = await TemplateCache.shared.prepare(
    letter: letter,
    fontFamily: LetterCanvas.fontFamily,
    fontSize: LetterCanvas.fontSize,
    guidelines: LetterCanvas.guidelines,
    canvasWidth: LetterCanvas.width,
  );
  return buildAnchors(
    data: letterFormationRegistry[letter]!,
    skeleton: Skeletonizer.skeletonize(result.mask),
    maskOrigin: result.bounds.topLeft,
    tightBounds: result.tightBounds!,
  );
}

void main() {
  setUpAll(() async {
    final bytes = File('fonts/Andika-Regular.ttf').readAsBytesSync();
    final loader = FontLoader(LetterCanvas.fontFamily)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  group('splineSamples', () {
    test('starts and ends on the first and last anchor', () {
      final s = splineSamples(const [Offset(0, 0), Offset(10, 10)]);
      expect(s.first, const Offset(0, 0));
      expect(s.last, const Offset(10, 10));
    });

    test('passes through every middle anchor', () {
      const pts = [
        Offset(0, 0),
        Offset(10, 20),
        Offset(30, 10),
        Offset(40, 40),
      ];
      final s = splineSamples(pts, perSegment: 10);
      expect(s.length, 31);
      for (var i = 0; i < pts.length; i++) {
        expect((s[i * 10] - pts[i]).distance, lessThan(0.001));
      }
    });
  });

  group('paintGuideMarkers', () {
    int drawnPixels(ScoringLevel level) {
      final recorder = ui.PictureRecorder();
      paintGuideMarkers(Canvas(recorder), _anchors, level);
      return recorder.endRecording().approximateBytesUsed;
    }

    test('level 1 paints nothing; higher levels paint more', () {
      expect(levelShowsMarkers(ScoringLevel.shapeOnly), isFalse);
      expect(
        drawnPixels(ScoringLevel.shapeOnly),
        (() {
          final r = ui.PictureRecorder();
          Canvas(r);
          return r.endRecording().approximateBytesUsed;
        })(),
      );
      expect(
        drawnPixels(ScoringLevel.shapeStartAndPath),
        greaterThan(drawnPixels(ScoringLevel.shapeAndStart)),
      );
    });
  });

  Future<void> pumpCanvas(
    WidgetTester tester, {
    required bool showModel,
    required ScoringLevel level,
    String letter = 'k',
    List<StrokeAnchors> anchors = _anchors,
    GlobalKey? key,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: LetterCanvas(
              letter: letter,
              strokes: const [],
              showModel: showModel,
              anchors: anchors,
              level: level,
              onStrokeStart: (_) {},
              onStrokeUpdate: (_) {},
              onStrokeEnd: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('markers follow the eye toggle', (tester) async {
    final key = GlobalKey();
    Future<List<int>> snapshot() async {
      late ByteData bytes;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage();
        bytes = (await image.toByteData())!;
      });
      return bytes.buffer.asUint8List().toList();
    }

    await pumpCanvas(
      tester,
      showModel: true,
      level: ScoringLevel.shapeAndStart,
      key: key,
    );
    final withMarkers = await snapshot();
    await pumpCanvas(
      tester,
      showModel: true,
      level: ScoringLevel.shapeOnly,
      key: key,
    );
    final level1 = await snapshot();
    await pumpCanvas(
      tester,
      showModel: false,
      level: ScoringLevel.shapeAndStart,
      key: key,
    );
    final hidden = await snapshot();
    await pumpCanvas(
      tester,
      showModel: false,
      level: ScoringLevel.shapeOnly,
      key: key,
    );
    final hiddenLevel1 = await snapshot();

    expect(withMarkers, isNot(level1));
    expect(hidden, hiddenLevel1);
  });

  testWidgets(
    'renders all 26 letters with L3 markers to build/guide_markers',
    tags: 'guide_markers',
    (tester) async {
      final letters = 'abcdefghijklmnopqrstuvwxyz'.split('');
      final dir = Directory('build/guide_markers')..createSync(recursive: true);
      final images = <ui.Image>[];
      for (final letter in letters) {
        final anchors = await tester.runAsync(() => _anchorsFor(letter));
        final key = GlobalKey();
        await pumpCanvas(
          tester,
          letter: letter,
          showModel: true,
          level: ScoringLevel.shapeStartAndPath,
          anchors: anchors!,
          key: key,
        );
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage();
          images.add(image);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${dir.path}/$letter.png',
          ).writeAsBytesSync(png!.buffer.asUint8List());
        });
      }

      await tester.runAsync(() async {
        const cols = 7;
        const cell = 300.0;
        final rows = (letters.length / cols).ceil();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, cols * cell, rows * cell),
          Paint()..color = AppColors.ground,
        );
        for (var i = 0; i < images.length; i++) {
          canvas.drawImage(
            images[i],
            Offset((i % cols) * cell, (i ~/ cols) * cell),
            Paint(),
          );
        }
        final sheet = await recorder.endRecording().toImage(
          (cols * cell).toInt(),
          (rows * cell).toInt(),
        );
        final png = await sheet.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${dir.path}/contact_sheet.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      });

      expect(File('${dir.path}/contact_sheet.png').existsSync(), isTrue);
    },
  );
}
