import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/streak_service.dart';

class StreakDashboardScreen extends StatelessWidget {
  const StreakDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('STREAK')),
      body: SafeArea(
        child: ValueListenableBuilder<StreakData>(
          valueListenable: StreakService.instance.data,
          builder: (context, streak, _) {
            final bars = StreakService.instance.getWeeklyBarData();
            final message = StreakService.instance.motivationalMessage;

            return SingleChildScrollView(
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
                        Text(
                          _streakEmoji(streak.currentStreak),
                          style: const TextStyle(fontSize: 56),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${streak.currentStreak}',
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: AppColors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          streak.currentStreak == 1
                              ? 'DAY STREAK'
                              : 'DAY STREAK',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.seafoam,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
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
                        value: '${streak.longestStreak} days',
                      ),
                      const SizedBox(width: 12),
                      _MilestoneCard(
                        emoji: '📅',
                        label: 'Total Clean Days',
                        value: '${streak.totalCleanDays}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Weekly calendar
                  Text('This Week', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _WeekCalendar(bars: bars),

                  const SizedBox(height: 24),

                  // Milestones
                  Text('Milestones', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ..._milestones.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MilestoneRow(
                        milestone: m,
                        currentStreak: streak.currentStreak,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _streakEmoji(int streak) {
    if (streak >= 365) return '👑';
    if (streak >= 180) return '🌟';
    if (streak >= 90) return '🏴\u200d☠️';
    if (streak >= 30) return '🧭';
    if (streak >= 7) return '🌊';
    if (streak >= 1) return '⚓';
    return '🔥';
  }

  static const _milestones = [
    (days: 1, label: '1 Day', emoji: '⚓'),
    (days: 7, label: '1 Week', emoji: '🌊'),
    (days: 30, label: '1 Month', emoji: '🧭'),
    (days: 90, label: '3 Months', emoji: '🏴\u200d☠️'),
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
  final List<int> bars;
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  const _WeekCalendar({required this.bars});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0=Mon, 6=Sun

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final checkedIn = bars[i] == 1;
        final isToday = i == todayIndex;
        final isFuture = i > todayIndex;

        return Column(
          children: [
            Text(
              _days[i],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isToday ? AppColors.navy : AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: checkedIn
                    ? AppColors.seafoam
                    : (isToday
                        ? AppColors.navy.withAlpha(20)
                        : AppColors.lightGray),
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(
                    color: isToday ? AppColors.navy : AppColors.midGray,
                    width: isToday ? 2 : 1,
                  ),
                ),
              ),
              child: Center(
                child: isFuture
                    ? const SizedBox.shrink()
                    : Icon(
                        checkedIn ? Icons.check : Icons.remove,
                        size: 14,
                        color: checkedIn ? AppColors.white : AppColors.slate,
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final ({int days, String label, String emoji}) milestone;
  final int currentStreak;

  const _MilestoneRow({
    required this.milestone,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Text(milestone.emoji, style: const TextStyle(fontSize: 24)),
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
