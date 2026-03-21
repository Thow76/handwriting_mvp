import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models/guideline_metrics.dart';
import '../utils/constants.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/guideline_painter.dart';

/// Debug utility: draw a letter and export its stroke data as Dart code that
/// can be pasted directly into `letter_templates.dart`.
///
/// Access via the `/capture` route (dev builds only).
class TemplateCaptureScreen extends StatefulWidget {
  const TemplateCaptureScreen({super.key});

  @override
  State<TemplateCaptureScreen> createState() => _TemplateCaptureScreenState();
}

class _TemplateCaptureScreenState extends State<TemplateCaptureScreen> {
  late final DrawingCanvasController _controller;
  final _canvasKey = GlobalKey();
  String _exportedCode = '';

  @override
  void initState() {
    super.initState();
    _controller = DrawingCanvasController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Convert all completed strokes from canvas pixels to template coordinates
  /// and format as a Dart literal ready to paste into letter_templates.dart.
  void _export() {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final canvasSize = renderBox.size;
    final metrics = GuidelineMetrics(canvasSize);

    final buffer = StringBuffer('[\n');
    for (var i = 0; i < _controller.strokes.length; i++) {
      final stroke = _controller.strokes[i];
      buffer.writeln('  // Stroke ${i + 1}');
      buffer.writeln('  [');
      for (final pt in stroke.points) {
        final tpt = metrics.canvasToTemplate(Offset(pt.x, pt.y));
        final tx = tpt.dx.toStringAsFixed(2);
        final ty = tpt.dy.toStringAsFixed(2);
        buffer.writeln('    const Offset($tx, $ty),');
      }
      buffer.writeln('  ],');
    }
    buffer.writeln('],');

    setState(() => _exportedCode = buffer.toString());

    // Also copy to clipboard for convenience.
    Clipboard.setData(ClipboardData(text: _exportedCode));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported to clipboard')),
    );

    // Print to console for debugging.
    debugPrint('--- TEMPLATE EXPORT ---');
    debugPrint(_exportedCode);
    debugPrint('--- END ---');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Capture'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _controller.undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
            onPressed: () {
              _controller.clear();
              setState(() => _exportedCode = '');
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Export strokes',
            onPressed: _export,
          ),
        ],
      ),
      body: Column(
        children: [
          // Drawing area with guidelines
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1 / kCanvasAspectRatio,
                child: Container(
                  key: _canvasKey,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      // Guidelines
                      Positioned.fill(
                        child: CustomPaint(
                          painter: const GuidelinePainter(
                            guidelineMode: GuidelineMode.full,
                          ),
                        ),
                      ),
                      // Drawing canvas
                      Positioned.fill(
                        child: DrawingCanvas(
                          controller: _controller,
                          strokeWidth: 3.0,
                          simulatePressure: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stroke count
          AnimatedBuilder(
            animation: _controller,
            builder: (_, child) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${_controller.strokes.length} stroke(s)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ),

          // Exported code preview
          if (_exportedCode.isNotEmpty)
            Container(
              height: 160,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _exportedCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
