import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single intercept event recording what happened and the user's state.
class InterceptEvent {
  final String id;
  final DateTime timestamp;
  final String? emotion;
  final String? exercise;
  final String outcome; // 'reflected', 'stayed', 'exercised'
  final String source; // 'app_guard', 'vpn_block'

  const InterceptEvent({
    required this.id,
    required this.timestamp,
    this.emotion,
    this.exercise,
    required this.outcome,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'emotion': emotion,
        'exercise': exercise,
        'outcome': outcome,
        'source': source,
      };

  factory InterceptEvent.fromJson(Map<String, dynamic> json) => InterceptEvent(
        id: json['id'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        emotion: json['emotion'] as String?,
        exercise: json['exercise'] as String?,
        outcome: json['outcome'] as String? ?? 'stayed',
        source: json['source'] as String? ?? 'app_guard',
      );
}

/// Stores and retrieves intercept events locally and syncs to Firestore.
class InterceptEventService {
  InterceptEventService._();
  static final InterceptEventService instance = InterceptEventService._();

  static const _secureKey = 'intercept_events';
  static const _legacyPrefsKey = 'intercept_events';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final ValueNotifier<List<InterceptEvent>> events = ValueNotifier([]);

  Future<void> init() async {
    await _load();
  }

  Future<void> logEvent({
    String? emotion,
    String? exercise,
    required String outcome,
    required String source,
  }) async {
    final event = InterceptEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      emotion: emotion,
      exercise: exercise,
      outcome: outcome,
      source: source,
    );

    final updated = [...events.value, event];
    events.value = updated;
    await _save(updated);
    _syncToFirestore(event);
  }

  /// Returns a count of events grouped by emotion for a given date range.
  Map<String, int> emotionCounts({DateTime? from, DateTime? to}) {
    final counts = <String, int>{};
    for (final e in events.value) {
      if (from != null && e.timestamp.isBefore(from)) continue;
      if (to != null && e.timestamp.isAfter(to)) continue;
      if (e.emotion != null && e.emotion!.isNotEmpty) {
        counts[e.emotion!] = (counts[e.emotion!] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Returns all events in a date range.
  List<InterceptEvent> eventsInRange(DateTime from, DateTime to) {
    return events.value
        .where((e) => !e.timestamp.isBefore(from) && !e.timestamp.isAfter(to))
        .toList();
  }

  Future<void> _load() async {
    try {
      final raw = await _secureStorage.read(key: _secureKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        events.value = list
            .map((e) => InterceptEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        return;
      }

      // One-time migration from legacy SharedPreferences storage.
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getStringList(_legacyPrefsKey);
      if (legacy != null && legacy.isNotEmpty) {
        events.value = legacy
            .map((s) => InterceptEvent.fromJson(
                json.decode(s) as Map<String, dynamic>))
            .toList();
        await _save(events.value);
        await prefs.remove(_legacyPrefsKey);
        debugPrint('[InterceptEventService] migrated to secure storage');
      }
    } catch (e) {
      debugPrint('[InterceptEventService] load error: $e');
    }
  }

  Future<void> _save(List<InterceptEvent> list) async {
    try {
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await _secureStorage.write(key: _secureKey, value: encoded);
    } catch (e) {
      debugPrint('[InterceptEventService] save error: $e');
    }
  }

  void _syncToFirestore(InterceptEvent event) {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('intercept_events')
          .doc(event.id)
          .set(event.toJson())
          .catchError((e) {
        debugPrint('[InterceptEventService] Firestore sync error: $e');
      });
    } catch (e) {
      debugPrint('[InterceptEventService] Firestore sync error: $e');
    }
  }
}
