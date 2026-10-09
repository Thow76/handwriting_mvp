import 'package:flutter/material.dart';

import '../models/practice_session.dart';
import '../models/score_builder.dart';
import '../models/scoring_level.dart';
import '../models/stroke.dart';
import '../models/template_rasterizer.dart';
import '../routes.dart';
import '../tester_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/letter_canvas.dart';
import 'breakdown_screen.dart';

const _levelChips = {
  ScoringLevel.shapeOnly: 'Level 1 · Shape only',
  ScoringLevel.shapeAndStart: 'Level 2 · Shape + start',
  ScoringLevel.shapeStartAndPath: 'Level 3 · Shape + start + path',
  ScoringLevel.full: 'Level 4 · Full',
};

/// Practice screen: the learner copies the current letter on the canvas.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final List<Stroke> _strokes = [];
  Stroke? _current;
  bool _showModel = true;
  bool _finishing = false;

  PracticeSession _session(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is PracticeSession
        ? args
        : PracticeSession(letters: const ['a'], level: ScoringLevel.shapeOnly);
  }

  void _start(Offset p) => setState(() {
    _current = Stroke([p]);
    _strokes.add(_current!);
  });

  void _update(Offset p) => setState(() => _current?.addPoint(p));

  void _end() => _current = null;

  void _undo() => setState(() {
    _strokes.clear();
    _current = null;
  });

  Future<void> _finish(PracticeSession session) async {
    if (_strokes.isEmpty || _finishing) return;
    setState(() => _finishing = true);
    final template = await TemplateRasterizer.rasterize(
      letter: session.current,
      fontFamily: LetterCanvas.fontFamily,
      fontSize: LetterCanvas.fontSize,
      guidelines: LetterCanvas.guidelines,
      canvasWidth: LetterCanvas.width,
    );
    session.lastResult = buildScoreResult(
      templateResult: template,
      strokes: _strokes,
      letter: session.current,
    );
    if (!mounted) return;
    final letter = session.current;
    final result = session.lastResult!;
    final String route;
    if (session.level == ScoringLevel.shapeOnly) {
      session.record(result);
      if (session.isLast) {
        route = AppRoutes.sessionComplete;
      } else {
        session.next();
        route = AppRoutes.guide;
      }
    } else {
      route = AppRoutes.feedback;
    }
    if (TesterMode.enabled.value) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.breakdown,
        arguments: BreakdownArgs(
          session: session,
          letter: letter,
          result: result,
          continueRoute: route,
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, route, arguments: session);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session(context);
    final caption = session.level == ScoringLevel.shapeOnly
        ? 'No score at level 1 — just copy the shape'
        : 'Copy the letter, then tap Finish';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Pill(
                    'PRACTICE',
                    filled: true,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                  Flexible(
                    child: _Pill(_levelChips[session.level]!, filled: false),
                  ),
                ],
              ),
            ),
            if (session.showsProgress)
              Padding(
                key: const Key('guideProgress'),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session.index + 1} of ${session.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppShapes.progressBarHeight / 2,
                      ),
                      child: LinearProgressIndicator(
                        value: (session.index + 1) / session.length,
                        minHeight: AppShapes.progressBarHeight,
                        backgroundColor: AppColors.border,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              // Scales the canvas + eye button down on very short screens.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LetterCanvas(
                      letter: session.current,
                      strokes: _strokes,
                      showModel: _showModel,
                      onStrokeStart: _start,
                      onStrokeUpdate: _update,
                      onStrokeEnd: _end,
                    ),
                    const SizedBox(height: 18),
                    Semantics(
                      label: 'Show or hide the letter',
                      button: true,
                      child: InkResponse(
                        key: const Key('eyeToggle'),
                        onTap: () => setState(() => _showModel = !_showModel),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(
                              color: AppColors.guideline,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            _showModel
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 26,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                children: [
                  Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('undoButton'),
                          onPressed: _strokes.isEmpty ? null : _undo,
                          child: const Text('Undo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const Key('finishButton'),
                          onPressed: _strokes.isEmpty || _finishing
                              ? null
                              : () => _finish(session),
                          child: const Text('Finish'),
                        ),
                      ),
                    ],
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

class _Pill extends StatelessWidget {
  const _Pill(
    this.text, {
    required this.filled,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w700,
    this.letterSpacing,
  });

  final String text;
  final bool filled;
  final double fontSize;
  final FontWeight fontWeight;
  final double? letterSpacing;

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
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: filled ? Colors.white : AppColors.muted,
        ),
      ),
    );
  }
}
