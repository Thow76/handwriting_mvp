import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/formation_score.dart';
import '../models/letter_formation_registry.dart';
import '../models/score_result.dart';

/// A developer-only widget that exposes every scorer's full diagnostic output.
///
/// Hidden behind [kDebugMode] — this widget renders nothing in release builds.
/// In debug builds it shows:
/// - Bitmap scores (coverage, precision, placement, efficiency) rounded to
///   two decimal places.
/// - Template tight bounds rect coordinates and dimensions (when provided).
/// - One panel per formation scorer with per-stroke technical and plain-English
///   columns, plus the scorer's overall summary below the observations.
///
/// Null [FormationScore] fields render as "(not applicable)" rather than being
/// hidden — the developer needs to see that the scorer was not invoked.
///
/// [StrokeBreakCounter] is always shown, even when [minRequiredStrokes] is 1
/// (the opposite of [ScoreDisplay]'s suppression rule).
///
/// This widget is used during QA and calibration work; it is never shown to
/// learners.
class DebugScoreView extends StatelessWidget {
  /// The score result to display. If null, shows a placeholder message.
  final ScoreResult? result;

  /// The tight bounding box of the template letter, in canvas coordinates.
  /// When provided, rendered as a single diagnostic line.
  final Rect? tightBounds;

  /// The letter [result] was scored against. Used to label the path-scoring
  /// panel with the scorer that actually ran — [WaypointSectionScorer] for
  /// letters migrated to `sections`, [CompoundStrokeScorer] otherwise — since
  /// [ScoreResult.compoundStroke] is populated by either one depending on the
  /// letter (see `ScoreIntegrator.score`'s routing).
  final String? letter;

  const DebugScoreView({super.key, this.result, this.tightBounds, this.letter});

  /// The name of the scorer that produced [ScoreResult.compoundStroke] for
  /// [letter], mirroring the routing in `ScoreIntegrator.score`.
  String get _compoundStrokeScorerName {
    final data = letter == null ? null : letterFormationRegistry[letter];
    final usesSections = data?.strokes.any((s) => s.sections.isNotEmpty) ?? false;
    return usesSections ? 'WaypointSectionScorer' : 'CompoundStrokeScorer';
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    if (result == null) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('(no score yet)', style: TextStyle(color: Colors.grey)),
      );
    }

    final r = result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BitmapScoresBlock(result: r),
          if (tightBounds != null) _TightBoundsLine(bounds: tightBounds!),
          const Divider(),
          _FormationPanel(name: 'StrokeStartScorer', score: r.strokeStart),
          _FormationPanel(
              name: _compoundStrokeScorerName, score: r.compoundStroke),
          _FormationPanel(name: 'StrokeBreakCounter', score: r.strokeBreak),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bitmap scores block
// ---------------------------------------------------------------------------

class _BitmapScoresBlock extends StatelessWidget {
  final ScoreResult result;
  const _BitmapScoresBlock({required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          Text('coverage: ${r.coverage.toStringAsFixed(2)}'),
          Text('precision: ${r.precision.toStringAsFixed(2)}'),
          Text('placement: ${r.placement.toStringAsFixed(2)}'),
          Text('efficiency: ${r.efficiency.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tight bounds line
// ---------------------------------------------------------------------------

class _TightBoundsLine extends StatelessWidget {
  final Rect bounds;
  const _TightBoundsLine({required this.bounds});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        'tightBounds: (${bounds.left.toStringAsFixed(1)}, '
        '${bounds.top.toStringAsFixed(1)}, '
        '${bounds.right.toStringAsFixed(1)}, '
        '${bounds.bottom.toStringAsFixed(1)}) '
        '${bounds.width.toStringAsFixed(1)}\u00d7'
        '${bounds.height.toStringAsFixed(1)}',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formation scorer panel
// ---------------------------------------------------------------------------

class _FormationPanel extends StatelessWidget {
  final String name;
  final FormationScore? score;

  const _FormationPanel({required this.name, this.score});

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '$name — (not applicable)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    final fs = score!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name — ${(fs.overallScore * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // Column headers
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Technical',
                  style: TextStyle(decoration: TextDecoration.underline, fontSize: 12),
                ),
              ),
              const Expanded(
                child: Text(
                  'Plain English',
                  style: TextStyle(decoration: TextDecoration.underline, fontSize: 12),
                ),
              ),
            ],
          ),
          // Observation rows
          for (final obs in fs.observations) _ObservationRow(obs: obs),
          // Summary
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Summary: ${fs.summary}',
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single observation row
// ---------------------------------------------------------------------------

/// A row in the observations table.
///
/// Skipped strokes (whose [StrokeObservation.note] starts with "skipped")
/// show "—" in the score column and the skip reason in both the technical
/// and plain-English columns.
class _ObservationRow extends StatelessWidget {
  final StrokeObservation obs;
  const _ObservationRow({required this.obs});

  bool get _isSkipped => obs.note.startsWith('skipped');

  @override
  Widget build(BuildContext context) {
    final String technicalText;
    final String plainText;

    if (_isSkipped) {
      technicalText = 'stroke ${obs.strokeIndex}: — (${obs.note})';
      plainText = obs.note;
    } else {
      technicalText = 'stroke ${obs.strokeIndex}: '
          'expected=${obs.expected} '
          'observed=${obs.observed} '
          'score=${obs.score.toStringAsFixed(2)}';
      plainText = obs.note;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(technicalText, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: Text(plainText, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
