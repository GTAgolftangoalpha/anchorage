import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  UserPreferencesService._();
  static final UserPreferencesService instance = UserPreferencesService._();

  static const _keyFirstName = 'user_first_name';
  static const _keyValues = 'user_values';
  static const _keyMotivation = 'user_motivation';
  static const _keyImpact = 'user_impact';
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyInstallDate = 'install_date';
  static const _keyGender = 'user_gender';
  static const _keyBirthYear = 'user_birth_year';
  static const _keyEmail = 'user_email';
  static const _keyUsageFrequency = 'user_usage_frequency';

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
      _firstName = prefs.getString(_keyFirstName) ?? '';
      _values = prefs.getStringList(_keyValues) ?? [];
      _motivation = prefs.getString(_keyMotivation) ?? '';
      _impact = prefs.getString(_keyImpact) ?? '';
      _onboardingComplete = prefs.getBool(_keyOnboardingComplete) ?? false;
      _installDate = prefs.getInt(_keyInstallDate) ?? 0;
      _gender = prefs.getString(_keyGender);
      _birthYear = prefs.getInt(_keyBirthYear);
      _email = prefs.getString(_keyEmail);
      _usageFrequency = prefs.getString(_keyUsageFrequency);

      // Migrate old dateOfBirth (milliseconds) to birthYear if present
      final oldDob = prefs.getInt('user_date_of_birth');
      if (oldDob != null && _birthYear == null) {
        final year = DateTime.fromMillisecondsSinceEpoch(oldDob).year;
        _birthYear = year;
        await prefs.setInt(_keyBirthYear, year);
        await prefs.remove('user_date_of_birth');
      }
    } catch (e) {
      debugPrint('[UserPreferencesService] init error: $e');
    }
  }

  Future<void> setFirstName(String name) async {
    _firstName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFirstName, name);
  }

  Future<void> setValues(List<String> values) async {
    _values = List.of(values);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyValues, values);
  }

  Future<void> setMotivation(String motivation) async {
    _motivation = motivation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMotivation, motivation);
  }

  Future<void> setImpact(String impact) async {
    _impact = impact;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyImpact, impact);
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
    final prefs = await SharedPreferences.getInstance();
    if (gender == null) {
      await prefs.remove(_keyGender);
    } else {
      await prefs.setString(_keyGender, gender);
    }
  }

  Future<void> setBirthYear(int? year) async {
    _birthYear = year;
    final prefs = await SharedPreferences.getInstance();
    if (year == null) {
      await prefs.remove(_keyBirthYear);
    } else {
      await prefs.setInt(_keyBirthYear, year);
    }
  }

  Future<void> setEmail(String? email) async {
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    if (email == null || email.isEmpty) {
      await prefs.remove(_keyEmail);
    } else {
      await prefs.setString(_keyEmail, email);
    }
  }

  Future<void> setUsageFrequency(String? frequency) async {
    _usageFrequency = frequency;
    final prefs = await SharedPreferences.getInstance();
    if (frequency == null) {
      await prefs.remove(_keyUsageFrequency);
    } else {
      await prefs.setString(_keyUsageFrequency, frequency);
    }
  }
}
