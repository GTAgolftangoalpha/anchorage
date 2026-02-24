import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  static const _prefsKey = 'reflect_entries';

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
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      entries.value = list
          .map((e) => ReflectEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ReflectService] load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(entries.value.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, json);
    } catch (e) {
      debugPrint('[ReflectService] save error: $e');
    }
  }
}
