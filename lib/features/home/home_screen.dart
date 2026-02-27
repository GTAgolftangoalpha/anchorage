import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../features/psychoeducation/psychoeducation_cards.dart';
import '../../models/guardable_app.dart';
import '../../services/guard_service.dart';
import '../../services/premium_service.dart';
import '../../services/streak_service.dart';
import '../../services/user_preferences_service.dart';
import '../../shared/widgets/anchor_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _hasPermission = false;
  List<String> _guardedPackages = [];
  bool _guardActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final permission = await GuardService.hasUsagePermission();
    final packages = await GuardService.loadGuardedPackages();
    if (mounted) {
      setState(() {
        _hasPermission = permission;
        _guardedPackages = packages;
        _guardActive = permission && packages.isNotEmpty;
      });
    }
  }

  List<GuardableApp> get _guardedApps => GuardableApp.predefined
      .where((a) => _guardedPackages.contains(a.packageName))
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: AnchorLogo(size: 22, color: AppColors.white),
        ),
        title: const Text('ANCHORAGE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.navy,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: ValueListenableBuilder<StreakData>(
              valueListenable: StreakService.instance.data,
              builder: (context, streak, _) {
                final message = StreakService.instance.motivationalMessage;
                final bars = StreakService.instance.getWeeklyBarData();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status hero card ──────────────────────────────
                    _StatusCard(
                      isActive: _guardActive,
                      guardedApps: _guardedApps,
                      onSetupTap: () async {
                        await context.push('/guarded-apps');
                        _refresh();
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Permission warning ────────────────────────────
                    if (!_hasPermission) ...[
                      _PermissionCard(
                        onTap: () async {
                          await GuardService.requestUsagePermission();
                          await Future.delayed(
                              const Duration(milliseconds: 600));
                          _refresh();
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Streak hero ──────────────────────────────────
                    _StreakHero(
                      currentStreak: streak.currentStreak,
                      message: message,
                    ),

                    const SizedBox(height: 16),

                    // ── Daily values card ──────────────────────────
                    Builder(builder: (context) {
                      final values =
                          UserPreferencesService.instance.values;
                      if (values.isEmpty) return const SizedBox.shrink();
                      final dayOfYear = DateTime.now()
                          .difference(DateTime(DateTime.now().year))
                          .inDays;
                      final todayValue =
                          values[dayOfYear % values.length];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () => context.push('/reflect'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: const Border(
                                left: BorderSide(
                                  color: AppColors.seafoam,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  todayValue,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "What's one thing you can do today that honours this?",
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // ── Stats row ────────────────────────────────────
                    Row(
                      children: [
                        _StatCard(
                          label: 'Current Streak',
                          value: '${streak.currentStreak}',
                          unit: 'days',
                          icon: Icons.local_fire_department,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Longest Streak',
                          value: '${streak.longestStreak}',
                          unit: 'days',
                          icon: Icons.emoji_events,
                          color: AppColors.seafoam,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _StatCard(
                          label: 'Weekly Intercepts',
                          value: '${streak.weeklyIntercepts}',
                          unit: 'blocked',
                          icon: Icons.shield,
                          color: AppColors.navy,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Anchored Days',
                          value: '${streak.totalCleanDays}',
                          unit: 'total',
                          icon: Icons.calendar_today,
                          color: AppColors.success,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Weekly bar chart ──────────────────────────────
                    Text('This Week', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _WeeklyBarChart(bars: bars),

                    const SizedBox(height: 20),

                    // ── Exercises ──────────────────────────────────
                    Text('Exercises', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _ExerciseRow(
                      exercises: const [
                        _MiniExercise(
                          icon: Icons.square_outlined,
                          label: 'Box\nBreathing',
                          route: '/exercise/box-breathing',
                        ),
                        _MiniExercise(
                          icon: Icons.air,
                          label: 'Physio\nSigh',
                          route: '/exercise/physiological-sigh',
                        ),
                        _MiniExercise(
                          icon: Icons.visibility,
                          label: '5-4-3-2-1\nGrounding',
                          route: '/exercise/grounding',
                        ),
                        _MiniExercise(
                          icon: Icons.waves,
                          label: 'Urge\nSurfing',
                          route: '/exercise/urge-surfing',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/exercises'),
                        child: const Text('See all exercises'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Learn ──────────────────────────────────────
                    Text('Learn', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    const PsychoeducationSection(),

                    const SizedBox(height: 12),

                    // ── Quick actions ────────────────────────────────
                    Text('Quick Actions', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),

                    _ActionTile(
                      icon: Icons.security,
                      title: 'Manage Guarded Apps',
                      subtitle: _guardedPackages.isEmpty
                          ? 'No apps guarded yet'
                          : '${_guardedPackages.length} app${_guardedPackages.length == 1 ? '' : 's'} protected',
                      onTap: () async {
                        await context.push('/guarded-apps');
                        _refresh();
                      },
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.edit_note,
                      title: 'Urge Log',
                      subtitle: 'Track triggers privately',
                      onTap: () => context.push('/urge-log'),
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.self_improvement,
                      title: 'Reflect',
                      subtitle: 'Journal a moment of clarity',
                      onTap: () => context.push('/reflect'),
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.replay,
                      title: 'Relapse Log',
                      subtitle: 'Track setbacks, build awareness',
                      onTap: () => context.push('/relapse-log'),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: PremiumService.instance.isPremium,
                      builder: (context, isPremium, _) {
                        if (isPremium) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _ActionTile(
                            icon: Icons.star_outline,
                            title: 'Go Premium',
                            subtitle: 'Guard unlimited apps + advanced features',
                            onTap: () => context.push('/paywall'),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StreakHero extends StatelessWidget {
  final int currentStreak;
  final String message;

  const _StreakHero({required this.currentStreak, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
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
          Text(
            '$currentStreak',
            style: theme.textTheme.displayLarge?.copyWith(
              color: AppColors.white,
              fontSize: 56,
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
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<int> bars;
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const _WeeklyBarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.midGray),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final active = bars[i] == 1;
          final isToday = i == todayIndex;
          final isFuture = i > todayIndex;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : 4,
                right: i == 6 ? 0 : 4,
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: active ? 48 : 20,
                    decoration: BoxDecoration(
                      color: isFuture
                          ? AppColors.midGray.withAlpha(80)
                          : (active ? AppColors.seafoam : AppColors.midGray),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(color: AppColors.navy, width: 2)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _days[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              isToday ? AppColors.navy : AppColors.textMuted,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isActive;
  final List<GuardableApp> guardedApps;
  final VoidCallback onSetupTap;

  const _StatusCard({
    required this.isActive,
    required this.guardedApps,
    required this.onSetupTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.seafoam : AppColors.slate,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'PROTECTION ACTIVE' : 'PROTECTION INACTIVE',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isActive ? AppColors.seafoam : AppColors.slate,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const AnchorLogo(size: 40, color: AppColors.white),
          const SizedBox(height: 10),

          Builder(builder: (context) {
            final name = UserPreferencesService.instance.firstName;
            final motivation = UserPreferencesService.instance.motivation;
            final isExploring = motivation == "I'm just exploring my options" ||
                motivation == 'Someone asked me to try this';
            String greeting;
            if (!isActive) {
              greeting = 'Not guarding any apps.';
            } else if (name.isNotEmpty) {
              greeting = isExploring
                  ? 'Welcome back, $name.'
                  : 'Stay anchored, $name.';
            } else {
              greeting = 'You are anchored.';
            }
            return Text(
              greeting,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
              ),
            );
          }),

          const SizedBox(height: 8),

          if (isActive && guardedApps.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: guardedApps.map((app) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.white.withAlpha(30)),
                  ),
                  child: Text(
                    '${app.emoji} ${app.displayName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withAlpha(220),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            TextButton(
              onPressed: onSetupTap,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.seafoam,
              ),
              child: const Text('TAP TO SET UP GUARD →'),
            ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PermissionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gold.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withAlpha(80)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.gold, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage access required',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Tap to grant in Settings — needed to detect guarded apps.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate, size: 18),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
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
              BorderSide(color: AppColors.midGray)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style:
                    theme.textTheme.displayMedium?.copyWith(fontSize: 32)),
            Text(unit, style: theme.textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MiniExercise {
  final IconData icon;
  final String label;
  final String route;

  const _MiniExercise({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _ExerciseRow extends StatelessWidget {
  final List<_MiniExercise> exercises;

  const _ExerciseRow({required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: exercises.map((ex) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: ex == exercises.last ? 0 : 8,
            ),
            child: InkWell(
              onTap: () => context.push(ex.route),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border.fromBorderSide(
                    BorderSide(color: AppColors.midGray),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(ex.icon, color: AppColors.navy, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      ex.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
              BorderSide(color: AppColors.midGray)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.navy, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate, size: 20),
          ],
        ),
      ),
    );
  }
}
