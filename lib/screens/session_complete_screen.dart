import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../feedback/feedback_strings.dart';
import '../models/practice_session.dart';
import '../models/score_result.dart';
import '../models/scoring_level.dart';
import '../routes.dart';
import '../theme/app_theme.dart';

/// The end of a run: a message, a row per letter when there is more than one,
/// and the two ways onward.
class SessionCompleteScreen extends StatelessWidget {
  const SessionCompleteScreen({super.key});

  PracticeSession _session(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is PracticeSession
        ? args
        : PracticeSession(letters: const ['a'], level: ScoringLevel.full);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session(context);
    final many = session.length > 1;
    final subtitle = many
        ? 'You practised ${session.length} letters'
        : 'You practised the letter ${session.letters.first}';
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Session complete',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: many
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Container(
                        key: const Key('resultList'),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < session.length; i++)
                              _ResultRow(
                                letter: session.letters[i],
                                result: session.results[i],
                                level: session.level,
                                last: i == session.length - 1,
                              ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const Key('practiceAgainButton'),
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.guide,
                        arguments: session.restarted(),
                      ),
                      child: const Text('Practice again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('homeButton'),
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (_) => false,
                      ),
                      child: const Text('Home'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.letter,
    required this.result,
    required this.level,
    required this.last,
  });

  final String letter;
  final ScoreResult? result;
  final ScoringLevel level;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final overall = r == null ? null : overallScore(r, level);
    final band = overall == null ? null : bandFor(overall);
    final color = switch (band) {
      FeedbackBand.good => AppColors.good,
      FeedbackBand.okay => AppColors.okay,
      FeedbackBand.morePractice => AppColors.morePractice,
      null => AppColors.border,
    };
    final wordColor = band == FeedbackBand.okay ? AppColors.okayText : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.ground)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ground,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              letter,
              style: const TextStyle(
                fontFamily: 'Andika',
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
          ),
          const Spacer(),
          if (overall != null) ...[
            SizedBox(
              key: Key('ring_$letter'),
              width: 30,
              height: 30,
              child: CustomPaint(painter: _MiniRingPainter(overall, color)),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 84,
              child: Text(
                band!.word,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: wordColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  _MiniRingPainter(this.fraction, this.color);

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const thickness = 4.0;
    final rect = (Offset.zero & size).deflate(thickness / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = AppColors.border;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
    paint.color = color;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, paint);
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.fraction != fraction || old.color != color;
}
