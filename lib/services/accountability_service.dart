import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Represents one accountability partner relationship.
class AccountabilityPartner {
  final String id;
  final String partnerEmail;
  final String partnerName;
  final String status; // 'invited' | 'accepted' | 'declined'
  final DateTime invitedAt;

  const AccountabilityPartner({
    required this.id,
    required this.partnerEmail,
    required this.partnerName,
    required this.status,
    required this.invitedAt,
  });

  factory AccountabilityPartner.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AccountabilityPartner(
      id: doc.id,
      partnerEmail: d['partnerEmail'] as String? ?? '',
      partnerName: d['partnerName'] as String? ?? '',
      status: d['status'] as String? ?? 'invited',
      invitedAt: (d['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class AccountabilityService {
  AccountabilityService._();
  static final AccountabilityService instance = AccountabilityService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Ensures a Firebase user exists, retrying anonymous sign-in if needed.
  Future<void> _ensureAuth() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  CollectionReference<Map<String, dynamic>> get _partnersRef {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    return _db.collection('users').doc(uid).collection('partners');
  }

  /// Returns a live stream of the current user's partners.
  Stream<List<AccountabilityPartner>> watchPartners() {
    if (_uid == null) {
      // Auth not ready yet — sign in then switch to the real stream.
      return Stream.fromFuture(_ensureAuth())
          .asyncExpand((_) => _partnersRef
              .orderBy('invitedAt', descending: true)
              .snapshots()
              .map((snap) => snap.docs
                  .map(AccountabilityPartner.fromDoc)
                  .toList()))
          .handleError((e) {
        debugPrint('[AccountabilityService] watchPartners error: $e');
      });
    }
    return _partnersRef
        .orderBy('invitedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(AccountabilityPartner.fromDoc).toList());
  }

  /// Adds a new partner and writes the Firestore document that
  /// triggers the [onPartnerInvited] Cloud Function.
  Future<void> invitePartner({
    required String name,
    required String email,
  }) async {
    await _ensureAuth();
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');

    final userName = _auth.currentUser?.displayName ??
        _auth.currentUser?.email?.split('@').first ??
        'Your friend';

    // Generate a unique invite token (UUID-style)
    final inviteToken = _generateToken();
    final unsubscribeToken = _generateToken();

    await _partnersRef.add({
      'partnerEmail': email.trim().toLowerCase(),
      'partnerName': name.trim(),
      'userName': userName,
      'userId': uid,
      'status': 'invited',
      'invitedAt': FieldValue.serverTimestamp(),
      'inviteToken': inviteToken,
      'unsubscribeToken': unsubscribeToken,
    });
  }

  /// Removes a partner (revokes invitation or removes accepted partner).
  Future<void> removePartner(String partnerId) async {
    await _ensureAuth();
    await _partnersRef.doc(partnerId).delete();
  }

  String _generateToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    // Set UUID v4 version and variant bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}'
        '-${hex.substring(12, 16)}-${hex.substring(16, 20)}'
        '-${hex.substring(20)}';
  }

  /// Records weekly stats in Firestore. Called from the app to keep stats current.
  Future<void> updateStats({
    required int streakDays,
    required int weeklyIntercepts,
    required int weeklyReflections,
  }) async {
    await _ensureAuth();
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('stats')
          .doc('current')
          .set({
        'streakDays': streakDays,
        'weeklyIntercepts': weeklyIntercepts,
        'weeklyReflections': weeklyReflections,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AccountabilityService] updateStats error: $e');
    }
  }
}
