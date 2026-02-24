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

  String _firstName = '';
  List<String> _values = [];
  String _motivation = '';
  String _impact = '';
  bool _onboardingComplete = false;
  int _installDate = 0;

  String get firstName => _firstName;
  List<String> get values => List.unmodifiable(_values);
  String get motivation => _motivation;
  String get impact => _impact;
  bool get onboardingComplete => _onboardingComplete;
  int get installDate => _installDate;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _firstName = prefs.getString(_keyFirstName) ?? '';
      _values = prefs.getStringList(_keyValues) ?? [];
      _motivation = prefs.getString(_keyMotivation) ?? '';
      _impact = prefs.getString(_keyImpact) ?? '';
      _onboardingComplete = prefs.getBool(_keyOnboardingComplete) ?? false;
      _installDate = prefs.getInt(_keyInstallDate) ?? 0;
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
}
