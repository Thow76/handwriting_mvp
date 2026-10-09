import 'dart:collection';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/guidelines.dart';
import 'package:handwriting_mvp/models/score_integrator.dart';
import 'package:handwriting_mvp/models/skeletonizer.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/template_rasterizer.dart';

/// Guards the two fixes from issue #234 against the real Andika letters, at the
/// size the Practice screen uses (font 180 on the 300 canvas):
///
/// 1. Coverage must not read too high. A perfect centre-line trace at a
///    fractional position inks a band 4 cells wide, so the "ideal trace" used to
///    normalise coverage has to be 4 wide too. Otherwise a letter that is only
///    two thirds drawn already reads about 90%.
/// 2. The skeleton of a letter whose ink touches the edge of the mask (the
///    stem tops of b, d and l) must not grow a flat bar along that edge.
typedef _Pixel = (int, int);

void main() {
  const fontFamily = 'Andika';
  const fontSize = 180.0;
  const canvasSize = 300.0;

  // A real pen almost never lands on a cell centre, so trace at a fractional
  // offset from the centre, as a finger would.
  const traceOffset = 0.3;

  setUpAll(() async {
    final bytes = File('fonts/Andika-Regular.ttf').readAsBytesSync();
    final loader = FontLoader(fontFamily)
      ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    await loader.load();
  });

  Future<TemplateRasterResult> template(WidgetTester tester, String letter) {
    final guidelines = Guidelines.fromFont(
      canvasHeight: canvasSize,
      fontFamily: fontFamily,
      fontSize: fontSize,
    );
    return tester
        .runAsync(
          () => TemplateRasterizer.rasterize(
            letter: letter,
            fontFamily: fontFamily,
            fontSize: fontSize,
            guidelines: guidelines,
            canvasWidth: canvasSize,
          ),
        )
        .then((r) => r!);
  }

  group('Coverage is not inflated for a real "b" (Andika, font 180)', () {
    late TemplateRasterResult b;
    late List<_Pixel> path;

    setUp(() => path = const []);

    Future<void> prepare(WidgetTester tester) async {
      b = await template(tester, 'b');
      path = _penPathForB(Skeletonizer.skeletonize(b.mask));
    }

    // Draws the first [fraction] of the path (counted in distinct skeleton
    // pixels) and returns the normalised Coverage.
    double coverageOfFirst(double fraction) {
      final distinct = path.toSet().length;
      final seen = <_Pixel>{};
      final points = <Offset>[];
      for (final p in path) {
        seen.add(p);
        points.add(
          Offset(
            b.bounds.left + p.$2 + 0.5 + traceOffset,
            b.bounds.top + p.$1 + 0.5 + traceOffset,
          ),
        );
        if (seen.length / distinct >= fraction) break;
      }
      return ScoreIntegrator.score(
        referenceMask: b.mask,
        bounds: b.bounds,
        strokes: [Stroke(points)],
      ).coverage;
    }

    testWidgets('full trace reads at least 90%', (tester) async {
      await prepare(tester);
      expect(coverageOfFirst(1.0), greaterThanOrEqualTo(0.90));
    });

    testWidgets('two thirds drawn reads between 55% and 72%', (tester) async {
      await prepare(tester);
      expect(coverageOfFirst(2 / 3), inInclusiveRange(0.55, 0.72));
    });

    testWidgets('half drawn reads between 38% and 52%', (tester) async {
      await prepare(tester);
      expect(coverageOfFirst(0.5), inInclusiveRange(0.38, 0.52));
    });
  });

  group('Skeleton has no flat bar along the top edge', () {
    for (final letter in ['b', 'd', 'l']) {
      testWidgets('$letter: no horizontal run longer than 5 in its top row', (
        tester,
      ) async {
        final t = await template(tester, letter);
        // These letters' ink touches the top row of the mask.
        expect(t.mask.first.any((p) => p), isTrue);

        final skeleton = Skeletonizer.skeletonize(t.mask);
        expect(skeleton.length, t.mask.length);
        expect(skeleton.first.length, t.mask.first.length);

        // Both the mask's first row and the first row that has any skeleton.
        final topRow = skeleton.indexWhere((row) => row.any((p) => p));
        expect(topRow, greaterThanOrEqualTo(0));
        expect(_longestRun(skeleton[0]), lessThanOrEqualTo(5));
        expect(_longestRun(skeleton[topRow]), lessThanOrEqualTo(5));
      });
    }
  });
}

int _longestRun(List<bool> row) {
  var best = 0;
  var run = 0;
  for (final p in row) {
    run = p ? run + 1 : 0;
    if (run > best) best = run;
  }
  return best;
}

List<_Pixel> _bfs(
  List<List<bool>> sk,
  _Pixel from,
  _Pixel to,
  Set<_Pixel> blocked,
) {
  final prev = <_Pixel, _Pixel>{from: from};
  final queue = Queue<_Pixel>()..add(from);
  while (queue.isNotEmpty) {
    final cur = queue.removeFirst();
    if (cur == to) break;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final n = (cur.$1 + dr, cur.$2 + dc);
        if (n == cur ||
            n.$1 < 0 ||
            n.$2 < 0 ||
            n.$1 >= sk.length ||
            n.$2 >= sk[0].length ||
            !sk[n.$1][n.$2] ||
            prev.containsKey(n) ||
            blocked.contains(n)) {
          continue;
        }
        prev[n] = cur;
        queue.add(n);
      }
    }
  }
  final path = <_Pixel>[];
  for (var c = to; c != from; c = prev[c]!) {
    path.add(c);
  }
  path.add(from);
  return path.reversed.toList();
}

/// The way a child writes a "b": the stem top to bottom, back up the stem to
/// where the bowl starts, then the bowl up, over and round to the stem foot.
///
/// Built from the skeleton of "b" so it follows the real centre-line. The stem
/// is the skeleton in the few columns around its topmost pixel; the bowl is
/// everything to the right of it.
List<_Pixel> _penPathForB(List<List<bool>> sk) {
  final pixels = [
    for (var r = 0; r < sk.length; r++)
      for (var c = 0; c < sk[r].length; c++)
        if (sk[r][c]) (r, c),
  ];
  final top = pixels.first; // row-major: the top of the stem
  bool inStem(_Pixel p) => p.$2 >= top.$2 - 1 && p.$2 <= top.$2 + 2;
  final stemPixels = pixels.where(inStem).toList();
  final foot = stemPixels.reduce((a, b) => b.$1 > a.$1 ? b : a);
  final stem = _bfs(sk, top, foot, {});

  final stemSet = stemPixels.toSet();
  bool touchesStem(_Pixel p) => [
    for (var dr = -1; dr <= 1; dr++)
      for (var dc = -1; dc <= 1; dc++) (p.$1 + dr, p.$2 + dc),
  ].any(stemSet.contains);
  final bowlPixels = pixels.where((p) => !inStem(p)).toList();
  final joins = bowlPixels.where(touchesStem).toList();
  final bowlStart = joins.reduce((a, b) => b.$1 < a.$1 ? b : a);
  final bowlEnd = joins.reduce((a, b) => b.$1 > a.$1 ? b : a);
  final bowl = _bfs(sk, bowlStart, bowlEnd, stemSet);

  // Where on the stem the pen turns round to go up to the bowl.
  int distSq(_Pixel a, _Pixel b) =>
      (a.$1 - b.$1) * (a.$1 - b.$1) + (a.$2 - b.$2) * (a.$2 - b.$2);
  var upFrom = 0;
  for (var i = 0; i < stem.length; i++) {
    if (distSq(stem[i], bowlStart) < distSq(stem[upFrom], bowlStart)) {
      upFrom = i;
    }
  }
  final retrace = stem.sublist(upFrom).reversed.skip(1);
  return [...stem, ...retrace, ...bowl];
}
