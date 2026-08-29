import 'package:flutter_test/flutter_test.dart';
import 'package:quick_translate_pro/services/translation_service.dart';
import 'package:quick_translate_pro/services/punctuation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PunctuationService Tests', () {
    test('Preserves gamer slang without adding forced ending periods', () {
      expect(PunctuationService.fixPunctuation('gg'), equals('Gg'));
      expect(PunctuationService.fixPunctuation('wp'), equals('Wp'));
      expect(PunctuationService.fixPunctuation('sa'), equals('Sa'));
      expect(PunctuationService.fixPunctuation('as'), equals('As'));
      expect(PunctuationService.fixPunctuation('brb'), equals('Brb'));
      expect(PunctuationService.fixPunctuation('afk'), equals('Afk'));
    });

    test('Correctly detects Turkish chat questions', () {
      expect(PunctuationService.fixPunctuation('nbr', targetLang: 'tr'), equals('Nbr?'));
      expect(PunctuationService.fixPunctuation('napıyon', targetLang: 'tr'), equals('Napıyon?'));
      expect(PunctuationService.fixPunctuation('geliyon mu', targetLang: 'tr'), equals('Geliyon mu?'));
      expect(PunctuationService.fixPunctuation('kim var', targetLang: 'tr'), equals('Kim var?'));
    });

    test('Correctly detects English chat questions', () {
      expect(PunctuationService.fixPunctuation('wbu', targetLang: 'en'), equals('Wbu?'));
      expect(PunctuationService.fixPunctuation('hbu', targetLang: 'en'), equals('Hbu?'));
      expect(PunctuationService.fixPunctuation('u ready', targetLang: 'en'), equals('U ready?'));
      expect(PunctuationService.fixPunctuation('who is mid', targetLang: 'en'), equals('Who is mid?'));
    });

    test('Correctly adds period for standard statements', () {
      expect(PunctuationService.fixPunctuation('geliyom', targetLang: 'tr'), equals('Geliyom.'));
      expect(PunctuationService.fixPunctuation('i am coming', targetLang: 'en'), equals('I am coming.'));
    });
  });

  group('TranslationResult Model & Serialization Tests', () {
    test('TranslationResult serializes and deserializes to JSON properly', () {
      const original = TranslationResult(
        text: 'Let\'s rush A site',
        targetLang: 'en',
        detectedSourceLang: 'tr',
        engine: TranslationEngine.gemini,
        errorDetail: null,
      );

      final json = original.toJson();
      final restored = TranslationResult.fromJson(json);

      expect(restored.text, equals(original.text));
      expect(restored.targetLang, equals(original.targetLang));
      expect(restored.detectedSourceLang, equals(original.detectedSourceLang));
      expect(restored.engine, equals(original.engine));
    });
  });
}
