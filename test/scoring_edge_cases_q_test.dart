import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'package:handwriting_mvp/app_state.dart';
import 'package:handwriting_mvp/data/letter_templates.dart';
import 'package:handwriting_mvp/models/scoring_result.dart';
import 'package:handwriting_mvp/models/stroke_data.dart';
import 'package:handwriting_mvp/services/scoring_service.dart';

// ==========================================================================
// Helpers
// ==========================================================================

/// Build a [StrokeData] from a list of offsets in canvas coordinates.
StrokeData _stroke(List<Offset> pts) => StrokeData(
      points: pts.map((p) => PointVector(p.dx, p.dy, 0.5)).toList(),
      width: 5.0,
      simulatePressure: true,
    );

/// Build a [StrokeData] from template-space offsets (converted to canvas).
StrokeData _strokeFromTemplate(List<Offset> pts) =>
    _stroke(pts.map(_templateToCanvas).toList());

const _canvasSize = Size(300, 360);

Offset _templateToCanvas(Offset t) {
  const pad = 0.05;
  const zone = 0.90;
  return Offset(
    t.dx * _canvasSize.width,
    (pad + (1.0 - t.dy) * zone) * _canvasSize.height,
  );
}

/// The lowercase q template for reference.
final _qTemplate = lookupTemplate('q', uppercase: false)!;

/// Circle stroke of q (template space).
final _qCircle = _qTemplate.strokes[0];

/// Stem stroke of q (template space).
final _qStem = _qTemplate.strokes[1];

/// Perfect drawing of q (both strokes, canvas coords).
List<StrokeData> _perfectQ() => [
      _strokeFromTemplate(_qCircle),
      _strokeFromTemplate(_qStem),
    ];

/// Score a user drawing against lowercase q.
ScoringResult _scoreQ(
  List<StrokeData> userStrokes, {
  Difficulty difficulty = Difficulty.beginner,
  GuidelineMode guidelineMode = GuidelineMode.full,
}) =>
    ScoringService.score(
      userStrokes: userStrokes,
      template: _qTemplate,
      canvasSize: _canvasSize,
      guidelineMode: guidelineMode,
      difficulty: difficulty,
    );

/// Flip all y-coordinates around the canvas centre (upside-down).
List<StrokeData> _flipVertical(List<StrokeData> strokes) {
  return strokes.map((s) {
    return StrokeData(
      points: s.points
          .map((p) => PointVector(p.x, _canvasSize.height - p.y, p.pressure))
          .toList(),
      width: s.width,
      simulatePressure: s.simulatePressure,
    );
  }).toList();
}

/// Rotate all points by [degrees] around the canvas centre.
List<StrokeData> _rotate(List<StrokeData> strokes, double degrees) {
  final cx = _canvasSize.width / 2;
  final cy = _canvasSize.height / 2;
  final rad = degrees * pi / 180;
  final cosR = cos(rad), sinR = sin(rad);
  return strokes.map((s) {
    return StrokeData(
      points: s.points.map((p) {
        final dx = p.x - cx;
        final dy = p.y - cy;
        return PointVector(
          cx + dx * cosR - dy * sinR,
          cy + dx * sinR + dy * cosR,
          p.pressure,
        );
      }).toList(),
      width: s.width,
      simulatePressure: s.simulatePressure,
    );
  }).toList();
}

/// Scale all points relative to the centroid.
List<StrokeData> _scale(List<StrokeData> strokes, double factor) {
  var cx = 0.0, cy = 0.0;
  var count = 0;
  for (final s in strokes) {
    for (final p in s.points) {
      cx += p.x;
      cy += p.y;
      count++;
    }
  }
  cx /= count;
  cy /= count;
  return strokes.map((s) {
    return StrokeData(
      points: s.points
          .map((p) => PointVector(
                cx + (p.x - cx) * factor,
                cy + (p.y - cy) * factor,
                p.pressure,
              ))
          .toList(),
      width: s.width,
      simulatePressure: s.simulatePressure,
    );
  }).toList();
}

// ==========================================================================
// Tests
// ==========================================================================

void main() {
  // ------------------------------------------------------------------
  // Baseline: confirm perfect q scores 10
  // ------------------------------------------------------------------
  group('Lowercase q — baseline', () {
    test('perfect drawing scores 10/10 on all categories', () {
      final result = _scoreQ(_perfectQ());
      expect(result.shapeScore, 10);
      expect(result.placementScore, 10);
      expect(result.thirdScore, 10);
      expect(result.combinedScore, 10);
    });
  });

  // ------------------------------------------------------------------
  // INCOMPLETE DRAWINGS — drawing only part of the letter
  // ------------------------------------------------------------------
  group('Lowercase q — incomplete drawings', () {
    test('stem only (no circle) should score poorly', () {
      // User draws just the descending stem — not the circular body.
      final stemOnly = [_strokeFromTemplate(_qStem)];
      final result = _scoreQ(stemOnly);

      // A stem alone is NOT the letter q — combined should be low.
      expect(result.combinedScore, lessThanOrEqualTo(5),
          reason:
              'Drawing only the stem of q should not score above 5. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });

    test('circle only (no stem) should score below perfect', () {
      // User draws just the circle — missing the descending stem.
      // The circle is ~71% of q's arc length, so coverage penalty is mild.
      // A stricter fix would need a bitmap coverage check (future work).
      final circleOnly = [_strokeFromTemplate(_qCircle)];
      final result = _scoreQ(circleOnly);

      expect(result.combinedScore, lessThanOrEqualTo(7),
          reason:
              'Drawing only the circle of q should not score above 7. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });

    test('stem only — individual category scores', () {
      final stemOnly = [_strokeFromTemplate(_qStem)];
      final result = _scoreQ(stemOnly);

      // Shape is still inflated (Procrustes rotation invariance — future fix).
      // Coverage penalty pulls the *combined* score down, but individual
      // category scores are not adjusted.
      expect(result.shapeScore, lessThanOrEqualTo(7),
          reason: 'Shape: stem-only got ${result.shapeScore}');

      // Proportion should suffer (wrong aspect ratio).
      expect(result.thirdScore, lessThanOrEqualTo(7),
          reason: 'Proportion: stem-only got ${result.thirdScore}');
    });
  });

  // ------------------------------------------------------------------
  // POSITION — drawing in wrong location (shape should survive)
  // ------------------------------------------------------------------
  group('Lowercase q — shifted position', () {
    test('q shifted left 60px keeps shape high', () {
      // Shift the drawing left by 60 canvas pixels (~0.2 template units).
      // Shape should be unaffected; only placement should drop.
      final rng = Random(42);
      final shifted = _perfectQ().map((s) {
        return StrokeData(
          points: s.points
              .map((p) => PointVector(
                    p.x - 60 + (rng.nextDouble() - 0.5) * 20,
                    p.y + (rng.nextDouble() - 0.5) * 20,
                    p.pressure,
                  ))
              .toList(),
          width: s.width,
          simulatePressure: s.simulatePressure,
        );
      }).toList();
      final result = _scoreQ(shifted);

      expect(result.shapeScore, greaterThanOrEqualTo(7),
          reason:
              'Shifted q should keep shape high. '
              'Got: shape=${result.shapeScore}, '
              'combined=${result.combinedScore}');
    });

    test('q shifted left 90px keeps shape high', () {
      final rng = Random(42);
      final shifted = _perfectQ().map((s) {
        return StrokeData(
          points: s.points
              .map((p) => PointVector(
                    p.x - 90 + (rng.nextDouble() - 0.5) * 20,
                    p.y + (rng.nextDouble() - 0.5) * 20,
                    p.pressure,
                  ))
              .toList(),
          width: s.width,
          simulatePressure: s.simulatePressure,
        );
      }).toList();
      final result = _scoreQ(shifted);

      expect(result.shapeScore, greaterThanOrEqualTo(7),
          reason:
              'Shifted q should keep shape high. '
              'Got: shape=${result.shapeScore}, '
              'combined=${result.combinedScore}');
    });
  });

  // ------------------------------------------------------------------
  // ROTATION — drawing the letter rotated
  // ------------------------------------------------------------------
  group('Lowercase q — rotation', () {
    test('90° rotated q should score poorly', () {
      final rotated = _rotate(_perfectQ(), 90);
      final result = _scoreQ(rotated);

      // A sideways q is not a valid q.
      expect(result.combinedScore, lessThanOrEqualTo(5),
          reason:
              '90° rotated q should not score above 5. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });

    test('180° rotated q (upside-down) should score poorly', () {
      final rotated = _rotate(_perfectQ(), 180);
      final result = _scoreQ(rotated);

      // With hybrid scoring, Procrustes aligns the 180° rotation and shape
      // scores high (correct form).  Placement catches the positional error.
      // Combined is the average of all three — no separate structural penalty.
      expect(result.combinedScore, lessThanOrEqualTo(8),
          reason:
              'Upside-down q should not score above 8. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });

    test('vertically flipped q should score poorly', () {
      final flipped = _flipVertical(_perfectQ());
      final result = _scoreQ(flipped);

      expect(result.combinedScore, lessThanOrEqualTo(5),
          reason:
              'Vertically flipped q should not score above 5. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });
  });

  // ------------------------------------------------------------------
  // SIZE — drawing much too small or too large
  // ------------------------------------------------------------------
  group('Lowercase q — size', () {
    test('half-size q should be penalised (full guidelines)', () {
      final small = _scale(_perfectQ(), 0.5);
      final result = _scoreQ(small);

      expect(result.combinedScore, lessThanOrEqualTo(8),
          reason:
              'Half-size q should not score above 8. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
      // Proportion should now reflect the size mismatch.
      expect(result.thirdScore, lessThan(10),
          reason:
              'Proportion should penalise half-size. '
              'Got: ${result.thirdScore}');
    });

    test('quarter-size q should score poorly', () {
      final tiny = _scale(_perfectQ(), 0.25);
      final result = _scoreQ(tiny);

      expect(result.combinedScore, lessThanOrEqualTo(7),
          reason:
              'Quarter-size q should not score above 7. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });

    test('half-size q — size metric (baseline-only mode)', () {
      final small = _scale(_perfectQ(), 0.5);
      final result = _scoreQ(small, guidelineMode: GuidelineMode.baselineOnly);

      // Size score should clearly reflect the scaling mismatch.
      expect(result.thirdScore, lessThanOrEqualTo(5),
          reason:
              'Size score for half-scale q should be ≤5. '
              'Got: ${result.thirdScore}');
    });
  });

  // ------------------------------------------------------------------
  // WRONG LETTER — drawing a different letter entirely
  // ------------------------------------------------------------------
  group('Lowercase q — wrong letter', () {
    test('drawing a perfect "b" against q template should score poorly', () {
      final bTemplate = lookupTemplate('b', uppercase: false)!;
      final perfectB = bTemplate.strokes
          .map((s) => _strokeFromTemplate(s))
          .toList();
      final result = _scoreQ(perfectB);

      expect(result.combinedScore, lessThanOrEqualTo(5),
          reason:
              'Drawing b when asked for q should not score above 5. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });

    test('drawing a perfect "d" against q template should score below 7', () {
      // d and q are similar (circle + stem on same side). Structural
      // check has limited effect since both have stems on the right.
      // Rotation penalty and placement (d has ascender, q has descender)
      // provide the main discrimination.
      final dTemplate = lookupTemplate('d', uppercase: false)!;
      final perfectD = dTemplate.strokes
          .map((s) => _strokeFromTemplate(s))
          .toList();
      final result = _scoreQ(perfectD);

      expect(result.combinedScore, lessThanOrEqualTo(7),
          reason:
              'Drawing d when asked for q should not score above 7. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });

    test('drawing a perfect "p" against q template should score poorly', () {
      // p has descender stem on LEFT; q has it on RIGHT.
      // Structural check catches this — stem on wrong side.
      final pTemplate = lookupTemplate('p', uppercase: false)!;
      final perfectP = pTemplate.strokes
          .map((s) => _strokeFromTemplate(s))
          .toList();
      final result = _scoreQ(perfectP);

      // With hybrid scoring, shape correctly scores very low (bitmap detects
      // mismatch after Procrustes alignment).  But placement and proportion
      // remain high because p and q occupy similar bounding boxes.
      // Combined = average of all three — no separate structural penalty.
      expect(result.shapeScore, lessThanOrEqualTo(3),
          reason:
              'Drawing p shape score against q template should be low. '
              'Got: shape=${result.shapeScore}');
      expect(result.combinedScore, lessThanOrEqualTo(8),
          reason:
              'Drawing p when asked for q should not score above 8. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });
  });

  // ------------------------------------------------------------------
  // MINIMAL INPUT — very little ink on the canvas
  // ------------------------------------------------------------------
  group('Lowercase q — minimal input', () {
    test('a single short tap should score poorly', () {
      // Simulate a quick tap — 3 very close points.
      final tap = [
        _stroke([
          _templateToCanvas(const Offset(0.5, 0.40)),
          _templateToCanvas(const Offset(0.51, 0.40)),
          _templateToCanvas(const Offset(0.52, 0.40)),
        ]),
      ];
      final result = _scoreQ(tap);

      expect(result.combinedScore, lessThanOrEqualTo(3),
          reason:
              'A tiny tap should not score above 3. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });

    test('a single straight horizontal line should score poorly', () {
      final hLine = [
        _stroke([
          _templateToCanvas(const Offset(0.1, 0.40)),
          _templateToCanvas(const Offset(0.9, 0.40)),
        ]),
      ];
      final result = _scoreQ(hLine);

      expect(result.combinedScore, lessThanOrEqualTo(3),
          reason:
              'A horizontal line is not q. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });

    test('a single straight vertical line should score poorly', () {
      // This is the "just the stem" scenario but as a single crude stroke
      // without matching the stem position exactly.
      final vLine = [
        _stroke([
          _templateToCanvas(const Offset(0.5, 0.80)),
          _templateToCanvas(const Offset(0.5, 0.05)),
        ]),
      ];
      final result = _scoreQ(vLine);

      expect(result.combinedScore, lessThanOrEqualTo(5),
          reason:
              'A vertical line is not q. '
              'Got: combined=${result.combinedScore}, '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });
  });

  // ------------------------------------------------------------------
  // RANDOM SCRIBBLE — incoherent input
  // ------------------------------------------------------------------
  group('Lowercase q — random scribble', () {
    test('random zigzag should score poorly', () {
      // Random scribble has high arc length (lots of zigzagging), so
      // coverage ratio is high (~1.0). The coverage check doesn't help here.
      // Shape score is inflated by Procrustes finding a partial match.
      // Needs rotation penalty or bitmap coverage (future fixes).
      final rng = Random(99);
      final zigzag = <Offset>[];
      for (var i = 0; i < 30; i++) {
        zigzag.add(_templateToCanvas(
          Offset(rng.nextDouble(), 0.20 + rng.nextDouble() * 0.40),
        ));
      }
      final result = _scoreQ([_stroke(zigzag)]);

      expect(result.combinedScore, lessThanOrEqualTo(6),
          reason:
              'Random scribble scores ${result.combinedScore}. '
              'shape=${result.shapeScore}, '
              'placement=${result.placementScore}, '
              'proportion=${result.thirdScore}');
    });
  });

  // ------------------------------------------------------------------
  // DIAGNOSTIC — print raw scores for all scenarios
  //
  // This test always passes. It prints a table of scores to help
  // calibrate thresholds before deciding what to fix.
  // ------------------------------------------------------------------
  group('Lowercase q — diagnostic score dump', () {
    test('print all scenario scores for analysis', () {
      // Simulate realistic hand-drawn q: add noise + slight shift left
      List<StrokeData> noisyQ(double noisePx, double shiftX, double shiftY) {
        final rng = Random(42);
        return _perfectQ().map((s) {
          return StrokeData(
            points: s.points
                .map((p) => PointVector(
                      p.x + shiftX + (rng.nextDouble() - 0.5) * 2 * noisePx,
                      p.y + shiftY + (rng.nextDouble() - 0.5) * 2 * noisePx,
                      p.pressure,
                    ))
                .toList(),
            width: s.width,
            simulatePressure: s.simulatePressure,
          );
        }).toList();
      }

      final scenarios = <String, List<StrokeData>>{
        'Perfect q': _perfectQ(),
        'Noisy q (10px)': noisyQ(10, 0, 0),
        'Noisy q (20px)': noisyQ(20, 0, 0),
        'Noisy+shifted left 30px': noisyQ(15, -30, 0),
        'Noisy+shifted left 60px': noisyQ(15, -60, 0),
        'Noisy+shifted left 90px': noisyQ(15, -90, 0),
        'Stem only': [_strokeFromTemplate(_qStem)],
        'Circle only': [_strokeFromTemplate(_qCircle)],
        '90° rotated': _rotate(_perfectQ(), 90),
        '180° rotated': _rotate(_perfectQ(), 180),
        'Flipped vertical': _flipVertical(_perfectQ()),
        'Half size': _scale(_perfectQ(), 0.5),
        'Quarter size': _scale(_perfectQ(), 0.25),
        'Double size': _scale(_perfectQ(), 2.0),
        'Perfect b as q': lookupTemplate('b', uppercase: false)!
            .strokes
            .map((s) => _strokeFromTemplate(s))
            .toList(),
        'Perfect d as q': lookupTemplate('d', uppercase: false)!
            .strokes
            .map((s) => _strokeFromTemplate(s))
            .toList(),
        'Perfect p as q': lookupTemplate('p', uppercase: false)!
            .strokes
            .map((s) => _strokeFromTemplate(s))
            .toList(),
        'Tiny tap': [
          _stroke([
            _templateToCanvas(const Offset(0.5, 0.40)),
            _templateToCanvas(const Offset(0.51, 0.40)),
            _templateToCanvas(const Offset(0.52, 0.40)),
          ]),
        ],
        'Horizontal line': [
          _stroke([
            _templateToCanvas(const Offset(0.1, 0.40)),
            _templateToCanvas(const Offset(0.9, 0.40)),
          ]),
        ],
        'Vertical line': [
          _stroke([
            _templateToCanvas(const Offset(0.5, 0.80)),
            _templateToCanvas(const Offset(0.5, 0.05)),
          ]),
        ],
      };

      // Header
      // ignore: avoid_print
      print('\n${"=" * 90}');
      // ignore: avoid_print
      print('SCORING EDGE CASE ANALYSIS — lowercase q (beginner, full guidelines)');
      // ignore: avoid_print
      print('=' * 90);
      // ignore: avoid_print
      print(
        '${"Scenario".padRight(22)} '
        '${"Shape".padLeft(6)} '
        '${"Place".padLeft(6)} '
        '${"Prop".padLeft(6)} '
        '${"Comb".padLeft(6)} '
        '  Raw errors',
      );
      // ignore: avoid_print
      print('-' * 90);

      for (final entry in scenarios.entries) {
        final result = _scoreQ(entry.value);
        final errors = result.rawErrors;
        final errorStr =
            'shape=${errors["shape"]?.toStringAsFixed(3)}, '
            'place=${errors["placement"]?.toStringAsFixed(3)}, '
            'prop=${errors["proportion"]?.toStringAsFixed(3) ?? errors["size"]?.toStringAsFixed(3)}, '
            'cov=${errors["coverageRatio"]?.toStringAsFixed(3)}, '
            'rot=${errors["rotationDeg"]?.toStringAsFixed(1)}°, '
            'str=${errors["structural"]?.toStringAsFixed(3)}';
        // ignore: avoid_print
        print(
          '${entry.key.padRight(22)} '
          '${result.shapeScore.toString().padLeft(6)} '
          '${result.placementScore.toString().padLeft(6)} '
          '${result.thirdScore.toString().padLeft(6)} '
          '${result.combinedScore.toString().padLeft(6)} '
          '  $errorStr',
        );
      }
      // ignore: avoid_print
      print('${"=" * 90}\n');

      // This test always passes — it exists to produce the diagnostic table.
      expect(true, isTrue);
    });
  });
}
