import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      question: 'How does ANCHORAGE block content?',
      answer:
          'ANCHORAGE uses a local VPN to intercept DNS queries and block '
          'known explicit domains. No traffic leaves your device — everything '
          'is filtered locally. The app also monitors guarded apps using '
          'Android\'s UsageStats API and shows an overlay when they\'re opened.',
    ),
    (
      question: 'Does ANCHORAGE slow down my internet?',
      answer:
          'No. ANCHORAGE uses DNS-only routing, meaning only DNS queries '
          'pass through the VPN filter. All other traffic (web browsing, '
          'streaming, gaming) goes directly to the internet without any '
          'extra processing.',
    ),
    (
      question: 'Is my data private?',
      answer:
          'Yes. Urge logs, relapse reflections, and journal entries are '
          'stored locally on your device only. They are never uploaded to '
          'our servers. Streak data is synced to Firebase so it persists '
          'across reinstalls, but no personal content is included.',
    ),
    (
      question: 'What is an accountability partner?',
      answer:
          'An accountability partner is someone you trust — a friend, '
          'mentor, or counsellor — who receives a brief weekly email '
          'summary of your streak and progress. They don\'t see any '
          'personal logs or details.',
    ),
    (
      question: 'How do I cancel my subscription?',
      answer:
          'Subscriptions are managed through the Google Play Store. '
          'Go to Play Store → tap your profile → Payments & subscriptions '
          '→ Subscriptions → ANCHORAGE → Cancel. You\'ll keep access '
          'until the end of your billing period.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('HELP & FAQ')),
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
                    'Frequently asked questions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find answers to common questions about ANCHORAGE.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withAlpha(180),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ..._faqs.map((faq) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FaqTile(
                    question: faq.question,
                    answer: faq.answer,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.midGray),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        title: Text(
          question,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            answer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
