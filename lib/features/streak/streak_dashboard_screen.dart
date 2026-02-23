import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StreakDashboardScreen extends StatelessWidget {
  const StreakDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('STREAK')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current streak hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navy, AppColors.navyLight],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🔥',
                      style: TextStyle(fontSize: 56),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '0',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: AppColors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'DAY STREAK',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.seafoam,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start your journey today.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _MilestoneCard(
                    emoji: '🏆',
                    label: 'Best Streak',
                    value: '0 days',
                  ),
                  const SizedBox(width: 12),
                  _MilestoneCard(
                    emoji: '📅',
                    label: 'Total Clean Days',
                    value: '0',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Weekly calendar placeholder
              Text('This Week', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _WeekCalendar(),

              const SizedBox(height: 24),

              // Milestones
              Text('Milestones', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._milestones.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MilestoneRow(milestone: m),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _milestones = [
    (days: 1, label: '1 Day', emoji: '⚓'),
    (days: 7, label: '1 Week', emoji: '🌊'),
    (days: 30, label: '1 Month', emoji: '🧭'),
    (days: 90, label: '3 Months', emoji: '🏴‍☠️'),
    (days: 180, label: '6 Months', emoji: '🌟'),
    (days: 365, label: '1 Year', emoji: '👑'),
  ];
}

class _MilestoneCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _MilestoneCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(16),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.midGray),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleLarge),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  final List<String> _days = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _days.map((day) {
        return Column(
          children: [
            Text(
              day,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                shape: BoxShape.circle,
                border: const Border.fromBorderSide(
                  BorderSide(color: AppColors.midGray),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.remove,
                  size: 14,
                  color: AppColors.slate,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final ({int days, String label, String emoji}) milestone;

  const _MilestoneRow({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const currentStreak = 0;
    final unlocked = currentStreak >= milestone.days;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.navy : AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.fromBorderSide(
          BorderSide(
            color: unlocked ? AppColors.navy : AppColors.midGray,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            milestone.emoji,
            style: TextStyle(
              fontSize: 24,
              color: unlocked ? null : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              milestone.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: unlocked ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            color: unlocked ? AppColors.seafoam : AppColors.slate,
            size: 20,
          ),
        ],
      ),
    );
  }
}
