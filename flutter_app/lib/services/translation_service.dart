/// Çoklu çeviri motoru servisi — akıllı fallback zinciri
///
/// Sıralama: Gemini AI (API key varsa) → DeepL (API key varsa) → Google Translate (ücretsiz) → MyMemory
/// Her motor başarısız olursa bir sonrakine geçer.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════
// SABİTLER
// ═══════════════════════════════════════════════════════

/// Çeviri motorları enum
enum TranslationEngine { google, myMemory, gemini, deepL }

/// Motor sabitleri
class _EngineUrls {
  _EngineUrls._();
  static const String google = 'https://translate.googleapis.com/translate_a/single';
  static const String myMemory = 'https://api.mymemory.translated.net/get';
  static const String gemini = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String deepL = 'https://api-free.deepl.com/v2/translate';
}

/// Timeout sabitleri
class _Timeouts {
  _Timeouts._();
  static const Duration primary = Duration(seconds: 8);
  static const Duration fallback = Duration(seconds: 6);
  static const Duration connectionCheck = Duration(seconds: 3);
}

/// Cache sabitleri
const int _maxCacheSize = 200;
const String _storageCacheKey = 'translation_lru_cache_v1';

/// Gaming & CS2 Callouts Glossary
/// Bunlar çevirilerde bozulmadan ve sözcük sözcük çevrilmeden korunacak terimlerdir.
const List<String> gamingGlossary = [
  // Çok kelimeli bölgeler ve terimler (önce eşleşsin diye üstte)
  'A site',
  'B site',
  'A-site',
  'B-site',
  't spawn',
  'ct spawn',
  't-spawn',
  'ct-spawn',
  'force buy',
  'force-buy',
  'ninja defuse',
  'bomb site',
  'fake plant',
  'catwalk',
  'apartments',
  'crosshair',
  'headshot',

  // Tek kelimeli bölgeler, silahlar, haritalar ve mekanikler
  'banana',
  'awp',
  'ak47',
  'ak-47',
  'm4a4',
  'm4a1-s',
  'm4a1',
  'defuse',
  'clutch',
  'rotate',
  'long',
  'short',
  'mid',
  'ct',
  'ak',
  'm4',
  'eco',
  'rush',
  'save',
  'smoke',
  'flash',
  'molly',
  'drop',
  'peek',
  'retake',
  'flank',
  'deagle',
  'scout',
];

// ═══════════════════════════════════════════════════════
// ANA SERVİS
// ═══════════════════════════════════════════════════════

class TranslationService {
  /// LRU Translation Cache — aynı metni tekrar çevirme
  static final Map<String, TranslationResult> _cache = {};
  static bool _isCacheLoaded = false;

  /// DeepL API anahtarı (isteğe bağlı, ayarlardan yüklenebilir)
  static String? deepLApiKey;

  /// Gemini API anahtarı (isteğe bağlı, ayarlardan yüklenebilir)
  static String? geminiApiKey;

  /// Son başarılı motor
  static TranslationEngine _lastSuccessfulEngine = TranslationEngine.google;

  /// Cache'i SharedPreferences'tan yükle
  static Future<void> loadCacheFromStorage() async {
    if (_isCacheLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageCacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        _cache.clear();
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _cache[key] = TranslationResult.fromJson(value);
          }
        });
      }
    } catch (e) {
      print('[TranslationService] Error loading cache from storage: $e');
    } finally {
      _isCacheLoaded = true;
    }
  }

  /// Cache'i SharedPreferences'a kaydet
  static Future<void> _saveCacheToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapData = _cache.map((key, val) => MapEntry(key, val.toJson()));
      await prefs.setString(_storageCacheKey, jsonEncode(mapData));
    } catch (e) {
      print('[TranslationService] Error saving cache to storage: $e');
    }
  }

  /// Metindeki gaming terimlerini yer tutucularla (__GT_0__, __GT_1__) korumaya alır.
  static (String protectedText, Map<String, String> termMap) _protectGamingTerms(String text) {
    if (text.isEmpty) return (text, {});

    final termMap = <String, String>{};
    var protectedText = text;
    int index = 0;

    // Terimleri uzunluğa göre azalan sırada sırala (ör: "A site", "site"'dan önce eşleşmeli)
    final sortedTerms = List<String>.from(gamingGlossary)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final term in sortedTerms) {
      final pattern = RegExp(r'\b' + RegExp.escape(term) + r'\b', caseSensitive: false);
      protectedText = protectedText.replaceAllMapped(pattern, (match) {
        final original = match.group(0)!;
        final placeholder = '__GT_${index++}__';
        termMap[placeholder] = original;
        return placeholder;
      });
    }

    // High Explosive bombası (HE) için özel kontrol
    final hePattern = RegExp(r'\b(HE|HE nade|HE grenade)\b');
    protectedText = protectedText.replaceAllMapped(hePattern, (match) {
      final original = match.group(0)!;
      final placeholder = '__GT_${index++}__';
      termMap[placeholder] = original;
      return placeholder;
    });

    return (protectedText, termMap);
  }

  /// Çeviri sonrasında __GT_0__ yer tutucularını orijinal gaming terimleriyle geri yükler.
  static String _restoreGamingTerms(String text, Map<String, String> termMap) {
    if (text.isEmpty || termMap.isEmpty) return text;

    var restored = text;
    termMap.forEach((placeholder, original) {
      final numOnly = placeholder.replaceAll(RegExp(r'\D'), '');
      final flexiblePattern = RegExp(r'__\s*GT_\s*' + numOnly + r'\s*__', caseSensitive: false);
      restored = restored.replaceAll(flexiblePattern, original);
    });

    return restored;
  }

  /// Ana çeviri metodu — fallback zinciri ile
  static Future<TranslationResult> translate({
    required String text,
    required String source,
    required String target,
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult(text: '', targetLang: target);
    }

    await loadCacheFromStorage();

    // Cache kontrol
    final cacheKey = '${source}_${target}_${text.trim().toLowerCase()}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Gaming terimlerini korumaya al
    final (protectedText, termMap) = _protectGamingTerms(text.trim());

    // Fallback zinciri
    final engines = _buildEngineOrder();
    final List<String> errorsList = [];

    for (final engine in engines) {
      try {
        final result = await _translateWithEngine(engine, protectedText, source, target);
        if (result != null && result.text.isNotEmpty) {
          // Terimleri geri yükle
          final restoredText = _restoreGamingTerms(result.text, termMap);
          final finalResult = result.copyWith(text: restoredText);

          _lastSuccessfulEngine = engine;

          // Bidirectional switching
          if (source == 'auto' &&
              restoredText.toLowerCase() == text.trim().toLowerCase() &&
              target == 'tr') {
            final reversed = await _translateWithEngine(engine, protectedText, 'tr', 'en');
            if (reversed != null && reversed.text.isNotEmpty) {
              final restoredReversedText = _restoreGamingTerms(reversed.text, termMap);
              if (restoredReversedText.toLowerCase() != text.trim().toLowerCase()) {
                final finalReversed = reversed.copyWith(text: restoredReversedText);
                _addToCache(cacheKey, finalReversed);
                return finalReversed;
              }
            }
          }

          _addToCache(cacheKey, finalResult);
          return finalResult;
        }
      } catch (e) {
        errorsList.add('[${engine.name}] Exception: $e');
        print('[TranslationService] ${engine.name} engine failed: $e');
        continue;
      }
    }

    // Hiçbiri çalışmadı
    final errorDetail = errorsList.isNotEmpty
        ? errorsList.join(' | ')
        : 'All translation engines failed or returned empty.';
    return TranslationResult(
      text: text,
      targetLang: target,
      errorDetail: errorDetail,
    );
  }

  /// Motor sırasını belirle — Gemini varsa birincil, yoksa Google
  static List<TranslationEngine> _buildEngineOrder() {
    final engines = <TranslationEngine>[];

    // Gemini API key varsa birincil motor yap — en doğal çeviri
    if (geminiApiKey != null && geminiApiKey!.isNotEmpty) {
      engines.add(TranslationEngine.gemini);
    }

    // Son başarılı motoru öncelikli ekle
    if (!engines.contains(_lastSuccessfulEngine)) {
      if (_lastSuccessfulEngine == TranslationEngine.deepL && deepLApiKey == null) {
        // skip
      } else if (_lastSuccessfulEngine == TranslationEngine.gemini && geminiApiKey == null) {
        // skip
      } else {
        engines.add(_lastSuccessfulEngine);
      }
    }

    // Kalan motorları ekle
    for (final e in TranslationEngine.values) {
      if (e == TranslationEngine.deepL && deepLApiKey == null) continue;
      if (e == TranslationEngine.gemini && geminiApiKey == null) continue;
      if (!engines.contains(e)) engines.add(e);
    }
    return engines;
  }

  /// Belirli bir motor ile çeviri yap
  static Future<TranslationResult?> _translateWithEngine(
    TranslationEngine engine,
    String text,
    String source,
    String target,
  ) async {
    switch (engine) {
      case TranslationEngine.google:
        return _googleTranslate(text, source, target);
      case TranslationEngine.myMemory:
        return _myMemoryTranslate(text, source, target);
      case TranslationEngine.gemini:
        return _geminiTranslate(text, source, target);
      case TranslationEngine.deepL:
        return _deepLTranslate(text, source, target);
    }
  }

  // ═══════════════════════════════════════════════════════
  // MOTOR 1: Google Translate (Ücretsiz)
  // ═══════════════════════════════════════════════════════

  static Future<TranslationResult?> _googleTranslate(
      String text, String source, String target) async {
    try {
      final uri = Uri.parse(_EngineUrls.google).replace(queryParameters: {
        'client': 'gtx',
        'sl': source,
        'tl': target,
        'dt': 't',
        'q': text,
      });

      final response = await http.get(uri).timeout(_Timeouts.primary);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final buffer = StringBuffer();

        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          for (final segment in decoded[0]) {
            if (segment is List && segment.isNotEmpty && segment[0] is String) {
              buffer.write(segment[0]);
            }
          }
        }

        String detectedSource = source;
        if (decoded is List && decoded.length > 2 && decoded[2] is String) {
          detectedSource = decoded[2];
        }

        return TranslationResult(
          text: buffer.toString(),
          targetLang: target,
          detectedSourceLang: detectedSource,
          engine: TranslationEngine.google,
        );
      } else {
        print('[TranslationService] Google Translate HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('[TranslationService] Google Translate error: $e');
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════
  // MOTOR 2: MyMemory (Ücretsiz, API key gerekmez)
  // ═══════════════════════════════════════════════════════

  static Future<TranslationResult?> _myMemoryTranslate(
      String text, String source, String target) async {
    try {
      final sourceLang = source == 'auto' ? 'en' : source;
      final langPair = '$sourceLang|$target';

      final uri = Uri.parse(_EngineUrls.myMemory).replace(queryParameters: {
        'q': text,
        'langpair': langPair,
      });

      final response = await http.get(uri).timeout(_Timeouts.fallback);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map &&
            decoded['responseStatus'] == 200 &&
            decoded['responseData'] is Map) {
          final translated = decoded['responseData']['translatedText'] as String?;
          if (translated != null && translated.isNotEmpty) {
            return TranslationResult(
              text: translated,
              targetLang: target,
              detectedSourceLang: sourceLang,
              engine: TranslationEngine.myMemory,
            );
          }
        }
      } else {
        print('[TranslationService] MyMemory HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('[TranslationService] MyMemory error: $e');
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════
  // MOTOR 3: Gemini AI (Bağlam anlayan akıllı çeviri)
  // ═══════════════════════════════════════════════════════

  /// Gemini system prompt — doğal, oyuncu/günlük konuşma dili ve argolar
  static const String _geminiSystemPrompt = '''
You are an expert real-time gamer & casual chat translator specializing in Turkish and English communications.
Your primary directive is to produce ultra-natural, non-robotic translations of chat messages, gamer slang, callouts, and informal expressions.

CRITICAL TRANSLATION RULES:
1. DO NOT translate word-for-word. Understand the MEANING, INTENT, and CHAT CONTEXT, then render it how a real gamer/friend would type.
2. Handle Casual & Gamer Slang Naturally:
   - Turkish to English Examples:
     * "sa" / "s.a" -> "sup" / "hey" / "yo"
     * "as" / "a.s" -> "yo" / "hey"
     * "nbr" / "ne haber" -> "what's up?" / "sup?"
     * "napıyon" / "napyosun" / "naptın" -> "whatcha doin?" / "what are you up to?"
     * "geliyom" / "geliyorm" -> "coming" / "on my way" / "omw"
     * "kanka" / "knk" -> "bro" / "dude"
     * "eyv" / "eyvallah" -> "thx" / "thanks"
   - English to Turkish Examples:
     * "wbu" / "hbu" -> "sen?" / "senden naber?"
     * "idc" -> "fark etmez" / "umrumda değil"
     * "tbh" -> "açıkçası" / "dürüst olmak gerekirse"
     * "imo" / "imho" -> "bence"
     * "brb" -> "hemen döncem" / "hemen geliyorum"
     * "gg" / "wp" -> "gg" / "wp"
     * "clutch" -> "clutch"
     * "omw" -> "geliyorum"
     * "nvm" -> "boşver"
3. Preserve Gaming Callouts & Terms INTACT without translation:
   - Terms like "A site", "B site", "long", "short", "catwalk", "mid", "banana", "apartments", "ct", "t spawn", "awp", "ak", "m4", "eco", "force buy", "rush", "rotate", "save", "clutch", "defuse", "smoke", "flash", "molly", "he", "drop", "peek", "crosshair", "headshot", placeholders like "__GT_0__" MUST BE PRESERVED EXACTLY AS WRITTEN.
4. Keep translations SHORT and CONCISE — this is fast live chat.
5. Match tone, uppercase/lowercase energy, and punctuation style.
6. OUTPUT ONLY THE FINAL TRANSLATED TEXT. No quotation marks, no explanations, no "Translation:" prefix.
''';

  static Future<TranslationResult?> _geminiTranslate(
      String text, String source, String target) async {
    if (geminiApiKey == null || geminiApiKey!.isEmpty) return null;

    final langNames = {
      'tr': 'Turkish', 'en': 'English', 'de': 'German', 'fr': 'French',
      'es': 'Spanish', 'it': 'Italian', 'ru': 'Russian', 'ja': 'Japanese',
      'zh-CN': 'Chinese', 'ar': 'Arabic', 'pt': 'Portuguese', 'ko': 'Korean',
      'nl': 'Dutch', 'pl': 'Polish', 'auto': 'auto-detect',
    };
    final sourceName = langNames[source] ?? source;
    final targetName = langNames[target] ?? target;
    final userPrompt = '[$sourceName → $targetName] $text';

    final uri = Uri.parse('${_EngineUrls.gemini}?key=${geminiApiKey!}');
    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': _geminiSystemPrompt}]
      },
      'contents': [
        {
          'parts': [{'text': userPrompt}]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 256,
      },
    });

    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_Timeouts.fallback);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['candidates'] is List) {
          final candidates = decoded['candidates'] as List;
          if (candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            if (content is Map && content['parts'] is List) {
              final parts = content['parts'] as List;
              if (parts.isNotEmpty && parts[0]['text'] is String) {
                final translated = (parts[0]['text'] as String).trim();
                if (translated.isNotEmpty) {
                  return TranslationResult(
                    text: translated,
                    targetLang: target,
                    detectedSourceLang: source,
                    engine: TranslationEngine.gemini,
                  );
                }
              }
            }
          }
        }
      } else {
        print('[TranslationService] Gemini API failed: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[TranslationService] Gemini API error: $e');
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════
  // MOTOR 4: DeepL (Ücretsiz plan — 500K karakter/ay)
  // ═══════════════════════════════════════════════════════

  static Future<TranslationResult?> _deepLTranslate(
      String text, String source, String target) async {
    if (deepLApiKey == null || deepLApiKey!.isEmpty) return null;

    try {
      final dlTarget = _deepLLangCode(target);
      final dlSource = source == 'auto' ? null : _deepLLangCode(source);

      final body = <String, String>{
        'auth_key': deepLApiKey!,
        'text': text,
        'target_lang': dlTarget,
      };
      if (dlSource != null) body['source_lang'] = dlSource;

      final response = await http
          .post(Uri.parse(_EngineUrls.deepL), body: body)
          .timeout(_Timeouts.fallback);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['translations'] is List) {
          final translations = decoded['translations'] as List;
          if (translations.isNotEmpty) {
            final translated = translations[0]['text'] as String?;
            final detectedLang =
                translations[0]['detected_source_language'] as String?;
            if (translated != null && translated.isNotEmpty) {
              return TranslationResult(
                text: translated,
                targetLang: target,
                detectedSourceLang: detectedLang?.toLowerCase(),
                engine: TranslationEngine.deepL,
              );
            }
          }
        }
      } else {
        print('[TranslationService] DeepL API failed: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[TranslationService] DeepL API error: $e');
    }
    return null;
  }

  /// DeepL dil kodu dönüştürme
  static String _deepLLangCode(String code) {
    const mapping = {
      'en': 'EN-US',
      'pt': 'PT-BR',
      'zh-CN': 'ZH',
    };
    return mapping[code] ?? code.toUpperCase();
  }

  // ═══════════════════════════════════════════════════════
  // CACHE
  // ═══════════════════════════════════════════════════════

  static void _addToCache(String key, TranslationResult result) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = result;
    _saveCacheToStorage();
  }

  /// Cache'i temizle
  static Future<void> clearCache() async {
    _cache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageCacheKey);
    } catch (e) {
      print('[TranslationService] Error clearing cache: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // BAĞLANTI KONTROLÜ
  // ═══════════════════════════════════════════════════════

  static Future<bool> checkConnection() async {
    try {
      final uri = Uri.parse(_EngineUrls.google).replace(queryParameters: {
        'client': 'gtx',
        'sl': 'en',
        'tl': 'tr',
        'dt': 't',
        'q': 'hi',
      });
      final response =
          await http.get(uri).timeout(_Timeouts.connectionCheck);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════
// SONUÇ MODELİ
// ═══════════════════════════════════════════════════════

class TranslationResult {
  final String text;
  final String targetLang;
  final String? detectedSourceLang;
  final TranslationEngine? engine;
  final String? errorDetail;

  const TranslationResult({
    required this.text,
    required this.targetLang,
    this.detectedSourceLang,
    this.engine,
    this.errorDetail,
  });

  TranslationResult copyWith({
    String? text,
    String? targetLang,
    String? detectedSourceLang,
    TranslationEngine? engine,
    String? errorDetail,
  }) {
    return TranslationResult(
      text: text ?? this.text,
      targetLang: targetLang ?? this.targetLang,
      detectedSourceLang: detectedSourceLang ?? this.detectedSourceLang,
      engine: engine ?? this.engine,
      errorDetail: errorDetail ?? this.errorDetail,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'targetLang': targetLang,
        'detectedSourceLang': detectedSourceLang,
        'engine': engine?.name,
        'errorDetail': errorDetail,
      };

  factory TranslationResult.fromJson(Map<String, dynamic> json) =>
      TranslationResult(
        text: json['text'] as String? ?? '',
        targetLang: json['targetLang'] as String? ?? 'en',
        detectedSourceLang: json['detectedSourceLang'] as String?,
        engine: json['engine'] != null
            ? TranslationEngine.values.firstWhere(
                (e) => e.name == json['engine'],
                orElse: () => TranslationEngine.google,
              )
            : null,
        errorDetail: json['errorDetail'] as String?,
      );
}
