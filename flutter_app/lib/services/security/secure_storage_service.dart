import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure Storage Service backed by Windows DPAPI via FlutterSecureStorage
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
  );

  static const String _geminiApiKeyPref = 'sec_gemini_api_key';
  static const String _deepLApiKeyPref = 'sec_deepl_api_key';

  /// Save Gemini API Key securely
  Future<void> setGeminiApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _storage.delete(key: _geminiApiKeyPref);
    } else {
      await _storage.write(key: _geminiApiKeyPref, value: key.trim());
    }
  }

  /// Retrieve Gemini API Key securely
  Future<String?> getGeminiApiKey() async {
    try {
      final key = await _storage.read(key: _geminiApiKeyPref);
      if (key == null || key.trim().isEmpty) return null;
      return key.trim();
    } catch (e) {
      debugPrint('[SecureStorage] Error reading Gemini API Key');
      return null;
    }
  }

  /// Save DeepL API Key securely
  Future<void> setDeepLApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _storage.delete(key: _deepLApiKeyPref);
    } else {
      await _storage.write(key: _deepLApiKeyPref, value: key.trim());
    }
  }

  /// Retrieve DeepL API Key securely
  Future<String?> getDeepLApiKey() async {
    try {
      final key = await _storage.read(key: _deepLApiKeyPref);
      if (key == null || key.trim().isEmpty) return null;
      return key.trim();
    } catch (e) {
      debugPrint('[SecureStorage] Error reading DeepL API Key');
      return null;
    }
  }

  /// Mask secret API key for UI display (e.g. "••••••••1234")
  static String maskSecret(String? secret) {
    if (secret == null || secret.trim().isEmpty) return '';
    final trimmed = secret.trim();
    if (trimmed.length <= 4) return '••••';
    final suffix = trimmed.substring(trimmed.length - 4);
    return '••••••••$suffix';
  }
}
