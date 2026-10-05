import 'package:flutter/material.dart';

import '../routes.dart';

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title, {this.next, this.nextLabel});

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
