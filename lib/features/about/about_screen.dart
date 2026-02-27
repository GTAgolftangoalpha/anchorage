import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/anchor_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openFindAHelpline() async {
    final uri = Uri.parse('https://findahelpline.com');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ABOUT ANCHORAGE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withAlpha(12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: AnchorLogo(size: 40, color: AppColors.navy),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Our Approach
              _SectionTitle(title: 'Our Approach'),
              const SizedBox(height: 12),
              Text(
                "ANCHORAGE isn't just another blocker. It's built on Acceptance and Commitment Therapy (ACT) \u2014 the most evidence-based psychological approach for changing unwanted sexual behaviours, with clinical trials showing 85\u201393% reductions in problematic use.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Most apps try to build a wall between you and content. Walls can be climbed. ANCHORAGE works differently \u2014 it uses the moments of temptation as opportunities to practise the psychological skills that create lasting change.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'When an urge hits, ANCHORAGE helps you:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 8),
              _BulletPoint(
                text: 'Notice the urge without obeying it (cognitive defusion)',
                theme: theme,
              ),
              _BulletPoint(
                text:
                    'Reconnect with what actually matters to you (values clarification)',
                theme: theme,
              ),
              _BulletPoint(
                text: 'Ride the wave until it passes (urge surfing)',
                theme: theme,
              ),
              _BulletPoint(
                text:
                    'Understand your triggers (present moment awareness)',
                theme: theme,
              ),
              const SizedBox(height: 16),
              Text(
                "These aren't motivational quotes. They're evidence-based techniques used by psychologists worldwide.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 32),
              const Divider(color: AppColors.midGray),
              const SizedBox(height: 24),

              // Section 2: What We Believe
              _SectionTitle(title: 'What We Believe'),
              const SizedBox(height: 12),
              Text(
                "We believe pornography use exists on a spectrum \u2014 and that many people want to change their relationship with it without being labelled or shamed.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "We don't use the word \u2018addiction\u2019. We don't promise a cure. We don't track or judge your behaviour.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "We give you tools, accountability, and the psychological strategies to make different choices \u2014 one moment at a time.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 32),
              const Divider(color: AppColors.midGray),
              const SizedBox(height: 24),

              // Section 3: Your Privacy
              _SectionTitle(title: 'Your Privacy'),
              const SizedBox(height: 12),
              Text(
                "Your values, reflections, urge logs, and personal data never leave your device. Accountability emails contain only streak and progress data \u2014 never what you tried to access. You're in control.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 32),
              const Divider(color: AppColors.midGray),
              const SizedBox(height: 24),

              // Section 4: Need More Support?
              _SectionTitle(title: 'Need More Support?'),
              const SizedBox(height: 12),
              Text(
                "ANCHORAGE is a self-help tool, not a replacement for professional support. If you're struggling, please reach out.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'If you are in crisis, please visit findahelpline.com for support in your country.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _openFindAHelpline,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.language, color: AppColors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'findahelpline.com',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.open_in_new, color: AppColors.white, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _BulletPoint({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.seafoam,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

