import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('HELP & LEGAL')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
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
                    'About ANCHORAGE',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ANCHORAGE is a self-help tool that blocks explicit content '
                    'and helps you build healthier habits. Your personal data '
                    'stays on your device.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withAlpha(180),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'LEGAL',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _HelpTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => context.push('/privacy'),
            ),
            const SizedBox(height: 8),
            _HelpTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => context.push('/terms'),
            ),
            const SizedBox(height: 24),
            Text(
              'SUPPORT',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _HelpTile(
              icon: Icons.email_outlined,
              title: 'Send Feedback',
              onTap: () async {
                final uri = Uri.parse(
                    'mailto:hello@getanchorage.app?subject=ANCHORAGE%20Feedback');
                try {
                  await launchUrl(uri);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please email us at hello@getanchorage.app'),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            _HelpTile(
              icon: Icons.favorite_outline,
              title: 'Crisis Resources',
              onTap: () => context.push('/sos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.midGray),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.navy, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate, size: 20),
          ],
        ),
      ),
    );
  }
}
