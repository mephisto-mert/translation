import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/translation_request.dart';
import '../models/translation_result.dart';
import '../services/cache/bounded_lru_cache.dart';
import '../services/glossary/gaming_glossary_service.dart';
import '../services/punctuation/punctuation_engine.dart';
import '../services/security/secure_storage_service.dart';
import '../services/translation/deepl_translation_engine.dart';
import '../services/translation/gemini_translation_engine.dart';
import '../services/translation/google_translation_engine.dart';
import '../services/translation/mymemory_translation_engine.dart';
import '../services/translation/translation_engine.dart';
import '../services/translation/translation_fallback_manager.dart';

class TranslationController extends ChangeNotifier {
  final SecureStorageService _secureStorage = SecureStorageService();
  final BoundedLruCache _cache = BoundedLruCache(maxEntries: 500);
  final GamingGlossaryService _glossaryService = GamingGlossaryService();

  late TranslationFallbackManager _fallbackManager;
  bool _isTranslating = false;
  String? _lastError;

  bool get isTranslating => _isTranslating;
  String? get lastError => _lastError;
  BoundedLruCache get cache => _cache;
  GamingGlossaryService get glossaryService => _glossaryService;

  TranslationController() {
    _initEngines();
  }

  void _initEngines() async {
    final geminiKey = await _secureStorage.getGeminiApiKey();
    final deepLKey = await _secureStorage.getDeepLApiKey();

    final engines = <TranslationEngine>[
      GeminiTranslationEngine(apiKey: geminiKey),
      DeepLTranslationEngine(apiKey: deepLKey),
      GoogleTranslationEngine(),
      MyMemoryTranslationEngine(),
    ];

    _fallbackManager = TranslationFallbackManager(engines);
    await _cache.loadFromStorage();
  }

  /// Reloads engines when API keys or credentials change
  Future<void> reloadCredentials() async {
    final geminiKey = await _secureStorage.getGeminiApiKey();
    final deepLKey = await _secureStorage.getDeepLApiKey();

    final engines = <TranslationEngine>[
      GeminiTranslationEngine(apiKey: geminiKey),
      DeepLTranslationEngine(apiKey: deepLKey),
      GoogleTranslationEngine(),
      MyMemoryTranslationEngine(),
    ];

    _fallbackManager = TranslationFallbackManager(engines);
    _fallbackManager.resetCooldowns();
    notifyListeners();
  }

  /// Translates request through Cache -> Glossary -> Fallback Engine -> Punctuation -> Cache
  Future<TranslationResult> translate(TranslationRequest request, AppSettings settings) async {
    _isTranslating = true;
    _lastError = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      // 1. Check LRU Cache
      final cacheKey = BoundedLruCache.computeCacheKey(
        text: request.text,
        sourceLang: request.sourceLanguage,
        targetLang: request.targetLanguage,
        engine: request.preferredEngine ?? settings.primaryEngine,
        glossaryVersion: _glossaryService.glossaryVersion,
      );

      if (settings.enablePersistentCache) {
        final cachedResult = _cache.get(cacheKey);
        if (cachedResult != null) {
          _isTranslating = false;
          notifyListeners();
          return TranslationResult(
            translatedText: cachedResult.translatedText,
            originalText: request.text,
            sourceLanguage: request.sourceLanguage,
            targetLanguage: request.targetLanguage,
            engine: cachedResult.engine,
            latency: stopwatch.elapsed,
            fromCache: true,
          );
        }
      }

      // 2. Protect Glossary Terms
      String textToTranslate = request.text;
      Map<String, String> tokenMap = {};

      if (settings.enableGlossary && request.applyGlossary) {
        final protection = _glossaryService.protectGlossaryTerms(request.text);
        textToTranslate = protection.protectedText;
        tokenMap = protection.tokenMap;
      }

      // 3. Perform Translation with Fallback Manager
      final engineRequest = request.copyWith(text: textToTranslate);
      final rawResult = await _fallbackManager.translateWithFallback(engineRequest);

      // 4. Restore Glossary Terms
      String restoredText = rawResult.translatedText;
      if (tokenMap.isNotEmpty) {
        restoredText = _glossaryService.restoreGlossaryTerms(restoredText, tokenMap);
      }

      // 5. Apply Deterministic Punctuation & Slang Polish
      String finalPolishedText = restoredText;
      if (settings.enableAutoPunctuation && request.applyPunctuation) {
        finalPolishedText = PunctuationEngine.processPunctuationAndSlang(restoredText);
      }

      final finalResult = TranslationResult(
        translatedText: finalPolishedText,
        originalText: request.text,
        sourceLanguage: request.sourceLanguage,
        targetLanguage: request.targetLanguage,
        engine: rawResult.engine,
        latency: stopwatch.elapsed,
        fromCache: false,
      );

      // 6. Cache Result
      if (settings.enablePersistentCache) {
        _cache.put(cacheKey, finalResult);
      }

      _isTranslating = false;
      notifyListeners();
      return finalResult;
    } catch (e) {
      _isTranslating = false;
      _lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _cache.dispose();
    super.dispose();
  }
}
