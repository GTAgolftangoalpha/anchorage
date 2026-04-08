# ANCHORAGE Security Audit

Audit date: 8 April 2026
Status: Pre-launch V1
Last verified: 8 April 2026

## 1. Data Storage Summary

### Data Stored Locally (On Device)

| Data | Storage Method | Encryption |
|---|---|---|
| Urge logs (triggers, timestamps, notes) | flutter_secure_storage | Android Keystore (EncryptedSharedPreferences) |
| Lapse logs (guided reflections) | flutter_secure_storage | Android Keystore (EncryptedSharedPreferences) |
| Reflection entries (mood, journal) | flutter_secure_storage | Android Keystore (EncryptedSharedPreferences) |
| Intercept events (emotion, outcome) | flutter_secure_storage + Firestore sync | Android Keystore (local); TLS (in transit) |
| White Flag events (blocked target) | flutter_secure_storage + Firestore sync | Android Keystore (local); TLS (in transit) |
| Custom blocklist domains | flutter_secure_storage | Android Keystore (EncryptedSharedPreferences) |
| User profile (name, email, values, motivation, gender, birth year, usage frequency) | flutter_secure_storage | Android Keystore (EncryptedSharedPreferences) |
| Streak data (counts, dates) | SharedPreferences | None (non-sensitive aggregate counts) |
| Onboarding complete flag, install date | SharedPreferences | None (non-sensitive flags) |
| Guarded app selections (package names) | SharedPreferences | None (non-sensitive) |

### Data Stored in Firebase (Cloud)

| Data | Location | Access Control |
|---|---|---|
| Anonymous user ID (UUID) | Firebase Auth | Auto-managed by Firebase |
| Streak data | Firestore `users/{uid}` | Auth UID match required |
| Accountability partner details | Firestore `users/{uid}/partners` | Auth UID match required |
| Heartbeat signals | Firestore `users/{uid}/heartbeats/latest` | Auth UID match required |
| Tamper events | Firestore `users/{uid}/tamper_events` | Auth UID match required |
| Intercept events | Firestore `users/{uid}/intercept_events` | Auth UID match required |
| Stats (for accountability) | Firestore `users/{uid}/stats` | Auth UID match required |
| Email send records (rate limiting) | Firestore `users/{uid}/email_sends` | Auth UID match required |
| Heartbeat alert records | Firestore `users/{uid}/heartbeat_alerts` | Auth UID match required |

### Data Processed by Third Parties

| Service | Data Processed | Purpose |
|---|---|---|
| SendGrid | Recipient email, streak/progress data | Accountability partner emails |
| RevenueCat | Subscription status (via Google Play) | Premium entitlement management |
| Firebase Auth | Anonymous UUID only | Authentication |

## 2. Access Controls

### Firestore Security Rules

- Every document under `users/{userId}` requires `request.auth.uid == userId`
- All subcollections inherit the same UID-scoped rule
- `partnerInvites` collection: read and write both denied (Cloud Functions use admin SDK, bypassing rules)
- Default catch-all rule denies all other access
- No public read or write access to any collection

### Firebase Realtime Database

Not used by this app. Only Cloud Firestore is used for cloud storage. No
`database` block is present in `firebase.json` and no `database.rules.json`
file exists in the project. No Realtime Database rules to configure.

### Client-Side Keys

| Key | Location | Risk Level | Notes |
|---|---|---|---|
| RevenueCat public API key | `lib/core/config/app_config.dart` | Low | Public key by design; identifies the app to RevenueCat |
| Firebase config | `google-services.json` | Low | Standard Firebase config; security enforced server-side |
| SendGrid API key | `functions/.env` (Cloud Functions only) | Medium | Never in client code; loaded as Firebase secret at runtime |

### No hardcoded secrets in client Dart code
- Searched all `.dart` files for API keys, tokens, and secrets
- Only the RevenueCat public API key is present (expected and safe)
- SendGrid API key exists only in Cloud Functions environment config

### API Key Audit (re-verified pre-launch)

Search performed across `lib/**.dart` for: `apiKey`, `api_key`, `secret`, `token`,
`password`, `Bearer`, `SendGrid`, `SENDGRID`, `sk-`, `pk-`, `SG.`, `sk_live`,
`pk_live`, `sk_test`, `pk_test`, `AKIA`, `appl_`, `goog_`.

| Finding | Location | Verdict |
|---|---|---|
| `revenueCatKey = 'REPLACE_WITH_PRODUCTION_KEY'` | `lib/core/config/app_config.dart` | Placeholder; runtime guard throws if not replaced. RevenueCat public keys are safe in client code. |
| `Firebase ID token refresh` | `lib/services/premium_service.dart` | Token is fetched at runtime from Firebase Auth, not hardcoded. |
| `inviteToken` / `unsubscribeToken` (random UUIDs) | `lib/services/accountability_service.dart` | Generated at runtime via `Random.secure`. Not secrets. |

No SendGrid API key, AWS key, or other private secret found in client Dart code.
Comment added at top of `app_config.dart` documenting that SendGrid keys live in
Cloud Functions environment config only.

## 3. Encryption

| Layer | Method |
|---|---|
| Data at rest (sensitive) | Android Keystore via flutter_secure_storage (EncryptedSharedPreferences) |
| Data in transit | HTTPS/TLS for all Firebase and SendGrid communication |
| VPN DNS queries | Local-only processing; no data transmitted to external servers |

## 4. Screen Protection

- `FLAG_SECURE` set globally on the `MainActivity` window in `onCreate()`.
- A single window-level flag covers every Flutter screen and every dialog
  (intercept bottom sheet, urge log, reflect journal, journey/stats,
  lapse log, export screen, paywall, settings, etc.) because all Flutter
  rendering happens inside that activity's window.
- Global application is preferred over per-screen flags because a new
  sensitive screen added in the future is automatically protected; there
  is no risk of forgetting to wire up FLAG_SECURE on a specific route.
- Screenshots and screen recording are blocked at the OS level; the
  Android recent-apps thumbnail is also blanked.

## 5. Code Obfuscation

- R8/ProGuard enabled for release builds (`isMinifyEnabled = true`, `isShrinkResources = true`)
- Custom `proguard-rules.pro` preserves Flutter, Firebase, WorkManager, and service classes
- APK contents are obfuscated to protect against reverse engineering

## 6. Rate Limiting

- Cloud Functions enforce max 10 emails per user per day across all email types
- Rate limit checked before every email send (invitations, weekly reports, heartbeat alerts, tamper alerts)
- Email send events recorded in `users/{uid}/email_sends` with server timestamps
- Each successful send (including tamper alerts) calls `recordEmailSend(userId)` so the daily counter advances
- Counter resets at midnight UTC because the query window is `>= startOfDay`

## 7. Accountability Partner Data Scoping

- Partner documents stored under `users/{uid}/partners/{partnerId}`
- Firestore rules ensure only the owning user can read/write their partner data
- Weekly reports contain only aggregate data (streak days, intercept count, reflection count)
- No urge logs, lapse details, browsing data, or personal content shared in any email

## 8. VPN Security

- DNS-only routing: only DNS queries and blocked-domain sentinel IP routed through TUN
- All real traffic bypasses the VPN entirely
- No browsing data logged, stored, or transmitted
- Blocklist loaded into memory as a HashSet; not accessible externally

## 9. Permissions

| Permission | Purpose | User Consent |
|---|---|---|
| PACKAGE_USAGE_STATS | Detect guarded app launches | Explicit (Settings redirect) |
| SYSTEM_ALERT_WINDOW | Display intercept overlay | Explicit (Settings redirect) |
| VPN consent | Local DNS filtering | System dialog |
| Battery optimization exemption | Prevent guard service throttling | Explicit dialog |
| Device admin (optional) | Tamper/uninstall protection | Explicit dialog |

## 10. Network Security

- `network_security_config.xml` denies all cleartext (HTTP) traffic
- Only system trust anchors permitted
- Referenced from `<application android:networkSecurityConfig="@xml/network_security_config"/>`
- All third-party endpoints (Firebase, RevenueCat, SendGrid via Cloud Functions) use HTTPS

## 11. Outstanding Items

- [ ] Replace RevenueCat placeholder key with production key before Play Store release
- [x] Configure proper release signing config (replace debug keystore) -- done 2026-03-15
- [x] Update `FROM_EMAIL` in Cloud Functions to `hello@getanchorage.app` -- done 2026-03-15
- [ ] Deploy updated Firestore rules via `firebase deploy --only firestore:rules`
- [ ] Deploy updated Cloud Functions via `firebase deploy --only functions`
- [x] Migrate sensitive local storage to flutter_secure_storage -- done 2026-04-08
- [x] Add rate limiting to onTamperEvent Cloud Function -- done 2026-04-08
- [x] Verify network security config and HTTPS-only enforcement -- done 2026-04-08
