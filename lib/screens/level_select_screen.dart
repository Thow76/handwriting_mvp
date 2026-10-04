import 'package:flutter/material.dart';

import '../models/practice_session.dart';
import '../models/scoring_level.dart';
import '../routes.dart';
import '../theme/app_theme.dart';

/// Level select, built from the board `Difficulty.dc.html`.
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  static const _captions = {
    ScoringLevel.shapeOnly: 'Shape only',
    ScoringLevel.shapeAndStart: '+ where you start',
    ScoringLevel.shapeStartAndPath: '+ the path',
    ScoringLevel.full: '+ pen lifts',
  };

  // Ring fill per level: share of the ring and its opacity (board values).
  static const _ringSweep = {
    ScoringLevel.shapeOnly: (0.25, 0.30),
    ScoringLevel.shapeAndStart: (0.50, 0.55),
    ScoringLevel.shapeStartAndPath: (0.75, 0.78),
  };

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final letters = args is List<String> && args.isNotEmpty ? args : null;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: letters == null
            ? const Center(child: Text('Pick some letters on Home first'))
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Level',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Each level checks one more thing',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: box.maxHeight,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GridView(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 14,
                                          crossAxisSpacing: 14,
                                          mainAxisExtent: 162,
                                        ),
                                    children: [
                                      for (final level in ScoringLevel.values)
                                        _LevelTile(
                                          key: Key('level_${level.index + 1}'),
                                          level: level,
                                          caption: _captions[level]!,
                                          sweep: _ringSweep[level],
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            AppRoutes.guide,
                                            arguments: PracticeSession(
                                              letters: letters,
                                              level: level,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (final (i, c) in [
                                        AppColors.accent.withValues(
                                          alpha: 0.30,
                                        ),
                                        AppColors.accent.withValues(
                                          alpha: 0.55,
                                        ),
                                        AppColors.accent.withValues(
                                          alpha: 0.78,
                                        ),
                                        AppColors.accent,
                                      ].indexed) ...[
                                        if (i > 0) const SizedBox(width: 6),
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: c,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    super.key,
    required this.level,
    required this.caption,
    required this.sweep,
    required this.onTap,
  });

  final ScoringLevel level;
  final String caption;
  final (double, double)? sweep; // null = level 4, filled teal
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = sweep == null;
    final numeral = Text(
      '${level.index + 1}',
      style: TextStyle(
        fontFamily: 'Andika',
        fontWeight: FontWeight.w700,
        fontSize: 30,
        color: filled ? Colors.white : AppColors.ink,
      ),
    );
    return Semantics(
      button: true,
      label: 'Level ${level.index + 1}, $caption',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: _RingPainter(sweep),
                  child: Center(child: numeral),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: filled
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                    : EdgeInsets.zero,
                decoration: filled
                    ? BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 96px ring with a 74px inner disc: a clockwise partial fill from 12 o'clock
/// over a pale track, or (level 4) solid teal with a faint inner outline.
class _RingPainter extends CustomPainter {
  _RingPainter(this.sweep);

  final (double, double)? sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = Rect.fromCircle(center: c, radius: 48);
    final s = sweep;
    if (s == null) {
      canvas.drawCircle(c, 48, Paint()..color = AppColors.accent);
      canvas.drawCircle(
        c,
        36,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.5),
      );
      return;
    }
    final (fraction, opacity) = s;
    canvas.drawCircle(c, 48, Paint()..color = AppColors.border);
    canvas.drawArc(
      outer,
      -3.141592653589793 / 2,
      fraction * 2 * 3.141592653589793,
      true,
      Paint()..color = AppColors.accent.withValues(alpha: opacity),
    );
    canvas.drawCircle(c, 37, Paint()..color = AppColors.surface);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.sweep != sweep;
}
