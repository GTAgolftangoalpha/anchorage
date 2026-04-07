# ANCHORAGE Pre-Launch TODOs

Last updated: 8 April 2026

This file tracks remaining items that must be addressed before V1 launch on
Google Play. Items are grouped by category and ordered by blocking severity.

## Blocking — Must Complete Before Submission

- [ ] Replace `revenueCatKey` placeholder in `lib/core/config/app_config.dart`
      with the production RevenueCat public API key. The runtime guard throws
      a `StateError` on app startup if the placeholder is still present.
- [ ] Deploy updated Firestore rules: `firebase deploy --only firestore:rules`
- [ ] Deploy updated Cloud Functions: `firebase deploy --only functions`
- [ ] Configure release signing config in `android/app/build.gradle.kts` and
      generate the upload keystore (do not reuse the debug keystore).
- [ ] Place real `google-services.json` (production project) in
      `android/app/`. The file is intentionally gitignored for security.
- [ ] Build signed AAB: `flutter build appbundle --release`
- [ ] Upload AAB to Google Play internal testing track.

## Non-Blocking — Should Complete Before Public Launch

- [ ] Update SendGrid accountability partner invitation template to clearly
      include opt-out instructions per ANCHORAGE privacy policy. The email
      must clearly state:
      - what ANCHORAGE is
      - that the recipient has been nominated as an accountability partner
      - that they do NOT have to accept
      - a clear ignore instruction: "If you did not expect this email or do
        not wish to take on this role, please ignore it. No further action
        is required."
      Tracked in `lib/services/accountability_service.dart:80`.
- [ ] Add integration tests for onboarding, intercept, and paywall flows.
      Currently only a placeholder widget test exists.
- [ ] Submit Privacy Policy and Terms of Service URLs to Play Console.
      Live HTML lives in `lib/features/legal/legal_viewer_screen.dart`.
- [ ] Set up Crashlytics dashboard alerts for crash-free user rate < 99%.

## Post-Launch

- [ ] Monitor Cloud Function rate limits across the first week of users.
- [ ] Review accountability partner email open rates via SendGrid.
- [ ] Schedule first content update for the psychoeducation cards.
