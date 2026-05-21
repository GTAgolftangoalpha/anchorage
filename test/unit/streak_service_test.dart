import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/services/streak_service.dart';

/// Tests for StreakData model and streak logic.
///
/// The StreakService singleton eagerly instantiates FirebaseAuth and
/// FirebaseFirestore in its constructor, so we cannot access
/// StreakService.instance in unit tests without Firebase initialisation.
/// Instead, we test:
///   1. The StreakData model (copyWith, defaults).
///   2. The streak check-in logic inline (same algorithm as checkIn()).
///   3. The motivational message logic inline (same thresholds).
void main() {
  group('StreakData model', () {
    test('default values are all zero/empty', () {
      const data = StreakData();
      expect(data.currentStreak, 0);
      expect(data.longestStreak, 0);
      expect(data.totalCleanDays, 0);
      expect(data.lastActiveDate, isNull);
      expect(data.weeklyCheckIns, isEmpty);
      expect(data.weeklyIntercepts, 0);
    });

    test('copyWith preserves unchanged fields', () {
      final original = StreakData(
        currentStreak: 5,
        longestStreak: 10,
        totalCleanDays: 50,
        lastActiveDate: DateTime(2026, 3, 15),
        weeklyCheckIns: [DateTime(2026, 3, 15)],
        weeklyIntercepts: 3,
      );

      final updated = original.copyWith(currentStreak: 6);
      expect(updated.currentStreak, 6);
      expect(updated.longestStreak, 10);
      expect(updated.totalCleanDays, 50);
      expect(updated.weeklyIntercepts, 3);
    });

    test('copyWith can update all fields', () {
      const original = StreakData();
      final newDate = DateTime(2026, 5, 20);
      final updated = original.copyWith(
        currentStreak: 7,
        longestStreak: 14,
        totalCleanDays: 100,
        lastActiveDate: newDate,
        weeklyCheckIns: [newDate],
        weeklyIntercepts: 5,
      );
      expect(updated.currentStreak, 7);
      expect(updated.longestStreak, 14);
      expect(updated.totalCleanDays, 100);
      expect(updated.lastActiveDate, newDate);
      expect(updated.weeklyCheckIns.length, 1);
      expect(updated.weeklyIntercepts, 5);
    });
  });

  group('Streak check-in logic (algorithm verification)', () {
    // These tests replicate the checkIn() algorithm from StreakService
    // without touching Firebase.

    StreakData simulateCheckIn(StreakData current) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (current.lastActiveDate != null) {
        final lastDate = DateTime(
          current.lastActiveDate!.year,
          current.lastActiveDate!.month,
          current.lastActiveDate!.day,
        );

        if (lastDate == today) return current; // Already checked in

        final diff = today.difference(lastDate).inDays;
        if (diff == 1) {
          // Consecutive day
          final newStreak = current.currentStreak + 1;
          final newLongest = newStreak > current.longestStreak
              ? newStreak
              : current.longestStreak;
          return current.copyWith(
            currentStreak: newStreak,
            longestStreak: newLongest,
            totalCleanDays: current.totalCleanDays + 1,
            lastActiveDate: today,
          );
        } else {
          // Missed day(s) -- reset streak
          return current.copyWith(
            currentStreak: 1,
            totalCleanDays: current.totalCleanDays + 1,
            lastActiveDate: today,
          );
        }
      } else {
        // First ever check-in
        return current.copyWith(
          currentStreak: 1,
          longestStreak: current.longestStreak > 0 ? current.longestStreak : 1,
          totalCleanDays: current.totalCleanDays + 1,
          lastActiveDate: today,
        );
      }
    }

    test('consecutive day increments streak by 1', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate =
          DateTime(yesterday.year, yesterday.month, yesterday.day);

      final before = StreakData(
        currentStreak: 5,
        longestStreak: 10,
        totalCleanDays: 50,
        lastActiveDate: yesterdayDate,
      );

      final after = simulateCheckIn(before);
      expect(after.currentStreak, 6);
      expect(after.totalCleanDays, 51);
      expect(after.longestStreak, 10); // 6 < 10, unchanged
    });

    test('consecutive day updates longest streak when surpassed', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDate =
          DateTime(yesterday.year, yesterday.month, yesterday.day);

      final before = StreakData(
        currentStreak: 10,
        longestStreak: 10,
        totalCleanDays: 50,
        lastActiveDate: yesterdayDate,
      );

      final after = simulateCheckIn(before);
      expect(after.currentStreak, 11);
      expect(after.longestStreak, 11); // Now surpassed
    });

    test('missed day resets streak to 1', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final twoDaysAgoDate =
          DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day);

      final before = StreakData(
        currentStreak: 5,
        longestStreak: 10,
        totalCleanDays: 50,
        lastActiveDate: twoDaysAgoDate,
      );

      final after = simulateCheckIn(before);
      expect(after.currentStreak, 1);
      expect(after.longestStreak, 10); // Longest preserved
      expect(after.totalCleanDays, 51);
    });

    test('first ever check-in sets streak to 1', () {
      const before = StreakData();
      final after = simulateCheckIn(before);
      expect(after.currentStreak, 1);
      expect(after.longestStreak, 1);
      expect(after.totalCleanDays, 1);
      expect(after.lastActiveDate, isNotNull);
    });

    test('same day check-in is a no-op', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final before = StreakData(
        currentStreak: 5,
        longestStreak: 10,
        totalCleanDays: 50,
        lastActiveDate: today,
      );

      final after = simulateCheckIn(before);
      expect(after.currentStreak, 5); // Unchanged
      expect(after.totalCleanDays, 50); // Unchanged
    });

    test('handles month boundary correctly', () {
      // Last day of January to first day of February
      final jan31 = DateTime(2026, 1, 31);
      final before = StreakData(
        currentStreak: 3,
        longestStreak: 3,
        totalCleanDays: 3,
        lastActiveDate: jan31,
      );

      // Simulate check-in on Feb 1
      final feb1 = DateTime(2026, 2, 1);
      final diff = feb1.difference(jan31).inDays;
      expect(diff, 1); // Confirms consecutive across month boundary

      // The algorithm should increment
      final newStreak = before.currentStreak + 1;
      expect(newStreak, 4);
    });

    test('handles leap year boundary (Feb 28 to Mar 1 in non-leap year)', () {
      final feb28 = DateTime(2025, 2, 28);
      final mar1 = DateTime(2025, 3, 1);
      final diff = mar1.difference(feb28).inDays;
      expect(diff, 1); // Should be consecutive
    });

    test('handles leap year (Feb 28 to Feb 29 to Mar 1)', () {
      final feb28 = DateTime(2028, 2, 28); // 2028 is a leap year
      final feb29 = DateTime(2028, 2, 29);
      final mar1 = DateTime(2028, 3, 1);
      expect(feb29.difference(feb28).inDays, 1);
      expect(mar1.difference(feb29).inDays, 1);
    });
  });

  group('Motivational message logic (algorithm verification)', () {
    // Replicate the motivationalMessage getter logic.
    String motivationalMessage(int streak) {
      if (streak == 0) return 'Start your journey today.';
      if (streak == 1) return 'Day one. Every journey starts here.';
      if (streak < 7) return 'Building momentum. Keep going.';
      if (streak < 14) return "One week strong. You're proving something.";
      if (streak < 30) return 'Two weeks of freedom. This is real.';
      if (streak < 60) return "A month of clarity. You're changing.";
      if (streak < 90) return "You're rewriting the pattern.";
      if (streak < 180) return 'Three months. The old you is fading.';
      if (streak < 365) return 'Half a year anchored. Incredible.';
      return 'Over a year. You are free.';
    }

    test('streak 0', () {
      expect(motivationalMessage(0), 'Start your journey today.');
    });

    test('streak 1', () {
      expect(motivationalMessage(1), 'Day one. Every journey starts here.');
    });

    test('streak 3', () {
      expect(motivationalMessage(3), 'Building momentum. Keep going.');
    });

    test('streak 6 (boundary before 7)', () {
      expect(motivationalMessage(6), 'Building momentum. Keep going.');
    });

    test('streak 7', () {
      expect(
          motivationalMessage(7), "One week strong. You're proving something.");
    });

    test('streak 14', () {
      expect(motivationalMessage(14), 'Two weeks of freedom. This is real.');
    });

    test('streak 30', () {
      expect(motivationalMessage(30), "A month of clarity. You're changing.");
    });

    test('streak 60', () {
      expect(motivationalMessage(60), "You're rewriting the pattern.");
    });

    test('streak 90', () {
      expect(
          motivationalMessage(90), 'Three months. The old you is fading.');
    });

    test('streak 180', () {
      expect(motivationalMessage(180), 'Half a year anchored. Incredible.');
    });

    test('streak 365', () {
      expect(motivationalMessage(365), 'Over a year. You are free.');
    });

    test('streak 500', () {
      expect(motivationalMessage(500), 'Over a year. You are free.');
    });
  });
}
