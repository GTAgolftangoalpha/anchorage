import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../services/intercept_event_service.dart';
import '../../services/intercept_prompt_service.dart';
import '../../services/premium_service.dart';
import '../../shared/widgets/anchor_logo.dart';

/// Full-screen overlay shown when a blocked site/app is intercepted.
class InterceptScreen extends StatefulWidget {
  const InterceptScreen({super.key});

  @override
  State<InterceptScreen> createState() => _InterceptScreenState();
}

class _InterceptScreenState extends State<InterceptScreen> {
  late final InterceptPrompt _prompt;
  bool _showNudge = false;

  @override
  void initState() {
    super.initState();
    _prompt = InterceptPromptService.instance.getPrompt();
    _checkNudgeEligibility();
  }

  Future<void> _checkNudgeEligibility() async {
    final isPremium = PremiumService.instance.isPremium.value;
    if (isPremium) return;

    final totalIntercepts = InterceptEventService.instance.events.value.length;
    if (totalIntercepts == 0) return; // First intercept, skip nudge

    final prefs = await SharedPreferences.getInstance();
    final lastNudge = prefs.getString('paywall_nudge_last_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastNudge == today) return;

    if (mounted) setState(() => _showNudge = true);
  }

  Future<void> _onNudgeTapped() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paywall_nudge_last_date', today);
    FirebaseAnalytics.instance.logEvent(
      name: 'paywall_nudge_tapped',
      parameters: {'source': 'post_intercept'},
    );
    if (mounted) context.push('/paywall');
  }

  void _logNudgeShown() {
    FirebaseAnalytics.instance.logEvent(
      name: 'paywall_nudge_shown',
      parameters: {'source': 'post_intercept'},
    );
    SharedPreferences.getInstance().then((prefs) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      prefs.setString('paywall_nudge_last_date', today);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Anchor warning
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withAlpha(15),
                  border: Border.all(
                    color: AppColors.white.withAlpha(60),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: AnchorLogo(size: 48, color: AppColors.white),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'HOLD ON.',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: AppColors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This content has been blocked\nby ANCHORAGE.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withAlpha(200),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 40),

              // ACT prompt card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withAlpha(30),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _prompt.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.seafoam,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _prompt.body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withAlpha(180),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pushReplacement('/reflect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.seafoam,
                    foregroundColor: AppColors.navy,
                  ),
                  child: const Text('REFLECT ON THIS MOMENT'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(color: AppColors.white.withAlpha(80)),
                  ),
                  child: const Text('GO BACK TO SAFETY'),
                ),
              ),

              // Upgrade nudge for free users
              if (_showNudge) ...[
                Builder(builder: (_) {
                  _logNudgeShown();
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.seafoam.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.seafoam.withAlpha(40)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: AppColors.seafoam, size: 28),
                      const SizedBox(height: 12),
                      Text(
                        'Want stronger protection next time?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ANCHORAGE+ adds hard blocking, unlimited guarded apps, '
                        'and a journal to track your patterns.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withAlpha(160),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _onNudgeTapped,
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
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
