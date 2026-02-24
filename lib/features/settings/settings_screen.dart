import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/premium_service.dart';
import '../../shared/widgets/anchor_logo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Profile card
            ValueListenableBuilder<bool>(
              valueListenable: PremiumService.instance.isPremium,
              builder: (context, isPremium, _) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withAlpha(15),
                          border: Border.all(
                            color: AppColors.white.withAlpha(60),
                          ),
                        ),
                        child: const Center(
                          child: AnchorLogo(size: 24, color: AppColors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, Sailor',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              isPremium ? 'ANCHORAGE+' : 'Free plan',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isPremium
                                    ? AppColors.gold
                                    : AppColors.seafoam,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isPremium)
                        TextButton(
                          onPressed: () => context.push('/paywall'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.gold,
                          ),
                          child: const Text('UPGRADE'),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            _SectionHeader(title: 'Protection'),
            _SettingsTile(
              icon: Icons.security,
              title: 'Guarded Apps',
              subtitle: 'Choose apps to intercept',
              onTap: () => context.push('/guarded-apps'),
            ),
            _SettingsTile(
              icon: Icons.vpn_lock,
              title: 'VPN Protection',
              subtitle: 'Active — explicit content blocked',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.seafoam.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.seafoam.withAlpha(120)),
                ),
                child: Text(
                  'ON',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.seafoam,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            _SettingsTile(
              icon: Icons.timer,
              title: 'Screen Time Limits',
              subtitle: 'Set daily usage limits',
              onTap: () {},
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Accountability'),
            _SettingsTile(
              icon: Icons.person_add,
              title: 'Accountability Partner',
              subtitle: 'Share your progress with someone',
              onTap: () => context.push('/accountability'),
            ),
            _SettingsTile(
              icon: Icons.notifications,
              title: 'Daily Check-in Reminder',
              subtitle: 'Not set',
              onTap: () {},
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Account'),
            _SettingsTile(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.lock,
              title: 'Change PIN / Password',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.star,
              title: 'Subscription',
              onTap: () => context.push('/paywall'),
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Support'),
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () {},
            ),

            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Sign Out',
              titleColor: AppColors.danger,
              onTap: () {
                // TODO: Firebase sign out
              },
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'ANCHORAGE v1.0.0',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.navy, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: titleColor ?? AppColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: theme.textTheme.bodySmall)
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right,
                    color: AppColors.slate,
                    size: 20,
                  )
                : null),
      ),
    );
  }
}
