import 'package:flutter/material.dart';

import '../models/score_result.dart';

/// Displays coverage and precision scores for the current handwriting attempt.
class ScoreDisplay extends StatelessWidget {
  final ScoreResult? result;

  const ScoreDisplay({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: result == null ? 0.0 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ScoreItem(label: 'Coverage', value: result?.coverage ?? 0),
              _ScoreItem(label: 'Precision', value: result?.precision ?? 0),
              _ScoreItem(label: 'Placement', value: result?.placement ?? 0),
              _ScoreItem(label: 'Efficiency', value: result?.efficiency ?? 0),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _FormationScoreItem(label: 'Start', value: result?.strokeStart?.overallScore),
              _FormationScoreItem(label: 'Direction', value: result?.strokeDirection?.overallScore),
              _FormationScoreItem(label: 'Path', value: result?.compoundStroke?.overallScore),
              _FormationScoreItem(label: 'Strokes', value: result?.strokeBreak?.overallScore),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text('$percentage%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _FormationScoreItem extends StatelessWidget {
  final String label;
  final double? value;

  const _FormationScoreItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final display = value == null ? '—' : '${(value! * 100).round()}%';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(display, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
