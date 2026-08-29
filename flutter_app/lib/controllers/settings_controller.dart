import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../services/security/secure_storage_service.dart';

class SettingsController extends ChangeNotifier {
  final SecureStorageService _secureStorage = SecureStorageService();
  AppSettings _settings = const AppSettings();
  static const String _settingsStorageKey = 'quicktrace_settings_v2';

  AppSettings get settings => _settings;

  SettingsController() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsStorageKey);
      if (raw != null) {
        final Map<String, dynamic> json = jsonDecode(raw);
        _settings = AppSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('[SettingsController] Error loading settings: $e');
    }
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsStorageKey, jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('[SettingsController] Error saving settings: $e');
    }
  }

  Future<void> setGeminiApiKey(String? key) async {
    await _secureStorage.setGeminiApiKey(key);
    notifyListeners();
  }

  Future<String?> getGeminiApiKey() async {
    return await _secureStorage.getGeminiApiKey();
  }

  Future<void> setDeepLApiKey(String? key) async {
    await _secureStorage.setDeepLApiKey(key);
    notifyListeners();
  }

  Future<String?> getDeepLApiKey() async {
    return await _secureStorage.getDeepLApiKey();
  }
}
