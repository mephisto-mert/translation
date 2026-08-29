import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/translation_error.dart';
import '../../models/translation_request.dart';
import '../../models/translation_result.dart';
import 'translation_engine.dart';

class GeminiTranslationEngine implements TranslationEngine {
  final String? apiKey;
  final http.Client _httpClient;
  final Duration timeout;

  GeminiTranslationEngine({
    this.apiKey,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 5),
  }) : _httpClient = httpClient ?? http.Client();

  @override
  String get id => 'gemini';

  @override
  String get displayName => 'Google Gemini 2.0 Flash';

  @override
  bool get requiresApiKey => true;

  @override
  bool get isConfigured => apiKey != null && apiKey!.trim().isNotEmpty;

  @override
  bool supportsLanguage(String sourceLang, String targetLang) => true;

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    if (!isConfigured) {
      throw AuthenticationError('Gemini API key is missing', engineId: id);
    }

    final stopwatch = Stopwatch()..start();
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final prompt = _buildPrompt(request.text, request.sourceLanguage, request.targetLanguage);

    try {
      final response = await _httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 500,
              }
            }),
          )
          .timeout(timeout);

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final translatedText = (parts[0]['text'] as String).trim();
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
        throw ParsingError('Malformed response structure from Gemini API', engineId: id);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthenticationError('Invalid Gemini API Key or unauthorized access', engineId: id);
      } else if (response.statusCode == 429) {
        throw const RateLimitError('Gemini API rate limit exceeded', engineId: 'gemini');
      } else {
        throw ProviderError('Gemini API returned status code ${response.statusCode}',
            statusCode: response.statusCode, engineId: id);
      }
    } on TimeoutException catch (e) {
      throw TimeoutError('Gemini request timed out after ${timeout.inSeconds}s',
          engineId: id, cause: e);
    } catch (e) {
      if (e is TranslationError) rethrow;
      throw NetworkError('Network error connecting to Gemini API', engineId: id, cause: e);
    }
  }

  String _buildPrompt(String text, String source, String target) {
    return '''
System: You are an expert real-time gaming chat translator.
Task: Translate the given text from $source to $target.
Rules:
1. Output ONLY the raw translated text. Do NOT add explanation, markdown quotes, or notes.
2. Use natural, fluent native gamer chat slang (e.g., 'tmm geliyom kanka' -> 'Got it, on my way bro!').
3. Keep gaming terms (e.g., A site, B site, mid, rush, save, eco, clutch) intact.
Text: "$text"
''';
  }
}
