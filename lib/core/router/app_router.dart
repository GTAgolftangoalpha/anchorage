import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
// HIDDEN: Accountability partner UI hidden until Cloud Function backend is built. Do not delete.
// import '../../features/accountability/accountability_screen.dart';
import '../../features/blocked_domain/blocked_domain_screen.dart';
import '../../features/custom_blocklist/custom_blocklist_screen.dart';
import '../../features/exercises/body_scan_screen.dart';
import '../../features/exercises/box_breathing_screen.dart';
import '../../features/exercises/exercise_chooser_screen.dart';
import '../../features/exercises/grounding_screen.dart';
import '../../features/exercises/physiological_sigh_screen.dart';
import '../../features/exercises/urge_surfing_screen.dart';
import '../../features/guarded_apps/guarded_apps_screen.dart';
import '../../features/help/help_screen.dart';
import '../../features/legal/legal_viewer_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/intercept/intercept_screen.dart';
import '../../features/journey/journey_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/reflect/reflect_screen.dart';
import '../../features/relapse_log/relapse_log_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/sos/emergency_sos_screen.dart';
import '../../features/streak/streak_dashboard_screen.dart';
import '../../features/urge_log/urge_log_screen.dart';
import '../../services/user_preferences_service.dart';
import '../../shared/widgets/bottom_nav_scaffold.dart';
import '../app_globals.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final onboardingDone =
          UserPreferencesService.instance.onboardingComplete;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!onboardingDone && !isOnboarding) return '/onboarding';
      if (onboardingDone && isOnboarding) return '/home';
      return null;
    },
    routes: [
      // ── Full-screen flows (no bottom nav) ────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => const MaterialPage(
          child: OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/blocked-domain',
        name: 'blocked-domain',
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: BlockedDomainScreen(
            domain: state.extra as String? ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/intercept',
        name: 'intercept',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: InterceptScreen(),
        ),
      ),
      GoRoute(
        path: '/reflect',
        name: 'reflect',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: ReflectScreen(),
        ),
      ),
      GoRoute(
        path: '/sos',
        name: 'sos',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: EmergencySosScreen(),
        ),
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: PaywallScreen(),
        ),
      ),
      GoRoute(
        path: '/guarded-apps',
        name: 'guarded-apps',
        pageBuilder: (context, state) => const MaterialPage(
          child: GuardedAppsScreen(),
        ),
      ),
      // HIDDEN: Accountability partner UI hidden until Cloud Function backend is built. Do not delete.
      // GoRoute(
      //   path: '/accountability',
      //   name: 'accountability',
      //   pageBuilder: (context, state) => const MaterialPage(
      //     child: AccountabilityScreen(),
      //   ),
      // ),
      GoRoute(
        path: '/urge-log',
        name: 'urge-log',
        pageBuilder: (context, state) => const MaterialPage(
          child: UrgeLogScreen(),
        ),
      ),
      GoRoute(
        path: '/custom-blocklist',
        name: 'custom-blocklist',
        pageBuilder: (context, state) => const MaterialPage(
          child: CustomBlocklistScreen(),
        ),
      ),
      GoRoute(
        path: '/relapse-log',
        name: 'relapse-log',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: RelapseLogScreen(),
        ),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        pageBuilder: (context, state) => const MaterialPage(
          child: HelpScreen(),
        ),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (context, state) => const MaterialPage(
          child: AboutScreen(),
        ),
      ),
      GoRoute(
        path: '/journey',
        name: 'journey',
        pageBuilder: (context, state) => const MaterialPage(
          child: JourneyScreen(),
        ),
      ),
      GoRoute(
        path: '/exercises',
        name: 'exercises',
        pageBuilder: (context, state) => const MaterialPage(
          child: ExerciseChooserScreen(),
        ),
      ),
      GoRoute(
        path: '/exercise/box-breathing',
        name: 'box-breathing',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: BoxBreathingScreen(),
        ),
      ),
      GoRoute(
        path: '/exercise/physiological-sigh',
        name: 'physiological-sigh',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: PhysiologicalSighScreen(),
        ),
      ),
      GoRoute(
        path: '/exercise/grounding',
        name: 'grounding',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: GroundingScreen(),
        ),
      ),
      GoRoute(
        path: '/exercise/urge-surfing',
        name: 'urge-surfing',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: UrgeSurfingScreen(),
        ),
      ),
      GoRoute(
        path: '/exercise/body-scan',
        name: 'body-scan',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: BodyScanScreen(),
        ),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        pageBuilder: (context, state) => const MaterialPage(
          child: LegalViewerScreen(
            title: 'PRIVACY POLICY',
            htmlContent: LegalHtml.privacy,
          ),
        ),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        pageBuilder: (context, state) => const MaterialPage(
          child: LegalViewerScreen(
            title: 'TERMS OF SERVICE',
            htmlContent: LegalHtml.terms,
          ),
        ),
      ),

      // ── Main shell with bottom navigation ────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/streak',
                name: 'streak',
                builder: (context, state) => const StreakDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
