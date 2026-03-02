import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
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
    final name = UserPreferencesService.instance.firstName;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Center(
                  child: Text(
                    name.isNotEmpty ? 'Hey $name.' : 'Hey.',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.navy,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Small streak indicator (tappable -> Journey tab)
                ValueListenableBuilder<StreakData>(
                  valueListenable: StreakService.instance.data,
                  builder: (context, streak, _) {
                    return Center(
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to Journey tab (index 3)
                          final shell = StatefulNavigationShell.maybeOf(context);
                          if (shell != null) {
                            shell.goBranch(3);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.anchor,
                                color: AppColors.seafoam, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${streak.currentStreak} days anchored',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right,
                                color: AppColors.slate, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Status card
                _StatusCard(
                  isActive: _guardActive,
                  guardedApps: _guardedApps,
                  onSetupTap: () async {
                    await context.push('/guarded-apps');
                    _refresh();
                  },
                ),

                const SizedBox(height: 16),

                // Permission warning
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

                // Upgrade banner (free users only)
                ValueListenableBuilder<bool>(
                  valueListenable: PremiumService.instance.isPremium,
                  builder: (context, isPremium, _) {
                    if (isPremium) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _UpgradeBanner(
                        onTap: () => context.push('/paywall'),
                      ),
                    );
                  },
                ),

                // Daily values card
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

                // Quick Actions
                Text('Quick Actions', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.edit_note,
                        label: 'Log Urge',
                        onTap: () => context.push('/urge-log'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.self_improvement,
                        label: 'Reflect',
                        onTap: () => context.push('/reflect'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.replay,
                        label: 'Lapse Log',
                        onTap: () => context.push('/relapse-log'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Crisis link
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/sos'),
                    child: Text(
                      'Need to talk to someone?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.seafoam,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.seafoam,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================

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
              child: const Text('TAP TO SET UP GUARD'),
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
                    'Tap to grant in Settings. Needed to detect guarded apps.',
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

class _UpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _UpgradeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.navyLight],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock the full ANCHORAGE experience',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hard blocking, unlimited apps, journal, and more.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withAlpha(160),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.seafoam,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SEE PLANS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.star, color: AppColors.gold, size: 36),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.midGray),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.navy, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
