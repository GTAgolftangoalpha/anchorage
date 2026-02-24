import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../services/custom_blocklist_service.dart';
import '../../services/premium_service.dart';

class CustomBlocklistScreen extends StatefulWidget {
  const CustomBlocklistScreen({super.key});

  @override
  State<CustomBlocklistScreen> createState() => _CustomBlocklistScreenState();
}

class _CustomBlocklistScreenState extends State<CustomBlocklistScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addDomain() async {
    final domain = _controller.text.trim().toLowerCase();
    if (domain.isEmpty) return;

    if (!CustomBlocklistService.isValidDomain(domain)) {
      setState(() => _error = 'Enter a valid domain (e.g. example.com)');
      return;
    }

    if (CustomBlocklistService.instance.domains.value.contains(domain)) {
      setState(() => _error = 'Domain already in list');
      return;
    }

    await CustomBlocklistService.instance.addDomain(domain);
    _controller.clear();
    setState(() => _error = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$domain added to blocklist'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _removeDomain(String domain) async {
    await CustomBlocklistService.instance.removeDomain(domain);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('CUSTOM BLOCKLIST')),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: PremiumService.instance.isPremium,
          builder: (context, isPremium, _) {
            return ValueListenableBuilder<List<String>>(
              valueListenable: CustomBlocklistService.instance.domains,
              builder: (context, domains, _) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Explainer
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Block specific domains',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add domains that the built-in blocklist doesn\'t '
                            'catch. These are blocked instantly via the VPN '
                            'filter — no restart needed.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.white.withAlpha(180),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Add domain form
                    if (isPremium) ...[
                      Text(
                        'ADD DOMAIN',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _controller,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'Domain',
                                hintText: 'example.com',
                                prefixIcon: const Icon(Icons.language),
                                errorText: _error,
                              ),
                              onFieldSubmitted: (_) => _addDomain(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: FilledButton(
                              onPressed: _addDomain,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'ADD',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Premium gate
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gold.withAlpha(60)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_outline,
                                color: AppColors.gold, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'Custom Blocklist is an ANCHORAGE+ feature',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upgrade to add your own domains to the blocklist.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => context.push('/paywall'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.gold,
                              ),
                              child: const Text(
                                'UPGRADE',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Domain list
                    Text(
                      'BLOCKED DOMAINS',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (domains.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              const Icon(Icons.dns_outlined,
                                  size: 48, color: AppColors.slate),
                              const SizedBox(height: 12),
                              Text(
                                'No custom domains yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...domains.map((domain) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.midGray),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.block,
                                      color: AppColors.danger, size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      domain,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  if (isPremium)
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 18, color: AppColors.slate),
                                      onPressed: () => _removeDomain(domain),
                                      tooltip: 'Remove',
                                    ),
                                ],
                              ),
                            ),
                          )),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
