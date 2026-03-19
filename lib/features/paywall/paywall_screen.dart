import 'package:firebase_analytics/firebase_analytics.dart';
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
  bool _loading = false;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'paywall_view');
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await PremiumService.instance.getOfferings();
    if (mounted) setState(() => _offerings = offerings);
  }

  /// Find the monthly package from the offering.
  Package? _findMonthlyPackage(Offering offering) {
    final packages = offering.availablePackages;
    return offering.monthly ??
        packages.cast<Package?>().firstWhere(
          (p) => p!.identifier.toLowerCase().contains('month'),
          orElse: () => null,
        );
  }

  /// Display price from RevenueCat if available, otherwise fallback.
  String get _displayPrice {
    final offering = _offerings?.current;
    if (offering != null) {
      final pkg = _findMonthlyPackage(offering);
      if (pkg != null) {
        return '${pkg.storeProduct.priceString}/month';
      }
    }
    return r'$9.99/month';
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

    final package = _findMonthlyPackage(offering);
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
      FirebaseAnalytics.instance.logEvent(name: 'paywall_purchase');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to ANCHORAGE+!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      FirebaseAnalytics.instance.logEvent(name: 'paywall_cancel');
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
          content: Text('No previous purchases found'),
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

                    // Founding member pricing card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'FOUNDING MEMBER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _displayPrice,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Founding Member pricing, locked in forever.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'One of our first 100 members.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Cancel anytime. No lock-in.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withAlpha(120),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r'Price increases to $14.99 for new members after our first 100.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withAlpha(100),
                        fontSize: 13,
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
                            Uri.parse('https://getanchorage.app/terms'),
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
                      Text(
                        '\u00b7',
                        style: TextStyle(color: AppColors.white.withAlpha(100)),
                      ),
                      TextButton(
                        onPressed: () {
                          launchUrl(
                            Uri.parse('https://getanchorage.app/privacy'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Text(
                          'Privacy',
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
    ('\u{1F4F1}', 'Unlimited app blocking & monitoring'),
    ('\u{1F9ED}', 'Accountability partner reports'),
    ('\u{1F512}', 'Custom domain blocklist'),
    ('\u{1F4CA}', 'Full urge log history & export'),
    ('\u{1F4D3}', 'Lapse log & guided reflection'),
    ('\u{1F3C6}', 'Milestone badges & progress'),
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
          Text(feature.$1, style: const TextStyle(fontSize: 22)),
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
