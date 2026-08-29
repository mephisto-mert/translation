import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/translation_error.dart';
import '../../models/translation_request.dart';
import '../../models/translation_result.dart';
import 'translation_engine.dart';

class MyMemoryTranslationEngine implements TranslationEngine {
  final http.Client _httpClient;
  final Duration timeout;

  MyMemoryTranslationEngine({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 4),
  }) : _httpClient = httpClient ?? http.Client();

  @override
  String get id => 'mymemory';

  @override
  String get displayName => 'MyMemory API';

  @override
  bool get requiresApiKey => false;

  @override
  bool get isConfigured => true;

  @override
  bool supportsLanguage(String sourceLang, String targetLang) => true;

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    final stopwatch = Stopwatch()..start();
    final langPair = '${request.sourceLanguage}|${request.targetLanguage}';
    final url = Uri.parse(
      'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(request.text)}&langpair=$langPair',
    );

    try {
      final response = await _httpClient.get(url).timeout(timeout);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = data['responseData'] as Map<String, dynamic>?;
        if (responseData != null) {
          final translatedText = (responseData['translatedText'] as String? ?? '').trim();
          if (translatedText.isNotEmpty) {
            return TranslationResult(
              translatedText: translatedText,
              originalText: request.text,
              sourceLanguage: request.sourceLanguage,
              targetLanguage: request.targetLanguage,
              engine: id,
              latency: stopwatch.elapsed,
            );
          }
        }
        throw ParsingError('Malformed MyMemory response', engineId: id);
      } else if (response.statusCode == 429) {
        throw const RateLimitError('MyMemory rate limit exceeded', engineId: 'mymemory');
      } else {
        throw ProviderError('MyMemory returned status ${response.statusCode}',
            statusCode: response.statusCode, engineId: id);
      }
    } on TimeoutException catch (e) {
      throw TimeoutError('MyMemory request timed out', engineId: id, cause: e);
    } catch (e) {
      if (e is TranslationError) rethrow;
      throw NetworkError('Network error connecting to MyMemory API', engineId: id, cause: e);
    }
  }
}
