# ANCHORAGE Security Audit

Audit date: 14 March 2026
Status: Pre-launch V1
Last verified: 14 March 2026

## 1. Data Storage Summary

### Data Stored Locally (On Device)

| Data | Storage Method | Encryption |
|---|---|---|
| Urge logs (triggers, timestamps, notes) | flutter_secure_storage | Android Keystore (EncryptedSharedPreferences) |
| Lapse logs (guided reflections) | flutter_secure_storage | Android Keystore (EncryptedSharedPreferences) |
| Reflection entries (mood, journal) | flutter_secure_storage | Android Keystore (EncryptedSharedPreferences) |
| Streak data (counts, dates) | SharedPreferences | None (non-sensitive aggregate data) |
| User preferences (name, values, settings) | SharedPreferences | None (non-sensitive) |
| Guarded app selections | SharedPreferences | None (non-sensitive) |
| Intercept events (emotion, outcome) | SharedPreferences + Firestore sync | None locally; TLS in transit |

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

## 3. Encryption

| Layer | Method |
|---|---|
| Data at rest (sensitive) | Android Keystore via flutter_secure_storage (EncryptedSharedPreferences) |
| Data in transit | HTTPS/TLS for all Firebase and SendGrid communication |
| VPN DNS queries | Local-only processing; no data transmitted to external servers |

## 4. Screen Protection

- `FLAG_SECURE` set on `MainActivity` window in `onCreate()`
- Prevents screenshots and screen recording across all Flutter screens
- Protects: urge logs, lapse logs, reflection journals, journey stats, export screen, intercept screens

## 5. Code Obfuscation

- R8/ProGuard enabled for release builds (`isMinifyEnabled = true`, `isShrinkResources = true`)
- Custom `proguard-rules.pro` preserves Flutter, Firebase, WorkManager, and service classes
- APK contents are obfuscated to protect against reverse engineering

## 6. Rate Limiting

- Cloud Functions enforce max 10 emails per user per day
- Rate limit checked before every email send (invitations, weekly reports, heartbeat alerts, tamper alerts)
- Email send events recorded in `users/{uid}/email_sends` with server timestamps

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

## 10. Outstanding Items

- [ ] Replace RevenueCat test API key with production key before Play Store release
- [x] Configure proper release signing config (replace debug keystore) -- done 2026-03-15
- [x] Update `FROM_EMAIL` in Cloud Functions to `hello@getanchorage.app` -- done 2026-03-15
- [ ] Deploy updated Firestore rules via `firebase deploy --only firestore:rules`
- [ ] Deploy updated Cloud Functions via `firebase deploy --only functions`
