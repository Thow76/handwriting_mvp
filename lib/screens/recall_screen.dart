import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/letter_templates.dart';
import '../services/scoring_service.dart';
import '../utils/constants.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/guideline_painter.dart';
import '../widgets/template_painter.dart';

// ---------------------------------------------------------------------------
// State machine phases
// ---------------------------------------------------------------------------

enum _Phase { preview, drawing, scoring, results }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Recall mode — 4-phase state machine:
///
///   PREVIEW  → 3-second countdown while the template is visible
///   DRAWING  → template hidden, user draws from memory
///   SCORING  → brief indicator while [ScoringService] runs (<100 ms)
///   RESULTS  → navigate to /score with the [ScoringResult]
class RecallScreen extends StatefulWidget {
  const RecallScreen({super.key});

  @override
  State<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends State<RecallScreen>
    with SingleTickerProviderStateMixin {
  late final DrawingCanvasController _canvasController;
  late AnimationController _fadeController;

  _Phase _phase = _Phase.preview;
  int _countdown = 3; // seconds remaining in preview
  Timer? _countdownTimer;

  /// Canvas size captured from LayoutBuilder — needed by ScoringService.
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _canvasController = DrawingCanvasController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..value = 1.0;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _canvasController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ---- Phase transitions --------------------------------------------------

  void _startCountdown() {
    _countdown = 3;
    _phase = _Phase.preview;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _transitionToDrawing();
      }
    });
  }

  void _transitionToDrawing() {
    _fadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _phase = _Phase.drawing);
      _fadeController.forward();
    });
  }

  void _onDone() {
    if (_phase != _Phase.drawing) return;
    if (!_canvasController.hasStrokes) return;
    setState(() => _phase = _Phase.scoring);
    _runScoring();
  }

  void _runScoring() {
    final state = context.read<AppState>();
    final letter = ModalRoute.of(context)!.settings.arguments as String? ?? 'a';
    final isUppercase = state.letterCase == LetterCase.uppercase;
    final template = lookupTemplate(letter, uppercase: isUppercase);

    if (template == null || _canvasSize == Size.zero) {
      // Fallback — shouldn't happen in normal flow.
      setState(() => _phase = _Phase.drawing);
      return;
    }

    final result = ScoringService.score(
      userStrokes: _canvasController.strokes.toList(),
      template: template,
      canvasSize: _canvasSize,
      guidelineMode: state.guidelineMode,
      difficulty: state.difficulty,
    );

    setState(() => _phase = _Phase.results);

    // Navigate to score screen after a brief pause so the user sees the
    // transition rather than an instant switch.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/score',
        arguments: {
          'result': result,
          'letter': letter,
          'uppercase': isUppercase,
        },
      );
    });
  }

  void _tryAgain() {
    _canvasController.clear();
    setState(() => _phase = _Phase.preview);
    _startCountdown();
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final letter =
        ModalRoute.of(context)!.settings.arguments as String? ?? 'a';
    final state = context.watch<AppState>();

    final isUppercase = state.letterCase == LetterCase.uppercase;
    final displayLetter =
        isUppercase ? letter.toUpperCase() : letter.toLowerCase();
    final template = lookupTemplate(letter, uppercase: isUppercase);

    final isFingerMode = state.inputMode == InputMode.finger;
    final widths = isFingerMode ? kFingerWidths : kStylusWidths;
    final strokeWidth = widths[state.widthPresetIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Recall — $displayLetter'),
        centerTitle: true,
        actions: [
          if (_phase == _Phase.drawing)
            AnimatedBuilder(
              animation: _canvasController,
              builder: (_, child) => IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo last stroke',
                onPressed: _canvasController.hasStrokes
                    ? _canvasController.undo
                    : null,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Phase indicator strip
          _PhaseStrip(phase: _phase, countdown: _countdown),

          // Drawing zone
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1 / kCanvasAspectRatio,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Capture canvas size for scoring.
                      _canvasSize =
                          Size(constraints.maxWidth, constraints.maxHeight);

                      return Stack(
                        children: [
                          // Layer 1 — guidelines (always visible)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GuidelinePainter(
                                guidelineMode: state.guidelineMode,
                              ),
                            ),
                          ),

                          // Layer 2 — template (preview only)
                          if (template != null && _phase == _Phase.preview)
                            Positioned.fill(
                              child: FadeTransition(
                                opacity: _fadeController,
                                child: CustomPaint(
                                  painter: TemplatePainter(
                                    template: template,
                                    strokeWidth: 4.0,
                                    opacity: 0.55,
                                  ),
                                ),
                              ),
                            ),

                          // Layer 3 — drawing canvas (drawing phase onward)
                          if (_phase == _Phase.drawing ||
                              _phase == _Phase.scoring ||
                              _phase == _Phase.results)
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: _phase != _Phase.drawing,
                                child: FadeTransition(
                                  opacity: _fadeController,
                                  child: DrawingCanvas(
                                    controller: _canvasController,
                                    strokeWidth: strokeWidth,
                                    simulatePressure: isFingerMode,
                                  ),
                                ),
                              ),
                            ),

                          // Countdown overlay
                          if (_phase == _Phase.preview)
                            Positioned.fill(
                              child: _CountdownOverlay(
                                  countdown: _countdown),
                            ),

                          // Scoring overlay
                          if (_phase == _Phase.scoring ||
                              _phase == _Phase.results)
                            Positioned.fill(
                              child: Container(
                                color: Colors.white54,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Bottom action bar
          _BottomBar(
            phase: _phase,
            hasStrokes: _canvasController,
            onDone: _onDone,
            onTryAgain: _tryAgain,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase indicator strip
// ---------------------------------------------------------------------------

class _PhaseStrip extends StatelessWidget {
  const _PhaseStrip({required this.phase, required this.countdown});
  final _Phase phase;
  final int countdown;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      _Phase.preview => ('Watch carefully…', const Color(0xFF1565C0)),
      _Phase.drawing => ('Now draw from memory', const Color(0xFF2E7D32)),
      _Phase.scoring => ('Scoring…', Colors.orange),
      _Phase.results => ('Done!', const Color(0xFF6A1B9A)),
    };

    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Countdown overlay
// ---------------------------------------------------------------------------

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.countdown});
  final int countdown;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            '$countdown',
            key: ValueKey(countdown),
            style: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.bold,
              color: Colors.black.withAlpha(30),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.phase,
    required this.hasStrokes,
    required this.onDone,
    required this.onTryAgain,
  });

  final _Phase phase;
  final DrawingCanvasController hasStrokes;
  final VoidCallback onDone;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: switch (phase) {
        _Phase.preview => const SizedBox(height: 48),
        _Phase.drawing => SizedBox(
            width: double.infinity,
            height: 48,
            child: AnimatedBuilder(
              animation: hasStrokes,
              builder: (_, child) => FilledButton.icon(
                onPressed: hasStrokes.hasStrokes ? onDone : null,
                icon: const Icon(Icons.check),
                label: const Text('Done — score my drawing'),
              ),
            ),
          ),
        _Phase.scoring || _Phase.results => const SizedBox(height: 48),
      },
    );
  }
}
