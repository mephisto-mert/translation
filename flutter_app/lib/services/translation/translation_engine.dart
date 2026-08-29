import '../../models/translation_request.dart';
import '../../models/translation_result.dart';

/// Abstract interface for all translation engines
abstract class TranslationEngine {
  /// Unique identifier of the engine (e.g. 'gemini', 'google', 'deepl', 'mymemory')
  String get id;

  /// Human-readable display name
  String get displayName;

  /// Checks whether the engine requires an API key
  bool get requiresApiKey;

  /// Checks whether the engine has a valid credential set
  bool get isConfigured;

  /// Checks if the language pair is supported
  bool supportsLanguage(String sourceLang, String targetLang);

  /// Performs translation with timeout and error handling
  Future<TranslationResult> translate(TranslationRequest request);
}
