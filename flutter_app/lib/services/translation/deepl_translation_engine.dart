import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/translation_error.dart';
import '../../models/translation_request.dart';
import '../../models/translation_result.dart';
import 'translation_engine.dart';

class DeepLTranslationEngine implements TranslationEngine {
  final String? apiKey;
  final http.Client _httpClient;
  final Duration timeout;

  DeepLTranslationEngine({
    this.apiKey,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 4),
  }) : _httpClient = httpClient ?? http.Client();

  @override
  String get id => 'deepl';

  @override
  String get displayName => 'DeepL API';

  @override
  bool get requiresApiKey => true;

  @override
  bool get isConfigured => apiKey != null && apiKey!.trim().isNotEmpty;

  @override
  bool supportsLanguage(String sourceLang, String targetLang) => true;

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    if (!isConfigured) {
      throw AuthenticationError('DeepL API key is missing', engineId: id);
    }

    final stopwatch = Stopwatch()..start();
    final isFreeKey = apiKey!.endsWith(':fx');
    final baseUrl = isFreeKey
        ? 'https://api-free.deepl.com/v2/translate'
        : 'https://api.deepl.com/v2/translate';

    try {
      final response = await _httpClient
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Authorization': 'DeepL-Auth-Key ${apiKey!.trim()}',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'text': request.text,
              'target_lang': request.targetLanguage.toUpperCase(),
              'source_lang': request.sourceLanguage.toUpperCase(),
            },
          )
          .timeout(timeout);

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final translations = data['translations'] as List?;
        if (translations != null && translations.isNotEmpty) {
          final translatedText = (translations[0]['text'] as String).trim();
          return TranslationResult(
            translatedText: translatedText,
            originalText: request.text,
            sourceLanguage: request.sourceLanguage,
            targetLanguage: request.targetLanguage,
            engine: id,
            latency: stopwatch.elapsed,
          );
        }
        throw ParsingError('Malformed DeepL response', engineId: id);
      } else if (response.statusCode == 403) {
        throw AuthenticationError('Invalid DeepL API Key', engineId: id);
      } else if (response.statusCode == 429 || response.statusCode == 456) {
        throw const RateLimitError('DeepL quota or rate limit exceeded', engineId: 'deepl');
      } else {
        throw ProviderError('DeepL returned status code ${response.statusCode}',
            statusCode: response.statusCode, engineId: id);
      }
    } on TimeoutException catch (e) {
      throw TimeoutError('DeepL request timed out', engineId: id, cause: e);
    } catch (e) {
      if (e is TranslationError) rethrow;
      throw NetworkError('Network error connecting to DeepL API', engineId: id, cause: e);
    }
  }
}
