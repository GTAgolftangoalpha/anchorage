import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/guardable_app.dart';
import '../../services/guard_service.dart';
import '../../services/premium_service.dart';
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(16),
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
                            'YOUR VALUES ANCHOR',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(
                              color: AppColors.seafoam,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'What matters most to you',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppColors.white.withAlpha(120),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (values.isEmpty)
                            Text(
                              'Set your values in Settings to see them here.',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppColors.white.withAlpha(140),
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            ...values.map((v) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                v,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )),
                        ],
                      ),
                    ),
                  );
                }),

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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const AnchorLogo(size: 56, color: AppColors.white),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.seafoam : AppColors.slate,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isActive ? 'PROTECTION ACTIVE' : 'PROTECTION INACTIVE',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isActive ? AppColors.seafoam : AppColors.slate,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

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

          if (!isActive && guardedApps.isEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSetupTap,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.seafoam,
              ),
              child: const Text('TAP TO SET UP GUARD'),
            ),
          ],
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.navyLight],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are doing the work.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ANCHORAGE+ gives you unlimited guarded apps, unlimited urge logging, '
              'your Reflect journal, therapist-ready data export, and accountability '
              'partner reports. Everything you need to go deeper.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.white.withAlpha(180),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.seafoam,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Explore ANCHORAGE+',
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
    );
  }
}


