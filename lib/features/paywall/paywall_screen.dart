import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../services/premium_service.dart';
import '../../shared/widgets/anchor_logo.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 1; // default: annual
  bool _loading = false;
  Offerings? _offerings;

  static const _plans = [
    _Plan(
      id: 0,
      label: 'Monthly',
      price: r'$19.99',
      period: '/month',
      badge: null,
      subtitle: null,
    ),
    _Plan(
      id: 1,
      label: 'Annual',
      price: r'$199',
      period: '/year',
      badge: 'SAVE 17%',
      subtitle: r'$16.58/month — save $40 vs monthly',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await PremiumService.instance.getOfferings();
    if (mounted) setState(() => _offerings = offerings);
  }

  /// Find a package from the offering by searching availablePackages.
  /// Typed accessors (offering.monthly / offering.annual) only match
  /// packages with RC standard identifiers ($rc_monthly, $rc_annual).
  /// Dashboard packages named "monthly" / "yearly" are custom — search by id.
  Package? _findPackage(Offering offering, {required bool monthly}) {
    final packages = offering.availablePackages;
    if (monthly) {
      return offering.monthly ??
          packages.cast<Package?>().firstWhere(
            (p) => p!.identifier.toLowerCase().contains('month'),
            orElse: () => null,
          );
    }
    return offering.annual ??
        packages.cast<Package?>().firstWhere(
          (p) =>
              p!.identifier.toLowerCase().contains('annual') ||
              p.identifier.toLowerCase().contains('year'),
          orElse: () => null,
        );
  }

  Future<void> _purchase() async {
    final offering = _offerings?.current;
    if (offering == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Products not available yet. Please try again later.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    debugPrint('[Paywall] Available packages: '
        '${offering.availablePackages.map((p) => '${p.identifier}(${p.packageType})').join(', ')}');

    final package = _findPackage(offering, monthly: _selectedPlan == 0);
    if (package == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This plan is not available yet. Please try again later.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    debugPrint('[Paywall] Purchasing: ${package.identifier} (${package.packageType})');
    setState(() => _loading = true);
    final success = await PremiumService.instance.purchasePackage(package);
    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to ANCHORAGE+! You\'re fully anchored.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    final success = await PremiumService.instance.restorePurchases();
    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases restored. Welcome back!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No previous purchases found.'),
          backgroundColor: AppColors.navy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.white),
                onPressed: () => context.pop(),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    const AnchorLogo(size: 56, color: AppColors.gold),
                    const SizedBox(height: 16),

                    Text(
                      'ANCHORAGE+',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: AppColors.white,
                        letterSpacing: 2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your full arsenal for lasting freedom.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withAlpha(180),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Feature list
                    ..._features.map((f) => _FeatureRow(feature: f)),

                    const SizedBox(height: 32),

                    // Plan selector
                    ...List.generate(_plans.length, (i) {
                      final plan = _plans[i];
                      final selected = _selectedPlan == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlan = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.white
                                  : AppColors.white.withAlpha(10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? AppColors.white
                                    : AppColors.white.withAlpha(40),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Custom radio dot
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.navy
                                          : AppColors.white.withAlpha(180),
                                      width: 2,
                                    ),
                                    color: selected
                                        ? AppColors.navy
                                        : Colors.transparent,
                                  ),
                                  child: selected
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: AppColors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            plan.label,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              color: selected
                                                  ? AppColors.navy
                                                  : AppColors.white,
                                            ),
                                          ),
                                          if (plan.badge != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.gold,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                plan.badge!,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.navy,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (plan.subtitle != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          plan.subtitle!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: selected
                                                ? AppColors.textMuted
                                                : AppColors.white.withAlpha(120),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: plan.price,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: selected
                                              ? AppColors.navy
                                              : AppColors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' ${plan.period}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: selected
                                              ? AppColors.textSecondary
                                              : AppColors.white.withAlpha(160),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 4),
                    Text(
                      'Cancel anytime.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withAlpha(100),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _purchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.navy,
                              ),
                            )
                          : Text(
                              'Get ANCHORAGE+',
                              style:
                                  Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppColors.navy,
                                        letterSpacing: 2,
                                      ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _loading ? null : _restore,
                        child: Text(
                          'Restore Purchases',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.white.withAlpha(140),
                              ),
                        ),
                      ),
                      Text(
                        '\u00b7',
                        style: TextStyle(color: AppColors.white.withAlpha(100)),
                      ),
                      TextButton(
                        onPressed: () {
                          launchUrl(
                            Uri.parse('https://anchorageapp.com/terms'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Text(
                          'Terms',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.white.withAlpha(140),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _features = [
    ('🛡️', 'Advanced VPN Content Filter'),
    ('📱', 'Unlimited app blocking & monitoring'),
    ('🧭', 'Accountability partner reports'),
    ('🔒', 'Anti-tamper PIN protection'),
    ('📊', 'Full urge log history & analytics'),
    ('📓', 'Relapse log & guided reflection'),
  ];
}

class _FeatureRow extends StatelessWidget {
  final (String, String) feature;

  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(feature.$1, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 14),
          Text(
            feature.$2,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withAlpha(220),
                ),
          ),
        ],
      ),
    );
  }
}

class _Plan {
  final int id;
  final String label;
  final String price;
  final String period;
  final String? badge;
  final String? subtitle;

  const _Plan({
    required this.id,
    required this.label,
    required this.price,
    required this.period,
    required this.badge,
    required this.subtitle,
  });
}
