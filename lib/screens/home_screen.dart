import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Handwriting Practice'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Settings ---
            _SettingsBar(state: state),
            const SizedBox(height: 40),

            // --- Mode buttons ---
            const Text(
              'Choose a mode',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            _ModeButton(
              label: 'Trace',
              description: 'Trace over the letter with colour guidance',
              icon: Icons.edit_outlined,
              onTap: () => Navigator.pushNamed(context, '/letter-picker',
                  arguments: 'trace'),
            ),
            const SizedBox(height: 16),
            _ModeButton(
              label: 'Recall',
              description: 'Remember and recreate the letter from memory',
              icon: Icons.psychology_outlined,
              onTap: () => Navigator.pushNamed(context, '/letter-picker',
                  arguments: 'recall'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBar extends StatelessWidget {
  const _SettingsBar({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    );

    return Column(
      children: [
        // Top row: Case, Input, Guidelines
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _LabelledToggle(
              label: 'Case',
              labelStyle: labelStyle,
              child: SegmentedButton<LetterCase>(
                segments: const [
                  ButtonSegment(
                      value: LetterCase.lowercase, label: Text('a–z')),
                  ButtonSegment(
                      value: LetterCase.uppercase, label: Text('A–Z')),
                ],
                selected: {state.letterCase},
                onSelectionChanged: (s) => state.setLetterCase(s.first),
              ),
            ),
            _LabelledToggle(
              label: 'Input',
              labelStyle: labelStyle,
              child: SegmentedButton<InputMode>(
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
            ),
            _LabelledToggle(
              label: 'Guidelines',
              labelStyle: labelStyle,
              child: SegmentedButton<GuidelineMode>(
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
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Bottom row: Difficulty, Stroke Width
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _LabelledToggle(
              label: 'Difficulty',
              labelStyle: labelStyle,
              child: SegmentedButton<Difficulty>(
                segments: const [
                  ButtonSegment(
                      value: Difficulty.beginner, label: Text('Easy')),
                  ButtonSegment(
                      value: Difficulty.intermediate, label: Text('Medium')),
                  ButtonSegment(
                      value: Difficulty.advanced, label: Text('Hard')),
                ],
                selected: {state.difficulty},
                onSelectionChanged: (s) => state.setDifficulty(s.first),
              ),
            ),
            _LabelledToggle(
              label: 'Stroke Width',
              labelStyle: labelStyle,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('S')),
                  ButtonSegment(value: 1, label: Text('M')),
                  ButtonSegment(value: 2, label: Text('L')),
                ],
                selected: {state.widthPresetIndex},
                onSelectionChanged: (s) => state.setWidthPresetIndex(s.first),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabelledToggle extends StatelessWidget {
  const _LabelledToggle({
    required this.label,
    required this.labelStyle,
    required this.child,
  });

  final String label;
  final TextStyle labelStyle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              Icon(icon, size: 36, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
