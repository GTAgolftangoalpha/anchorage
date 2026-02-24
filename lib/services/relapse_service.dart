import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  static const _prefsKey = 'relapse_log_entries';

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
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      entries.value = list
          .map((e) => RelapseEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[RelapseService] load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json =
          jsonEncode(entries.value.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, json);
    } catch (e) {
      debugPrint('[RelapseService] save error: $e');
    }
  }
}
