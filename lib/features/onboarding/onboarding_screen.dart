import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/guardable_app.dart';
import '../../services/guard_service.dart';
import '../../services/premium_service.dart';
import '../../services/user_preferences_service.dart';
import '../../services/vpn_service.dart';
import '../../shared/widgets/anchor_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Permission states
  bool _overlayGranted = false;
  bool _batteryExempt = false;

  // Waiting flags for lifecycle-based recheck
  bool _waitingForOverlay = false;
  bool _waitingForBattery = false;
  bool _waitingForVpn = false;

  // User input states
  final _nameController = TextEditingController();
  final Set<String> _selectedValues = {};
  String? _selectedMotivation;
  String? _selectedImpact;
  final Set<String> _selectedGuardedApps = {};

  // Page indices
  static const _welcomeIdx = 0;
  static const _nameIdx = 1;
  static const _expectationsIdx = 2;
  static const _valuesIdx = 3;
  static const _motivationIdx = 4;
  static const _impactIdx = 5;
  static const _transitionIdx = 6;
  static const _overlayIdx = 7;
  static const _batteryIdx = 8;
  static const _vpnIdx = 9;
  static const _guardedAppsIdx = 10;
  static const _whatToExpectIdx = 11;
  static const _completionIdx = 12;
  static const _totalPages = 13;

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

  static const _motivationOptions = [
    "I'm ready to make a change",
    "I want to change but I'm not sure I can",
    "I'm just exploring my options",
    "Someone asked me to try this",
  ];

  static const _impactOptions = [
    "Not much \u2014 I just want better habits",
    "Somewhat \u2014 it's starting to bother me",
    "Significantly \u2014 it's affecting my relationships or work",
    "Severely \u2014 I feel out of control",
  ];

  String get _firstName => _nameController.text.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final overlay = await GuardService.hasOverlayPermission();
    final battery = await GuardService.isBatteryOptimizationExempt();
    if (mounted) {
      setState(() {
        _overlayGranted = overlay;
        _batteryExempt = battery;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _onResume();
  }

  Future<void> _onResume() async {
    if (_waitingForOverlay) {
      _waitingForOverlay = false;
      final granted = await GuardService.hasOverlayPermission();
      if (mounted) setState(() => _overlayGranted = granted);
      if (granted) _goTo(_batteryIdx);
    } else if (_waitingForBattery) {
      _waitingForBattery = false;
      final exempt = await GuardService.isBatteryOptimizationExempt();
      if (mounted) setState(() => _batteryExempt = exempt);
      if (exempt) _goTo(_vpnIdx);
    } else if (_waitingForVpn) {
      _waitingForVpn = false;
      await VpnService.startVpn();
      if (mounted) _goTo(_guardedAppsIdx);
    }
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  bool _validateName() {
    final name = _firstName;
    if (name.isEmpty) {
      _showSnack('Please enter your first name.');
      return false;
    }
    if (name.length > 20) {
      _showSnack('Name must be 20 characters or less.');
      return false;
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(name)) {
      _showSnack('Letters only, please.');
      return false;
    }
    return true;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.warning),
    );
  }

  Future<void> _onAction() async {
    final prefs = UserPreferencesService.instance;

    if (_currentPage == _welcomeIdx) {
      _goTo(_nameIdx);
    } else if (_currentPage == _nameIdx) {
      if (!_validateName()) return;
      await prefs.setFirstName(_firstName);
      _goTo(_expectationsIdx);
    } else if (_currentPage == _expectationsIdx) {
      _goTo(_valuesIdx);
    } else if (_currentPage == _valuesIdx) {
      if (_selectedValues.length != 3) {
        _showSnack('Please select exactly 3 values.');
        return;
      }
      await prefs.setValues(_selectedValues.toList());
      _goTo(_motivationIdx);
    } else if (_currentPage == _motivationIdx) {
      if (_selectedMotivation == null) {
        _showSnack('Please select an option.');
        return;
      }
      await prefs.setMotivation(_selectedMotivation!);
      _goTo(_impactIdx);
    } else if (_currentPage == _impactIdx) {
      if (_selectedImpact == null) {
        _showSnack('Please select an option.');
        return;
      }
      await prefs.setImpact(_selectedImpact!);
      _goTo(_transitionIdx);
    } else if (_currentPage == _transitionIdx) {
      _goTo(_overlayIdx);
    } else if (_currentPage == _overlayIdx) {
      final granted = await GuardService.hasOverlayPermission();
      if (mounted) setState(() => _overlayGranted = granted);
      if (granted) {
        _goTo(_batteryIdx);
      } else {
        _waitingForOverlay = true;
        await GuardService.requestOverlayPermission();
      }
    } else if (_currentPage == _batteryIdx) {
      final exempt = await GuardService.isBatteryOptimizationExempt();
      if (mounted) setState(() => _batteryExempt = exempt);
      if (exempt) {
        _goTo(_vpnIdx);
      } else {
        _waitingForBattery = true;
        await GuardService.requestBatteryOptimizationExempt();
      }
    } else if (_currentPage == _vpnIdx) {
      if (!mounted) return;
      final granted = await VpnService.prepareVpn();
      if (!mounted) return;
      if (granted) {
        await VpnService.startVpn();
        if (mounted) _goTo(_guardedAppsIdx);
      } else {
        _waitingForVpn = true;
      }
    } else if (_currentPage == _guardedAppsIdx) {
      if (_selectedGuardedApps.isEmpty) {
        _showSnack('Select at least 1 app to guard.');
        return;
      }
      final packages = _selectedGuardedApps.toList();
      await GuardService.saveGuardedPackages(packages);
      final hasUsage = await GuardService.hasUsagePermission();
      if (hasUsage) {
        await GuardService.start(packages);
      }
      _goTo(_whatToExpectIdx);
    } else if (_currentPage == _whatToExpectIdx) {
      _goTo(_completionIdx);
    } else if (_currentPage == _completionIdx) {
      await prefs.setOnboardingComplete(true);
      if (prefs.installDate == 0) {
        await prefs.setInstallDate(DateTime.now().millisecondsSinceEpoch);
      }
      if (mounted) context.go('/home');
    }
  }

  String get _buttonText {
    switch (_currentPage) {
      case _welcomeIdx:
      case _expectationsIdx:
        return 'CONTINUE';
      case _nameIdx:
      case _valuesIdx:
      case _motivationIdx:
      case _impactIdx:
        return 'CONTINUE';
      case _transitionIdx:
        return 'SET UP PERMISSIONS';
      case _overlayIdx:
        return _overlayGranted ? 'CONTINUE' : 'OPEN SETTINGS';
      case _batteryIdx:
        return _batteryExempt ? 'CONTINUE' : 'DISABLE OPTIMIZATION';
      case _vpnIdx:
        return 'ACTIVATE VPN SHIELD';
      case _guardedAppsIdx:
        return 'CONTINUE';
      case _whatToExpectIdx:
        return 'CONTINUE';
      case _completionIdx:
        return 'GET STARTED';
      default:
        return 'CONTINUE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _totalPages,
            itemBuilder: (_, index) {
              switch (index) {
                case _welcomeIdx:
                  return _WelcomePage();
                case _nameIdx:
                  return _NamePage(controller: _nameController);
                case _expectationsIdx:
                  return _ExpectationsPage();
                case _valuesIdx:
                  return _ValuesPage(
                    selectedValues: _selectedValues,
                    firstName: _firstName,
                    onToggle: (v) => setState(() {
                      if (_selectedValues.contains(v)) {
                        _selectedValues.remove(v);
                      } else if (_selectedValues.length < 3) {
                        _selectedValues.add(v);
                      } else {
                        _showSnack(
                            'You can only select 3 values. Deselect one first.');
                      }
                    }),
                  );
                case _motivationIdx:
                  return _RadioPage(
                    title: 'Where are you at right now?',
                    subtitle:
                        'No wrong answer. ANCHORAGE meets you where you are.',
                    options: _motivationOptions,
                    selected: _selectedMotivation,
                    onSelect: (v) =>
                        setState(() => _selectedMotivation = v),
                  );
                case _impactIdx:
                  return _RadioPage(
                    title: 'How much is this affecting your daily life?',
                    subtitle: 'This helps us tailor your experience.',
                    options: _impactOptions,
                    selected: _selectedImpact,
                    onSelect: (v) => setState(() => _selectedImpact = v),
                  );
                case _transitionIdx:
                  return _TransitionPage(firstName: _firstName);
                case _overlayIdx:
                  return _PermissionPage(
                    icon: Icons.layers_rounded,
                    title: 'Display Over\nOther Apps',
                    description:
                        'ANCHORAGE needs to display over other apps to show the intercept screen when you open a guarded app. Without this, content blocking cannot work.',
                    granted: _overlayGranted,
                    steps: const [
                      'Tap "OPEN SETTINGS" below',
                      'Toggle "Allow display over other apps" to ON',
                      'Press Back to return to ANCHORAGE',
                    ],
                  );
                case _batteryIdx:
                  return _PermissionPage(
                    icon: Icons.battery_saver_rounded,
                    title: 'Unrestricted\nBattery Access',
                    description:
                        'Samsung aggressively kills background services to save battery. ANCHORAGE must be exempt so the guard and VPN stay active at all times.',
                    granted: _batteryExempt,
                    steps: const [
                      'Tap "DISABLE OPTIMIZATION" below',
                      'Select "Allow" on the system dialog',
                      'Press Back to return to ANCHORAGE',
                    ],
                    samsungNote:
                        'Samsung users: If protection stops after the phone is idle, go to Settings \u2192 Battery \u2192 Background usage limits and remove ANCHORAGE from "Sleeping apps" or set it to "Unrestricted".',
                  );
                case _vpnIdx:
                  return _PermissionPage(
                    icon: Icons.vpn_lock_rounded,
                    title: 'Activate\nVPN Shield',
                    description:
                        'ANCHORAGE uses a local VPN to filter DNS requests and block explicit content at the network level. No data leaves your device \u2014 everything is processed locally.',
                    granted: false,
                    steps: const [
                      'Tap "ACTIVATE VPN SHIELD" below',
                      'Accept the Android VPN connection request',
                      'ANCHORAGE will begin protecting you immediately',
                    ],
                  );
                case _guardedAppsIdx:
                  return _GuardedAppsPage(
                    firstName: _firstName,
                    selected: _selectedGuardedApps,
                    onToggle: (pkg) => setState(() {
                      final isPremium =
                          PremiumService.instance.isPremium.value;
                      final atLimit = !isPremium &&
                          _selectedGuardedApps.length >=
                              GuardableApp.freeTierLimit;
                      if (_selectedGuardedApps.contains(pkg)) {
                        _selectedGuardedApps.remove(pkg);
                      } else if (!atLimit) {
                        _selectedGuardedApps.add(pkg);
                      } else {
                        _showSnack(
                            'Free plan: up to ${GuardableApp.freeTierLimit} apps.');
                      }
                    }),
                  );
                case _whatToExpectIdx:
                  return const _WhatToExpectPage();
                case _completionIdx:
                  return _CompletionPage(firstName: _firstName);
                default:
                  return const SizedBox.shrink();
              }
            },
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (i) {
                        final isCurrent = _currentPage == i;
                        final isGranted =
                            (i == _overlayIdx && _overlayGranted) ||
                                (i == _batteryIdx && _batteryExempt);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: isCurrent ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isGranted
                                ? AppColors.success
                                : isCurrent
                                    ? AppColors.white
                                    : AppColors.white.withAlpha(60),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.navy,
                        ),
                        child: Text(
                          _buttonText,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.navy,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page widgets ────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 60, 32, 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AnchorBrandLogo(anchorSize: 64),
              const SizedBox(height: 48),
              Text(
                'Take back control.',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ANCHORAGE combines smart content blocking with psychological strategies from Acceptance and Commitment Therapy \u2014 the most evidence-based approach for changing unwanted sexual behaviours.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withAlpha(200),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;

  const _NamePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What should we call you?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "We'll use this to personalise your experience.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withAlpha(180),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: controller,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                ),
                cursorColor: AppColors.white,
                maxLength: 20,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  filled: false,
                  hintText: 'First name',
                  hintStyle: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.white.withAlpha(60),
                  ),
                  counterStyle: TextStyle(
                    color: AppColors.white.withAlpha(120),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.white.withAlpha(60),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.seafoam),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpectationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "What ANCHORAGE is\nand isn't.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // IS section
              _ExpectationCard(
                title: 'ANCHORAGE IS',
                color: AppColors.seafoam,
                items: const [
                  'A tool to support your journey.',
                  'Evidence-based strategies for the moments that matter.',
                  'A way to build awareness and accountability.',
                ],
              ),
              const SizedBox(height: 16),

              // IS NOT section
              _ExpectationCard(
                title: 'ANCHORAGE IS NOT',
                color: AppColors.white.withAlpha(140),
                items: const [
                  'A cure.',
                  'A perfect blocker \u2014 determined users can bypass any filter.',
                  'A replacement for professional support if you need it.',
                ],
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  "What makes the difference isn't the blocker. It's what happens in the moments between urge and action.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.seafoam,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpectationCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> items;

  const _ExpectationCard({
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withAlpha(200),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuesPage extends StatelessWidget {
  final Set<String> selectedValues;
  final String firstName;
  final ValueChanged<String> onToggle;

  const _ValuesPage({
    required this.selectedValues,
    required this.firstName,
    required this.onToggle,
  });

  static const _values = _OnboardingScreenState._valueOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = firstName.isNotEmpty ? firstName : null;

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 200),
          child: Column(
            children: [
              Text(
                name != null
                    ? '$name, what matters most to you?'
                    : 'What matters most to you?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll use these to help you stay anchored when it matters most.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withAlpha(160),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selectedValues.length == 3
                      ? AppColors.seafoam.withAlpha(30)
                      : AppColors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${selectedValues.length}/3 selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selectedValues.length == 3
                        ? AppColors.seafoam
                        : AppColors.white.withAlpha(140),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                itemCount: _values.length,
                itemBuilder: (_, i) {
                  final value = _values[i];
                  final selected = selectedValues.contains(value);

                  return GestureDetector(
                    onTap: () => onToggle(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.seafoam.withAlpha(20)
                            : AppColors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.seafoam
                              : AppColors.white.withAlpha(30),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              value,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: selected
                                    ? AppColors.seafoam
                                    : AppColors.white.withAlpha(200),
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (selected)
                            const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.check_circle,
                                color: AppColors.seafoam,
                                size: 18,
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.circle_outlined,
                                color: Color(0x40FFFFFF),
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _RadioPage({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withAlpha(160),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ...options.map((option) {
                final isSelected = selected == option;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => onSelect(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.seafoam.withAlpha(20)
                            : AppColors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.seafoam
                              : AppColors.white.withAlpha(30),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? AppColors.seafoam
                                : AppColors.white.withAlpha(80),
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              option,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? AppColors.seafoam
                                    : AppColors.white.withAlpha(200),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransitionPage extends StatelessWidget {
  final String firstName;

  const _TransitionPage({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = firstName.isNotEmpty ? firstName : null;

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AnchorLogo(size: 64, color: AppColors.seafoam),
              const SizedBox(height: 40),
              Text(
                name != null
                    ? "$name, you've taken the first step."
                    : "You've taken the first step.",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Now let's set up your protection.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withAlpha(180),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuardedAppsPage extends StatelessWidget {
  final String firstName;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _GuardedAppsPage({
    required this.firstName,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = firstName.isNotEmpty ? firstName : null;

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 200),
          child: Column(
            children: [
              Text(
                name != null
                    ? '$name, which apps should ANCHORAGE watch?'
                    : 'Which apps should ANCHORAGE watch?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'When you open these apps, ANCHORAGE will pause you with a moment to reflect before you continue. You can change these anytime in Settings.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withAlpha(160),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${selected.length}/${GuardableApp.freeTierLimit} selected (free plan)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selected.isNotEmpty
                        ? AppColors.seafoam
                        : AppColors.white.withAlpha(140),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...GuardableApp.predefined.map((app) {
                final isSelected = selected.contains(app.packageName);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => onToggle(app.packageName),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.seafoam.withAlpha(20)
                            : AppColors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.seafoam
                              : AppColors.white.withAlpha(30),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(app.emoji,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              app.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? AppColors.seafoam
                                    : AppColors.white.withAlpha(200),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? AppColors.seafoam
                                : AppColors.white.withAlpha(60),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatToExpectPage extends StatelessWidget {
  const _WhatToExpectPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 200),
          child: Column(
            children: [
              Text(
                "Here's what happens next",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Intercept preview card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.white.withAlpha(30)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withAlpha(10),
                        border: Border.all(
                          color: AppColors.white.withAlpha(40),
                        ),
                      ),
                      child: const Center(
                        child: Text('\u2693', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HOLD ON.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.white.withAlpha(20)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Notice the urge',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.seafoam,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You don't have to obey it.\nThis is a moment to choose with intention.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.white.withAlpha(200),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mock buttons
                    _MockButton(
                      label: 'REFLECT ON THIS MOMENT',
                      color: AppColors.seafoam,
                      textColor: AppColors.navy,
                    ),
                    const SizedBox(height: 8),
                    _MockButton(
                      label: "I'M STAYING ANCHORED",
                      color: Colors.transparent,
                      textColor: AppColors.white,
                      border: true,
                    ),
                    const SizedBox(height: 8),
                    _MockButton(
                      label: 'EMERGENCY SOS',
                      color: Colors.transparent,
                      textColor: AppColors.danger,
                      border: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "This will appear when you open a guarded app. It's not a punishment \u2014 it's a pause. A moment to choose with intention.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withAlpha(180),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool border;

  const _MockButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: border
            ? Border.all(color: textColor.withAlpha(80))
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: textColor,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _CompletionPage extends StatelessWidget {
  final String firstName;

  const _CompletionPage({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = firstName.isNotEmpty ? firstName : null;

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.seafoam.withAlpha(20),
                  border:
                      Border.all(color: AppColors.seafoam.withAlpha(60), width: 2),
                ),
                child: const Center(
                  child: AnchorLogo(size: 56, color: AppColors.seafoam),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                name != null
                    ? "You're anchored, $name."
                    : "You're anchored.",
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ANCHORAGE is working in the background.\nYour values. Your commitment. Your journey.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withAlpha(180),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final List<String> steps;
  final String? samsungNote;

  const _PermissionPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.steps,
    this.samsungNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 200),
          child: Column(
            children: [
              Icon(
                granted ? Icons.check_circle_rounded : icon,
                size: 64,
                color: granted ? AppColors.success : AppColors.seafoam,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withAlpha(200),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: granted
                      ? AppColors.success.withAlpha(30)
                      : AppColors.danger.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: granted ? AppColors.success : AppColors.danger,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      granted ? Icons.check_circle : Icons.error_outline,
                      size: 18,
                      color: granted ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      granted ? 'Permission granted' : 'Permission required',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: granted ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (!granted) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.white.withAlpha(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to enable',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.seafoam,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...steps.asMap().entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.seafoam.withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.seafoam,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    e.value,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color:
                                          AppColors.white.withAlpha(220),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (samsungNote != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withAlpha(60),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.phone_android,
                          size: 20,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            samsungNote!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
