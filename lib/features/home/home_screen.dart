import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/guardable_app.dart';
import '../../services/guard_service.dart';
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
                // ── Status hero card ──────────────────────────────────────
                _StatusCard(
                  isActive: _guardActive,
                  guardedApps: _guardedApps,
                  onSetupTap: () async {
                    await context.push('/guarded-apps');
                    _refresh();
                  },
                ),

                const SizedBox(height: 16),

                // ── Permission warning ────────────────────────────────────
                if (!_hasPermission) ...[
                  _PermissionCard(
                    onTap: () async {
                      await GuardService.requestUsagePermission();
                      await Future.delayed(const Duration(milliseconds: 600));
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Stats row ─────────────────────────────────────────────
                Row(
                  children: [
                    _StatCard(
                      label: 'Current Streak',
                      value: '0',
                      unit: 'days',
                      icon: Icons.local_fire_department,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Blocked Today',
                      value: '0',
                      unit: 'attempts',
                      icon: Icons.shield,
                      color: AppColors.seafoam,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Quick actions ─────────────────────────────────────────
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
                  icon: Icons.self_improvement,
                  title: 'Reflect',
                  subtitle: 'Journal a moment of clarity',
                  onTap: () => context.push('/reflect'),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.star_outline,
                  title: 'Go Premium',
                  subtitle: 'Guard unlimited apps + advanced features',
                  onTap: () => context.push('/paywall'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Status indicator dot + label
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

          const SizedBox(height: 20),
          const AnchorLogo(size: 52, color: AppColors.white),
          const SizedBox(height: 16),

          Text(
            isActive ? 'You are anchored.' : 'Not guarding any apps.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.white,
            ),
          ),

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
