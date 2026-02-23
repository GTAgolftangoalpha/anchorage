/// Represents a blockable app that can be added to the guard list.
class GuardableApp {
  final String packageName;
  final String displayName;
  final String emoji;

  const GuardableApp({
    required this.packageName,
    required this.displayName,
    required this.emoji,
  });

  static const int freeTierLimit = 3;

  /// Apps available for UsageStats-based guard interception.
  ///
  /// Browsers (Chrome, Firefox, Brave, Opera) are intentionally excluded —
  /// browser content is handled exclusively by the VPN DNS filter, not by
  /// UsageStatsManager. Adding a browser here would cause the overlay to fire
  /// on every browser launch, fighting with the VPN blocked-domain overlay.
  static const List<GuardableApp> predefined = [
    GuardableApp(
      packageName: 'com.reddit.frontpage',
      displayName: 'Reddit',
      emoji: '🔴',
    ),
    GuardableApp(
      packageName: 'com.twitter.android',
      displayName: 'Twitter / X',
      emoji: '🐦',
    ),
    GuardableApp(
      packageName: 'org.telegram.messenger',
      displayName: 'Telegram',
      emoji: '✈️',
    ),
  ];
}
