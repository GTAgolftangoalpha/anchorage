import 'package:flutter/services.dart';

/// Flutter bridge for [AnchorageVpnService].
///
/// Call [init] once in main() to wire native → Flutter callbacks.
/// Call [prepareVpn] first — it shows the system VPN consent dialog if needed
/// and returns `true` when permission is already granted or just granted.
/// Only call [startVpn] after [prepareVpn] returns `true`.
class VpnService {
  static const _channel = MethodChannel('com.anchorage.app/vpn');

  /// Called when VPN blocks a domain (e.g. "pornhub.com").
  /// The native OverlayService shows the blocked-domain overlay;
  /// this callback lets Flutter update state (counters, in-app screens, etc.).
  static Function(String domain)? onDomainBlocked;

  /// Wire native → Flutter callbacks. Call once in main() before runApp.
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDomainBlocked') {
        onDomainBlocked?.call(call.arguments as String? ?? '');
      }
    });
  }

  /// Returns `true` if VPN permission is already granted.
  /// Returns `false` if the system consent dialog was shown (user must confirm,
  /// then call [prepareVpn] again to verify).
  static Future<bool> prepareVpn() async {
    return await _channel.invokeMethod<bool>('prepareVpn') ?? false;
  }

  static Future<void> startVpn() async {
    await _channel.invokeMethod('startVpn');
  }

  static Future<void> stopVpn() async {
    await _channel.invokeMethod('stopVpn');
  }

  static Future<bool> isVpnActive() async {
    return await _channel.invokeMethod<bool>('isVpnActive') ?? false;
  }
}
