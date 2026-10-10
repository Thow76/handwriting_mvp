import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/score_builder.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/template_cache.dart';
import 'package:handwriting_mvp/models/template_rasterizer.dart';
import 'package:handwriting_mvp/widgets/letter_canvas.dart';

Future<TemplateRasterResult> _fresh(String letter) =>
    TemplateRasterizer.rasterize(
      letter: letter,
      fontFamily: LetterCanvas.fontFamily,
      fontSize: LetterCanvas.fontSize,
      guidelines: LetterCanvas.guidelines,
      canvasWidth: LetterCanvas.width,
    );

Future<TemplateRasterResult> _cached(TemplateCache cache, String letter) =>
    cache.prepare(
      letter: letter,
      fontFamily: LetterCanvas.fontFamily,
      fontSize: LetterCanvas.fontSize,
      guidelines: LetterCanvas.guidelines,
      canvasWidth: LetterCanvas.width,
    );

void main() {
  testWidgets('same letter and size is rasterized once', (tester) async {
    final cache = TemplateCache();
    final results = await tester.runAsync(() async {
      final first = await _cached(cache, 'a');
      final again = await _cached(cache, 'a');
      return [first, again];
    });
    expect(identical(results![0], results[1]), isTrue);
    expect(cache.length, 1);
  });

  testWidgets('different letters get their own entries', (tester) async {
    final cache = TemplateCache();
    await tester.runAsync(() async {
      await _cached(cache, 'a');
      await _cached(cache, 'i');
    });
    expect(cache.length, 2);
  });

  testWidgets('scores are identical with and without the cache (a, i, k)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final cache = TemplateCache();
      for (final letter in ['a', 'i', 'k']) {
        final fresh = await _fresh(letter);
        final cached = await _cached(cache, letter);
        expect(cached.bounds, fresh.bounds);
        expect(cached.tightBounds, fresh.tightBounds);
        expect(cached.mask, fresh.mask);

        final b = fresh.tightBounds!;
        final strokes = [
          Stroke([
            Offset(b.left + 5, b.top + 5),
            Offset(b.center.dx, b.center.dy),
            Offset(b.right - 5, b.bottom - 5),
          ]),
        ];
        final s1 = buildScoreResult(
          templateResult: fresh,
          strokes: strokes,
          letter: letter,
        );
        final s2 = buildScoreResult(
          templateResult: cached,
          strokes: strokes,
          letter: letter,
        );
        expect(s2.coverage, s1.coverage);
        expect(s2.precision, s1.precision);
        expect(s2.placement, s1.placement);
        expect(s2.efficiency, s1.efficiency);
      }
    });
  });
}
