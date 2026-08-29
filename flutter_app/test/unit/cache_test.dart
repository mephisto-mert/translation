import 'package:flutter_test/flutter_test.dart';
import 'package:quick_translate_pro/models/translation_result.dart';
import 'package:quick_translate_pro/services/cache/bounded_lru_cache.dart';

void main() {
  group('BoundedLruCache Tests', () {
    test('evicts least recently used items when capacity is reached', () {
      final cache = BoundedLruCache(maxEntries: 2);

      final res1 = TranslationResult(
        translatedText: 'trans1',
        originalText: 'orig1',
        sourceLanguage: 'tr',
        targetLanguage: 'en',
        engine: 'google',
        latency: Duration.zero,
      );

      final res2 = TranslationResult(
        translatedText: 'trans2',
        originalText: 'orig2',
        sourceLanguage: 'tr',
        targetLanguage: 'en',
        engine: 'google',
        latency: Duration.zero,
      );

      final res3 = TranslationResult(
        translatedText: 'trans3',
        originalText: 'orig3',
        sourceLanguage: 'tr',
        targetLanguage: 'en',
        engine: 'google',
        latency: Duration.zero,
      );

      cache.put('key1', res1);
      cache.put('key2', res2);

      // Access key1 to promote it to MRU
      expect(cache.get('key1'), isNotNull);

      // Put key3 -> key2 (oldest) should be evicted
      cache.put('key3', res3);

      expect(cache.get('key1'), isNotNull);
      expect(cache.get('key3'), isNotNull);
      expect(cache.get('key2'), isNull);
    });

    test('generates consistent SHA-256 cache keys', () {
      final key1 = BoundedLruCache.computeCacheKey(
        text: 'hello',
        sourceLang: 'en',
        targetLang: 'tr',
        engine: 'google',
      );

      final key2 = BoundedLruCache.computeCacheKey(
        text: 'hello',
        sourceLang: 'en',
        targetLang: 'tr',
        engine: 'google',
      );

      expect(key1, equals(key2));
      expect(key1.length, equals(64)); // SHA-256 hex length
    });
  });
}
