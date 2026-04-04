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
      child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ScoreItem(label: 'Coverage', value: result?.coverage ?? 0),
        _ScoreItem(label: 'Precision', value: result?.precision ?? 0),
        _ScoreItem(label: 'Placement', value: result?.placement ?? 0),
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
