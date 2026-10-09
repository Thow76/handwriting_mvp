import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feedback/feedback_strings.dart';
import '../models/formation_score.dart';
import '../models/practice_session.dart';
import '../models/score_result.dart';
import '../models/scoring_level.dart';
import '../theme/app_theme.dart';

/// What the Breakdown screen needs. [letter] is passed explicitly because at
/// level 1 the session has already moved on to the next letter by now.
class BreakdownArgs {
  const BreakdownArgs({
    required this.session,
    required this.letter,
    required this.result,
    required this.continueRoute,
  });

  final PracticeSession session;
  final String letter;
  final ScoreResult result;

  /// Where Continue goes (the route the app would have used without tester
  /// mode), opened with [session] as its argument.
  final String continueRoute;
}

const _names = {
  ScoreKind.coverage: 'Coverage',
  ScoreKind.precision: 'Precision',
  ScoreKind.placement: 'Placement',
  ScoreKind.efficiency: 'Efficiency',
  ScoreKind.start: 'Start',
  ScoreKind.path: 'Path',
  ScoreKind.strokes: 'Strokes',
};

int _pct(double v) => (v * 100).round();

/// The one-line text the Copy button puts on the clipboard.
String breakdownCopyText({
  required String letter,
  required ScoringLevel level,
  required ScoreResult result,
}) {
  final parts = [
    for (final kind in ScoreKind.values)
      () {
        final v = scoreOf(result, kind);
        return '${_names[kind]} ${v == null ? 'n/a' : _pct(v)}';
      }(),
  ];
  final overall = overallScore(result, level);
  return '$letter · level ${level.index + 1} · ${parts.join(' · ')}'
      ' · app said ${bandFor(overall).word} (${_pct(overall)})';
}

/// Tester-only screen: every score behind an attempt, at every level.
class BreakdownScreen extends StatefulWidget {
  const BreakdownScreen({super.key});

  @override
  State<BreakdownScreen> createState() => _BreakdownScreenState();
}

class _BreakdownScreenState extends State<BreakdownScreen> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as BreakdownArgs;
    final level = args.session.level;
    final result = args.result;
    final overall = overallScore(result, level);
    final formation = {
      ScoreKind.start: result.strokeStart,
      ScoreKind.path: result.compoundStroke,
      ScoreKind.strokes: result.strokeBreak,
    };
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${args.letter} · Level ${level.index + 1}',
                key: const Key('breakdownTitle'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Learner would see: ${bandFor(overall).word} '
                '(${_pct(overall)}%)',
                key: const Key('breakdownBand'),
                style: const TextStyle(fontSize: 16, color: AppColors.ink),
              ),
              const SizedBox(height: 16),
              for (final kind in ScoreKind.values)
                Padding(
                  key: Key('row_${_names[kind]}'),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          _names[kind]!,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(() {
                          final v = scoreOf(result, kind);
                          return v == null ? 'n/a' : '${_pct(v)}%';
                        }()),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          isScoreVisible(level, kind)
                              ? 'counts at this level'
                              : 'not counted at this level',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 28),
              for (final e in formation.entries)
                _FormationDetail(name: _names[e.key]!, score: e.value),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('copyButton'),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: breakdownCopyText(
                        letter: args.letter,
                        level: level,
                        result: result,
                      ),
                    ),
                  );
                  if (mounted) setState(() => _copied = true);
                },
                child: Text(_copied ? 'Copied' : 'Copy'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('continueButton'),
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  args.continueRoute,
                  arguments: args.session,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormationDetail extends StatelessWidget {
  const _FormationDetail({required this.name, required this.score});

  final String name;
  final FormationScore? score;

  @override
  Widget build(BuildContext context) {
    final s = score;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s == null ? '$name — n/a' : '$name — ${_pct(s.overallScore)}%',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (s != null) ...[
            Text(s.summary, style: const TextStyle(fontSize: 12)),
            for (final o in s.observations)
              Text(
                'stroke ${o.strokeIndex}: expected ${o.expected}, '
                'observed ${o.observed} — ${o.note}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
          ],
        ],
      ),
    );
  }
}
