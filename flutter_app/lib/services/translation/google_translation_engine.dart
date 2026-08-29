import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/translation_error.dart';
import '../../models/translation_request.dart';
import '../../models/translation_result.dart';
import 'translation_engine.dart';

class GoogleTranslationEngine implements TranslationEngine {
  final http.Client _httpClient;
  final Duration timeout;

  GoogleTranslationEngine({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 4),
  }) : _httpClient = httpClient ?? http.Client();

  @override
  String get id => 'google';

  @override
  String get displayName => 'Google Translate';

  @override
  bool get requiresApiKey => false;

  @override
  bool get isConfigured => true;

  @override
  bool supportsLanguage(String sourceLang, String targetLang) => true;

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=${request.sourceLanguage}&tl=${request.targetLanguage}&dt=t&q=${Uri.encodeComponent(request.text)}',
    );

    try {
      final response = await _httpClient.get(url).timeout(timeout);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List?;
        if (data != null && data.isNotEmpty && data[0] is List) {
          final StringBuffer sb = StringBuffer();
          for (final item in data[0] as List) {
            if (item is List && item.isNotEmpty && item[0] != null) {
              sb.write(item[0].toString());
            }
          }
          final translatedText = sb.toString().trim();
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
        throw ParsingError('Could not parse Google Translate response', engineId: id);
      } else if (response.statusCode == 429) {
        throw const RateLimitError('Google Translate rate limit exceeded', engineId: 'google');
      } else {
        throw ProviderError('Google Translate returned status ${response.statusCode}',
            statusCode: response.statusCode, engineId: id);
      }
    } on TimeoutException catch (e) {
      throw TimeoutError('Google Translate request timed out', engineId: id, cause: e);
    } catch (e) {
      if (e is TranslationError) rethrow;
      throw NetworkError('Network error connecting to Google Translate', engineId: id, cause: e);
    }
  }
}
