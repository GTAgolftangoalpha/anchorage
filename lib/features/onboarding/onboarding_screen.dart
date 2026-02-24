import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/guard_service.dart';
import '../../services/vpn_service.dart';

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

  // Page indices
  static const _introCount = 4;
  static const _overlayIdx = 4;
  static const _batteryIdx = 5;
  static const _vpnIdx = 6;
  static const _totalPages = 7;

  static const _introPages = [
    _IntroData(
      title: 'Drop Anchor.',
      subtitle:
          'ANCHORAGE is your first mate in the fight for a clean digital life.',
      icon: '\u2693',
      background: AppColors.navy,
    ),
    _IntroData(
      title: 'VPN Shield.',
      subtitle:
          'Our always-on VPN filter blocks explicit content at the network level \u2014 before it reaches your eyes.',
      icon: '\uD83D\uDEE1\uFE0F',
      background: AppColors.navyMid,
    ),
    _IntroData(
      title: 'Build Streaks.',
      subtitle:
          'Track your progress day by day. Every clean day counts. Every streak matters.',
      icon: '\uD83D\uDD25',
      background: AppColors.navyLight,
    ),
    _IntroData(
      title: 'Stay Anchored.',
      subtitle:
          'Reflect on your journey, celebrate wins, and keep your compass true.',
      icon: '\uD83E\uDDED',
      background: AppColors.navy,
    ),
  ];

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
      if (mounted) context.go('/home');
    }
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onAction() async {
    if (_currentPage < _introCount - 1) {
      // Intro pages 0–2: advance
      _goTo(_currentPage + 1);
    } else if (_currentPage == _introCount - 1) {
      // Last intro page: advance to first permission
      _goTo(_overlayIdx);
    } else if (_currentPage == _overlayIdx) {
      // Recheck before acting (may have been granted externally)
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
        if (mounted) context.go('/home');
      } else {
        _waitingForVpn = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPermission = _currentPage >= _introCount;

    String buttonText;
    if (_currentPage < _introCount - 1) {
      buttonText = 'NEXT';
    } else if (_currentPage == _introCount - 1) {
      buttonText = 'SET UP PERMISSIONS';
    } else if (_currentPage == _overlayIdx) {
      buttonText = _overlayGranted ? 'CONTINUE' : 'OPEN SETTINGS';
    } else if (_currentPage == _batteryIdx) {
      buttonText = _batteryExempt ? 'CONTINUE' : 'DISABLE OPTIMIZATION';
    } else {
      buttonText = 'ACTIVATE VPN SHIELD';
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics:
                isPermission ? const NeverScrollableScrollPhysics() : null,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _totalPages,
            itemBuilder: (_, index) {
              if (index < _introCount) {
                return _IntroPage(data: _introPages[index]);
              }
              if (index == _overlayIdx) {
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
              }
              if (index == _batteryIdx) {
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
              }
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
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isCurrent ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isGranted
                                ? AppColors.success
                                : isCurrent
                                    ? AppColors.white
                                    : AppColors.white.withAlpha(80),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

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
                          buttonText,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.navy,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                    // Skip intro (pages 0–2 only — permissions are mandatory)
                    if (_currentPage < _introCount - 1) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _goTo(_overlayIdx),
                        child: Text(
                          'Skip intro',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.white.withAlpha(180),
                          ),
                        ),
                      ),
                    ],
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

// ── Data classes & page widgets ────────────────────────────────────────────

class _IntroData {
  final String title;
  final String subtitle;
  final String icon;
  final Color background;

  const _IntroData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
  });
}

class _IntroPage extends StatelessWidget {
  final _IntroData data;
  const _IntroPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: data.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(data.icon, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 40),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                data.subtitle,
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

                // Step-by-step instructions card
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

                // Samsung-specific note
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
