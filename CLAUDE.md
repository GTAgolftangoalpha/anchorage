# ANCHORAGE -- Claude Code Project Context

## Company
**Golf Tango Alpha Pty Ltd** (GTA) -- this is the ONLY legal entity that appears in the app, store listings, marketing, and all external materials. Jackie's name NEVER appears anywhere. The developer is anonymous by design.

## What this app is
Android app for pornography/compulsive internet use recovery. ACT-informed (Acceptance and Commitment Therapy), shame-free, secular positioning. Deliberate contrast to faith-based competitors like Covenant Eyes. Nautical theme -- anchor imagery, ocean language throughout.

## Tech stack
- Flutter / Android (no iOS yet)
- Firebase (backend, auth, accountability email trigger)
- SendGrid (accountability email delivery)
- RevenueCat (paywall / subscription management)
- VPN-based domain blocklist (~157K entries)
- Accessibility service layer
- Device Admin integration

## Brand rules
- Nautical theme: anchor + white logo, anonymous brand voice
- NO shame language. NO religious references. NO judgement.
- ACT framework underpins all copy: psychological flexibility, values, defusion
- Tone: calm, clinical, grounded, matter-of-fact

## Subscription tiers
- **Harbour** -- free tier
- **ANCHORAGE+** -- paid tier (founding member pricing $9.99 AUD/month)
- Storm Mode was removed from V1 after safety review. Do not re-add.
- Only two tiers, no other naming

## Core features built
- VPN-based domain blocklist (~157K entries)
- Accessibility service layer (tamper detection)
- Emotional state selector (10 states including Aroused)
- 58 behavioural activation suggestions
- 5 guided exercises
- Psychoeducation cards
- Device Admin integration
- Streak tracking
- Accountability email via SendGrid/Firebase
- RevenueCat paywall

## Project directory
`C:\Users\jacki\AndroidStudioProjects\anchorage\` (confirm actual path if different)

## Build status
W1-W7 of 8-week build plan complete.
Outstanding W8 tasks:
- Landing page (getanchorage.app on Cloudflare)
- Signed APK/AAB
- Play Store submission
- Off-Play-Store APK distribution path on Cloudflare (insurance against policy risk)

## Key infrastructure
- Domain: getanchorage.app (Cloudflare)
- Social: @AnchorageApp (TikTok, YouTube), @getanchorage (X), @AnchorageApp (Instagram, Facebook)

## Marketing strategy
Primary launch: Reddit (r/pornfree, r/NoFap, r/selfimprovement)
Secondary: Faceless TikTok/Instagram Reels/YouTube Shorts via AI avatar (HeyGen)
SEO blog, paid ads later
n8n automation stack designed for marketing

## Security requirements
- Jackie's name must NEVER appear in source code, comments, store listing, or metadata
- Only Golf Tango Alpha Pty Ltd as legal reference
- VPN service must not leak DNS
- Tamper detection must resist accessibility service disabling

## Code conventions
- Follow existing Flutter project structure
- All copy must pass ACT-alignment check (shame-free, values-focused)
- RevenueCat product IDs must match store listing exactly
- Keep Harbour/ANCHORAGE+ tier names consistent everywhere

## What NOT to do
- Do not add subscription tiers or rename existing ones without explicit instruction
- Do not add Jackie's name, real name, or any personal identifier
- Do not add religious or faith-based language
- Do not use shame or failure framing in any user-facing copy
- Do not use em dashes in any UI text, comments, or strings

## Test suite

### Running tests
```bash
# Unit + widget tests (no device needed)
flutter test

# Single test file
flutter test test/unit/urge_log_service_test.dart

# Integration tests (requires device or emulator)
flutter test integration_test/onboarding_flow_test.dart
flutter test integration_test/underage_block_test.dart
flutter test integration_test/urge_log_gating_test.dart
flutter test integration_test/feedback_test.dart

# Static analysis
flutter analyze --no-fatal-infos

# Coverage report
flutter test --coverage
# Coverage file: coverage/lcov.info
```

### Test structure
- `test/unit/` -- pure logic tests (services, models, algorithms)
- `test/widget/` -- widget rendering, content presence/absence, regression
- `integration_test/` -- full-flow tests requiring device or emulator

### Device-only manual tests (not automatable)
- VPN permission grant and DNS blocking of a known blocked domain
- Accessibility Service interception of a guarded app
- FLAG_SECURE screenshot blocking on sensitive screens
- RevenueCat purchase flow in Play Store closed testing
- SendGrid accountability partner email arriving in real inbox
- Firebase Cloud Function rate limiting against live calls
