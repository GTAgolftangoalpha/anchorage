import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class ExerciseChooserScreen extends StatelessWidget {
  const ExerciseChooserScreen({super.key});

  static const _exercises = [
    _ExerciseInfo(
      icon: Icons.square_outlined,
      title: 'Box Breathing',
      subtitle: '4-4-4-4 pattern to calm your nervous system',
      duration: '4 min',
      route: '/exercise/box-breathing',
    ),
    _ExerciseInfo(
      icon: Icons.air,
      title: 'Physiological Sigh',
      subtitle: 'Double inhale, long exhale to reduce stress fast',
      duration: '3 min',
      route: '/exercise/physiological-sigh',
    ),
    _ExerciseInfo(
      icon: Icons.visibility,
      title: '5-4-3-2-1 Grounding',
      subtitle: 'Use your senses to anchor yourself in the present',
      duration: '5 min',
      route: '/exercise/grounding',
    ),
    _ExerciseInfo(
      icon: Icons.waves,
      title: 'Urge Surfing',
      subtitle: 'Observe the urge like a wave. It rises, peaks, and passes.',
      duration: '4 min',
      route: '/exercise/urge-surfing',
    ),
    _ExerciseInfo(
      icon: Icons.accessibility_new,
      title: 'Body Scan',
      subtitle: 'Progressive relaxation from head to toe',
      duration: '5 min',
      route: '/exercise/body-scan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('EXERCISES')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Guided Exercises',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Choose an exercise to practice right now. Each one is designed to help you ride out urges and return to calm.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ..._exercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExerciseTile(info: ex),
                )),
          ],
        ),
      ),
    );
  }
}

class _ExerciseInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final String duration;
  final String route;

  const _ExerciseInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.route,
  });
}

class _ExerciseTile extends StatelessWidget {
  final _ExerciseInfo info;

  const _ExerciseTile({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(info.route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.midGray),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(info.icon, color: AppColors.navy, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(info.subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                info.duration,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
