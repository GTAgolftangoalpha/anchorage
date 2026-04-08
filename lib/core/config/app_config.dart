// SendGrid key lives in Cloud Functions env only - never in client code.
class AppConfig {
  // Replace with your RevenueCat production API key before release.
  // RevenueCat public keys are safe to ship in client code by design.
  static const String revenueCatKey = 'REPLACE_WITH_PRODUCTION_KEY';

  /// Call during app startup to catch misconfiguration early.
  static void assertKeysConfigured() {
    if (revenueCatKey == 'REPLACE_WITH_PRODUCTION_KEY' ||
        revenueCatKey.isEmpty) {
      throw StateError(
        'RevenueCat production key not set. '
        'Update AppConfig.revenueCatKey before building a release.',
      );
    }
  }
}
