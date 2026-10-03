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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Practice',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                title: 'Alphabet a–z',
                child: FilledButton(
                  key: const Key('practiceAlphabet'),
                  onPressed: () => _start(LetterSets.alphabet),
                  child: const Text('Practise a–z'),
                ),
              ),
              const SizedBox(height: 16),
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
                    const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              _Card(
                title: 'By letter shape',
                child: Column(
                  children: [
                    _GroupButton(
                      label: 'Sits on the line',
                      letters: LetterSets.sitsOnLine,
                      onTap: _start,
                    ),
                    const SizedBox(height: 10),
                    _GroupButton(
                      label: 'Reaches up',
                      letters: LetterSets.reachesUp,
                      onTap: _start,
                    ),
                    const SizedBox(height: 10),
                    _GroupButton(
                      label: 'Drops below',
                      letters: LetterSets.dropsBelow,
                      onTap: _start,
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
      padding: const EdgeInsets.all(18),
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.ground,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontFamily: 'Andika',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.surface : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupButton extends StatelessWidget {
  const _GroupButton({
    required this.label,
    required this.letters,
    required this.onTap,
  });

  final String label;
  final List<String> letters;
  final void Function(List<String>) onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => onTap(letters),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Text(
            letters.join(' '),
            style: const TextStyle(
              fontFamily: 'Andika',
              fontSize: 14,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
