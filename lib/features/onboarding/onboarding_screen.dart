import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/guardable_app.dart';
import '../../services/accountability_service.dart';
import '../../services/guard_service.dart';
import '../../services/premium_service.dart';
import '../../services/tamper_service.dart';
import '../../services/user_preferences_service.dart';
import '../../services/vpn_service.dart';
import '../../shared/widgets/anchor_logo.dart';

// REMOVED: Storm Mode removed from V1. Do not re-add without safety review.
// REMOVED: Partner-held PIN lockout removed from V1. Do not re-add without safety review.
// Only Harbour (free) and Anchor (paid) blocking modes are available.

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _controller = PageController();
  int _currentPage = 0;
  static const _totalPages = 6;

  // Screen 1: Name + Email
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Screen 2: DOB + Gender + Usage frequency
  String? _selectedGender;
  int? _selectedBirthYear;
  bool _dobSkipped = false;
  String? _selectedUsageFrequency;

  // Screen 3: Values
  final Set<String> _selectedValues = {};

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

  // Screen 4: Permissions
  bool _usageGranted = false;
  bool _overlayGranted = false;
  bool _batteryExempt = false;
  bool _vpnReady = false;
  bool _waitingForUsage = false;
  bool _waitingForOverlay = false;
  bool _waitingForBattery = false;
  bool _waitingForVpn = false;
  bool _waitingForDeviceAdmin = false;
  bool _deviceAdminActive = false;

  // Screen 5: Guarded apps
  final Set<String> _selectedApps = {};

  // Screen 6: Accountability
  final _partnerNameController = TextEditingController();
  final _partnerEmailController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _emailController.dispose();
    _partnerNameController.dispose();
    _partnerEmailController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _onResume();
  }

  Future<void> _checkPermissions() async {
    final usage = await GuardService.hasUsagePermission();
    final overlay = await GuardService.hasOverlayPermission();
    final battery = await GuardService.isBatteryOptimizationExempt();
    final vpn = await VpnService.isVpnActive();
    final deviceAdmin = await TamperService.isDeviceAdminActive();
    if (!mounted) return;
    setState(() {
      _usageGranted = usage;
      _overlayGranted = overlay;
      _batteryExempt = battery;
      _vpnReady = vpn;
      _deviceAdminActive = deviceAdmin;
    });
  }

  Future<void> _onResume() async {
    if (_waitingForUsage) {
      _waitingForUsage = false;
      final granted = await GuardService.hasUsagePermission();
      if (mounted) setState(() => _usageGranted = granted);
    }
    if (_waitingForOverlay) {
      _waitingForOverlay = false;
      final granted = await GuardService.hasOverlayPermission();
      if (mounted) setState(() => _overlayGranted = granted);
    }
    if (_waitingForBattery) {
      _waitingForBattery = false;
      final exempt = await GuardService.isBatteryOptimizationExempt();
      if (mounted) setState(() => _batteryExempt = exempt);
    }
    if (_waitingForVpn) {
      _waitingForVpn = false;
      final ready = await VpnService.prepareVpn();
      if (ready) {
        await VpnService.startVpn();
        if (mounted) setState(() => _vpnReady = true);
      }
    }
    if (_waitingForDeviceAdmin) {
      _waitingForDeviceAdmin = false;
      final active = await TamperService.isDeviceAdminActive();
      if (mounted) setState(() => _deviceAdminActive = active);
    }
  }

  void _goToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _saving = true);

    // Save name
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await UserPreferencesService.instance.setFirstName(name);
    }

    // Save email
    final email = _emailController.text.trim();
    await UserPreferencesService.instance.setEmail(email);

    // Save guarded apps and start guard
    final packages = _selectedApps.toList();
    await GuardService.saveGuardedPackages(packages);
    if (packages.isNotEmpty && _usageGranted) {
      await GuardService.start(packages);
    }

    // Send accountability invite if both fields filled
    final partnerName = _partnerNameController.text.trim();
    final partnerEmail = _partnerEmailController.text.trim();
    if (partnerName.isNotEmpty && partnerEmail.isNotEmpty) {
      try {
        await AccountabilityService.instance.invitePartner(
          name: partnerName,
          email: partnerEmail,
        );
      } catch (e) {
        debugPrint('[Onboarding] Failed to send invite: $e');
      }
    }

    // Mark complete
    await UserPreferencesService.instance.setOnboardingComplete(true);
    if (UserPreferencesService.instance.installDate == 0) {
      await UserPreferencesService.instance
          .setInstallDate(DateTime.now().millisecondsSinceEpoch);
    }

    FirebaseAnalytics.instance.logEvent(name: 'onboarding_complete');

    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/home');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.navy,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
          children: [
            // Page indicator dots
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) {
                  final isCurrent = i == _currentPage;
                  // Pages with white bg use navy dots
                  final onLightBg = _currentPage == 1 || _currentPage == 2;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: onLightBg
                          ? (isCurrent
                              ? AppColors.navy
                              : AppColors.navy.withAlpha(60))
                          : (isCurrent
                              ? AppColors.white
                              : AppColors.white.withAlpha(60)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildAboutYouPage(),
                  _buildValuesPage(),
                  _buildPermissionsPage(),
                  _buildGuardedAppsPage(),
                  _buildAccountabilityPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // == Screen 1: Welcome + Name + Email ===================================

  Widget _buildWelcomePage() {
    final theme = Theme.of(context);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(height: keyboardVisible ? 16 : 48),
          if (!keyboardVisible) ...[
            const AnchorLogo(size: 64, color: AppColors.white),
            const SizedBox(height: 16),
            Text(
              'ANCHORAGE',
              style: theme.textTheme.displayMedium?.copyWith(
                color: AppColors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay Grounded',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.white.withAlpha(180),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
          ],
          Text(
            'What should we call you?',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: false,
            cursorColor: AppColors.white,
            style: const TextStyle(color: AppColors.white, fontSize: 20),
            textCapitalization: TextCapitalization.words,
            maxLength: 20,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white.withAlpha(15),
              hintText: 'Your first name',
              hintStyle:
                  TextStyle(color: AppColors.white.withAlpha(100)),
              counterStyle:
                  TextStyle(color: AppColors.white.withAlpha(80)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.white.withAlpha(60)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.seafoam, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            autofocus: false,
            cursorColor: AppColors.white,
            style: const TextStyle(color: AppColors.white, fontSize: 18),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white.withAlpha(15),
              labelText: 'Email',
              labelStyle:
                  TextStyle(color: AppColors.white.withAlpha(140)),
              floatingLabelStyle:
                  const TextStyle(color: AppColors.seafoam),
              hintText: 'your@email.com',
              hintStyle:
                  TextStyle(color: AppColors.white.withAlpha(80)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.white.withAlpha(60)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.seafoam, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Used to restore your account and keep you updated with tips, new features, and offers from the Anchorage team.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.white.withAlpha(120),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Builder(builder: (context) {
              final name = _nameController.text.trim();
              final email = _emailController.text.trim();
              final nameValid = name.isNotEmpty && RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
              final emailValid = email.contains('@') && email.contains('.', email.indexOf('@'));
              final canContinue = nameValid && emailValid;

              return FilledButton(
                onPressed: canContinue
                    ? () {
                        UserPreferencesService.instance.setFirstName(name);
                        UserPreferencesService.instance.setEmail(email);
                        FocusScope.of(context).unfocus();
                        _nextPage();
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.navy,
                  disabledBackgroundColor: AppColors.white.withAlpha(40),
                  disabledForegroundColor: AppColors.navy.withAlpha(100),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'CONTINUE',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: canContinue
                        ? AppColors.navy
                        : AppColors.navy.withAlpha(100),
                    letterSpacing: 2,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'ANCHORAGE is a self-help tool. It is not a mental health service.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.white.withAlpha(90),
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // == Screen 2: About You (Gender + Birth Year + Usage Frequency) ========

  bool _isUnder18(int birthYear) {
    return DateTime.now().year - birthYear < 18;
  }

  bool get _dobAnswered => _selectedBirthYear != null || _dobSkipped;

  void _showYearPicker() {
    final currentYear = DateTime.now().year;
    final initialYear = _selectedBirthYear ?? (currentYear - 25);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select birth year'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(1940),
              lastDate: DateTime(currentYear),
              selectedDate: DateTime(initialYear),
              onChanged: (DateTime dateTime) {
                Navigator.pop(ctx);
                final year = dateTime.year;
                if (_isUnder18(year)) {
                  FirebaseAnalytics.instance.logEvent(name: 'onboarding_blocked_minor');
                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Age requirement'),
                        content: const Text(
                          'ANCHORAGE is designed for adults aged 18 and over. '
                          'We are not able to create an account for you at this time.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }
                setState(() {
                  _selectedBirthYear = year;
                  _dobSkipped = false;
                });
                UserPreferencesService.instance.setBirthYear(year);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutYouPage() {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          // Skip button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 4),
              child: TextButton(
                onPressed: () => _nextPage(),
                child: Text(
                  'Skip',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.navy.withAlpha(160),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'A bit about you',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps us personalise your experience. Both are optional.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Gender selection
                  Text(
                    'Gender',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Male', 'Female', 'Non-binary', 'Prefer not to say']
                        .map((g) {
                      final isSelected = _selectedGender == g;
                      return GestureDetector(
                        onTap: () {
                          setState(() =>
                              _selectedGender = isSelected ? null : g);
                          UserPreferencesService.instance
                              .setGender(isSelected ? null : g);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.navy
                                : AppColors.lightGray,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.navy
                                  : AppColors.midGray,
                            ),
                          ),
                          child: Text(
                            g,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.navy,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Birth year
                  Text(
                    'When were you born?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _selectedBirthYear != null
                            ? '$_selectedBirthYear'
                            : (_dobSkipped ? 'Prefer not to say' : 'Select year'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: BorderSide(color: AppColors.midGray),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _showYearPicker,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        FirebaseAnalytics.instance.logEvent(name: 'onboarding_skipped_dob');
                        setState(() {
                          _dobSkipped = true;
                          _selectedBirthYear = null;
                        });
                        UserPreferencesService.instance.setBirthYear(null);
                      },
                      child: Text(
                        'Prefer not to say',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Usage frequency
                  Text(
                    'How often do you find yourself viewing content you want to change?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Daily',
                      'Several times a week',
                      'Weekly',
                      'Less often',
                      'Prefer not to say',
                    ].map((f) {
                      final isSelected = _selectedUsageFrequency == f;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedUsageFrequency =
                              isSelected ? null : f);
                          UserPreferencesService.instance
                              .setUsageFrequency(isSelected ? null : f);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.navy
                                : AppColors.lightGray,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.navy
                                  : AppColors.midGray,
                            ),
                          ),
                          child: Text(
                            f,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.navy,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Privacy note
                  Center(
                    child: Text(
                      'Everything you share here stays on your device. We never see it.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Continue button (disabled until DOB answered)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _dobAnswered
                    ? () {
                        UserPreferencesService.instance
                            .setGender(_selectedGender);
                        UserPreferencesService.instance
                            .setBirthYear(_selectedBirthYear);
                        UserPreferencesService.instance
                            .setUsageFrequency(_selectedUsageFrequency);
                        _nextPage();
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.navy.withAlpha(30),
                  disabledForegroundColor: AppColors.navy.withAlpha(80),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'CONTINUE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _dobAnswered
                            ? AppColors.white
                            : AppColors.navy.withAlpha(80),
                        letterSpacing: _dobAnswered ? 2 : 1,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // == Screen 3: Values =====================================================

  Widget _buildValuesPage() {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'What matters to you?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose 3 values. These will guide your ANCHORAGE experience.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${_selectedValues.length} of 3 selected',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _selectedValues.length == 3
                          ? AppColors.navy
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _valueOptions.map((v) {
                      final isSelected = _selectedValues.contains(v);
                      return FilterChip(
                        label: Text(v),
                        selected: isSelected,
                        selectedColor: AppColors.navy,
                        backgroundColor: AppColors.lightGray,
                        checkmarkColor: AppColors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.white : AppColors.navy,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.navy
                                : AppColors.midGray,
                          ),
                        ),
                        onSelected: (sel) {
                          setState(() {
                            if (sel && _selectedValues.length < 3) {
                              _selectedValues.add(v);
                            } else if (!sel) {
                              _selectedValues.remove(v);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'You can change these later in Settings.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedValues.length == 3
                    ? () {
                        UserPreferencesService.instance
                            .setValues(_selectedValues.toList());
                        _nextPage();
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.navy.withAlpha(30),
                  disabledForegroundColor: AppColors.navy.withAlpha(80),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'CONTINUE',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _selectedValues.length == 3
                        ? AppColors.white
                        : AppColors.navy.withAlpha(80),
                    letterSpacing: _selectedValues.length == 3 ? 2 : 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // == Screen 4: Permissions ==============================================

  Widget _buildPermissionsPage() {
    final theme = Theme.of(context);
    final allGranted =
        _usageGranted && _overlayGranted && _batteryExempt && _vpnReady;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  'ANCHORAGE needs a few permissions to protect you',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'These are required for guard and VPN features to work.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 28),
                _PermissionRow(
                  icon: Icons.bar_chart,
                  title: 'Usage Access',
                  subtitle: 'Detect when guarded apps open',
                  granted: _usageGranted,
                  onGrant: () async {
                    _waitingForUsage = true;
                    await GuardService.requestUsagePermission();
                  },
                ),
                const SizedBox(height: 10),
                _PermissionRow(
                  icon: Icons.layers,
                  title: 'Display Over Apps',
                  subtitle: 'Show intercept when urge hits',
                  granted: _overlayGranted,
                  onGrant: () async {
                    _waitingForOverlay = true;
                    await GuardService.requestOverlayPermission();
                  },
                ),
                const SizedBox(height: 10),
                _PermissionRow(
                  icon: Icons.battery_saver,
                  title: 'Unrestricted Battery',
                  subtitle: 'Keep protection running always',
                  granted: _batteryExempt,
                  onGrant: () async {
                    _waitingForBattery = true;
                    await GuardService.requestBatteryOptimizationExempt();
                    await Future.delayed(const Duration(milliseconds: 500));
                    final exempt =
                        await GuardService.isBatteryOptimizationExempt();
                    if (mounted) setState(() => _batteryExempt = exempt);
                  },
                ),
                const SizedBox(height: 10),
                _PermissionRow(
                  icon: Icons.shield_outlined,
                  title: 'VPN Content Filter',
                  subtitle: 'Block explicit content in browsers',
                  granted: _vpnReady,
                  onGrant: () async {
                    final ready = await VpnService.prepareVpn();
                    if (ready) {
                      await VpnService.startVpn();
                      if (mounted) setState(() => _vpnReady = true);
                    } else {
                      _waitingForVpn = true;
                    }
                  },
                ),

                // Advanced Protection (shown after core permissions)
                if (_vpnReady) ...[
                  const SizedBox(height: 20),
                  Text(
                    'ADVANCED PROTECTION',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withAlpha(100),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended for stronger protection.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withAlpha(80),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PermissionRow(
                    icon: Icons.admin_panel_settings,
                    title: 'Device Admin',
                    subtitle: 'Prevents ANCHORAGE from being uninstalled without deactivating first. Recommended.',
                    granted: _deviceAdminActive,
                    onGrant: () async {
                      _waitingForDeviceAdmin = true;
                      await TamperService.requestDeviceAdmin();
                    },
                  ),
                  const SizedBox(height: 10),
                  _AlwaysOnVpnRow(
                    onTap: () => TamperService.openAlwaysOnVpnSettings(),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _BottomButton(
          label: allGranted
              ? 'CONTINUE'
              : 'GRANT ALL PERMISSIONS TO CONTINUE',
          onPressed: allGranted ? _nextPage : null,
        ),
      ],
    );
  }

  // == Screen 5: Guarded Apps =============================================

  Widget _buildGuardedAppsPage() {
    final theme = Theme.of(context);
    final isPremium = PremiumService.instance.isPremium.value;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Which apps should ANCHORAGE watch?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPremium
                      ? 'Select as many apps as you like.'
                      : '${GuardableApp.freeTierLimit} apps on free plan',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withAlpha(160),
                  ),
                ),

                // Free tier slot indicator
                if (!isPremium) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ...List.generate(GuardableApp.freeTierLimit, (i) {
                        final filled = i < _selectedApps.length;
                        return Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? AppColors.seafoam
                                : Colors.transparent,
                            border: Border.all(
                              color: filled
                                  ? AppColors.seafoam
                                  : AppColors.white.withAlpha(40),
                              width: 2,
                            ),
                          ),
                          child: filled
                              ? const Icon(Icons.check,
                                  color: AppColors.navy, size: 14)
                              : null,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedApps.length} / ${GuardableApp.freeTierLimit} selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                ...GuardableApp.predefined.map((app) {
                  final isSelected =
                      _selectedApps.contains(app.packageName);
                  final atLimit = !isPremium &&
                      _selectedApps.length >= GuardableApp.freeTierLimit;
                  final isLocked = !isSelected && atLimit;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AppTile(
                      app: app,
                      isSelected: isSelected,
                      isLocked: isLocked,
                      onTap: () {
                        if (isSelected) {
                          setState(
                              () => _selectedApps.remove(app.packageName));
                        } else if (isLocked) {
                          _showSnack(
                            'Free plan: up to ${GuardableApp.freeTierLimit} apps. '
                            'Upgrade to guard more.',
                          );
                        } else {
                          setState(
                              () => _selectedApps.add(app.packageName));
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _BottomButton(
          label: 'CONTINUE',
          onPressed: () {
            if (_selectedApps.isEmpty) {
              _showSnack('Select at least 1 app to guard.');
              return;
            }
            _nextPage();
          },
        ),
      ],
    );
  }

  // == Screen 6: Accountability Partner ===================================

  Widget _buildAccountabilityPage() {
    final theme = Theme.of(context);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: keyboardVisible ? 16 : 32),
          if (!keyboardVisible) ...[
            const Center(
              child: AnchorLogo(size: 40, color: AppColors.seafoam),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Add someone you trust',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "They'll receive a weekly report with "
            'no sensitive details, just your progress.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withAlpha(160),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _partnerNameController,
            autofocus: false,
            cursorColor: AppColors.white,
            style: const TextStyle(
                color: AppColors.white, fontSize: 18),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white.withAlpha(15),
              labelText: 'Their name',
              labelStyle:
                  TextStyle(color: AppColors.white.withAlpha(140)),
              floatingLabelStyle:
                  const TextStyle(color: AppColors.seafoam),
              prefixIcon: Icon(Icons.person_outline,
                  color: AppColors.white.withAlpha(140)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppColors.white.withAlpha(60)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.seafoam, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _partnerEmailController,
            autofocus: false,
            cursorColor: AppColors.white,
            style: const TextStyle(
                color: AppColors.white, fontSize: 18),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white.withAlpha(15),
              labelText: 'Their email',
              labelStyle:
                  TextStyle(color: AppColors.white.withAlpha(140)),
              floatingLabelStyle:
                  const TextStyle(color: AppColors.seafoam),
              prefixIcon: Icon(Icons.email_outlined,
                  color: AppColors.white.withAlpha(140)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppColors.white.withAlpha(60)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.seafoam, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving
                  ? null
                  : () {
                      final pName =
                          _partnerNameController.text.trim();
                      final pEmail =
                          _partnerEmailController.text.trim();
                      if (pName.isNotEmpty && pEmail.isEmpty) {
                        _showSnack(
                            'Please enter their email address.');
                        return;
                      }
                      if (pEmail.isNotEmpty &&
                          !pEmail.contains('@')) {
                        _showSnack('Please enter a valid email.');
                        return;
                      }
                      FocusScope.of(context).unfocus();
                      _completeOnboarding();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.navy,
                disabledBackgroundColor:
                    AppColors.white.withAlpha(60),
                padding:
                    const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.navy,
                      ),
                    )
                  : Text(
                      'GET STARTED',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.navy,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _saving
                  ? null
                  : () {
                      _partnerNameController.clear();
                      _partnerEmailController.clear();
                      FocusScope.of(context).unfocus();
                      _completeOnboarding();
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: BorderSide(
                    color: AppColors.white.withAlpha(100)),
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Skip for now',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.white.withAlpha(180),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Everything you write stays on your device. We never see it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.white.withAlpha(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// == Bottom CTA Button ====================================================

class _BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _BottomButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.navy,
            disabledBackgroundColor: AppColors.white.withAlpha(30),
            disabledForegroundColor: AppColors.white.withAlpha(80),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color:
                      enabled ? AppColors.navy : AppColors.white.withAlpha(80),
                  letterSpacing: enabled ? 2 : 1,
                ),
          ),
        ),
      ),
    );
  }
}

// == Permission Row =======================================================

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onGrant;

  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: granted
            ? AppColors.success.withAlpha(20)
            : AppColors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted
              ? AppColors.success.withAlpha(80)
              : AppColors.white.withAlpha(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: granted
                  ? AppColors.success.withAlpha(30)
                  : AppColors.white.withAlpha(15),
            ),
            child: Icon(
              granted ? Icons.check : icon,
              color: granted
                  ? AppColors.success
                  : AppColors.white.withAlpha(180),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withAlpha(140),
                  ),
                ),
              ],
            ),
          ),
          if (granted)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
              child:
                  const Icon(Icons.check, color: AppColors.white, size: 18),
            )
          else
            FilledButton(
              onPressed: onGrant,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.seafoam,
                foregroundColor: AppColors.navy,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Grant',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}

// == App Tile =============================================================

class _AppTile extends StatelessWidget {
  final GuardableApp app;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _AppTile({
    required this.app,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.white.withAlpha(15)
              : AppColors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.seafoam
                : isLocked
                    ? AppColors.gold.withAlpha(40)
                    : AppColors.white.withAlpha(25),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(app.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                app.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isLocked
                      ? AppColors.white.withAlpha(80)
                      : AppColors.white,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.seafoam,
                ),
                child:
                    const Icon(Icons.check, color: AppColors.navy, size: 16),
              )
            else if (isLocked)
              Icon(
                Icons.lock_outline,
                color: AppColors.gold.withAlpha(120),
                size: 20,
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withAlpha(40),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// == Always-on VPN Guide Row ==============================================

class _AlwaysOnVpnRow extends StatelessWidget {
  final VoidCallback onTap;

  const _AlwaysOnVpnRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.white.withAlpha(30)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withAlpha(15),
              ),
              child: Icon(
                Icons.vpn_lock,
                color: AppColors.white.withAlpha(180),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Always-on VPN',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Keeps content filtering active at all times, even after a device restart. Recommended.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: AppColors.seafoam.withAlpha(180),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
