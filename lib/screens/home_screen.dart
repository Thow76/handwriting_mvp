import 'package:flutter/material.dart';

import '../models/letter_sets.dart';
import '../routes.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _picked = {};

  void _start(List<String> letters) {
    Navigator.pushNamed(context, AppRoutes.levelSelect, arguments: letters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Practice',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'What would you like to practise today?',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              _Card(
                title: 'Alphabet',
                child: InkWell(
                  key: const Key('practiceAlphabet'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _start(LetterSets.alphabet),
                  child: Container(
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.ground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'a\u2014z',
                      style: TextStyle(
                        fontFamily: 'Andika',
                        fontSize: 32,
                        letterSpacing: 0.64,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _Card(
                title: 'Choose your own',
                child: Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      children: [
                        for (final l in LetterSets.alphabet)
                          _LetterCell(
                            letter: l,
                            selected: _picked.contains(l),
                            onTap: () => setState(() {
                              if (!_picked.remove(l)) _picked.add(l);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      key: const Key('practiceChosen'),
                      onPressed: _picked.isEmpty
                          ? null
                          : () =>
                                _start(LetterSets.inAlphabeticalOrder(_picked)),
                      child: const Text('Practice'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Card(
                title: 'By letter shape',
                child: Row(
                  children: [
                    _ShapeDiagram(
                      key: const Key('shape_sitsOnLine'),
                      semanticLabel: 'Sits on the line',
                      sample: 'a',
                      band: _Band.sitsOnLine,
                      onTap: () => _start(LetterSets.sitsOnLine),
                    ),
                    const SizedBox(width: 10),
                    _ShapeDiagram(
                      key: const Key('shape_reachesUp'),
                      semanticLabel: 'Reaches up',
                      sample: 'b',
                      band: _Band.reachesUp,
                      onTap: () => _start(LetterSets.reachesUp),
                    ),
                    const SizedBox(width: 10),
                    _ShapeDiagram(
                      key: const Key('shape_dropsBelow'),
                      semanticLabel: 'Drops below',
                      sample: 'g',
                      band: _Band.dropsBelow,
                      onTap: () => _start(LetterSets.dropsBelow),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.dev),
                  child: const Text('Dev'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        key: Key('letter_$letter'),
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.pickedTile : AppColors.ground,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontFamily: 'Andika',
              fontSize: 17,
              color: selected ? AppColors.accent : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

enum _Band { sitsOnLine, reachesUp, dropsBelow }

/// One of the three "By letter shape" tiles: a tiny guideline diagram with the
/// zone the group lives in tinted (board: Home.dc.html, 100×70 viewBox).
class _ShapeDiagram extends StatelessWidget {
  const _ShapeDiagram({
    super.key,
    required this.semanticLabel,
    required this.sample,
    required this.band,
    required this.onTap,
  });

  final String semanticLabel;
  final String sample;
  final _Band band;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.ground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomPaint(
              painter: _ShapeDiagramPainter(sample, band),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeDiagramPainter extends CustomPainter {
  _ShapeDiagramPainter(this.sample, this.band);

  final String sample;
  final _Band band;

  static const _w = 100.0;
  static const _h = 70.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _w < size.height / _h
        ? size.width / _w
        : size.height / _h;
    canvas.save();
    canvas.translate(
      (size.width - _w * scale) / 2,
      (size.height - _h * scale) / 2,
    );
    canvas.scale(scale);

    final (bandTop, bandHeight, bandColor, bandOpacity) = switch (band) {
      _Band.sitsOnLine => (35.0, 20.0, AppColors.accent, 0.14),
      _Band.reachesUp => (10.0, 45.0, AppColors.okay, 0.16),
      _Band.dropsBelow => (55.0, 10.0, AppColors.morePractice, 0.14),
    };
    canvas.drawRect(
      Rect.fromLTWH(0, bandTop, _w, bandHeight),
      Paint()..color = bandColor.withValues(alpha: bandOpacity),
    );

    _dashed(canvas, 10);
    _dashed(canvas, 35);
    if (band == _Band.dropsBelow) _dashed(canvas, 65);
    canvas.drawLine(
      const Offset(0, 55),
      const Offset(_w, 55),
      Paint()
        ..color = AppColors.baseline
        ..strokeWidth = 1.5,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: sample,
        style: const TextStyle(
          fontFamily: 'Andika',
          fontSize: 46,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    tp.paint(canvas, Offset(_w / 2 - tp.width / 2, 55 - baseline));
    canvas.restore();
  }

  void _dashed(Canvas canvas, double y) {
    final paint = Paint()
      ..color = AppColors.guideline
      ..strokeWidth = 1;
    for (var x = 0.0; x < _w; x += 5) {
      canvas.drawLine(Offset(x, y), Offset((x + 2).clamp(0, _w), y), paint);
    }
  }

  @override
  bool shouldRepaint(_ShapeDiagramPainter old) =>
      old.sample != sample || old.band != band;
}
