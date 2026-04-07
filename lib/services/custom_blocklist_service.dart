import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomBlocklistService {
  CustomBlocklistService._();
  static final CustomBlocklistService instance = CustomBlocklistService._();

  static const _secureKey = 'custom_blocklist_domains';
  static const _legacyPrefsKey = 'custom_blocklist_domains';
  static const _vpnChannel = MethodChannel('com.anchorage.app/vpn');

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Regex: valid domain (e.g. example.com, sub.domain.co.uk)
  static final _domainRegex = RegExp(
    r'^([a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$',
  );

  final ValueNotifier<List<String>> domains = ValueNotifier([]);

  Future<void> init() async {
    await _load();
    // Sync to native on startup so VPN picks up custom domains
    await _syncToNative();
  }

  /// Validates a domain string.
  static bool isValidDomain(String domain) {
    final d = domain.trim().toLowerCase();
    if (d.isEmpty || d.length > 253) return false;
    return _domainRegex.hasMatch(d);
  }

  Future<void> addDomain(String domain) async {
    final d = domain.trim().toLowerCase();
    if (!isValidDomain(d)) return;
    if (domains.value.contains(d)) return;
    domains.value = [d, ...domains.value];
    await _save();
    await _syncToNative();
  }

  Future<void> removeDomain(String domain) async {
    domains.value = domains.value.where((d) => d != domain).toList();
    await _save();
    await _syncToNative();
  }

  Future<void> _syncToNative() async {
    try {
      await _vpnChannel.invokeMethod(
          'reloadCustomBlocklist', domains.value);
    } catch (e) {
      debugPrint('[CustomBlocklistService] syncToNative error: $e');
    }
  }

  Future<void> _load() async {
    try {
      final raw = await _secureStorage.read(key: _secureKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).cast<String>();
        domains.value = list;
        return;
      }

      // One-time migration from legacy SharedPreferences storage.
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_legacyPrefsKey);
      if (legacy != null) {
        final list = (jsonDecode(legacy) as List).cast<String>();
        domains.value = list;
        await _save();
        await prefs.remove(_legacyPrefsKey);
        debugPrint('[CustomBlocklistService] migrated to secure storage');
      }
    } catch (e) {
      debugPrint('[CustomBlocklistService] load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      await _secureStorage.write(
        key: _secureKey,
        value: jsonEncode(domains.value),
      );
    } catch (e) {
      debugPrint('[CustomBlocklistService] save error: $e');
    }
  }
}
