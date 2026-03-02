import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReflectEntry {
  final String id;
  final DateTime timestamp;
  final String mood;
  final String journal;
  final Map<String, String> valuesAlignment;
  final String trigger;

  const ReflectEntry({
    required this.id,
    required this.timestamp,
    required this.mood,
    this.journal = '',
    this.valuesAlignment = const {},
    this.trigger = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'mood': mood,
        'journal': journal,
        'valuesAlignment': valuesAlignment,
        'trigger': trigger,
      };

  factory ReflectEntry.fromJson(Map<String, dynamic> json) => ReflectEntry(
        id: json['id'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        mood: json['mood'] as String? ?? '',
        journal: json['journal'] as String? ?? '',
        valuesAlignment: json['valuesAlignment'] != null
            ? Map<String, String>.from(
                json['valuesAlignment'] as Map<String, dynamic>)
            : const {},
        trigger: json['trigger'] as String? ?? '',
      );
}

class ReflectService {
  ReflectService._();
  static final ReflectService instance = ReflectService._();

  static const _secureKey = 'reflect_entries';
  static const _legacyPrefsKey = 'reflect_entries';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final ValueNotifier<List<ReflectEntry>> entries = ValueNotifier([]);

  Future<void> init() async {
    await _load();
  }

  Future<void> addEntry({
    required String mood,
    String journal = '',
    Map<String, String> valuesAlignment = const {},
    String trigger = '',
  }) async {
    final entry = ReflectEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      mood: mood,
      journal: journal,
      valuesAlignment: valuesAlignment,
      trigger: trigger,
    );
    entries.value = [entry, ...entries.value];
    await _save();
  }

  /// Number of reflections recorded in the last 7 days.
  int get weeklyReflections {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return entries.value.where((e) => e.timestamp.isAfter(cutoff)).length;
  }

  Future<void> _load() async {
    try {
      // Try secure storage first
      final raw = await _secureStorage.read(key: _secureKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        entries.value = list
            .map((e) => ReflectEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return;
      }

      // Migrate from SharedPreferences if present
      final prefs = await SharedPreferences.getInstance();
      final legacyRaw = prefs.getString(_legacyPrefsKey);
      if (legacyRaw != null) {
        final list = jsonDecode(legacyRaw) as List;
        entries.value = list
            .map((e) => ReflectEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        // Write to secure storage and remove from SharedPreferences
        await _save();
        await prefs.remove(_legacyPrefsKey);
        debugPrint('[ReflectService] migrated to secure storage');
      }
    } catch (e) {
      debugPrint('[ReflectService] load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final json = jsonEncode(entries.value.map((e) => e.toJson()).toList());
      await _secureStorage.write(key: _secureKey, value: json);
    } catch (e) {
      debugPrint('[ReflectService] save error: $e');
    }
  }
}
