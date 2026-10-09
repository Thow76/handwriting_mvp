import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../feedback/feedback_strings.dart';
import '../feedback/scoring_rules.dart';
import '../models/practice_session.dart';
import '../models/score_result.dart';
import '../models/scoring_level.dart';
import '../routes.dart';
import '../theme/app_theme.dart';

/// Shows one word (never a number) for the attempt just finished.
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  PracticeSession _session(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is PracticeSession
        ? args
        : PracticeSession(letters: const ['a'], level: ScoringLevel.full);
  }

  void _tryAgain(BuildContext context, PracticeSession session) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.guide,
      arguments: session,
    );
  }

  void _nextLetter(
    BuildContext context,
    PracticeSession session,
    ScoreResult? result,
  ) {
    if (result != null) session.record(result);
    if (session.isLast) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.sessionComplete,
        arguments: session,
      );
    } else {
      session.next();
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.guide,
        arguments: session,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session(context);
    final result = session.lastResult;
    final verdict = result == null
        ? const BandVerdict(band: FeedbackBand.morePractice, average: 0.0)
        : judgeAttempt(result, session.level, session.current);
    final band = verdict.band;
    final note = result == null ? null : feedbackNote(result, session.level);
    final (ringColor, wordColor) = switch (band) {
      FeedbackBand.good => (AppColors.good, AppColors.good),
      FeedbackBand.okay => (AppColors.okay, AppColors.okayText),
      FeedbackBand.morePractice => (
        AppColors.morePractice,
        AppColors.morePractice,
      ),
    };
    final next = FilledButton(
      key: const Key('nextLetterButton'),
      onPressed: () => _nextLetter(context, session, result),
      child: const Text('Next letter'),
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Pill('PRACTICE', filled: true),
                  Flexible(
                    child: _Pill(
                      'Level ${session.level.index + 1} · Feedback',
                      filled: false,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ScoreRing(
                        fraction: verdict.ringFill,
                        color: ringColor,
                        word: band.word,
                        wordColor: wordColor,
                      ),
                      if (note != null) ...[
                        const SizedBox(height: 22),
                        Container(
                          key: const Key('feedbackNote'),
                          constraints: const BoxConstraints(maxWidth: 280),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            note,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: band == FeedbackBand.good
                  ? next
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('tryAgainButton'),
                            onPressed: () => _tryAgain(context, session),
                            child: const Text('Try again'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: next),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.fraction,
    required this.color,
    required this.word,
    required this.wordColor,
  });

  final double fraction;
  final Color color;
  final String word;
  final Color wordColor;

  static const double size = 170;
  static const double thickness = 17;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('scoreRing'),
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(fraction.clamp(0.0, 1.0), color),
        child: Center(
          child: Text(
            word,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Andika',
              fontWeight: FontWeight.w700,
              fontSize: 34,
              height: 1.1,
              color: wordColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color);

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_ScoreRing.thickness / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ScoreRing.thickness
      ..color = AppColors.border;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
    paint.color = color;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.filled});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: filled ? AppColors.accent : AppColors.surface,
        border: filled
            ? null
            : Border.all(color: AppColors.guideline, width: 1.5),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: filled ? 11 : 12,
          fontWeight: filled ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: filled ? 1.1 : null,
          color: filled ? Colors.white : AppColors.muted,
        ),
      ),
    );
  }
}
