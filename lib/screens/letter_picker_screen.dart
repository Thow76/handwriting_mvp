import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

// MVP letter subset
const List<String> kLetters = [
  'a', 'b', 'd', 'e', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'p', 'q', 't', 'y',
];

class LetterPickerScreen extends StatelessWidget {
  const LetterPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = ModalRoute.of(context)!.settings.arguments as String? ?? 'trace';
    final state = context.watch<AppState>();
    final isUppercase = state.letterCase == LetterCase.uppercase;
    final destination = mode == 'trace' ? '/trace' : '/recall';

    return Scaffold(
      appBar: AppBar(
        title: Text('${mode == 'trace' ? 'Trace' : 'Recall'} — Pick a Letter'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: kLetters.length,
          itemBuilder: (context, index) {
            final letterKey = kLetters[index]; // always lowercase
            final display = isUppercase
                ? letterKey.toUpperCase()
                : letterKey;
            return _LetterTile(
              letter: display,
              onTap: () => Navigator.pushNamed(
                context,
                destination,
                arguments: letterKey, // always lowercase key
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({required this.letter, required this.onTap});
  final String letter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
