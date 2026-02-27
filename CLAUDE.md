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
│   └── router/app_router.dart         # go_router config (26 routes), uses navigatorKey from app_globals
├── features/
│   ├── about/                         # About screen with findahelpline.com link
│   ├── accountability/                # Accountability partner invite + management (UI HIDDEN)
│   ├── blocked_domain/                # Blocked domain intercept screen (VPN)
│   ├── custom_blocklist/              # User-added blocked domains
│   ├── exercises/                     # 5 guided exercises + chooser screen
│   │   ├── exercise_chooser_screen.dart  # List of all exercises with durations
│   │   ├── box_breathing_screen.dart     # 4-4-4-4 pattern with square tracer animation
│   │   ├── physiological_sigh_screen.dart # Double inhale + long exhale with pulsing circle
│   │   ├── grounding_screen.dart         # 5-4-3-2-1 interactive sense-based steps
│   │   ├── urge_surfing_screen.dart      # Guided meditation with wave animation
│   │   └── body_scan_screen.dart         # Progressive relaxation through 7 body regions
│   ├── export/                        # Premium PDF export ("Anchor Report")
│   │   ├── export_screen.dart            # Date pickers, notes, generate + share
│   │   └── pdf_generator.dart            # Styled PDF with 5 sections
│   ├── guarded_apps/                  # 10-app selector with free-tier 3-slot limit
│   ├── help/                          # FAQ screen (5 topics)
│   ├── home/                          # Dashboard: guard status, stats, exercises, learn, quick actions
│   ├── intercept/                     # Full-screen app guard intercept with ACT prompt
│   ├── journey/                       # Journey dashboard (days since install, stats)
│   ├── legal/                         # Privacy policy + terms of service (WebView)
│   ├── onboarding/                    # 4-page PageView; requests permissions + setup
│   ├── paywall/                       # RevenueCat plan selector (monthly/annual)
│   ├── psychoeducation/               # 5 expandable learn cards for home screen
│   │   └── psychoeducation_cards.dart    # PsychoeducationCard, PsychoeducationSection widgets
│   ├── reflect/                       # Mood selector + journal + trigger + values
│   ├── relapse_log/                   # Relapse journal (what happened, triggers, learnings)
│   ├── settings/                      # VPN toggle, guarded apps, export, account
│   ├── sos/                           # Emergency SOS: findahelpline.com + local resources + IASP
│   ├── streak/                        # Streak counter, weekly calendar, milestones
│   └── urge_log/                      # Urge/trigger logger with notes
├── models/
│   └── guardable_app.dart             # GuardableApp model + predefined list of 10 apps
├── services/
│   ├── accountability_service.dart    # Partner invite, Firestore sync, stats sharing
│   ├── custom_blocklist_service.dart  # User-added domains, hot-reload to VPN
│   ├── export_service.dart            # CSV export for streak + urge data
│   ├── guard_service.dart             # MethodChannel bridge to native guard + overlay (GuardNavigation)
│   ├── intercept_event_service.dart   # Intercept event storage with emotion + Firestore sync
│   ├── intercept_prompt_service.dart  # ACT prompts with emotion-to-category mappings
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
| `/export` | ExportScreen | no |
| `/exercises` | ExerciseChooserScreen | no |
| `/exercise/box-breathing` | BoxBreathingScreen | no (fullscreenDialog) |
| `/exercise/physiological-sigh` | PhysiologicalSighScreen | no (fullscreenDialog) |
| `/exercise/grounding` | GroundingScreen | no (fullscreenDialog) |
| `/exercise/urge-surfing` | UrgeSurfingScreen | no (fullscreenDialog) |
| `/exercise/body-scan` | BodyScanScreen | no (fullscreenDialog) |

Navigate with `context.go('/route')` (replace) or `context.push('/route')` (push).

The `anchorage://sos` deep link (from the VPN blocked page) opens the app and routes to `/sos`.

**Note:** The `/accountability` route is commented out (HIDDEN) until the Cloud Function backend is built.

## Home Screen Sections

The home screen displays these sections in order:

1. **Status hero card** — guard active/inactive, guarded app chips
2. **Permission warning** — shown if usage access not granted
3. **Streak hero** — current streak count with motivational message
4. **Daily values card** — rotating value with prompt to reflect
5. **Stats row** — current streak, longest streak, weekly intercepts, anchored days
6. **Weekly bar chart** — 7-day visual streak tracker
7. **Exercises** — 4 quick-access exercise tiles + "See all exercises" link
8. **Learn** — 5 expandable psychoeducation cards (PsychoeducationSection)
9. **Quick Actions** — manage guarded apps, urge log, reflect, relapse log, go premium

## Exercises

5 guided exercises in `lib/features/exercises/`, each a full-screen page with animation and timer:

| Exercise | Route | Duration | Animation |
|---|---|---|---|
| Box Breathing | `/exercise/box-breathing` | ~4 min | Square tracer with dot, phase labels |
| Physiological Sigh | `/exercise/physiological-sigh` | ~3 min | Pulsing circle, pattern step indicators |
| 5-4-3-2-1 Grounding | `/exercise/grounding` | ~5 min | Interactive checkable sense items |
| Urge Surfing | `/exercise/urge-surfing` | ~2 min | Sine wave with amplitude tied to phase |
| Body Scan | `/exercise/body-scan` | ~2.5 min | Icon-based region focus, progress bar |

Exercise chooser at `/exercises` lists all 5 with descriptions and durations.

## Psychoeducation Cards

5 expandable cards in `lib/features/psychoeducation/psychoeducation_cards.dart`:

1. **Urges Are Waves** — urge duration, habituation, ride-it-out framing
2. **Not a Character Flaw** — learned behaviour vs moral failure, dopamine loop
3. **Shame vs Guilt** — identity vs behaviour, growth framing
4. **Why Willpower Is Not Enough** — systems over motivation, depletion model
5. **What Aroused Means Here** — physiological response awareness, naming without judging

## Intercept System

### Emotion-to-Category Mappings

`InterceptPromptService.getPromptForEmotion(emotion)` maps 10 emotional states to preferred ACT prompt categories:

| Emotion | Primary Category | Secondary Category |
|---|---|---|
| Bored | Urge Surfing | Values |
| Stressed | Present Moment | Cognitive Defusion |
| Lonely | Values | Present Moment |
| Tired | Present Moment | Urge Surfing |
| Anxious | Present Moment | Cognitive Defusion |
| Down | Values | Urge Surfing |
| Angry | Cognitive Defusion | Present Moment |
| Aroused | Urge Surfing | Cognitive Defusion |
| Numb | Present Moment | Values |
| Rewarding | Values | Cognitive Defusion |

### Intercept Event Storage

`InterceptEventService` stores each intercept with:
- `emotion` — selected emotional state (from native overlay or Flutter)
- `exercise` — exercise chosen (if any)
- `outcome` — 'reflected', 'stayed', 'exercised'
- `source` — 'app_guard' or 'vpn_block'
- Persisted to SharedPreferences + synced to Firestore `users/{uid}/intercept_events`

### Native Overlay (Two-Phase)

The native overlay (`OverlayService.kt`) uses a two-phase flow:

**Phase 1 — Emotion selector:** 10 emotion cards in a 2x5 grid. User selects emotional state.

**Phase 2 — Intervention:** ACT prompt matched to emotion, 2 random behavioural suggestions, exercise chooser button, 60-second countdown timer. Action buttons (Reflect, Stay Anchored) appear when timer completes.

`GuardNavigation` data class passes `route`, `emotion`, and `exercise` from native to Flutter via MethodChannel.

## PDF Export (Premium)

`lib/features/export/` — premium-only "Anchor Report" PDF generation:

- **Date range pickers** — default last 30 days
- **Notes field** — user-entered context for therapist (max 500 chars)
- **5 PDF sections:** Overview (streak stats), Emotional Pattern (emotion frequency table), Urge Log (date/trigger/notes table), Reflection Entries (mood/journal cards), Notes
- **Styling:** Navy headers, teal section dividers, light background tables
- **Share:** via `share_plus` share sheet
- **Premium gate:** non-premium users see upgrade prompt

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
              Phase 1: Emotion grid (10 states)
              Phase 2: Matched ACT prompt + suggestions + timer
              User taps "Reflect" → dismiss + startActivity(MainActivity, NAVIGATE_TO=reflect, EMOTION, EXERCISE)
              User taps "Stay Anchored" → dismiss + startActivity(MainActivity, EMOTION)
              MainActivity.deliverGuardIntent() → channel.invokeMethod("navigateTo", {route, emotion, exercise})
              Flutter GuardService.onNavigateTo(GuardNavigation) → context.go('/${nav.route}')
      NO  → startActivity(MainActivity, EXTRA_APP_NAME) [fallback]
              → channel.invokeMethod("onGuardedAppDetected", appName)
              → Flutter shows InterceptBottomSheet
```

### Key Kotlin files

| File | Role |
|---|---|
| `AppGuardService.kt` | Foreground service, polls UsageStats, calls `launchIntercept()` |
| `OverlayService.kt` | Two-phase overlay: emotion grid → matched prompt + timer + suggestions |
| `AnchorageVpnService.kt` | VPN service; DNS interception, blocklist matching, TCP RST |
| `BlocklistUpdateWorker.kt` | WorkManager worker; refreshes blocklist every 14 days |
| `HeartbeatWorker.kt` | WorkManager worker; 4-hour periodic heartbeat to Firestore |
| `AnchorageDeviceAdminReceiver.kt` | Device admin receiver for tamper detection |
| `MainActivity.kt` | MethodChannel hub for `guard`, `vpn`, and `tamper` channels; passes emotion/exercise extras |

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
| `navigateTo` | `Map {route, emotion?, exercise?}` | Overlay button tapped; Flutter receives `GuardNavigation` |

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

1. Open guarded app → overlay appears (Phase 1: emotion grid)
2. Select an emotion → Phase 2: matched ACT prompt + suggestions + 60s timer
3. Wait for timer → action buttons appear
4. Tap "Stay Anchored" → overlay dismisses, ANCHORAGE comes forward
5. Open guarded app again → overlay appears again (re-arm confirmed, 2s cooldown)
6. Select emotion → tap "Reflect" → overlay dismisses, `/reflect` screen opens
7. Complete reflect, return to home → open guarded app → overlay appears again
8. Enable VPN in Settings → toggle shows "Active — explicit content blocked"
9. Open Chrome → navigate to a porn domain → DNS resolves to 10.111.222.3 → connection refused

## Android Configuration

- `minSdk = maxOf(flutter.minSdkVersion, 23)` — `maxOf()` prevents the Flutter build tool from resetting this on every build.
- Google Services plugin declared in `settings.gradle.kts`, applied in `app/build.gradle.kts`.
- `google-services.json` at `android/app/google-services.json`.
- Namespace (`com.anchorage.anchorage`) and applicationId (`com.anchorage.app`) intentionally differ.
- Notification icon: `android/app/src/main/res/drawable/ic_notification.xml` (white anchor vector).
- Overlay layout: `android/app/src/main/res/layout/overlay_intercept.xml` (two-phase: emotion grid + intervention).
- Exercise chooser dialog: `android/app/src/main/res/layout/dialog_exercise_chooser.xml`.
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
- **Never** use em dashes in UI text, comments, or strings.
- Use `WidgetState` (not deprecated `MaterialState`) for theme property callbacks.
- Use `.withAlpha(n)` (0-255) not `.withOpacity(n)`.
- All new screens: `AppBar` with `title: const Text('SCREEN NAME')` — theme auto-applies styling.

## Crisis Resources

- **Primary:** `findahelpline.com` — shown prominently on SOS screen and About screen
- **Local resources:** AU (Lifeline, Beyond Blue), US (988, SAMHSA), GB (Samaritans, CALM) — shown on SOS screen below primary, detected via device locale
- **IASP link:** secondary worldwide directory on SOS screen
- **Non-SOS locations:** use "If you are in crisis, please visit findahelpline.com for support in your country." instead of hardcoded numbers

## Firebase + RevenueCat Init

Both initialized in `main()` before `runApp`. Firebase wrapped in try/catch. RevenueCat configured unconditionally. Firestore writes go in the feature file. Auth state not yet wired to a provider.

## Tamper Detection

- 4-hour periodic heartbeat via WorkManager (`HeartbeatWorker`)
- Heartbeat writes `uid`, `timestamp`, `vpn_active`, `guard_active`, `client_time` to `users/{uid}/heartbeats/latest`
- VPN revocation events logged to `users/{uid}/tamper_events`
- Device admin activation for uninstall protection
- Immediate heartbeat on app startup (3s timeout, fire-and-forget)

## Accountability System (HIDDEN)

UI is hidden until Cloud Function backend is built. Code preserved with HIDDEN comments in `app_router.dart` and `settings_screen.dart`.

- Partner invite via email + name → stored at `users/{uid}/partners/{id}` in Firestore
- Free tier: 1 partner; Premium: unlimited
- Stats sync: streak days, weekly intercepts, weekly reflections
- Cloud Function for weekly summary emails (backend, not in this repo)
