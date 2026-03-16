import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../services/intercept_event_service.dart';
import '../../services/intercept_prompt_service.dart';
import '../../services/premium_service.dart';
import 'white_flag_dialog.dart';

/// Shown as a full-height modal bottom sheet when a guarded app is
/// detected in the foreground. The user must actively choose to reflect
/// or navigate away. There is no passive dismiss.
class InterceptBottomSheet extends StatelessWidget {
  final String appName;
  final InterceptPrompt prompt;

  const InterceptBottomSheet({
    super.key,
    required this.appName,
    required this.prompt,
  });

  /// Show this sheet from anywhere using the provided [context].
  static Future<void> show(BuildContext context, String appName) {
    final prompt = InterceptPromptService.instance.getPrompt();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => InterceptBottomSheet(appName: appName, prompt: prompt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.white.withAlpha(60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
              child: Column(
                children: [
                  // Anchor circle
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withAlpha(60),
                        width: 2,
                      ),
                      color: AppColors.white.withAlpha(12),
                    ),
                    child: const Center(
                      child: Text('\u2693', style: TextStyle(fontSize: 44)),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'HOLD ON.',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: AppColors.white,
                      letterSpacing: 4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.white.withAlpha(200),
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(text: 'You just opened '),
                        TextSpan(
                          text: appName,
                          style: const TextStyle(
                            color: AppColors.seafoam,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text: '.\nANCHORAGE intercepted it for you.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ACT prompt card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.white.withAlpha(25)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          prompt.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.seafoam,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          prompt.body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.white.withAlpha(180),
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/reflect');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.seafoam,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        'REFLECT ON THIS MOMENT',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.navy,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side:
                            BorderSide(color: AppColors.white.withAlpha(60)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        "I'M STAYING ANCHORED",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final confirmed = await showWhiteFlagConfirmation(
                        context,
                        blockedTarget: appName,
                      );
                      if (confirmed && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Text('\u{1F3F3}',
                        style: TextStyle(fontSize: 16)),
                    label: Text(
                      'White Flag',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withAlpha(140),
                      ),
                    ),
                  ),

                  // Upgrade nudge for free users
                  _UpgradeNudge(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeNudge extends StatefulWidget {
  @override
  State<_UpgradeNudge> createState() => _UpgradeNudgeState();
}

class _UpgradeNudgeState extends State<_UpgradeNudge> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (PremiumService.instance.isPremium.value) return;

    final totalIntercepts = InterceptEventService.instance.events.value.length;
    if (totalIntercepts == 0) return;

    final prefs = await SharedPreferences.getInstance();
    final lastNudge = prefs.getString('paywall_nudge_last_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastNudge == today) return;

    if (mounted) {
      setState(() => _show = true);
      await prefs.setString('paywall_nudge_last_date', today);
      FirebaseAnalytics.instance.logEvent(
        name: 'paywall_nudge_shown',
        parameters: {'source': 'post_intercept'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.seafoam.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.seafoam.withAlpha(40)),
        ),
        child: Column(
          children: [
            const Icon(Icons.shield_outlined,
                color: AppColors.seafoam, size: 24),
            const SizedBox(height: 8),
            Text(
              'Want stronger protection next time?',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ANCHORAGE+ adds unlimited guarded apps, '
              'accountability reports, and a journal to track your patterns.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.white.withAlpha(160),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  FirebaseAnalytics.instance.logEvent(
                    name: 'paywall_nudge_tapped',
                    parameters: {'source': 'post_intercept'},
                  );
                  Navigator.of(context).pop();
                  context.push('/paywall');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.seafoam,
                  foregroundColor: AppColors.navy,
                ),
                child: const Text(
                  'SEE PLANS',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
