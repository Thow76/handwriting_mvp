import 'package:flutter/material.dart';

import '../models/scoring_result.dart';

// ---------------------------------------------------------------------------
// Score Screen — Phase 7
// ---------------------------------------------------------------------------

/// Displays the scoring breakdown after a Recall session with animated bars.
///
/// Expected route arguments (Map[String, dynamic]):
///   'result'    → ScoringResult
///   'letter'    → String  (lowercase letter key, e.g. 'a')
///   'uppercase' → bool
class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Populated once in didChangeDependencies when route args are available.
  ScoringResult? _result;
  String _letter = '?';
  bool _isUppercase = false;

  // Animated values — null until _result is set.
  Animation<int>? _scoreAnim;
  Animation<double>? _shapeAnim;
  Animation<double>? _placementAnim;
  Animation<double>? _thirdAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_result != null) return; // already initialised

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final result = args?['result'] as ScoringResult?;
    if (result == null) return;

    _result = result;
    _letter = args?['letter'] as String? ?? '?';
    _isUppercase = args?['uppercase'] as bool? ?? false;

    final ease = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _scoreAnim =
        IntTween(begin: 0, end: result.combinedScore).animate(ease);
    _shapeAnim = Tween<double>(begin: 0, end: result.shapeScore / 10.0)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    ));
    _placementAnim =
        Tween<double>(begin: 0, end: result.placementScore / 10.0)
            .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.85, curve: Curves.easeOut),
    ));
    _thirdAnim = Tween<double>(begin: 0, end: result.thirdScore / 10.0)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor(int score) {
    if (score >= 9) return const Color(0xFF2E7D32);
    if (score >= 7) return const Color(0xFF1565C0);
    if (score >= 5) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Score'), centerTitle: true),
        body: const Center(child: Text('No result available.')),
      );
    }

    final displayLetter =
        _isUppercase ? _letter.toUpperCase() : _letter.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text('Score — $displayLetter'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final liveScore = _scoreAnim?.value ?? result.combinedScore;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Hero card -----------------------------------------
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 16),
                      child: Column(
                        children: [
                          // Letter label above score
                          Text(
                            displayLetter,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey.shade400,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Animated combined score
                          Text(
                            '$liveScore',
                            style: TextStyle(
                              fontSize: 88,
                              fontWeight: FontWeight.bold,
                              color: _scoreColor(liveScore),
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'out of 10',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Feedback message fades in after bars finish
                          AnimatedOpacity(
                            opacity: _controller.value > 0.6 ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              result.feedbackMessage,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _scoreColor(result.combinedScore),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ---- Category breakdown ----------------------------------
                  _CategoryRow(
                    label: 'Shape',
                    icon: Icons.gesture,
                    score: result.shapeScore,
                    progress:
                        _shapeAnim?.value ?? result.shapeScore / 10.0,
                    color: _scoreColor(result.shapeScore),
                  ),
                  const SizedBox(height: 14),
                  _CategoryRow(
                    label: 'Placement',
                    icon: Icons.vertical_align_center,
                    score: result.placementScore,
                    progress: _placementAnim?.value ??
                        result.placementScore / 10.0,
                    color: _scoreColor(result.placementScore),
                  ),
                  const SizedBox(height: 14),
                  _CategoryRow(
                    label: result.thirdScoreLabel,
                    icon: result.thirdScoreLabel == 'Proportion'
                        ? Icons.aspect_ratio
                        : Icons.straighten,
                    score: result.thirdScore,
                    progress:
                        _thirdAnim?.value ?? result.thirdScore / 10.0,
                    color: _scoreColor(result.thirdScore),
                  ),

                  const Spacer(),

                  // ---- Action buttons -------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/recall',
                        arguments: _letter,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/letter-picker',
                        ModalRoute.withName('/'),
                        arguments: 'recall',
                      ),
                      icon: const Icon(Icons.list),
                      label: const Text('Choose Another Letter'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category score row
// ---------------------------------------------------------------------------

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.icon,
    required this.score,
    required this.progress,
    required this.color,
  });

  final String label;
  final IconData icon;
  final int score;
  final double progress; // 0.0–1.0, pre-animated
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 22,
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
