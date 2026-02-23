import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/anchor_logo.dart';

/// Full-screen overlay shown when a blocked site/app is intercepted.
class InterceptScreen extends StatelessWidget {
  const InterceptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Anchor warning
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withAlpha(15),
                  border: Border.all(
                    color: AppColors.white.withAlpha(60),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: AnchorLogo(size: 48, color: AppColors.white),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'HOLD ON.',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: AppColors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This content has been blocked\nby ANCHORAGE.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withAlpha(200),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 48),

              // Pause prompt
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withAlpha(30),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Take a breath.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.seafoam,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You don\'t need this. You are stronger than this urge. Let it pass.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withAlpha(180),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pushReplacement('/reflect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.seafoam,
                    foregroundColor: AppColors.navy,
                  ),
                  child: const Text('REFLECT ON THIS MOMENT'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(color: AppColors.white.withAlpha(80)),
                  ),
                  child: const Text('GO BACK TO SAFETY'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
