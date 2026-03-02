import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RelapseEntry {
  final String id;
  final DateTime timestamp;
  final String whatHappened;
  final String whatTriggered;
  final String whatLearned;
  final String nextTime;

  const RelapseEntry({
    required this.id,
    required this.timestamp,
    this.whatHappened = '',
    this.whatTriggered = '',
    this.whatLearned = '',
    this.nextTime = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'whatHappened': whatHappened,
        'whatTriggered': whatTriggered,
        'whatLearned': whatLearned,
        'nextTime': nextTime,
      };

  factory RelapseEntry.fromJson(Map<String, dynamic> json) => RelapseEntry(
        id: json['id'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        whatHappened: json['whatHappened'] as String? ?? '',
        whatTriggered: json['whatTriggered'] as String? ?? '',
        whatLearned: json['whatLearned'] as String? ?? '',
        nextTime: json['nextTime'] as String? ?? '',
      );
}

class RelapseService {
  RelapseService._();
  static final RelapseService instance = RelapseService._();

  static const _secureKey = 'relapse_log_entries';
  static const _legacyPrefsKey = 'relapse_log_entries';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final ValueNotifier<List<RelapseEntry>> entries = ValueNotifier([]);

  Future<void> init() async {
    await _load();
  }

  Future<void> addEntry({
    required String whatHappened,
    required String whatTriggered,
    required String whatLearned,
    required String nextTime,
  }) async {
    final entry = RelapseEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      whatHappened: whatHappened,
      whatTriggered: whatTriggered,
      whatLearned: whatLearned,
      nextTime: nextTime,
    );
    entries.value = [entry, ...entries.value];
    await _save();
  }

  Future<void> _load() async {
    try {
      // Try secure storage first
      final raw = await _secureStorage.read(key: _secureKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        entries.value = list
            .map((e) => RelapseEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return;
      }

      // Migrate from SharedPreferences if present
      final prefs = await SharedPreferences.getInstance();
      final legacyRaw = prefs.getString(_legacyPrefsKey);
      if (legacyRaw != null) {
        final list = jsonDecode(legacyRaw) as List;
        entries.value = list
            .map((e) => RelapseEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        // Write to secure storage and remove from SharedPreferences
        await _save();
        await prefs.remove(_legacyPrefsKey);
        debugPrint('[RelapseService] migrated to secure storage');
      }
    } catch (e) {
      debugPrint('[RelapseService] load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final json =
          jsonEncode(entries.value.map((e) => e.toJson()).toList());
      await _secureStorage.write(key: _secureKey, value: json);
    } catch (e) {
      debugPrint('[RelapseService] save error: $e');
    }
  }
}
