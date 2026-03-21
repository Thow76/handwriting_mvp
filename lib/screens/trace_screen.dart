import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/letter_templates.dart';
import '../services/trace_feedback_service.dart';
import '../utils/constants.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/guideline_painter.dart';
import '../widgets/template_painter.dart';
import '../widgets/trace_stroke_painter.dart';

/// Trace mode — the template letter is displayed on screen and the user draws
/// over it.  Strokes are colour-coded green/orange/red based on proximity to
/// the template path.  No scoring.
class TraceScreen extends StatefulWidget {
  const TraceScreen({super.key});

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  late final DrawingCanvasController _canvasController;

  final _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _canvasController = DrawingCanvasController();
  }

  @override
  void dispose() {
    _canvasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letter =
        ModalRoute.of(context)!.settings.arguments as String? ?? 'a';
    final state = context.watch<AppState>();

    final isFingerMode = state.inputMode == InputMode.finger;
    final drawWidths = isFingerMode ? kFingerWidths : kStylusWidths;
    final strokeWidth = drawWidths[state.widthPresetIndex];

    // Template tolerance zone width (drives green/orange/red thresholds).
    final templateWidths =
        isFingerMode ? kFingerTemplateWidths : kStylusTemplateWidths;
    final templateWidth = templateWidths[state.widthPresetIndex];

    final isUppercase = state.letterCase == LetterCase.uppercase;
    final template = lookupTemplate(letter, uppercase: isUppercase);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trace — ${isUppercase ? letter.toUpperCase() : letter.toLowerCase()}',
        ),
        centerTitle: true,
        actions: [
          // Undo button
          AnimatedBuilder(
            animation: _canvasController,
            builder: (_, child) => IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo last stroke',
              onPressed:
                  _canvasController.hasStrokes ? _canvasController.undo : null,
            ),
          ),
          // Clear button
          AnimatedBuilder(
            animation: _canvasController,
            builder: (_, child) => IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear all',
              onPressed:
                  _canvasController.hasStrokes ? _canvasController.clear : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Settings strip
          _ControlStrip(state: state),

          // Drawing zone — three-layer Stack
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
                      // Rebuild feedback service whenever layout is known.
                      final service = template != null
                          ? TraceFeedbackService(
                              template: template,
                              canvasSize: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                              templateWidth: templateWidth,
                            )
                          : null;

                      return Stack(
                        key: _canvasKey,
                        children: [
                          // Layer 1 — guidelines
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GuidelinePainter(
                                guidelineMode: state.guidelineMode,
                              ),
                            ),
                          ),

                          // Layer 2 — template letter (rendered at tolerance
                          // width so user can see the zone to stay inside)
                          if (template != null)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: TemplatePainter(
                                  template: template,
                                  strokeWidth: templateWidth,
                                  opacity: 0.15,
                                ),
                              ),
                            ),

                          // Layer 3 — user drawing with colour feedback
                          Positioned.fill(
                            child: DrawingCanvas(
                              controller: _canvasController,
                              strokeWidth: strokeWidth,
                              simulatePressure: isFingerMode,
                              painterBuilder: service != null
                                  ? ({
                                      required completedStrokes,
                                      required currentPoints,
                                      required currentWidth,
                                      required currentSimulatePressure,
                                    }) =>
                                      TraceStrokePainter(
                                        completedStrokes: completedStrokes,
                                        feedbackService: service,
                                        currentPoints: currentPoints,
                                        currentWidth: currentWidth,
                                        currentSimulatePressure:
                                            currentSimulatePressure,
                                      )
                                  : null,
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

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Control strip — input mode, width preset, guideline mode
// ---------------------------------------------------------------------------

class _ControlStrip extends StatelessWidget {
  const _ControlStrip({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          // Input mode
          SegmentedButton<InputMode>(
            segments: const [
              ButtonSegment(
                value: InputMode.finger,
                icon: Icon(Icons.touch_app_outlined, size: 18),
                label: Text('Finger'),
              ),
              ButtonSegment(
                value: InputMode.stylus,
                icon: Icon(Icons.edit_outlined, size: 18),
                label: Text('Stylus'),
              ),
            ],
            selected: {state.inputMode},
            onSelectionChanged: (s) => state.setInputMode(s.first),
          ),
          // Width preset (controls both drawing width and template tolerance)
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('S')),
              ButtonSegment(value: 1, label: Text('M')),
              ButtonSegment(value: 2, label: Text('L')),
            ],
            selected: {state.widthPresetIndex},
            onSelectionChanged: (s) => state.setWidthPresetIndex(s.first),
          ),
          // Guideline mode
          SegmentedButton<GuidelineMode>(
            segments: const [
              ButtonSegment(
                value: GuidelineMode.full,
                label: Text('4-line'),
              ),
              ButtonSegment(
                value: GuidelineMode.baselineOnly,
                label: Text('Baseline'),
              ),
            ],
            selected: {state.guidelineMode},
            onSelectionChanged: (s) => state.setGuidelineMode(s.first),
          ),
        ],
      ),
    );
  }
}
