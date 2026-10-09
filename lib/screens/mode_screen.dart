import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme/app_theme.dart';

/// First screen: choose Practice or Games. Games is not built yet.
class ModeScreen extends StatelessWidget {
  const ModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Handwriting practice',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Choose how you'd like to practice today",
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ModeCard(
                          key: const Key('modePractice'),
                          title: 'Practice',
                          description:
                              'The model stays on screen. Work at your own '
                              'pace, no clock.',
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 26,
                            color: AppColors.ink,
                          ),
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.home),
                        ),
                        const SizedBox(height: 16),
                        _ModeCard(
                          key: const Key('modeGames'),
                          title: 'Games',
                          comingSoon: true,
                          description:
                              'The letter appears, then hides. Draw it from '
                              'memory before time runs out.',
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                startAngle: -1.5707963,
                                endAngle: 4.7123889,
                                colors: [
                                  AppColors.morePractice,
                                  AppColors.morePractice,
                                  AppColors.border,
                                  AppColors.border,
                                ],
                                stops: [0, 0.639, 0.639, 1],
                                transform: GradientRotation(-1.5707963),
                              ),
                            ),
                          ),
                          onTap: () {},
                        ),
                      ],
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.comingSoon = false,
  });

  final String title;
  final String description;
  final Widget icon;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppShapes.cardRadius);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: icon,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (comingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.guideline,
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              'COMING SOON',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.baseline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
