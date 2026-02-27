import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'core/app_globals.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'models/guardable_app.dart';
import 'services/accountability_service.dart';
import 'services/custom_blocklist_service.dart';
import 'services/guard_service.dart';
import 'services/intercept_event_service.dart';
import 'services/premium_service.dart';
import 'services/reflect_service.dart';
import 'services/relapse_service.dart';
import 'services/streak_service.dart';
import 'services/urge_log_service.dart';
import 'services/user_preferences_service.dart';
import 'services/tamper_service.dart';
import 'services/vpn_service.dart';
import 'shared/widgets/intercept_bottom_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // User preferences (first name, values, onboarding state) — must load
  // before router is created so the redirect can check onboarding status.
  await UserPreferencesService.instance.init();

  // Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[ANCHORAGE] Firebase init failed: $e');
  }

  // Anonymous sign-in so Firestore always has a valid uid.
  // Separate try/catch so a transient network error doesn't skip auth entirely.
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('[ANCHORAGE] Anonymous sign-in failed: $e');
  }

  // RevenueCat
  await Purchases.setLogLevel(LogLevel.debug);
  await Purchases.configure(
    PurchasesConfiguration('test_tcrYhxTeUMvQTkeJHipqSHzQqAI'),
  );

  // RevenueCat premium status
  await PremiumService.instance.init();

  // Streak + urge log + reflections + relapse — local prefs + Firebase sync
  await StreakService.instance.init();
  await UrgeLogService.instance.init();
  await ReflectService.instance.init();
  await RelapseService.instance.init();
  await CustomBlocklistService.instance.init();
  await InterceptEventService.instance.init();

  // Sync accountability stats whenever streak or reflect data changes.
  // Fire-and-forget — updateStats has its own error handling.
  void syncStats() {
    final streak = StreakService.instance.data.value;
    AccountabilityService.instance.updateStats(
      streakDays: streak.currentStreak,
      weeklyIntercepts: streak.weeklyIntercepts,
      weeklyReflections: ReflectService.instance.weeklyReflections,
    );
  }

  StreakService.instance.data.addListener(syncStats);
  ReflectService.instance.entries.addListener(syncStats);

  // Heartbeat — schedule 4-hour periodic heartbeat + send one now.
  // Fire-and-forget with timeout so a slow channel never blocks startup.
  TamperService.scheduleHeartbeat()
      .timeout(const Duration(seconds: 3), onTimeout: () {})
      .catchError((_) {});
  TamperService.sendHeartbeatNow()
      .timeout(const Duration(seconds: 3), onTimeout: () {})
      .catchError((_) {});

  // Guard service — wire native → Flutter callbacks
  GuardService.init();

  // VPN service — wire native → Flutter callbacks
  VpnService.init();

  // VPN is always on for all users — auto-start on launch.
  // Consent was already granted during onboarding; this is a no-op if already running.
  try {
    final vpnGranted = await VpnService.prepareVpn();
    if (vpnGranted && !await VpnService.isVpnActive()) {
      await VpnService.startVpn();
    }
  } catch (e) {
    debugPrint('[ANCHORAGE] VPN auto-start failed: $e');
  }

  // Debounce: avoid re-pushing blocked-domain screen for repeated DNS queries.
  DateTime? lastBlockedPush;
  VpnService.onDomainBlocked = (domain) async {
    // OverlayService handles the visual block over Chrome/other apps.
    // If ANCHORAGE is in the foreground, also push the Flutter blocked-domain screen.
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (lastBlockedPush != null &&
          now.difference(lastBlockedPush!).inSeconds < 10) {
        return; // suppress duplicate pushes within 10 s
      }
      lastBlockedPush = now;
      await _waitForNavigator();
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        context.push('/blocked-domain', extra: domain);
      }
    }
    // When app is backgrounded, the native overlay handles the UX —
    // no need to store the domain for later since the overlay is the primary UI.
  };

  // Fallback: activity-based intercept shown when overlay permission not granted
  GuardService.onGuardedAppDetected((appName) async {
    await _waitForNavigator();
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      await InterceptBottomSheet.show(context, appName);
    }
  });

  // Overlay button tapped on native overlay (e.g. "Reflect", "Stay Anchored", exercise)
  GuardService.onNavigateTo((nav) async {
    await _waitForNavigator();
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      context.go('/${nav.route}');
    }
  });

  // Resume guard if apps were saved from a previous session.
  // Filter against the current predefined list to purge any stale packages
  // (e.g. browsers that were in prefs before being removed from GuardableApp.predefined).
  final savedPackages = await GuardService.loadGuardedPackages();
  if (savedPackages.isNotEmpty) {
    final validPackages =
        GuardableApp.predefined.map((a) => a.packageName).toSet();
    final filtered =
        savedPackages.where((p) => validPackages.contains(p)).toList();
    if (filtered.isNotEmpty) {
      final hasPermission = await GuardService.hasUsagePermission();
      if (hasPermission) {
        await GuardService.start(filtered);
      }
    } else {
      // All saved packages were stale (e.g. browsers removed from predefined list).
      // Clear prefs so they don't persist into the next session.
      await GuardService.saveGuardedPackages([]);
    }
  }

  runApp(const AnchorageApp());
}

/// Polls until the GoRouter's navigator has a valid context, then resolves.
/// Gives up after 3 seconds to avoid hanging indefinitely.
Future<void> _waitForNavigator() async {
  const maxWait = Duration(seconds: 3);
  const interval = Duration(milliseconds: 100);
  var waited = Duration.zero;
  while (navigatorKey.currentContext == null && waited < maxWait) {
    await Future.delayed(interval);
    waited += interval;
  }
}

class AnchorageApp extends StatelessWidget {
  const AnchorageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Anchorage',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
