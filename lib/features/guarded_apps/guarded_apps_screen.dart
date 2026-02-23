import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/guardable_app.dart';
import '../../services/guard_service.dart';

class GuardedAppsScreen extends StatefulWidget {
  const GuardedAppsScreen({super.key});

  @override
  State<GuardedAppsScreen> createState() => _GuardedAppsScreenState();
}

class _GuardedAppsScreenState extends State<GuardedAppsScreen>
    with WidgetsBindingObserver {
  final Set<String> _selected = {};
  bool _hasUsagePermission = false;
  bool _loading = true;
  bool _saving = false;
  // True when we sent the user to Settings; on resume we auto-activate
  bool _waitingForPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns from the Settings app, re-check permission
    if (state == AppLifecycleState.resumed && _waitingForPermission) {
      _waitingForPermission = false;
      debugPrint('[GuardedApps] Returned from Settings, re-checking permission');
      _recheckPermissionAndActivate();
    }
  }

  Future<void> _recheckPermissionAndActivate() async {
    final granted = await GuardService.hasUsagePermission();
    debugPrint('[GuardedApps] Permission re-check after Settings: granted=$granted');
    if (!mounted) return;
    setState(() => _hasUsagePermission = granted);
    if (granted) {
      // Auto-activate now that we have permission
      await _activateGuard();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usage access not granted. Tap ACTIVATE to try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _load() async {
    final granted = await GuardService.hasUsagePermission();
    final saved = await GuardService.loadGuardedPackages();
    // Only restore packages still in the predefined list.
    // Stale entries (e.g. browsers removed from GuardableApp.predefined) are silently dropped.
    final validPackages =
        GuardableApp.predefined.map((a) => a.packageName).toSet();
    if (mounted) {
      setState(() {
        _hasUsagePermission = granted;
        _selected.addAll(saved.where((p) => validPackages.contains(p)));
        _loading = false;
      });
    }
  }

  void _toggle(String pkg) {
    final atLimit = _selected.length >= GuardableApp.freeTierLimit;
    final isSelected = _selected.contains(pkg);

    if (!isSelected && atLimit) {
      _showLimitSnackbar();
      return;
    }

    setState(() {
      if (isSelected) {
        _selected.remove(pkg);
      } else {
        _selected.add(pkg);
      }
    });
  }

  void _showLimitSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🔒  '),
            Expanded(
              child: Text(
                'Free plan: up to ${GuardableApp.freeTierLimit} apps. Upgrade to guard unlimited apps.',
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.navyMid,
        action: SnackBarAction(
          label: 'UPGRADE',
          textColor: AppColors.gold,
          onPressed: () => context.push('/paywall'),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_hasUsagePermission) {
      // Send to Settings — we'll auto-activate when they return via
      // didChangeAppLifecycleState + _recheckPermissionAndActivate()
      debugPrint('[GuardedApps] No usage permission — opening Settings');
      _waitingForPermission = true;
      await GuardService.requestUsagePermission();
      // Don't check here — user is still in Settings app
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grant "Usage access" for Anchorage, then come back.'),
            duration: Duration(seconds: 5),
            backgroundColor: AppColors.navyMid,
          ),
        );
      }
      return;
    }

    await _activateGuard();
  }

  Future<void> _activateGuard() async {
    setState(() => _saving = true);
    final packages = _selected.toList();
    debugPrint('[GuardedApps] Activating guard for packages: $packages');

    await GuardService.saveGuardedPackages(packages);

    if (packages.isEmpty) {
      debugPrint('[GuardedApps] No packages selected — stopping guard service');
      await GuardService.stop();
    } else {
      debugPrint('[GuardedApps] Starting guard service with ${packages.length} apps');
      await GuardService.start(packages);
      debugPrint('[GuardedApps] Guard service start call completed');
    }

    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            packages.isEmpty
                ? 'Guard stopped.'
                : '⚓ Guarding ${packages.length} app(s). Open a guarded app to test.',
          ),
          backgroundColor: AppColors.navy,
          duration: const Duration(seconds: 4),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GUARDED APPS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            )
          : Column(
              children: [
                // Permission banner
                if (!_hasUsagePermission) _PermissionBanner(),

                // Free tier indicator
                _FreeTierBar(selectedCount: _selected.length),

                // App list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: GuardableApp.predefined.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final app = GuardableApp.predefined[index];
                      final isSelected = _selected.contains(app.packageName);
                      final atLimit = _selected.length >= GuardableApp.freeTierLimit;
                      final isLocked = !isSelected && atLimit;

                      return _AppCard(
                        app: app,
                        isSelected: isSelected,
                        isLocked: isLocked,
                        onTap: () => _toggle(app.packageName),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _hasUsagePermission
                          ? 'ACTIVATE GUARD (${_selected.length})'
                          : 'GRANT PERMISSION & ACTIVATE',
                      style: theme.textTheme.labelLarge,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeTierBar extends StatelessWidget {
  final int selectedCount;

  const _FreeTierBar({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = GuardableApp.freeTierLimit - selectedCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.lightGray,
        border: Border(bottom: BorderSide(color: AppColors.midGray)),
      ),
      child: Row(
        children: [
          // Slot indicators
          Row(
            children: List.generate(GuardableApp.freeTierLimit, (i) {
              final filled = i < selectedCount;
              return Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppColors.navy : AppColors.white,
                  border: Border.all(
                    color: filled ? AppColors.navy : AppColors.midGray,
                    width: 2,
                  ),
                ),
                child: filled
                    ? const Icon(Icons.check, color: AppColors.white, size: 14)
                    : null,
              );
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              remaining > 0
                  ? '$remaining slot${remaining == 1 ? '' : 's'} remaining (free plan)'
                  : 'All free slots used — upgrade for more',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    remaining > 0 ? AppColors.textSecondary : AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.gold.withAlpha(30),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Usage access required. Tap "ACTIVATE" to open Settings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final GuardableApp app;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _AppCard({
    required this.app,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.navy : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.navy : AppColors.midGray,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // App emoji in circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.white.withAlpha(15)
                        : AppColors.lightGray,
                  ),
                  child: Center(
                    child: Text(
                      app.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + package
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color:
                              isSelected ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.packageName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppColors.white.withAlpha(160)
                              : AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // State indicator
                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.seafoam,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.navy,
                      size: 16,
                    ),
                  )
                else if (isLocked)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withAlpha(30),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.gold,
                      size: 16,
                    ),
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.midGray, width: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
