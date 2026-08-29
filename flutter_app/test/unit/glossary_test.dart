import 'package:flutter_test/flutter_test.dart';
import 'package:quick_translate_pro/services/glossary/gaming_glossary_service.dart';

void main() {
  group('GamingGlossaryService Tests', () {
    final glossaryService = GamingGlossaryService();

    test('replaces built-in gaming terms with collision-resistant placeholders', () {
      const text = 'rush A site and save awp';
      final protection = glossaryService.protectGlossaryTerms(text);

      expect(protection.protectedText, isNot(equals(text)));
      expect(protection.tokenMap, isNotEmpty);
      expect(protection.protectedText, contains('__QT_GLOSSARY_'));
    });

    test('restores protected glossary terms safely', () {
      const originalText = 'rush A site and save awp';
      final protection = glossaryService.protectGlossaryTerms(originalText);

      final restored = glossaryService.restoreGlossaryTerms(
        protection.protectedText,
        protection.tokenMap,
      );

      expect(restored.toLowerCase(), equals(originalText.toLowerCase()));
    });

    test('supports user-defined custom glossary terms', () {
      glossaryService.setCustomTerms({'myclan': 'klanım'});

      const text = 'join myclan today';
      final protection = glossaryService.protectGlossaryTerms(text);
      final restored = glossaryService.restoreGlossaryTerms(
        protection.protectedText,
        protection.tokenMap,
      );

      expect(restored, contains('klanım'));
    });
  });
}
