import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data passed from the native overlay when the user navigates.
class GuardNavigation {
  final String route;
  final String? emotion;
  final String? exercise;

  const GuardNavigation({
    required this.route,
    this.emotion,
    this.exercise,
  });
}

/// Flutter / Native bridge for the AppGuardService foreground service.
class GuardService {
  GuardService._();

  static const _channel = MethodChannel('com.anchorage.app/guard');
  static const _prefsKey = 'guarded_app_packages';

  static void Function(String appName)? _onDetected;
  static void Function(GuardNavigation nav)? _onNavigateTo;

  /// Call once at app startup to wire up the native to Flutter callback.
  static void init() {
    debugPrint('[GuardService] init: registering MethodChannel handler');
    _channel.setMethodCallHandler((call) async {
      debugPrint('[GuardService] native->flutter: ${call.method} args=${call.arguments}');
      if (call.method == 'onGuardedAppDetected') {
        final appName = call.arguments as String;
        debugPrint('[GuardService] onGuardedAppDetected: "$appName"');
        _onDetected?.call(appName);
      } else if (call.method == 'navigateTo') {
        final args = call.arguments;
        GuardNavigation nav;
        if (args is Map) {
          nav = GuardNavigation(
            route: args['route'] as String? ?? 'home',
            emotion: args['emotion'] as String?,
            exercise: args['exercise'] as String?,
          );
        } else {
          // Backwards compatibility: plain string route
          nav = GuardNavigation(route: args as String);
        }
        debugPrint('[GuardService] navigateTo: route=${nav.route} emotion=${nav.emotion} exercise=${nav.exercise}');
        _onNavigateTo?.call(nav);
      }
    });
  }

  /// Register a callback invoked when a guarded app is detected in foreground
  /// (fallback path: used when overlay permission is not granted).
  static void onGuardedAppDetected(void Function(String appName) callback) {
    debugPrint('[GuardService] onGuardedAppDetected: callback registered');
    _onDetected = callback;
  }

  /// Register a callback invoked when the native overlay triggers navigation
  /// (e.g. user taps "Reflect" on the overlay, navigates to /reflect).
  static void onNavigateTo(void Function(GuardNavigation nav) callback) {
    debugPrint('[GuardService] onNavigateTo: callback registered');
    _onNavigateTo = callback;
  }

  // ── Overlay permission ────────────────────────────────────────────────────

  static Future<bool> hasOverlayPermission() async {
    final result = await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
    debugPrint('[GuardService] hasOverlayPermission: $result');
    return result;
  }

  static Future<void> requestOverlayPermission() {
    debugPrint('[GuardService] requestOverlayPermission');
    return _channel.invokeMethod('requestOverlayPermission');
  }

  // ── Battery optimization ─────────────────────────────────────────────────

  static Future<bool> isBatteryOptimizationExempt() async {
    final result =
        await _channel.invokeMethod<bool>('isBatteryOptimizationExempt') ??
            false;
    debugPrint('[GuardService] isBatteryOptimizationExempt: $result');
    return result;
  }

  static Future<void> requestBatteryOptimizationExempt() {
    debugPrint('[GuardService] requestBatteryOptimizationExempt');
    return _channel.invokeMethod('requestBatteryOptimizationExempt');
  }

  // ── Usage stats permission ────────────────────────────────────────────────

  static Future<bool> hasUsagePermission() async {
    final result = await _channel.invokeMethod<bool>('isUsagePermissionGranted') ?? false;
    debugPrint('[GuardService] hasUsagePermission: $result');
    return result;
  }

  static Future<void> requestUsagePermission() {
    debugPrint('[GuardService] requestUsagePermission');
    return _channel.invokeMethod('requestUsagePermission');
  }

  // ── Service lifecycle ─────────────────────────────────────────────────────

  static Future<void> start(List<String> packageNames) async {
    debugPrint('[GuardService] start: $packageNames');
    await _channel.invokeMethod('startGuardService', {'apps': packageNames});
    debugPrint('[GuardService] start: native call returned');
  }

  static Future<void> stop() async {
    debugPrint('[GuardService] stop');
    await _channel.invokeMethod('stopGuardService');
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  static Future<List<String>> loadGuardedPackages() async {
    final prefs = await SharedPreferences.getInstance();
    final packages = prefs.getStringList(_prefsKey) ?? [];
    debugPrint('[GuardService] loadGuardedPackages: $packages');
    return packages;
  }

  static Future<void> saveGuardedPackages(List<String> packages) async {
    debugPrint('[GuardService] saveGuardedPackages: $packages');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, packages);
  }
}
