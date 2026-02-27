# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

ANCHORAGE — Flutter Android app that blocks pornography via VPN filtering and app interception. White/navy/teal palette, anchor imagery, DM Serif Display + DM Sans typography.

**Package ID:** `com.anchorage.app`
**Test device:** Samsung Galaxy A16 5G (SM-A166P), Android 14 / OneUI 6.1
**Firebase project:** `anchorage-ea242`
**RevenueCat key:** `test_tcrYhxTeUMvQTkeJHipqSHzQqAI` (test key — swap for prod before release)

## Commands

```bash
flutter run                          # run on connected device (debug)
flutter run --release                # release build
flutter analyze --no-fatal-infos     # lint (must be 0 issues before any commit)
flutter test                         # run tests
flutter test test/path/to_test.dart  # run a single test file

# After changing pubspec.yaml assets or deps:
flutter pub get

# Regenerate native splash (after changing flutter_native_splash config):
dart run flutter_native_splash:create
```

## Architecture

Feature-first structure under `lib/features/<name>/`.

```
lib/
├── main.dart                          # Firebase + RevenueCat + GuardService init + callbacks
├── theme.dart                         # ANCHORAGE design system — Anchorage, AnchorageType, AnchorageTheme + widgets
├── core/
│   ├── app_globals.dart               # navigatorKey (avoids circular imports with app_router)
│   ├── constants/app_colors.dart      # Backwards-compatible alias → delegates to Anchorage palette
│   ├── theme/app_theme.dart           # Backwards-compatible alias → delegates to AnchorageTheme.light
│   └── router/app_router.dart         # go_router config (19 routes), uses navigatorKey from app_globals
├── features/
│   ├── about/                         # About screen with crisis resources
│   ├── accountability/                # Accountability partner invite + management
│   ├── blocked_domain/                # Blocked domain intercept screen (VPN)
│   ├── custom_blocklist/              # User-added blocked domains
│   ├── guarded_apps/                  # 10-app selector with free-tier 3-slot limit
│   ├── help/                          # FAQ screen (5 topics)
│   ├── home/                          # Dashboard: guard status, stats, permission banners
│   ├── intercept/                     # Full-screen app guard intercept with ACT prompt
│   ├── journey/                       # Journey dashboard (days since install, stats)
│   ├── legal/                         # Privacy policy + terms of service (WebView)
│   ├── onboarding/                    # 4-page PageView; requests permissions + setup
│   ├── paywall/                       # RevenueCat plan selector (monthly/annual)
│   ├── reflect/                       # Mood selector + journal + trigger + values
│   ├── relapse_log/                   # Relapse journal (what happened, triggers, learnings)
│   ├── settings/                      # VPN toggle (live), guarded apps entry, account
│   ├── sos/                           # Emergency SOS screen (Lifeline, Beyond Blue, IASP)
│   ├── streak/                        # Streak counter, weekly calendar, milestones
│   └── urge_log/                      # Urge/trigger logger with notes
├── models/
│   └── guardable_app.dart             # GuardableApp model + predefined list of 10 apps
├── services/
│   ├── accountability_service.dart    # Partner invite, Firestore sync, stats sharing
│   ├── custom_blocklist_service.dart  # User-added domains, hot-reload to VPN
│   ├── export_service.dart            # CSV export for streak + urge data
│   ├── guard_service.dart             # MethodChannel bridge to native guard + overlay
│   ├── intercept_prompt_service.dart  # ACT-based intervention prompts
│   ├── premium_service.dart           # RevenueCat entitlements, purchase, restore
│   ├── reflect_service.dart           # Mood/journal persistence + Firestore sync
│   ├── relapse_service.dart           # Relapse log persistence
│   ├── streak_service.dart            # Streak tracking, daily check-in, milestones
│   ├── tamper_service.dart            # Heartbeat, VPN revocation detection, device admin
│   ├── urge_log_service.dart          # Urge/trigger logging + persistence
│   ├── user_preferences_service.dart  # SharedPreferences wrapper (name, values, onboarding)
│   └── vpn_service.dart               # MethodChannel bridge to AnchorageVpnService
└── shared/widgets/
    ├── anchor_logo.dart               # AnchorLogo + AnchorBrandLogo
    ├── bottom_nav_scaffold.dart       # Shell scaffold (Home / Streak / Settings tabs)
    └── intercept_bottom_sheet.dart    # Fallback intercept UI (used when overlay not granted)
```

## Navigation (go_router)

`StatefulShellRoute.indexedStack` wraps the three bottom-nav branches:

| Route | Screen | Shell? |
|---|---|---|
| `/home` | HomeScreen | yes (tab 0) |
| `/streak` | StreakDashboardScreen | yes (tab 1) |
| `/settings` | SettingsScreen | yes (tab 2) |
| `/onboarding` | OnboardingScreen | no |
| `/reflect` | ReflectScreen | no (fullscreenDialog) |
| `/sos` | EmergencySosScreen | no (fullscreenDialog) |
| `/paywall` | PaywallScreen | no (fullscreenDialog) |
| `/guarded-apps` | GuardedAppsScreen | no |
| `/accountability` | AccountabilityScreen | no |
| `/urge-log` | UrgeLogScreen | no |
| `/relapse-log` | RelapseLogScreen | no (fullscreenDialog) |
| `/custom-blocklist` | CustomBlocklistScreen | no |
| `/blocked-domain` | BlockedDomainScreen | no (fullscreenDialog) |
| `/intercept` | InterceptScreen | no (fullscreenDialog) |
| `/journey` | JourneyScreen | no |
| `/help` | HelpScreen | no |
| `/about` | AboutScreen | no |
| `/privacy` | LegalViewerScreen | no |
| `/terms` | LegalViewerScreen | no |

Navigate with `context.go('/route')` (replace) or `context.push('/route')` (push).

The `anchorage://sos` deep link (from the VPN blocked page) opens the app and routes to `/sos`.

## App Guard System

### Architecture

Samsung blocks `FLAG_ACTIVITY_NEW_TASK` from background services launching over other apps. The solution is `TYPE_APPLICATION_OVERLAY` via `WindowManager` — this is how BlockerX, AppBlock, and every production Android blocker works.

**Full intercept flow:**
```
AppGuardService (polls 150ms)
  → detects guarded app via UsageStatsManager.queryEvents()
  → falls back to queryUsageStats() if events empty (Samsung quirk)
  → Settings.canDrawOverlays()?
      YES → startService(OverlayService) with app name
              OverlayService.showOverlay() → WindowManager.addView(TYPE_APPLICATION_OVERLAY)
              User taps "REFLECT" → dismiss overlay + startActivity(MainActivity, NAVIGATE_TO=reflect)
              User taps "STAY ANCHORED" → dismiss overlay + startActivity(MainActivity)
              User taps "EMERGENCY SOS" → dismiss overlay + startActivity(MainActivity, NAVIGATE_TO=sos)
              MainActivity.deliverGuardIntent() → channel.invokeMethod("navigateTo", route)
              Flutter GuardService.onNavigateTo callback → context.go('/reflect') or context.go('/sos')
      NO  → startActivity(MainActivity, EXTRA_APP_NAME) [fallback]
              → channel.invokeMethod("onGuardedAppDetected", appName)
              → Flutter shows InterceptBottomSheet
```

### Key Kotlin files

| File | Role |
|---|---|
| `AppGuardService.kt` | Foreground service, polls UsageStats, calls `launchIntercept()` |
| `OverlayService.kt` | Inflates `overlay_intercept.xml` over WindowManager; handles button taps |
| `AnchorageVpnService.kt` | VPN service; DNS interception, blocklist matching, TCP RST |
| `BlocklistUpdateWorker.kt` | WorkManager worker; refreshes blocklist every 14 days |
| `HeartbeatWorker.kt` | WorkManager worker; 4-hour periodic heartbeat to Firestore |
| `AnchorageDeviceAdminReceiver.kt` | Device admin receiver for tamper detection |
| `MainActivity.kt` | MethodChannel hub for `guard`, `vpn`, and `tamper` channels; VPN consent via `onActivityResult` |

### MethodChannel `com.anchorage.app/guard`

**Flutter → Native:**
| Method | Returns | Notes |
|---|---|---|
| `isUsagePermissionGranted` | bool | Check before starting guard |
| `requestUsagePermission` | void | Opens Settings → Special app access |
| `startGuardService({apps})` | void | Starts/restarts AppGuardService |
| `stopGuardService` | void | Stops AppGuardService |
| `hasOverlayPermission` | bool | `Settings.canDrawOverlays()` |
| `requestOverlayPermission` | void | Opens Settings → Appear on top |

**Native → Flutter:**
| Method | Arg | Notes |
|---|---|---|
| `onGuardedAppDetected` | `String appName` | Fallback only (no overlay permission) |
| `navigateTo` | `String route` | Overlay button tapped; Flutter calls `context.go('/$route')` |

### MethodChannel `com.anchorage.app/vpn`

| Method | Returns | Notes |
|---|---|---|
| `prepareVpn` | bool | Shows system VPN consent if needed; `true` = permission held |
| `startVpn` | void | Starts `AnchorageVpnService` |
| `stopVpn` | void | Stops `AnchorageVpnService` |
| `isVpnActive` | bool | Reads `AnchorageVpnService.isRunning` |
| `reloadCustomBlocklist` | void | Hot-reloads user-added domains into VPN |

`prepareVpn` returning `false` means the system dialog was shown — caller must wait for `AppLifecycleState.resumed` and call again to confirm.

### Guard state machine

`AppGuardService` uses a three-state machine stored in `guardState`:

| State | Meaning |
|---|---|
| `IDLE` | No guarded app in foreground; normal polling |
| `OVERLAY_SHOWING` | Overlay is visible; polling continues but no re-launch |
| `POST_DISMISS_COOLDOWN` | Overlay just dismissed; 2-second cooldown before re-intercept |

**Transitions:**
- `IDLE → OVERLAY_SHOWING`: guarded app detected → `launchIntercept()` called
- `OVERLAY_SHOWING → POST_DISMISS_COOLDOWN`: `OverlayService.dismiss()` sets `AppGuardService.overlayDismissed = true`; consumed by next poll
- `POST_DISMISS_COOLDOWN → IDLE`: ANCHORAGE detected in foreground (user completed the intercept flow)
- `POST_DISMISS_COOLDOWN → OVERLAY_SHOWING`: guarded app still/back in foreground after 2s cooldown

**Key invariant**: When ANCHORAGE comes to foreground (`foregroundPkg == packageName`), the state machine is ALWAYS reset to `IDLE` and `lastForegroundPkg` is reset. **Never break this.**

**Cross-service signal**: `AppGuardService.overlayDismissed` (`@Volatile var`) is set by `OverlayService.dismiss()` and consumed (cleared) by `AppGuardService.checkForeground()`. This avoids a hard dependency between the two services.

## VPN System

### Architecture

DNS-only VPN — only `10.111.222.2/32` (fake DNS) and `10.111.222.3/32` (blocked domain IP) are routed through the TUN interface. All real traffic bypasses the VPN, keeping battery and latency impact minimal.

```
AnchorageVpnService
  Builder: addAddress(10.111.222.1/24), addDnsServer(10.111.222.2)
           addRoute(10.111.222.2/32)   ← DNS queries only
           addRoute(10.111.222.3/32)   ← blocked-domain sentinel IP only
           (NO addRoute("0.0.0.0", 0) — real traffic bypasses TUN entirely)
  Packet loop (background thread):
    UDP port 53 → 10.111.222.2:
      → parseDnsName() extracts query domain
      → isBlocked(): traverses subdomains left-to-right (www.x.com → x.com → …)
          blocked  → buildBlockedDnsResponse() → A record 10.111.222.3
                     notifyDomainBlocked() → OverlayService
          allowed  → forwardDns() via protect()ed DatagramSocket to 8.8.8.8
    TCP SYN → 10.111.222.3:
      → sendTcpRst() — browser shows connection refused
    All other traffic (real IPs):
      → bypasses TUN, no proxying required
```

**Critical**: Never add `addRoute("0.0.0.0", 0)` — this routes all traffic through TUN and requires a TCP proxy for every browser connection. The naive `TcpProxySession` approach breaks HTTPS due to timing races (SYN-ACK sent before upstream connection is ready). DNS-only routing is the correct, battle-tested architecture.

### Blocklist

- **Bundled:** `android/app/src/main/assets/blocklist.txt` — 157,176 domains (Steven Black porn category)
- **Updated:** `filesDir/blocklist.txt` — written by `BlocklistUpdateWorker` every 14 days; preferred over bundled if present
- **Custom:** User-added domains via `CustomBlocklistService` → hot-reloaded into VPN via MethodChannel
- Source: `https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts`
- Loaded into `HashSet<String>` at VPN start on a background thread

### Blocked page

`android/app/src/main/assets/blocked_page.html` — themed page served when a user navigates to a blocked domain over HTTP. Contains:
- "You've got this." heading + anchor logo
- "I NEED SUPPORT" → `anchorage://sos` deep link (opens SOS screen in app)
- "GO BACK" → `history.back()`

Note: The HTML is bundled for future use. Currently, TCP connections to `10.111.222.3` receive a RST — the browser shows its own error page. Serving the custom HTML requires a local HTTP server or WebView-based approach (not yet implemented).

### Required permissions (full stack)

1. **`PACKAGE_USAGE_STATS`** — user grants via Settings → Special app access → Usage access
2. **`SYSTEM_ALERT_WINDOW`** — user grants via Settings → Apps → Anchorage → Appear on top
3. **VPN consent** — system dialog shown once via `VpnService.prepare()`; onboarding requests this after overlay permission
4. **Battery optimization exemption** — prevents Samsung doze from throttling the guard poll handler
5. **Device admin** (optional) — enables tamper detection for uninstall protection

### Guarded apps (free tier: max 3)

| Display Name | Package |
|---|---|
| Reddit | `com.reddit.frontpage` |
| Twitter / X | `com.twitter.android` |
| Telegram | `org.telegram.messenger` |
| Instagram | `com.instagram.android` |
| TikTok | `com.zhiliaoapp.musically` |
| Snapchat | `com.snapchat.android` |
| Discord | `com.discord` |
| YouTube | `com.google.android.youtube` |
| Tumblr | `com.tumblr` |
| Pinterest | `com.pinterest` |

Browsers (Chrome, Firefox, Brave, Opera) are intentionally excluded — browser content is handled exclusively by the VPN DNS filter. Adding a browser here would cause the app-guard overlay to fire on every browser launch, fighting with the VPN blocked-domain overlay.

## Samsung-Specific Constraints

- **Never use `FLAG_ACTIVITY_NEW_TASK` to launch over another app from a background service** — Samsung (and Android 10+) blocks this. Use `OverlayService` instead.
- **`queryEvents()` can return 0 events** on Samsung even when apps are actively in foreground. `AppGuardService` falls back to `queryUsageStats()` when events are empty.
- **Battery optimization** — Samsung's aggressive doze may throttle the polling handler. If interception stops working after the phone has been idle, this is the likely cause.
- **`INTERVAL_BEST`** is the correct interval constant for `queryUsageStats` on Samsung.
- BLASTBufferQueue and mali_gralloc logcat errors during screen transitions are Samsung GPU driver noise — not actionable.

## Testing Requirements

Always test the **full intercept loop**, not just the happy path:

1. Open guarded app → overlay appears
2. Tap "I'M STAYING ANCHORED" → overlay dismisses, ANCHORAGE comes forward
3. Open guarded app again → overlay appears again (re-arm confirmed, 2s cooldown)
4. Tap "REFLECT ON THIS MOMENT" → overlay dismisses, `/reflect` screen opens
5. Complete reflect, return to home → open guarded app → overlay appears again
6. Enable VPN in Settings → toggle shows "Active — explicit content blocked"
7. Open Chrome → navigate to a porn domain → DNS resolves to 10.111.222.3 → connection refused

## Android Configuration

- `minSdk = maxOf(flutter.minSdkVersion, 23)` — `maxOf()` prevents the Flutter build tool from resetting this on every build.
- Google Services plugin declared in `settings.gradle.kts`, applied in `app/build.gradle.kts`.
- `google-services.json` at `android/app/google-services.json`.
- Namespace (`com.anchorage.anchorage`) and applicationId (`com.anchorage.app`) intentionally differ.
- Notification icon: `android/app/src/main/res/drawable/ic_notification.xml` (white anchor vector).
- Overlay layout: `android/app/src/main/res/layout/overlay_intercept.xml`.
- WorkManager dependency: `androidx.work:work-runtime-ktx:2.9.1` in `app/build.gradle.kts`.

## Design System

The design system lives in `lib/theme.dart` with three main classes:

| Class | Purpose |
|---|---|
| `Anchorage` | Colour constants (backgrounds, text, borders, accent, semantic) |
| `AnchorageType` | Typography helpers — DM Serif Display (headings) + DM Sans (body) |
| `AnchorageTheme` | Full Material 3 `ThemeData` (accessed via `AnchorageTheme.light`) |

**Backwards-compatible aliases:** `AppColors` delegates to `Anchorage.*`, `AppTheme.light` delegates to `AnchorageTheme.light`.

### Colour palette

| Token | Hex | Usage |
|---|---|---|
| `bgPrimary` | `#FFFFFF` | Scaffold, primary background |
| `bgCard` | `#F5F8FA` | Card fill, input fill |
| `textPrimary` | `#0D2B45` | Navy — headings, primary text |
| `textSecond` | `#3D5A6E` | Body text, secondary labels |
| `textHint` | `#8FA3B1` | Muted text, placeholders |
| `borderLight` | `#E1E8ED` | Card borders, dividers |
| `borderMid` | `#C4D0D8` | Outlined button borders |
| `accent` | `#1A6B72` | Deep teal — buttons, links, active states |
| `accentLight` | `#E5F0F1` | Light teal — selected card backgrounds |
| `danger` | `#C0392B` | Destructive actions, errors |

### Reusable widgets (in `lib/theme.dart`)

| Widget | Purpose |
|---|---|
| `AnchorageCard` | Standard card with optional `selected` state + `onTap` |
| `StatusBadge` | ON/OFF pill badge |
| `AnchorageFooter` | Branded footer for scrollable screens |
| `AnchorageSectionHeader` | Uppercase label-style section header |
| `AnchorageSettingsRow` | Icon + title + optional subtitle row for settings |

### Rules

- **Never** use `Colors.*` directly — always `AppColors.*` or `Anchorage.*`.
- **Never** hardcode text styles — always `Theme.of(context).textTheme.*` or `AnchorageType.*`.
- Use `WidgetState` (not deprecated `MaterialState`) for theme property callbacks.
- Use `.withAlpha(n)` (0–255) not `.withOpacity(n)`.
- All new screens: `AppBar` with `title: const Text('SCREEN NAME')` — theme auto-applies styling.

## Firebase + RevenueCat Init

Both initialized in `main()` before `runApp`. Firebase wrapped in try/catch. RevenueCat configured unconditionally. Firestore writes go in the feature file. Auth state not yet wired to a provider.

## Tamper Detection

- 4-hour periodic heartbeat via WorkManager (`HeartbeatWorker`)
- Heartbeat writes `uid`, `timestamp`, `vpn_active`, `guard_active`, `client_time` to `users/{uid}/heartbeats/latest`
- VPN revocation events logged to `users/{uid}/tamper_events`
- Device admin activation for uninstall protection
- Immediate heartbeat on app startup (3s timeout, fire-and-forget)

## Accountability System

- Partner invite via email + name → stored at `users/{uid}/partners/{id}` in Firestore
- Free tier: 1 partner; Premium: unlimited
- Stats sync: streak days, weekly intercepts, weekly reflections
- Cloud Function for weekly summary emails (backend, not in this repo)
