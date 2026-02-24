import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../services/premium_service.dart';
import '../../services/user_preferences_service.dart';
import '../../services/vpn_service.dart';
import '../../shared/widgets/anchor_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _vpnActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshVpnState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshVpnState();
  }

  Future<void> _refreshVpnState() async {
    final active = await VpnService.isVpnActive();
    if (mounted) setState(() => _vpnActive = active);
  }

  static const _privacyUrl = 'https://anchorageapp.com/privacy';
  static const _termsUrl = 'https://anchorageapp.com/terms';

  static const _valueOptions = [
    'Relationship integrity',
    'Self-respect',
    'Being present for family',
    'Career focus',
    'Mental clarity',
    'Physical health',
    'Spiritual growth',
    'Emotional stability',
    'Trust',
    'Freedom',
  ];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: UserPreferencesService.instance.firstName,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit your name'),
        content: TextField(
          controller: controller,
          maxLength: 20,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'First name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await UserPreferencesService.instance.setFirstName(name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditValuesSheet(BuildContext context) {
    final current = Set<String>.from(UserPreferencesService.instance.values);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit your values',
                    style: Theme.of(ctx).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select exactly 3 values.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _valueOptions.map((v) {
                      final selected = current.contains(v);
                      return FilterChip(
                        label: Text(v),
                        selected: selected,
                        selectedColor: AppColors.seafoam.withAlpha(40),
                        checkmarkColor: AppColors.navy,
                        onSelected: (sel) {
                          setSheetState(() {
                            if (sel && current.length < 3) {
                              current.add(v);
                            } else if (!sel) {
                              current.remove(v);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: current.length == 3
                          ? () async {
                              await UserPreferencesService.instance
                                  .setValues(current.toList());
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) setState(() {});
                            }
                          : null,
                      child: Text('SAVE (${current.length}/3)'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'This will clear all local data (logs, reflections, settings) '
          'and sign you out. Your streak is backed up to the cloud and '
          'will restore on sign-in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      context.go('/onboarding');
    }
  }

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
                            Builder(builder: (context) {
                              final name =
                                  UserPreferencesService.instance.firstName;
                              return Text(
                                name.isNotEmpty
                                    ? 'Welcome, $name'
                                    : 'Welcome, Sailor',
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.white,
                                ),
                              );
                            }),
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

            _SectionHeader(title: 'Personalisation'),
            _SettingsTile(
              icon: Icons.edit,
              title: 'Edit my name',
              subtitle: UserPreferencesService.instance.firstName.isNotEmpty
                  ? UserPreferencesService.instance.firstName
                  : 'Not set',
              onTap: () => _showEditNameDialog(context),
            ),
            _SettingsTile(
              icon: Icons.favorite_border,
              title: 'Edit my values',
              subtitle: UserPreferencesService.instance.values.isNotEmpty
                  ? UserPreferencesService.instance.values.join(', ')
                  : 'Not set',
              onTap: () => _showEditValuesSheet(context),
            ),
            _SettingsTile(
              icon: Icons.timeline,
              title: 'My ANCHORAGE journey',
              subtitle: 'Your progress and stats',
              onTap: () => context.push('/journey'),
            ),

            const SizedBox(height: 8),
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
              subtitle: _vpnActive
                  ? 'Active — explicit content blocked'
                  : 'Inactive — tap to manage',
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _vpnActive
                      ? AppColors.seafoam.withAlpha(40)
                      : AppColors.slate.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _vpnActive
                        ? AppColors.seafoam.withAlpha(120)
                        : AppColors.slate.withAlpha(80),
                  ),
                ),
                child: Text(
                  _vpnActive ? 'ON' : 'OFF',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _vpnActive ? AppColors.seafoam : AppColors.slate,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            _SettingsTile(
              icon: Icons.dns_outlined,
              title: 'Custom Blocklist',
              subtitle: 'Add your own blocked domains',
              onTap: () => context.push('/custom-blocklist'),
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Accountability'),
            _SettingsTile(
              icon: Icons.person_add,
              title: 'Accountability Partner',
              subtitle: 'Share your progress with someone',
              onTap: () => context.push('/accountability'),
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Account'),
            _SettingsTile(
              icon: Icons.star,
              title: 'Subscription',
              onTap: () => context.push('/paywall'),
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Support'),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About ANCHORAGE',
              subtitle: 'Our approach, beliefs, and privacy',
              onTap: () => context.push('/about'),
            ),
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              onTap: () => context.push('/help'),
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => _launchUrl(_privacyUrl),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => _launchUrl(_termsUrl),
            ),

            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Sign Out',
              titleColor: AppColors.danger,
              onTap: () => _signOut(context),
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
