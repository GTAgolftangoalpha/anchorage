import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores user profile and onboarding answers.
///
/// Sensitive personal data (name, email, values, motivation, demographics) is
/// kept in [FlutterSecureStorage], which on Android is backed by
/// EncryptedSharedPreferences (Android Keystore). Non-sensitive flags
/// (onboarding complete, install date) remain in [SharedPreferences].
class UserPreferencesService {
  UserPreferencesService._();
  static final UserPreferencesService instance = UserPreferencesService._();

  // Secure (encrypted) keys
  static const _secureKeyFirstName = 'user_first_name';
  static const _secureKeyValues = 'user_values';
  static const _secureKeyMotivation = 'user_motivation';
  static const _secureKeyImpact = 'user_impact';
  static const _secureKeyGender = 'user_gender';
  static const _secureKeyBirthYear = 'user_birth_year';
  static const _secureKeyEmail = 'user_email';
  static const _secureKeyUsageFrequency = 'user_usage_frequency';

  // Legacy SharedPreferences keys (used only during one-time migration)
  static const _legacyFirstName = 'user_first_name';
  static const _legacyValues = 'user_values';
  static const _legacyMotivation = 'user_motivation';
  static const _legacyImpact = 'user_impact';
  static const _legacyGender = 'user_gender';
  static const _legacyBirthYear = 'user_birth_year';
  static const _legacyEmail = 'user_email';
  static const _legacyUsageFrequency = 'user_usage_frequency';

  // Non-sensitive (kept in SharedPreferences)
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyInstallDate = 'install_date';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _firstName = '';
  List<String> _values = [];
  String _motivation = '';
  String _impact = '';
  bool _onboardingComplete = false;
  int _installDate = 0;
  String? _gender;
  int? _birthYear;
  String? _email;
  String? _usageFrequency;

  String get firstName => _firstName;
  List<String> get values => List.unmodifiable(_values);
  String get motivation => _motivation;
  String get impact => _impact;
  bool get onboardingComplete => _onboardingComplete;
  int get installDate => _installDate;
  String? get gender => _gender;
  int? get birthYear => _birthYear;
  String? get email => _email;
  String? get usageFrequency => _usageFrequency;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Non-sensitive flags from SharedPreferences
      _onboardingComplete = prefs.getBool(_keyOnboardingComplete) ?? false;
      _installDate = prefs.getInt(_keyInstallDate) ?? 0;

      // Sensitive values from secure storage (with one-time migration from
      // SharedPreferences for users upgrading from earlier builds).
      _firstName = await _readSecureString(
            prefs,
            secureKey: _secureKeyFirstName,
            legacyKey: _legacyFirstName,
          ) ??
          '';
      _motivation = await _readSecureString(
            prefs,
            secureKey: _secureKeyMotivation,
            legacyKey: _legacyMotivation,
          ) ??
          '';
      _impact = await _readSecureString(
            prefs,
            secureKey: _secureKeyImpact,
            legacyKey: _legacyImpact,
          ) ??
          '';
      _gender = await _readSecureString(
        prefs,
        secureKey: _secureKeyGender,
        legacyKey: _legacyGender,
      );
      _email = await _readSecureString(
        prefs,
        secureKey: _secureKeyEmail,
        legacyKey: _legacyEmail,
      );
      _usageFrequency = await _readSecureString(
        prefs,
        secureKey: _secureKeyUsageFrequency,
        legacyKey: _legacyUsageFrequency,
      );

      final birthYearStr = await _readSecureString(
        prefs,
        secureKey: _secureKeyBirthYear,
        legacyKey: _legacyBirthYear,
        legacyIsInt: true,
      );
      _birthYear = birthYearStr == null ? null : int.tryParse(birthYearStr);

      final valuesRaw = await _readSecureString(
        prefs,
        secureKey: _secureKeyValues,
        legacyKey: _legacyValues,
        legacyIsStringList: true,
      );
      if (valuesRaw != null && valuesRaw.isNotEmpty) {
        _values = valuesRaw.split('\u0001');
      }

      // Migrate old dateOfBirth (milliseconds) to birthYear if present
      final oldDob = prefs.getInt('user_date_of_birth');
      if (oldDob != null && _birthYear == null) {
        final year = DateTime.fromMillisecondsSinceEpoch(oldDob).year;
        _birthYear = year;
        await _secureStorage.write(
          key: _secureKeyBirthYear,
          value: year.toString(),
        );
        await prefs.remove('user_date_of_birth');
      }
    } catch (e) {
      debugPrint('[UserPreferencesService] init error: $e');
    }
  }

  /// Reads a value from secure storage. If absent and a legacy
  /// SharedPreferences entry exists, migrates it into secure storage and
  /// removes the legacy entry.
  Future<String?> _readSecureString(
    SharedPreferences prefs, {
    required String secureKey,
    required String legacyKey,
    bool legacyIsInt = false,
    bool legacyIsStringList = false,
  }) async {
    final existing = await _secureStorage.read(key: secureKey);
    if (existing != null) return existing;

    String? legacy;
    if (legacyIsInt) {
      final v = prefs.getInt(legacyKey);
      legacy = v?.toString();
    } else if (legacyIsStringList) {
      final v = prefs.getStringList(legacyKey);
      legacy = (v == null || v.isEmpty) ? null : v.join('\u0001');
    } else {
      legacy = prefs.getString(legacyKey);
    }

    if (legacy != null) {
      await _secureStorage.write(key: secureKey, value: legacy);
      await prefs.remove(legacyKey);
      debugPrint('[UserPreferencesService] migrated $legacyKey to secure storage');
    }
    return legacy;
  }

  Future<void> setFirstName(String name) async {
    _firstName = name;
    await _secureStorage.write(key: _secureKeyFirstName, value: name);
  }

  Future<void> setValues(List<String> values) async {
    _values = List.of(values);
    await _secureStorage.write(
      key: _secureKeyValues,
      value: values.join('\u0001'),
    );
  }

  Future<void> setMotivation(String motivation) async {
    _motivation = motivation;
    await _secureStorage.write(key: _secureKeyMotivation, value: motivation);
  }

  Future<void> setImpact(String impact) async {
    _impact = impact;
    await _secureStorage.write(key: _secureKeyImpact, value: impact);
  }

  Future<void> setOnboardingComplete(bool complete) async {
    _onboardingComplete = complete;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, complete);
  }

  Future<void> setInstallDate(int millisSinceEpoch) async {
    _installDate = millisSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyInstallDate, millisSinceEpoch);
  }

  Future<void> setGender(String? gender) async {
    _gender = gender;
    if (gender == null) {
      await _secureStorage.delete(key: _secureKeyGender);
    } else {
      await _secureStorage.write(key: _secureKeyGender, value: gender);
    }
  }

  Future<void> setBirthYear(int? year) async {
    _birthYear = year;
    if (year == null) {
      await _secureStorage.delete(key: _secureKeyBirthYear);
    } else {
      await _secureStorage.write(
        key: _secureKeyBirthYear,
        value: year.toString(),
      );
    }
  }

  Future<void> setEmail(String? email) async {
    _email = email;
    if (email == null || email.isEmpty) {
      await _secureStorage.delete(key: _secureKeyEmail);
    } else {
      await _secureStorage.write(key: _secureKeyEmail, value: email);
    }
  }

  Future<void> setUsageFrequency(String? frequency) async {
    _usageFrequency = frequency;
    if (frequency == null) {
      await _secureStorage.delete(key: _secureKeyUsageFrequency);
    } else {
      await _secureStorage.write(
        key: _secureKeyUsageFrequency,
        value: frequency,
      );
    }
  }
}
