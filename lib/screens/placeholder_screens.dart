import 'package:flutter/material.dart';

import '../routes.dart';

class _Placeholder extends StatelessWidget {
  const _Placeholder(
    this.title, {
    this.next,
    this.nextLabel,
  });

  final String title;
  final String? next;
  final String? nextLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            if (next != null)
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, next!),
                child: Text(nextLabel ?? 'Next'),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Home', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.levelSelect),
              child: const Text('Practice'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.dev),
              child: const Text('Dev'),
            ),
          ],
        ),
      ),
    );
  }
}

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) => const _Placeholder(
    'Level select',
    next: AppRoutes.guide,
    nextLabel: 'Start',
  );
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) => const _Placeholder(
    'Guide',
    next: AppRoutes.feedback,
    nextLabel: 'Finish',
  );
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) => const _Placeholder(
    'Feedback',
    next: AppRoutes.sessionComplete,
    nextLabel: 'Next letter',
  );
}

class SessionCompleteScreen extends StatelessWidget {
  const SessionCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      _Placeholder('Session complete', next: AppRoutes.home, nextLabel: 'Home');
}
