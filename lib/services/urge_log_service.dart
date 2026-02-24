import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  static const _prefsKey = 'urge_log_entries';

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

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      entries.value = list
          .map((e) => UrgeEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[UrgeLogService] load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(entries.value.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, json);
    } catch (e) {
      debugPrint('[UrgeLogService] save error: $e');
    }
  }
}
