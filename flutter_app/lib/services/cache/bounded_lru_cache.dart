import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/translation_result.dart';

/// True Bounded LRU Cache with debounced async persistence
class BoundedLruCache {
  final int maxEntries;
  final LinkedHashMap<String, TranslationResult> _cache = LinkedHashMap();
  Timer? _persistenceDebounceTimer;
  bool _isDirty = false;
  bool _enabled = true;
  static const String _storageKey = 'quicktrace_lru_cache_v2';

  BoundedLruCache({this.maxEntries = 500});

  bool get enabled => _enabled;

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!_enabled) {
      clearMemoryCache();
    }
  }

  /// Generates a collision-resistant SHA-256 cache key
  static String computeCacheKey({
    required String text,
    required String sourceLang,
    required String targetLang,
    required String engine,
    int glossaryVersion = 1,
  }) {
    final normalizedText = text.trim().toLowerCase();
    final raw = '$sourceLang|$targetLang|$engine|$glossaryVersion|$normalizedText';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Get item from LRU cache (promotes key on access)
  TranslationResult? get(String key) {
    if (!_enabled) return null;
    final item = _cache.remove(key);
    if (item != null) {
      _cache[key] = item; // Re-insert at the end (most recently used)
      return item;
    }
    return null;
  }

  /// Put item into LRU cache
  void put(String key, TranslationResult result) {
    if (!_enabled) return;

    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxEntries) {
      // Evict least recently used (first item in LinkedHashMap)
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[key] = result;
    _markDirtyAndDebouncePersist();
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _cache.clear();
  }

  /// Clear memory and persistent storage
  Future<void> clearAllCache() async {
    _cache.clear();
    _isDirty = false;
    _persistenceDebounceTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Load cache from persistent storage on startup
  Future<void> loadFromStorage() async {
    if (!_enabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);
      if (rawJson != null) {
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        _cache.clear();
        decoded.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            _cache[key] = TranslationResult.fromJson(val);
          }
        });
        debugPrint('[LruCache] Loaded ${_cache.length} entries from persistent storage.');
      }
    } catch (e) {
      debugPrint('[LruCache] Error loading cache from storage: $e');
    }
  }

  void _markDirtyAndDebouncePersist() {
    _isDirty = true;
    _persistenceDebounceTimer?.cancel();
    _persistenceDebounceTimer = Timer(const Duration(seconds: 2), () {
      _flushToStorage();
    });
  }

  Future<void> _flushToStorage() async {
    if (!_isDirty || !_enabled) return;
    _isDirty = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> exportMap = {};
      _cache.forEach((key, result) {
        exportMap[key] = result.toJson();
      });
      await prefs.setString(_storageKey, jsonEncode(exportMap));
      debugPrint('[LruCache] Debounced persistence saved ${_cache.length} entries to disk.');
    } catch (e) {
      debugPrint('[LruCache] Error flushing cache to storage: $e');
    }
  }

  void dispose() {
    _persistenceDebounceTimer?.cancel();
    if (_isDirty) {
      _flushToStorage();
    }
  }
}
