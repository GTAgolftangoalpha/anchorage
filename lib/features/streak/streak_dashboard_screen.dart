import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../services/export_service.dart';
import '../../services/premium_service.dart';
import '../../services/streak_service.dart';
import '../../services/user_preferences_service.dart';

class StreakDashboardScreen extends StatefulWidget {
  const StreakDashboardScreen({super.key});

  @override
  State<StreakDashboardScreen> createState() => _StreakDashboardScreenState();
}

class _StreakDashboardScreenState extends State<StreakDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStreakReset();
    });
  }

  void _checkStreakReset() {
    if (StreakService.instance.streakResetDetected) {
      StreakService.instance.streakResetDetected = false;
      _showCompassionScreen(context);
    }
  }

  static void _showCompassionScreen(BuildContext context) {
    final name = UserPreferencesService.instance.firstName;
    final values = UserPreferencesService.instance.values;
    final v1 = values.isNotEmpty ? values[0] : '';
    final v2 = values.length > 1 ? values[1] : '';
    final v3 = values.length > 2 ? values[2] : '';
    final n = name.isNotEmpty ? name : 'friend';

    final valuesText = v1.isNotEmpty && v2.isNotEmpty && v3.isNotEmpty
        ? '$v1, $v2, and $v3 are still who you are.'
        : 'Your values are still who you are.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Dialog.fullscreen(
          backgroundColor: AppColors.navy,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.seafoam.withAlpha(20),
                      border: Border.all(
                        color: AppColors.seafoam.withAlpha(60),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text('\u2693', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Your streak has reset',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "$n, a setback is not a failure. Your values haven't changed. $valuesText Every moment is a new chance to choose differently.\n\nThe fact that you're here, in this app, right now \u2014 that matters.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.white.withAlpha(200),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.seafoam,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'START AGAIN',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.navy,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('STREAK'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: PremiumService.instance.isPremium,
            builder: (context, isPremium, _) {
              return IconButton(
                icon: const Icon(Icons.ios_share, color: AppColors.white),
                tooltip: 'Export streak data',
                onPressed: () {
                  if (!isPremium) {
                    _showUpgradeDialog(context);
                    return;
                  }
                  ExportService.exportStreakData();
                },
              );
            },
          ),
        ],
      ),
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
                          'DAY STREAK',
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
                        label: 'Total Anchored Days',
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
                  ValueListenableBuilder<bool>(
                    valueListenable: PremiumService.instance.isPremium,
                    builder: (context, isPremium, _) {
                      return Column(
                        children: _milestones.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _MilestoneRow(
                              milestone: m,
                              currentStreak: streak.currentStreak,
                              isPremium: isPremium,
                              onTap: () => _showMilestoneDialog(
                                  context, m, streak.currentStreak, isPremium),
                            ),
                          ),
                        ).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ANCHORAGE+ Feature'),
        content: const Text('Export your data with ANCHORAGE+.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/paywall');
            },
            child: const Text('UPGRADE'),
          ),
        ],
      ),
    );
  }

  static String _milestoneMessage(int days) {
    final name = UserPreferencesService.instance.firstName;
    final values = UserPreferencesService.instance.values;
    final v1 = values.isNotEmpty ? values[0] : '';
    final v2 = values.length > 1 ? values[1] : '';
    final v3 = values.length > 2 ? values[2] : '';
    final n = name.isNotEmpty ? name : 'Sailor';

    switch (days) {
      case 1:
        return "$n, your first anchored day. This is where it starts.";
      case 3:
        return v1.isNotEmpty
            ? "3 anchored days, $n. Your commitment to $v1 is taking root."
            : "3 anchored days, $n. Your commitment is taking root.";
      case 7:
        return v2.isNotEmpty
            ? "A full week, $n. $v2 is becoming more than a word \u2014 it's how you live."
            : "A full week, $n. Your values are becoming how you live.";
      case 14:
        return "Two weeks anchored. $n, you're building something real.";
      case 30:
        return "$n, 30 days. The science says new neural pathways are forming. Your values are becoming habits.";
      case 60:
        return v3.isNotEmpty
            ? "60 anchored days. $n, $v3 isn't just something you believe \u2014 it's something you practise."
            : "60 anchored days. $n, your values aren't just beliefs \u2014 they're practice.";
      case 90:
        return "$n, 90 days anchored. Most people never get here. You did.";
      case 180:
        return "Half a year, $n. You've proven that change is possible.";
      case 365:
        return v1.isNotEmpty && v2.isNotEmpty && v3.isNotEmpty
            ? "One year anchored, $n. Your values \u2014 $v1, $v2, $v3 \u2014 carried you here. Extraordinary."
            : "One year anchored, $n. Your values carried you here. Extraordinary.";
      default:
        return "$n, you've reached $days anchored days. Stay anchored.";
    }
  }

  static void _showMilestoneDialog(
    BuildContext context,
    ({int days, String label, String emoji}) milestone,
    int currentStreak,
    bool isPremium,
  ) {
    final unlocked = currentStreak >= milestone.days;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${milestone.emoji} ${milestone.label}'),
        content: Text(
          () {
            if (unlocked) {
              return _milestoneMessage(milestone.days);
            }
            if (isPremium) {
              final name = UserPreferencesService.instance.firstName;
              return name.isNotEmpty
                  ? '$name, keep going \u2014 ${milestone.days - currentStreak} more days to unlock this milestone.'
                  : 'Keep going \u2014 ${milestone.days - currentStreak} more days to unlock this milestone.';
            }
            return 'Upgrade to ANCHORAGE+ to unlock milestone badges and detailed progress.';
          }(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          if (!isPremium && !unlocked)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/paywall');
              },
              child: const Text('UPGRADE'),
            ),
        ],
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
    (days: 3, label: '3 Days', emoji: '🔥'),
    (days: 7, label: '1 Week', emoji: '🌊'),
    (days: 14, label: '2 Weeks', emoji: '🚀'),
    (days: 30, label: '1 Month', emoji: '🧭'),
    (days: 60, label: '2 Months', emoji: '💎'),
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
  final bool isPremium;
  final VoidCallback onTap;

  const _MilestoneRow({
    required this.milestone,
    required this.currentStreak,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = currentStreak >= milestone.days;
    // Free users see badges as locked even if streak qualifies
    final showUnlocked = unlocked && isPremium;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: showUnlocked ? AppColors.navy : AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.fromBorderSide(
            BorderSide(
              color: showUnlocked ? AppColors.navy : AppColors.midGray,
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
                  color:
                      showUnlocked ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
            if (!isPremium && unlocked)
              const Icon(Icons.lock_outline, color: AppColors.gold, size: 20)
            else
              Icon(
                unlocked ? Icons.check_circle : Icons.lock_outline,
                color: unlocked ? AppColors.seafoam : AppColors.slate,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
