import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Handles heartbeat scheduling, device admin, and tamper detection
/// via the native `com.anchorage.app/tamper` MethodChannel.
class TamperService {
  TamperService._();
  static const _channel = MethodChannel('com.anchorage.app/tamper');

  /// Schedule the 4-hour heartbeat WorkManager job.
  static Future<void> scheduleHeartbeat() async {
    try {
      await _channel.invokeMethod('scheduleHeartbeat');
    } catch (e) {
      debugPrint('[TamperService] scheduleHeartbeat error: $e');
    }
  }

  /// Send a one-time heartbeat immediately.
  static Future<void> sendHeartbeatNow() async {
    try {
      await _channel.invokeMethod('sendHeartbeatNow');
    } catch (e) {
      debugPrint('[TamperService] sendHeartbeatNow error: $e');
    }
  }

  /// Check if ANCHORAGE is registered as a device administrator.
  static Future<bool> isDeviceAdminActive() async {
    try {
      return await _channel.invokeMethod<bool>('isDeviceAdminActive') ?? false;
    } catch (e) {
      debugPrint('[TamperService] isDeviceAdminActive error: $e');
      return false;
    }
  }

  /// Request device admin activation (opens system dialog).
  static Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } catch (e) {
      debugPrint('[TamperService] requestDeviceAdmin error: $e');
    }
  }

  /// Open Android VPN settings so the user can enable Always-on VPN.
  static Future<void> openAlwaysOnVpnSettings() async {
    try {
      await _channel.invokeMethod('openAlwaysOnVpnSettings');
    } catch (e) {
      debugPrint('[TamperService] openAlwaysOnVpnSettings error: $e');
    }
  }
}
