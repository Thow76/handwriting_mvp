import 'package:flutter/material.dart';

import '../models/practice_session.dart';
import '../models/scoring_level.dart';
import '../routes.dart';
import '../theme/app_theme.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  static const _descriptions = {
    ScoringLevel.shapeOnly: 'Shape only',
    ScoringLevel.shapeAndStart: 'Shape and where you start',
    ScoringLevel.shapeStartAndPath: 'Shape, start and path',
    ScoringLevel.full: 'Everything, including lifts',
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
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Level select',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final level in ScoringLevel.values) ...[
                    InkWell(
                      key: Key('level_${level.index + 1}'),
                      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.guide,
                        arguments: PracticeSession(
                          letters: letters,
                          level: level,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(
                            AppShapes.cardRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${level.index + 1}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent,
                                  ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(_descriptions[level]!)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }
}
