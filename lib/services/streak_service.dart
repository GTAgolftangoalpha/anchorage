import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalCleanDays;
  final DateTime? lastActiveDate;
  final List<DateTime> weeklyCheckIns;
  final int weeklyIntercepts;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCleanDays = 0,
    this.lastActiveDate,
    this.weeklyCheckIns = const [],
    this.weeklyIntercepts = 0,
  });

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalCleanDays,
    DateTime? lastActiveDate,
    List<DateTime>? weeklyCheckIns,
    int? weeklyIntercepts,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCleanDays: totalCleanDays ?? this.totalCleanDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      weeklyCheckIns: weeklyCheckIns ?? this.weeklyCheckIns,
      weeklyIntercepts: weeklyIntercepts ?? this.weeklyIntercepts,
    );
  }
}

class StreakService {
  StreakService._();
  static final StreakService instance = StreakService._();

  static const _prefCurrentStreak = 'streak_current';
  static const _prefLongestStreak = 'streak_longest';
  static const _prefTotalCleanDays = 'streak_total_clean';
  static const _prefLastActive = 'streak_last_active';
  static const _prefWeeklyCheckIns = 'streak_weekly_checkins';
  static const _prefWeeklyIntercepts = 'streak_weekly_intercepts';

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final ValueNotifier<StreakData> data = ValueNotifier(const StreakData());

  /// Load streak from local prefs, then sync with Firebase.
  Future<void> init() async {
    await _loadLocal();
    await _syncFromFirebase();
    await checkIn();
  }

  /// Daily check-in: if today hasn't been recorded, update streak.
  Future<void> checkIn() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = data.value;

    if (current.lastActiveDate != null) {
      final lastDate = DateTime(
        current.lastActiveDate!.year,
        current.lastActiveDate!.month,
        current.lastActiveDate!.day,
      );

      if (lastDate == today) return; // Already checked in today

      final diff = today.difference(lastDate).inDays;
      if (diff == 1) {
        // Consecutive day — increment streak
        final newStreak = current.currentStreak + 1;
        final newLongest =
            newStreak > current.longestStreak ? newStreak : current.longestStreak;
        _update(current.copyWith(
          currentStreak: newStreak,
          longestStreak: newLongest,
          totalCleanDays: current.totalCleanDays + 1,
          lastActiveDate: today,
          weeklyCheckIns: _addCheckIn(current.weeklyCheckIns, today),
        ));
      } else {
        // Missed day(s) — reset streak
        _update(current.copyWith(
          currentStreak: 1,
          totalCleanDays: current.totalCleanDays + 1,
          lastActiveDate: today,
          weeklyCheckIns: _addCheckIn(current.weeklyCheckIns, today),
        ));
      }
    } else {
      // First ever check-in
      _update(current.copyWith(
        currentStreak: 1,
        longestStreak: current.longestStreak > 0 ? current.longestStreak : 1,
        totalCleanDays: current.totalCleanDays + 1,
        lastActiveDate: today,
        weeklyCheckIns: [today],
      ));
    }

    await _saveLocal();
    await _syncToFirebase();
  }

  /// Record a blocked intercept for weekly stats.
  Future<void> recordIntercept() async {
    final current = data.value;
    _update(current.copyWith(
      weeklyIntercepts: current.weeklyIntercepts + 1,
    ));
    await _saveLocal();
    await _syncToFirebase();
  }

  /// Get daily intercept counts for the last 7 days (Mon-Sun).
  List<int> getWeeklyBarData() {
    final now = DateTime.now();
    // Find the most recent Monday
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);

    final bars = List<int>.filled(7, 0);
    for (final checkIn in data.value.weeklyCheckIns) {
      final d = DateTime(checkIn.year, checkIn.month, checkIn.day);
      final dayIndex = d.difference(mondayDate).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        bars[dayIndex] = 1; // 1 = checked in that day
      }
    }
    return bars;
  }

  /// Motivational message based on streak length.
  String get motivationalMessage {
    final streak = data.value.currentStreak;
    if (streak == 0) return 'Start your journey today.';
    if (streak == 1) return 'Day one. Every journey starts here.';
    if (streak < 7) return 'Building momentum. Keep going.';
    if (streak < 14) return 'One week strong. You\'re proving something.';
    if (streak < 30) return 'Two weeks of freedom. This is real.';
    if (streak < 60) return 'A month of clarity. You\'re changing.';
    if (streak < 90) return 'You\'re rewriting the pattern.';
    if (streak < 180) return 'Three months. The old you is fading.';
    if (streak < 365) return 'Half a year anchored. Incredible.';
    return 'Over a year. You are free.';
  }

  List<DateTime> _addCheckIn(List<DateTime> existing, DateTime date) {
    // Keep only last 7 days of check-ins
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final filtered = existing
        .where((d) => d.isAfter(cutoff))
        .toList()
      ..add(date);
    return filtered;
  }

  void _update(StreakData newData) {
    data.value = newData;
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveMs = prefs.getInt(_prefLastActive);
    final checkInsStr = prefs.getStringList(_prefWeeklyCheckIns) ?? [];

    data.value = StreakData(
      currentStreak: prefs.getInt(_prefCurrentStreak) ?? 0,
      longestStreak: prefs.getInt(_prefLongestStreak) ?? 0,
      totalCleanDays: prefs.getInt(_prefTotalCleanDays) ?? 0,
      lastActiveDate: lastActiveMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastActiveMs)
          : null,
      weeklyCheckIns: checkInsStr
          .map((s) => DateTime.fromMillisecondsSinceEpoch(int.parse(s)))
          .toList(),
      weeklyIntercepts: prefs.getInt(_prefWeeklyIntercepts) ?? 0,
    );
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final d = data.value;
    await prefs.setInt(_prefCurrentStreak, d.currentStreak);
    await prefs.setInt(_prefLongestStreak, d.longestStreak);
    await prefs.setInt(_prefTotalCleanDays, d.totalCleanDays);
    if (d.lastActiveDate != null) {
      await prefs.setInt(
          _prefLastActive, d.lastActiveDate!.millisecondsSinceEpoch);
    }
    await prefs.setStringList(
      _prefWeeklyCheckIns,
      d.weeklyCheckIns.map((dt) => dt.millisecondsSinceEpoch.toString()).toList(),
    );
    await prefs.setInt(_prefWeeklyIntercepts, d.weeklyIntercepts);
  }

  Future<void> _syncToFirebase() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final d = data.value;
      await _db.collection('users').doc(uid).set({
        'currentStreak': d.currentStreak,
        'longestStreak': d.longestStreak,
        'totalCleanDays': d.totalCleanDays,
        'lastActiveDate': d.lastActiveDate != null
            ? Timestamp.fromDate(d.lastActiveDate!)
            : null,
        'weeklyIntercepts': d.weeklyIntercepts,
        'lastSynced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[StreakService] syncToFirebase error: $e');
    }
  }

  /// On reinstall, load streak from Firebase if local is empty.
  Future<void> _syncFromFirebase() async {
    // Only sync from Firebase if local data is empty (fresh install)
    if (data.value.currentStreak > 0) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return;
      final d = doc.data()!;

      final fbStreak = d['currentStreak'] as int? ?? 0;
      if (fbStreak == 0) return;

      final lastActive = (d['lastActiveDate'] as Timestamp?)?.toDate();
      data.value = StreakData(
        currentStreak: fbStreak,
        longestStreak: d['longestStreak'] as int? ?? fbStreak,
        totalCleanDays: d['totalCleanDays'] as int? ?? fbStreak,
        lastActiveDate: lastActive,
        weeklyIntercepts: d['weeklyIntercepts'] as int? ?? 0,
      );
      await _saveLocal();
    } catch (e) {
      debugPrint('[StreakService] syncFromFirebase error: $e');
    }
  }
}
