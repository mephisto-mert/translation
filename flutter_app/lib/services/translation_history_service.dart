/// Çeviri geçmişi kaydetme ve yönetme servisi (maksimum 50 öğe)
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Çeviri geçmişi öğesi modeli
class TranslationHistoryItem {
  final String id;
  final String originalText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final DateTime timestamp;
  final String engine;

  TranslationHistoryItem({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.timestamp,
    required this.engine,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalText': originalText,
        'translatedText': translatedText,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        'timestamp': timestamp.toIso8601String(),
        'engine': engine,
      };

  factory TranslationHistoryItem.fromJson(Map<String, dynamic> json) {
    return TranslationHistoryItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: json['originalText'] as String? ?? '',
      translatedText: json['translatedText'] as String? ?? '',
      sourceLang: json['sourceLang'] as String? ?? 'auto',
      targetLang: json['targetLang'] as String? ?? 'tr',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      engine: json['engine'] as String? ?? 'Google',
    );
  }
}

class TranslationHistoryService {
  static const String _prefKey = 'translation_history_items';
  static const int maxHistoryCount = 50;

  SharedPreferences? _prefs;
  final List<TranslationHistoryItem> _history = [];

  List<TranslationHistoryItem> get history => List.unmodifiable(_history);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadHistory();
  }

  void _loadHistory() {
    _history.clear();
    final jsonStringList = _prefs?.getStringList(_prefKey);
    if (jsonStringList != null) {
      for (final jsonStr in jsonStringList) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          _history.add(TranslationHistoryItem.fromJson(map));
        } catch (_) {}
      }
    }
  }

  Future<void> _saveHistory() async {
    if (_prefs == null) return;
    final jsonStringList = _history.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs!.setStringList(_prefKey, jsonStringList);
  }

  Future<void> addHistory({
    required String originalText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
    required String engine,
  }) async {
    if (originalText.trim().isEmpty || translatedText.trim().isEmpty) return;

    // Aynı son çeviriyi tekrar eklememek için kontrol
    if (_history.isNotEmpty &&
        _history.first.originalText == originalText &&
        _history.first.translatedText == translatedText) {
      return;
    }

    final newItem = TranslationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: originalText.trim(),
      translatedText: translatedText.trim(),
      sourceLang: sourceLang,
      targetLang: targetLang,
      timestamp: DateTime.now(),
      engine: engine,
    );

    _history.insert(0, newItem);

    // Maksimum 50 öğe ile sınırla
    if (_history.length > maxHistoryCount) {
      _history.removeRange(maxHistoryCount, _history.length);
    }

    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    if (_prefs != null) {
      await _prefs!.remove(_prefKey);
    }
  }

  Future<void> removeItem(String id) async {
    _history.removeWhere((item) => item.id == id);
    await _saveHistory();
  }

  List<TranslationHistoryItem> searchHistory(String query) {
    if (query.trim().isEmpty) return history;
    final q = query.trim().toLowerCase();
    return _history.where((item) {
      return item.originalText.toLowerCase().contains(q) ||
          item.translatedText.toLowerCase().contains(q) ||
          item.engine.toLowerCase().contains(q) ||
          item.sourceLang.toLowerCase().contains(q) ||
          item.targetLang.toLowerCase().contains(q);
    }).toList();
  }
}
