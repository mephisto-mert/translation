/// Ayarları kalıcı olarak kaydetme/yükleme servisi
///
/// shared_preferences paketi ile kullanıcı tercihlerini persist eder.
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key sabitleri
class _PrefKeys {
  _PrefKeys._();
  static const String sourceLang = 'source_lang';
  static const String targetLang = 'target_lang';
  static const String uiLang = 'ui_lang';
  static const String bubbleMode = 'bubble_mode';
  static const String inputMode = 'input_mode';
  static const String clipboardMode = 'clipboard_mode';
  
  // API Keys
  static const String geminiApiKey = 'gemini_api_key';
  static const String deepLApiKey = 'deepl_api_key';
  
  // Hotkey ayarları (VK kod listesi JSON)
  static const String chatKeys = 'chat_keys';
  static const String triggerChars = 'trigger_chars';
}

/// Varsayılan değerler
class _Defaults {
  _Defaults._();
  static const List<int> chatKeys = [89, 85, 13]; // Y, U, Enter
  static const List<String> triggerChars = ['.', '!', '?', ','];
}

class SettingsService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Kaynak Dil ──
  String get sourceLang => _prefs?.getString(_PrefKeys.sourceLang) ?? 'auto';
  Future<void> setSourceLang(String code) async {
    await _prefs?.setString(_PrefKeys.sourceLang, code);
  }

  // ── Hedef Dil ──
  String get targetLang => _prefs?.getString(_PrefKeys.targetLang) ?? 'tr';
  Future<void> setTargetLang(String code) async {
    await _prefs?.setString(_PrefKeys.targetLang, code);
  }

  // ── Arayüz Dili ──
  String get uiLang => _prefs?.getString(_PrefKeys.uiLang) ?? 'tr';
  Future<void> setUiLang(String lang) async {
    await _prefs?.setString(_PrefKeys.uiLang, lang);
  }

  // ── Baloncuk Modu ──
  bool get bubbleMode => _prefs?.getBool(_PrefKeys.bubbleMode) ?? true;
  Future<void> setBubbleMode(bool value) async {
    await _prefs?.setBool(_PrefKeys.bubbleMode, value);
  }

  // ── Giriş Modu ──
  bool get inputMode => _prefs?.getBool(_PrefKeys.inputMode) ?? true;
  Future<void> setInputMode(bool value) async {
    await _prefs?.setBool(_PrefKeys.inputMode, value);
  }

  // ── Clipboard Monitör Modu ──
  bool get clipboardMode => _prefs?.getBool(_PrefKeys.clipboardMode) ?? false;
  Future<void> setClipboardMode(bool value) async {
    await _prefs?.setBool(_PrefKeys.clipboardMode, value);
  }

  // ── API Keys ──
  String get geminiApiKey => _prefs?.getString(_PrefKeys.geminiApiKey) ?? '';
  Future<void> setGeminiApiKey(String key) async {
    await _prefs?.setString(_PrefKeys.geminiApiKey, key);
  }

  String get deepLApiKey => _prefs?.getString(_PrefKeys.deepLApiKey) ?? '';
  Future<void> setDeepLApiKey(String key) async {
    await _prefs?.setString(_PrefKeys.deepLApiKey, key);
  }

  // ── Hotkey Ayarları ──
  List<int> get chatKeys {
    final json = _prefs?.getString(_PrefKeys.chatKeys);
    if (json == null || json.isEmpty) return _Defaults.chatKeys;
    try {
      final list = (jsonDecode(json) as List).cast<int>();
      return list.isEmpty ? _Defaults.chatKeys : list;
    } catch (_) {
      return _Defaults.chatKeys;
    }
  }

  Future<void> setChatKeys(List<int> keys) async {
    await _prefs?.setString(_PrefKeys.chatKeys, jsonEncode(keys));
  }

  List<String> get triggerChars {
    final json = _prefs?.getString(_PrefKeys.triggerChars);
    if (json == null || json.isEmpty) return _Defaults.triggerChars;
    try {
      final list = (jsonDecode(json) as List).cast<String>();
      return list.isEmpty ? _Defaults.triggerChars : list;
    } catch (_) {
      return _Defaults.triggerChars;
    }
  }

  Future<void> setTriggerChars(List<String> chars) async {
    await _prefs?.setString(_PrefKeys.triggerChars, jsonEncode(chars));
  }
}
