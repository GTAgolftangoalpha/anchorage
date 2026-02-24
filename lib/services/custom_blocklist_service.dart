import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomBlocklistService {
  CustomBlocklistService._();
  static final CustomBlocklistService instance = CustomBlocklistService._();

  static const _prefsKey = 'custom_blocklist_domains';
  static const _vpnChannel = MethodChannel('com.anchorage.app/vpn');

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
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<String>();
      domains.value = list;
    } catch (e) {
      debugPrint('[CustomBlocklistService] load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(domains.value));
    } catch (e) {
      debugPrint('[CustomBlocklistService] save error: $e');
    }
  }
}
