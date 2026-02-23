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
  bool _waitingForOverlayPermission = false;
  bool _waitingForVpnPermission = false;

  static const _pages = [
    _OnboardingPage(
      title: 'Drop Anchor.',
      subtitle:
          'ANCHORAGE is your first mate in the fight for a clean digital life.',
      icon: '⚓',
      background: AppColors.navy,
    ),
    _OnboardingPage(
      title: 'VPN Shield.',
      subtitle:
          'Our always-on VPN filter blocks explicit content at the network level — before it reaches your eyes.',
      icon: '🛡️',
      background: AppColors.navyMid,
    ),
    _OnboardingPage(
      title: 'Build Streaks.',
      subtitle:
          'Track your progress day by day. Every clean day counts. Every streak matters.',
      icon: '🔥',
      background: AppColors.navyLight,
    ),
    _OnboardingPage(
      title: 'Stay Anchored.',
      subtitle:
          'Reflect on your journey, celebrate wins, and keep your compass true.',
      icon: '🧭',
      background: AppColors.navy,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // Returned from "Draw over other apps" settings page
    if (_waitingForOverlayPermission) {
      _waitingForOverlayPermission = false;
      // Now request VPN permission
      _requestVpnAndProceed();
    }

    // Returned after VPN consent dialog (shown via startActivityForResult)
    if (_waitingForVpnPermission) {
      _waitingForVpnPermission = false;
      if (mounted) context.go('/home');
    }
  }

  Future<void> _next() async {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page — request overlay permission, then VPN, then proceed to home
      final hasOverlay = await GuardService.hasOverlayPermission();
      if (!mounted) return;
      if (hasOverlay) {
        await _requestVpnAndProceed();
      } else {
        _waitingForOverlayPermission = true;
        await GuardService.requestOverlayPermission();
        // Continues in didChangeAppLifecycleState when user returns
      }
    }
  }

  Future<void> _requestVpnAndProceed() async {
    if (!mounted) return;
    final granted = await VpnService.prepareVpn();
    if (!mounted) return;
    if (granted) {
      // VPN permission already held — start the VPN and go to home
      await VpnService.startVpn();
      if (mounted) context.go('/home');
    } else {
      // System consent dialog was shown — wait for the result
      _waitingForVpnPermission = true;
      // didChangeAppLifecycleState handles the return
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _PageContent(page: page);
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
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppColors.white
                                : AppColors.white.withAlpha(80),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // CTA button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.navy,
                        ),
                        child: Text(
                          isLast ? 'GRANT PERMISSION & START' : 'NEXT',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.navy,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                    if (!isLast) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          'Skip',
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

class _OnboardingPage {
  final String title;
  final String subtitle;
  final String icon;
  final Color background;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
  });
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: page.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(page.icon, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 40),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                page.subtitle,
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
