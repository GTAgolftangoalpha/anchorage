import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/intercept_prompt_service.dart';

/// Shown as a full-height modal bottom sheet when a guarded app is
/// detected in the foreground. The user must actively choose to reflect
/// or navigate away — there is no passive dismiss.
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
