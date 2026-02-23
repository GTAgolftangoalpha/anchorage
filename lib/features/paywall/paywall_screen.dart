import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/anchor_logo.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 1; // default: annual

  static const _plans = [
    _Plan(id: 0, label: 'Monthly', price: r'$9.99', period: '/month', badge: null),
    _Plan(
      id: 1,
      label: 'Annual',
      price: r'$59.99',
      period: '/year',
      badge: 'BEST VALUE',
    ),
    _Plan(id: 2, label: 'Lifetime', price: r'$149.99', period: 'once', badge: null),
  ];

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
                      'ANCHORAGE\nPREMIUM',
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      onPressed: () {
                        // TODO: RevenueCat purchase
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        'START FREE TRIAL',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                        onPressed: () {
                          // TODO: RevenueCat restore
                        },
                        child: Text(
                          'Restore Purchases',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.white.withAlpha(140),
                              ),
                        ),
                      ),
                      Text(
                        '·',
                        style: TextStyle(color: AppColors.white.withAlpha(100)),
                      ),
                      TextButton(
                        onPressed: () {},
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
    ('📱', 'App-level blocking & monitoring'),
    ('🧭', 'Accountability partner reports'),
    ('🔒', 'Anti-tamper PIN protection'),
    ('📊', 'Detailed usage analytics'),
    ('🆘', 'SOS mode & crisis support links'),
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

  const _Plan({
    required this.id,
    required this.label,
    required this.price,
    required this.period,
    required this.badge,
  });
}
