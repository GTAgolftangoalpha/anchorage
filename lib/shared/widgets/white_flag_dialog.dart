import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/accountability_service.dart';
import '../../services/premium_service.dart';
import '../../services/white_flag_service.dart';

/// Shows a White Flag confirmation bottom sheet. Returns true if the user
/// confirmed, false if they cancelled.
Future<bool> showWhiteFlagConfirmation(
  BuildContext context, {
  required String blockedTarget,
}) async {
  final isPremium = PremiumService.instance.isPremium.value;
  bool hasPartner = false;
  if (isPremium) {
    try {
      final partners =
          await AccountabilityService.instance.watchPartners().first;
      hasPartner = partners.any((p) => p.status == 'accepted');
    } catch (_) {}
  }

  if (!context.mounted) return false;

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Raise the White Flag?',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'White Flag pauses your protection and lets you through. '
              'Use it if ANCHORAGE is blocking something it shouldn\'t. '
              'Your choice is always yours.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withAlpha(180),
                height: 1.6,
              ),
            ),
            if (isPremium && hasPartner) ...[
              const SizedBox(height: 12),
              Text(
                'Your accountability partner will be notified.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white.withAlpha(25),
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Yes, let me through'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.seafoam,
                  side: const BorderSide(color: AppColors.seafoam),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Stay anchored'),
              ),
            ),
          ],
        ),
      );
    },
  );

  if (result == true) {
    await WhiteFlagService.instance.logWhiteFlag(
      blockedTarget: blockedTarget,
    );
    return true;
  }
  return false;
}
