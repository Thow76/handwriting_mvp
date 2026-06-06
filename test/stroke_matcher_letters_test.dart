import 'dart:io';
import 'dart:ui' show Offset, Rect;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/guidelines.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_matcher.dart';
import 'package:handwriting_mvp/models/stroke_start_scorer.dart';
import 'package:handwriting_mvp/models/template_rasterizer.dart';

/// Regression coverage for the order-based [matchStrokes].
///
/// For every multi-stroke letter, a *correctly-ordered* trace is built from
/// the real glyph's tight bounds and the pairing is asserted to be the
/// identity `[0, 1]` (observed stroke i ↔ expected stroke i).
///
/// The traces are positioned where each stroke actually sits, so these tests
/// also guard against any reintroduction of spatial (nearest-centroid)
/// matching: under that scheme the stem-first letters (f, t, i, b, d, h, k)
/// mis-pair to `[1, 0]`, and the remaining letters (j, x, g, p, q) only paired
/// correctly by coincidence — all are pinned here so a future pairing
/// regression is caught.
void main() {
  const fontFamily = 'Andika';
  const fontSize = 120.0;

  setUpAll(() async {
    final bytes = File('fonts/Andika-Regular.ttf').readAsBytesSync();
    final loader = FontLoader(fontFamily)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  final guidelines = Guidelines.fromFont(
    canvasHeight: 600.0,
    fontFamily: fontFamily,
    fontSize: fontSize,
  );

  // Correctly-ordered traces in canonical stroke order, expressed as fractions
  // of the letter's tight ink bounds. Each inner list is one stroke; the points
  // follow the real letterform path so a spatial matcher would (mis)pair them
  // exactly as documented above.
  final traces = <String, List<List<List<double>>>>{
    // stem/hook (top → baseline) then crossbar (left → right)
    'f': [
      [[0.86, 0.03], [0.41, 0.13], [0.40, 0.40], [0.40, 0.95]],
      [[0.02, 0.30], [0.50, 0.31], [0.95, 0.31]],
    ],
    // stem (top → baseline) then crossbar (left → right)
    't': [
      [[0.55, 0.02], [0.55, 0.50], [0.55, 0.95]],
      [[0.05, 0.30], [0.45, 0.30], [0.85, 0.30]],
    ],
    // stem (x-height → baseline) then dot (top)
    'i': [
      [[0.50, 0.30], [0.50, 0.60], [0.50, 0.98]],
      [[0.50, 0.02], [0.55, 0.06], [0.50, 0.10]],
    ],
    // stem (x-height → descender) then dot (top)
    'j': [
      [[0.55, 0.25], [0.55, 0.60], [0.30, 0.98]],
      [[0.55, 0.02], [0.60, 0.06], [0.55, 0.10]],
    ],
    // stem (top → baseline) then right-opening bowl
    'b': [
      [[0.10, 0.02], [0.10, 0.50], [0.10, 0.98]],
      [[0.10, 0.50], [0.55, 0.55], [0.55, 0.98], [0.10, 0.98]],
    ],
    // stem (top → baseline) then left-opening oval
    'd': [
      [[0.85, 0.02], [0.85, 0.50], [0.85, 0.98]],
      [[0.85, 0.50], [0.40, 0.55], [0.40, 0.95], [0.85, 0.90]],
    ],
    // stem (top → baseline) then compound arch
    'h': [
      [[0.10, 0.02], [0.10, 0.50], [0.10, 0.98]],
      [[0.10, 0.50], [0.50, 0.45], [0.85, 0.60], [0.85, 0.98]],
    ],
    // stem (top → baseline) then compound kick
    'k': [
      [[0.10, 0.02], [0.10, 0.50], [0.10, 0.98]],
      [[0.80, 0.45], [0.30, 0.65], [0.85, 0.98]],
    ],
    // diagonal TL → BR then diagonal TR → BL
    'x': [
      [[0.05, 0.05], [0.50, 0.50], [0.95, 0.95]],
      [[0.95, 0.05], [0.50, 0.50], [0.05, 0.95]],
    ],
    // left-opening oval then descending tail
    'g': [
      [[0.85, 0.10], [0.40, 0.10], [0.40, 0.55], [0.85, 0.55]],
      [[0.85, 0.10], [0.85, 0.70], [0.40, 0.98]],
    ],
    // stem (top → descender) then right-opening bowl
    'p': [
      [[0.10, 0.10], [0.10, 0.55], [0.10, 0.98]],
      [[0.10, 0.10], [0.55, 0.15], [0.55, 0.50], [0.10, 0.55]],
    ],
    // left-opening oval then descending stem
    'q': [
      [[0.80, 0.10], [0.40, 0.12], [0.40, 0.45], [0.80, 0.45]],
      [[0.92, 0.10], [0.92, 0.55], [0.92, 0.98]],
    ],
  };

  Stroke fromRel(Rect tb, List<List<double>> rel) => Stroke([
        for (final p in rel)
          Offset(tb.left + p[0] * tb.width, tb.top + p[1] * tb.height),
      ]);

  Future<Rect> tightBoundsFor(String letter) async {
    final result = await TemplateRasterizer.rasterize(
      letter: letter,
      fontFamily: fontFamily,
      fontSize: fontSize,
      guidelines: guidelines,
      canvasWidth: 400.0,
    );
    return result.tightBounds!;
  }

  group('matchStrokes — correctly-ordered traces pair to identity', () {
    for (final entry in traces.entries) {
      final letter = entry.key;
      testWidgets('"$letter" pairs observed[i] → expected[i]', (tester) async {
        await tester.runAsync(() async {
          final tb = await tightBoundsFor(letter);
          final strokes = [for (final s in entry.value) fromRel(tb, s)];
          final data = letterFormationRegistry[letter]!;

          final pairing = matchStrokes(strokes, data.strokes, tb);

          expect(
            pairing,
            [for (var i = 0; i < strokes.length; i++) i],
            reason: 'order-based pairing must be the identity for "$letter"; '
                'a non-identity result means spatial matching has crept back in',
          );
        });
      });
    }
  });

  group('matchStrokes — swapped order is reflected, not corrected', () {
    testWidgets('f drawn crossbar-then-stem mis-pairs and lowers Start score',
        (tester) async {
      await tester.runAsync(() async {
        final tb = await tightBoundsFor('f');
        final data = letterFormationRegistry['f']!;

        final stem = fromRel(tb, traces['f']![0]);
        final crossbar = fromRel(tb, traces['f']![1]);

        final correct = <Stroke>[stem, crossbar];
        final swapped = <Stroke>[crossbar, stem]; // wrong order

        // The matcher must NOT silently re-order the swapped strokes back:
        // positional pairing is still the identity [0, 1].
        expect(
          matchStrokes(swapped, data.strokes, tb),
          [0, 1],
          reason: 'swapped strokes must pair positionally, not be corrected',
        );

        final correctScore =
            StrokeStartScorer(letter: 'f', data: data, bounds: tb)
                .score(correct)
                .overallScore;
        final swappedScore =
            StrokeStartScorer(letter: 'f', data: data, bounds: tb)
                .score(swapped)
                .overallScore;

        // Drawing in the wrong order should cost the learner Start credit,
        // rather than being invisibly fixed up by the matcher.
        expect(
          swappedScore,
          lessThan(correctScore),
          reason: 'mis-ordered f should score lower on Start than correct order '
              '(correct=$correctScore, swapped=$swappedScore)',
        );
      });
    });
  });
}
