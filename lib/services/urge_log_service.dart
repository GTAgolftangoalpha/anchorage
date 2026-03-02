import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UrgeEntry {
  final String id;
  final DateTime timestamp;
  final String trigger;
  final String notes;

  const UrgeEntry({
    required this.id,
    required this.timestamp,
    required this.trigger,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'trigger': trigger,
        'notes': notes,
      };

  factory UrgeEntry.fromJson(Map<String, dynamic> json) => UrgeEntry(
        id: json['id'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        trigger: json['trigger'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
}

class UrgeLogService {
  UrgeLogService._();
  static final UrgeLogService instance = UrgeLogService._();

  static const _secureKey = 'urge_log_entries';
  static const _legacyPrefsKey = 'urge_log_entries';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const triggers = [
    'Boredom',
    'Stress',
    'Loneliness',
    'Anxiety',
    'Late night',
    'Social media',
    'Saw triggering content',
    'Relationship issues',
    'Other',
  ];

  final ValueNotifier<List<UrgeEntry>> entries = ValueNotifier([]);

  Future<void> init() async {
    await _load();
  }

  Future<void> addEntry({
    required String trigger,
    String notes = '',
  }) async {
    final entry = UrgeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      trigger: trigger,
      notes: notes,
    );
    entries.value = [entry, ...entries.value];
    await _save();
  }

  Future<void> deleteEntry(String id) async {
    entries.value = entries.value.where((e) => e.id != id).toList();
    await _save();
  }

  /// Returns entries visible based on tier.
  /// Free tier: last 7 entries. Paid tier: all entries.
  List<UrgeEntry> visibleEntries({required bool isPaid}) {
    if (isPaid) return entries.value;
    return entries.value.take(7).toList();
  }

  /// Count of urge log entries created in the current calendar month.
  int urgeLogsThisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    return entries.value
        .where((e) => !e.timestamp.isBefore(monthStart))
        .length;
  }

  /// For free users: remaining logs this month (max 3).
  /// For premium users: returns -1 (unlimited).
  int freeLogsRemaining({required bool isPremium}) {
    if (isPremium) return -1;
    final used = urgeLogsThisMonth();
    return (3 - used).clamp(0, 3);
  }

  Future<void> _load() async {
    try {
      // Try secure storage first
      final raw = await _secureStorage.read(key: _secureKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        entries.value = list
            .map((e) => UrgeEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return;
      }

      // Migrate from SharedPreferences if present
      final prefs = await SharedPreferences.getInstance();
      final legacyRaw = prefs.getString(_legacyPrefsKey);
      if (legacyRaw != null) {
        final list = jsonDecode(legacyRaw) as List;
        entries.value = list
            .map((e) => UrgeEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        // Write to secure storage and remove from SharedPreferences
        await _save();
        await prefs.remove(_legacyPrefsKey);
        debugPrint('[UrgeLogService] migrated to secure storage');
      }
    } catch (e) {
      debugPrint('[UrgeLogService] load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final json = jsonEncode(entries.value.map((e) => e.toJson()).toList());
      await _secureStorage.write(key: _secureKey, value: json);
    } catch (e) {
      debugPrint('[UrgeLogService] save error: $e');
    }
  }
}
