import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/reflect_service.dart';
import '../../services/streak_service.dart';
import '../../services/urge_log_service.dart';
import '../../services/user_preferences_service.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = UserPreferencesService.instance.firstName;
    final installDate = UserPreferencesService.instance.installDate;

    return Scaffold(
      appBar: AppBar(title: const Text('MY JOURNEY')),
      body: SafeArea(
        child: ValueListenableBuilder<StreakData>(
          valueListenable: StreakService.instance.data,
          builder: (context, streak, _) {
            final daysSinceInstall = installDate > 0
                ? DateTime.now()
                    .difference(
                        DateTime.fromMillisecondsSinceEpoch(installDate))
                    .inDays
                : 0;
            final reflections = ReflectService.instance.entries.value.length;
            final urgesLogged = UrgeLogService.instance.entries.value.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.navy, AppColors.navyLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text('\u2693',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          name.isNotEmpty
                              ? "$name's Journey"
                              : 'Your Journey',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Every step counts.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.white.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats grid
                  _JourneyStat(
                    icon: Icons.calendar_month,
                    label: 'Days since install',
                    value: '$daysSinceInstall',
                    color: AppColors.seafoam,
                  ),
                  const SizedBox(height: 12),
                  _JourneyStat(
                    icon: Icons.anchor,
                    label: 'Total anchored days',
                    value: '${streak.totalCleanDays}',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  _JourneyStat(
                    icon: Icons.self_improvement,
                    label: 'Reflections completed',
                    value: '$reflections',
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 12),
                  _JourneyStat(
                    icon: Icons.edit_note,
                    label: 'Urges logged',
                    value: '$urgesLogged',
                    color: AppColors.rope,
                  ),
                  const SizedBox(height: 12),
                  _JourneyStat(
                    icon: Icons.local_fire_department,
                    label: 'Current streak',
                    value: '${streak.currentStreak} days',
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 12),
                  _JourneyStat(
                    icon: Icons.emoji_events,
                    label: 'Longest streak',
                    value: '${streak.longestStreak} days',
                    color: AppColors.navy,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _JourneyStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _JourneyStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.midGray),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
