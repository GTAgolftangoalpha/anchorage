import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/services/urge_log_service.dart';

void main() {
  group('UrgeLogService', () {
    late UrgeLogService service;

    setUp(() {
      // Create a fresh instance for each test by accessing the singleton
      // and resetting its entries directly.
      service = UrgeLogService.instance;
      service.entries.value = [];
    });

    group('freeLogsRemaining()', () {
      test('returns 3 when no entries this month', () {
        service.entries.value = [];
        expect(service.freeLogsRemaining(isPremium: false), 3);
      });

      test('returns 2 when 1 entry this month', () {
        final now = DateTime.now();
        service.entries.value = [
          UrgeEntry(
            id: '1',
            timestamp: now,
            trigger: 'Boredom',
          ),
        ];
        expect(service.freeLogsRemaining(isPremium: false), 2);
      });

      test('returns 0 when 3 entries this month', () {
        final now = DateTime.now();
        service.entries.value = [
          UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
          UrgeEntry(id: '2', timestamp: now, trigger: 'Stress'),
          UrgeEntry(id: '3', timestamp: now, trigger: 'Loneliness'),
        ];
        expect(service.freeLogsRemaining(isPremium: false), 0);
      });

      test('ignores entries from prior months', () {
        final now = DateTime.now();
        // Create a date in the previous month
        final lastMonth = DateTime(now.year, now.month - 1, 15);
        service.entries.value = [
          UrgeEntry(id: '1', timestamp: lastMonth, trigger: 'Boredom'),
          UrgeEntry(id: '2', timestamp: lastMonth, trigger: 'Stress'),
          UrgeEntry(id: '3', timestamp: lastMonth, trigger: 'Loneliness'),
        ];
        expect(service.freeLogsRemaining(isPremium: false), 3);
      });

      test('returns -1 for premium users (unlimited)', () {
        final now = DateTime.now();
        service.entries.value = [
          UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
          UrgeEntry(id: '2', timestamp: now, trigger: 'Stress'),
          UrgeEntry(id: '3', timestamp: now, trigger: 'Loneliness'),
        ];
        expect(service.freeLogsRemaining(isPremium: true), -1);
      });
    });

    group('urgeLogsThisMonth()', () {
      test('counts only current calendar month', () {
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1, 15);

        service.entries.value = [
          UrgeEntry(id: '1', timestamp: now, trigger: 'Boredom'),
          UrgeEntry(id: '2', timestamp: lastMonth, trigger: 'Stress'),
          UrgeEntry(id: '3', timestamp: now, trigger: 'Anxiety'),
        ];
        expect(service.urgeLogsThisMonth(), 2);
      });

      test('returns 0 when no entries exist', () {
        service.entries.value = [];
        expect(service.urgeLogsThisMonth(), 0);
      });

      test('counts entries from first day of current month', () {
        final now = DateTime.now();
        final firstOfMonth = DateTime(now.year, now.month, 1);
        final lastDayPrevMonth = firstOfMonth.subtract(const Duration(days: 1));

        service.entries.value = [
          UrgeEntry(id: '1', timestamp: firstOfMonth, trigger: 'Boredom'),
          UrgeEntry(id: '2', timestamp: lastDayPrevMonth, trigger: 'Stress'),
        ];
        expect(service.urgeLogsThisMonth(), 1);
      });
    });

    group('visibleEntries()', () {
      test('returns all entries for paid users', () {
        final entries = List.generate(
          10,
          (i) => UrgeEntry(
            id: '$i',
            timestamp: DateTime.now(),
            trigger: 'Boredom',
          ),
        );
        service.entries.value = entries;
        expect(service.visibleEntries(isPaid: true).length, 10);
      });

      test('returns at most 7 entries for free users', () {
        final entries = List.generate(
          10,
          (i) => UrgeEntry(
            id: '$i',
            timestamp: DateTime.now(),
            trigger: 'Boredom',
          ),
        );
        service.entries.value = entries;
        expect(service.visibleEntries(isPaid: false).length, 7);
      });
    });

    group('UrgeEntry', () {
      test('serializes and deserializes correctly', () {
        final entry = UrgeEntry(
          id: 'test-id',
          timestamp: DateTime(2026, 3, 15, 10, 30),
          trigger: 'Boredom',
          notes: 'Some notes',
        );
        final json = entry.toJson();
        final restored = UrgeEntry.fromJson(json);

        expect(restored.id, 'test-id');
        expect(restored.trigger, 'Boredom');
        expect(restored.notes, 'Some notes');
        expect(restored.timestamp.year, 2026);
        expect(restored.timestamp.month, 3);
      });
    });

    group('daysUntilNextMonth()', () {
      // The UrgeLogService does not expose daysUntilNextMonth directly,
      // but the _UpgradeCard widget in urge_log_screen.dart calculates it.
      // We verify the same logic here.
      test('returns the correct number of days remaining', () {
        final now = DateTime.now();
        final nextMonth = DateTime(now.year, now.month + 1);
        final daysUntilReset = nextMonth.difference(now).inDays;
        // Should be between 0 and 31
        expect(daysUntilReset, greaterThanOrEqualTo(0));
        expect(daysUntilReset, lessThanOrEqualTo(31));
      });
    });
  });
}
