import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'premium_service.dart';

/// A single White Flag event.
class WhiteFlagEvent {
  final String id;
  final DateTime timestamp;
  final String blockedTarget; // app name or domain
  final String tier; // 'free' or 'paid'

  const WhiteFlagEvent({
    required this.id,
    required this.timestamp,
    required this.blockedTarget,
    required this.tier,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'blockedTarget': blockedTarget,
        'tier': tier,
      };

  factory WhiteFlagEvent.fromJson(Map<String, dynamic> json) => WhiteFlagEvent(
        id: json['id'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        blockedTarget: json['blockedTarget'] as String? ?? '',
        tier: json['tier'] as String? ?? 'free',
      );
}

/// Logs White Flag events locally and to Firestore.
class WhiteFlagService {
  WhiteFlagService._();
  static final WhiteFlagService instance = WhiteFlagService._();

  static const _prefsKey = 'white_flag_events';

  final ValueNotifier<List<WhiteFlagEvent>> events = ValueNotifier([]);

  Future<void> init() async {
    await _load();
  }

  Future<void> logWhiteFlag({required String blockedTarget}) async {
    final isPremium = PremiumService.instance.isPremium.value;
    final event = WhiteFlagEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      blockedTarget: blockedTarget,
      tier: isPremium ? 'paid' : 'free',
    );

    final updated = [...events.value, event];
    events.value = updated;
    await _save(updated);
    _syncToFirestore(event);
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? [];
      events.value = raw
          .map((s) =>
              WhiteFlagEvent.fromJson(json.decode(s) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[WhiteFlagService] load error: $e');
    }
  }

  Future<void> _save(List<WhiteFlagEvent> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKey,
        list.map((e) => json.encode(e.toJson())).toList(),
      );
    } catch (e) {
      debugPrint('[WhiteFlagService] save error: $e');
    }
  }

  void _syncToFirestore(WhiteFlagEvent event) {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('white_flag_events')
          .doc(event.id)
          .set(event.toJson())
          .catchError((e) {
        debugPrint('[WhiteFlagService] Firestore sync error: $e');
      });
    } catch (e) {
      debugPrint('[WhiteFlagService] Firestore sync error: $e');
    }
  }
}
