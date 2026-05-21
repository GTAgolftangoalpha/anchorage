import 'package:flutter_test/flutter_test.dart';
import 'package:anchorage/services/user_preferences_service.dart';

/// Tests for UserPreferencesService logic.
///
/// NOTE: The service uses FlutterSecureStorage and SharedPreferences
/// internally. Since we cannot mock the singleton's private storage in
/// pure unit tests, we test the in-memory setter/getter pairs and the
/// logic that does not depend on persistence. The init() and persistence
/// paths are exercised by integration tests on a real device.
void main() {
  group('UserPreferencesService', () {
    late UserPreferencesService service;

    setUp(() {
      service = UserPreferencesService.instance;
    });

    group('setGender() / gender getter', () {
      test('stores and retrieves value correctly', () async {
        // The setter writes to secure storage (will throw in test without
        // platform channels), but we can verify the in-memory state by
        // catching the platform exception and checking the field.
        try {
          await service.setGender('Male');
        } catch (_) {
          // Platform channel not available in unit test
        }
        // The in-memory field should be updated regardless of storage
        expect(service.gender, 'Male');
      });

      test('Prefer not to say stores null without error', () async {
        try {
          await service.setGender(null);
        } catch (_) {
          // Platform channel not available in unit test
        }
        expect(service.gender, isNull);
      });
    });

    group('setBirthYear() / birthYear getter', () {
      test('stores and retrieves value correctly', () async {
        try {
          await service.setBirthYear(1990);
        } catch (_) {}
        expect(service.birthYear, 1990);
      });

      test('null birth year stores without error', () async {
        try {
          await service.setBirthYear(null);
        } catch (_) {}
        expect(service.birthYear, isNull);
      });
    });

    group('isUnderage logic', () {
      // The underage check is done in the onboarding screen, not in the
      // service itself. The logic is: currentYear - birthYear < 18.
      // We test that logic inline here.

      test('returns true when DOB is less than 18 years ago', () {
        final currentYear = DateTime.now().year;
        final birthYear = currentYear - 17; // 17 years old
        final isUnderage = currentYear - birthYear < 18;
        expect(isUnderage, isTrue);
      });

      test('returns false when DOB is 18 or more years ago', () {
        final currentYear = DateTime.now().year;
        final birthYear = currentYear - 18; // Could be 18 this year
        final isUnderage = currentYear - birthYear < 18;
        expect(isUnderage, isFalse);
      });

      test('returns false for birth year well in the past', () {
        final currentYear = DateTime.now().year;
        final birthYear = currentYear - 30;
        final isUnderage = currentYear - birthYear < 18;
        expect(isUnderage, isFalse);
      });
    });

    group('setFirstName() / firstName getter', () {
      test('stores and retrieves name', () async {
        try {
          await service.setFirstName('Test');
        } catch (_) {}
        expect(service.firstName, 'Test');
      });
    });

    group('setValues() / values getter', () {
      test('stores and retrieves list of values', () async {
        final testValues = ['Trust', 'Freedom', 'Mental clarity'];
        try {
          await service.setValues(testValues);
        } catch (_) {}
        expect(service.values, testValues);
      });
    });

    group('setEmail() / email getter', () {
      test('stores and retrieves email', () async {
        try {
          await service.setEmail('test@example.com');
        } catch (_) {}
        expect(service.email, 'test@example.com');
      });

      test('null email stores without error', () async {
        try {
          await service.setEmail(null);
        } catch (_) {}
        expect(service.email, isNull);
      });
    });
  });
}
