import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../services/premium_service.dart';
import '../../services/user_preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  bool _deleting = false;

  Future<void> _deleteAllData() async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_all_data');
    setState(() => _deleting = true);
    try {
      // 1. Clear flutter_secure_storage
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      await secureStorage.deleteAll();

      // 2. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Delete Firestore user document and subcollections
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(uid);
        const subcollections = [
          'urge_logs',
          'reflect_entries',
          'intercept_events',
          'lapse_logs',
          'accountability',
          'partners',
          'stats',
          'heartbeats',
          'tamper_events',
        ];
        for (final sub in subcollections) {
          final snap = await userDoc.collection(sub).get();
          for (final doc in snap.docs) {
            await doc.reference.delete();
          }
        }
        await userDoc.delete();
      }

      // 4. Sign out of FirebaseAuth
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      setState(() => _deleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All your data has been deleted.'),
          backgroundColor: AppColors.success,
        ),
      );

      // 5. Navigate to onboarding (fresh install state)
      context.go('/onboarding');
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting data: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _confirmDeleteAllData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
          'This will permanently delete all your logs, journal entries, '
          'streak data, and preferences from this device. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAllData();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: const Text('Yes, delete everything'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
            _SectionHeader(title: 'Profile'),
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

            const SizedBox(height: 8),
            _SectionHeader(title: 'Protection'),
            _SettingsTile(
              icon: Icons.security,
              title: 'Guarded Apps',
              subtitle: 'Choose apps to intercept',
              onTap: () => context.push('/guarded-apps'),
            ),
            _SettingsTile(
              icon: Icons.dns_outlined,
              title: 'Custom Blocklist',
              subtitle: 'Add your own blocked domains',
              onTap: () => context.push('/custom-blocklist'),
            ),

            // HIDDEN: Accountability partner UI hidden until Cloud Function backend is built. Do not delete.
            // const SizedBox(height: 8),
            // _SectionHeader(title: 'Accountability'),
            // _SettingsTile(
            //   icon: Icons.person_add,
            //   title: 'Accountability Partner',
            //   subtitle: 'Share your progress with someone',
            //   onTap: () => context.push('/accountability'),
            // ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Subscription'),
            ValueListenableBuilder<bool>(
              valueListenable: PremiumService.instance.isPremium,
              builder: (context, isPremium, _) {
                if (isPremium) {
                  return _SettingsTile(
                    icon: Icons.check_circle,
                    title: 'ANCHORAGE+ Active',
                    subtitle: 'Manage your subscription via Google Play',
                  );
                }
                return _SettingsTile(
                  icon: Icons.star,
                  title: 'Upgrade to ANCHORAGE+',
                  subtitle: 'Unlock unlimited apps, custom blocklist, and more',
                  onTap: () => context.push('/paywall'),
                );
              },
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Data'),
            _SettingsTile(
              icon: Icons.picture_as_pdf,
              title: 'Export My Data',
              subtitle: 'Generate a PDF report for your therapist',
              onTap: () => context.push('/export'),
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Support'),
            _SettingsTile(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Help us improve ANCHORAGE',
              onTap: () {
                launchUrl(
                  Uri.parse(
                      'mailto:hello@getanchorage.app?subject=ANCHORAGE%20Feedback%20(v1.0.0)'),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About ANCHORAGE',
              subtitle: 'Our approach, beliefs, and privacy',
              onTap: () => context.push('/about'),
            ),
            _SettingsTile(
              icon: Icons.favorite_outline,
              title: 'Get Help',
              subtitle: 'Crisis resources and support lines',
              onTap: () => context.push('/sos'),
            ),
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & Legal',
              subtitle: 'FAQ, privacy policy, and terms',
              onTap: () => context.push('/help'),
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Danger Zone'),
            _SettingsTile(
              icon: Icons.delete_forever_outlined,
              title: 'Delete All My Data',
              subtitle: 'Permanently erase everything from this device',
              onTap: _deleting ? null : _confirmDeleteAllData,
              iconColor: Colors.red.shade700,
              titleColor: Colors.red.shade700,
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
          if (_deleting)
            Container(
              color: Colors.black.withAlpha(120),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.white),
              ),
            ),
        ],
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
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
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
          child: Icon(icon, color: iconColor ?? AppColors.navy, size: 20),
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
        trailing: onTap != null
            ? const Icon(
                Icons.chevron_right,
                color: AppColors.slate,
                size: 20,
              )
            : null,
      ),
    );
  }
}
