import 'package:flutter_test/flutter_test.dart';
import 'package:quick_translate_pro/services/punctuation/punctuation_engine.dart';

void main() {
  group('PunctuationEngine Tests', () {
    test('protects URLs from corruption', () {
      const url = 'https://example.com/api/v1/test';
      final result = PunctuationEngine.processPunctuationAndSlang(url);
      expect(result, equals(url));
    });

    test('protects decimals and versions', () {
      const versionText = 'v2.1.0 version 3.14';
      final result = PunctuationEngine.processPunctuationAndSlang(versionText);
      expect(result, contains('v2.1.0'));
      expect(result, contains('3.14'));
    });

    test('protects Windows file paths', () {
      const path = r'C:\Users\Test\AppData\Local';
      final result = PunctuationEngine.processPunctuationAndSlang(path);
      expect(result, equals(path));
    });

    test('transforms literal slang to natural gamer English', () {
      const input = 'ok i am coming brother';
      final result = PunctuationEngine.processPunctuationAndSlang(input);
      expect(result, equals('Got it, on my way bro!'));
    });

    test('transforms tamam geliyorum to natural gamer English', () {
      const input = 'tamam geliyorum';
      final result = PunctuationEngine.processPunctuationAndSlang(input);
      expect(result, equals('Got it, on my way!'));
    });
  });
}
