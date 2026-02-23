import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/anchor_logo.dart';

class EmergencySosScreen extends StatelessWidget {
  const EmergencySosScreen({super.key});

  // Detect country from device locale (e.g. "en_AU" → "AU")
  static String? get _countryCode =>
      ui.PlatformDispatcher.instance.locale.countryCode;

  static List<_CrisisResource> get _localResources {
    switch (_countryCode) {
      case 'AU':
        return const [
          _CrisisResource(
            name: 'Lifeline Australia',
            description: '24/7 crisis support and suicide prevention',
            number: '13 11 14',
            dialNumber: '131114',
          ),
          _CrisisResource(
            name: 'Beyond Blue',
            description: 'Anxiety, depression and mental wellbeing support',
            number: '1300 22 4636',
            dialNumber: '1300224636',
          ),
        ];
      case 'US':
        return const [
          _CrisisResource(
            name: '988 Suicide & Crisis Lifeline',
            description: 'Free, confidential 24/7 support — call or text 988',
            number: '988',
            dialNumber: '988',
          ),
          _CrisisResource(
            name: 'SAMHSA National Helpline',
            description: 'Mental health & substance use support, 24/7',
            number: '1-800-662-4357',
            dialNumber: '18006624357',
          ),
        ];
      case 'GB':
        return const [
          _CrisisResource(
            name: 'Samaritans',
            description: 'Free, confidential 24/7 emotional support',
            number: '116 123',
            dialNumber: '116123',
          ),
          _CrisisResource(
            name: 'CALM',
            description: 'Support for men in crisis, 5pm–midnight daily',
            number: '0800 58 58 58',
            dialNumber: '0800585858',
          ),
        ];
      default:
        return const [];
    }
  }

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _openIasp() async {
    final uri = Uri.parse('https://www.iasp.info/resources/Crisis_Centres/');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resources = _localResources;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('GET SUPPORT'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Anchor logo
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.navy.withAlpha(12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AnchorLogo(size: 44, color: AppColors.navy),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "You're not alone.",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Reaching out is strength.\nThese services are free, confidential,\nand available 24 hours a day.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 36),

              if (resources.isNotEmpty) ...[
                // Local crisis resource cards
                ...List.generate(resources.length, (i) {
                  final r = resources[i];
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: i < resources.length - 1 ? 16 : 0),
                    child: _ResourceCard(
                      resource: r,
                      onCall: () => _call(r.dialNumber),
                    ),
                  );
                }),
                const SizedBox(height: 32),
                const Divider(color: AppColors.midGray),
                const SizedBox(height: 20),
              ],

              // IASP worldwide link — always shown
              GestureDetector(
                onTap: _openIasp,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.language, size: 18, color: AppColors.seafoam),
                    const SizedBox(width: 8),
                    Text(
                      'Find crisis centres worldwide',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.seafoam,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.seafoam,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new, size: 14, color: AppColors.seafoam),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Always-free badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_open,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'This screen is always free. No subscription required.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
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
  }
}

class _ResourceCard extends StatelessWidget {
  final _CrisisResource resource;
  final VoidCallback onCall;

  const _ResourceCard({required this.resource, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.midGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resource.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resource.number,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.seafoam,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.phone, size: 16),
            label: const Text('CALL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrisisResource {
  final String name;
  final String description;
  final String number;
  final String dialNumber;

  const _CrisisResource({
    required this.name,
    required this.description,
    required this.number,
    required this.dialNumber,
  });
}
