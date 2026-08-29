import 'package:flutter/foundation.dart';

class GlossaryProtectionResult {
  final String protectedText;
  final Map<String, String> tokenMap;

  GlossaryProtectionResult({
    required this.protectedText,
    required this.tokenMap,
  });
}

class GamingGlossaryService {
  int glossaryVersion = 1;

  final Set<String> _builtinTerms = {
    'A site', 'B site', 'long', 'short', 'catwalk', 'mid', 'banana',
    'apartments', 'ct', 't spawn', 'awp', 'ak', 'm4', 'eco', 'force buy',
    'rush', 'rotate', 'save', 'clutch', 'defuse', 'smoke', 'flash', 'molly',
    'he', 'drop', 'peek', 'crosshair', 'headshot', 'drop me', 'buy', 'wp',
    'gg', 'ez', 'afk', 'brb', 'nt'
  };

  Map<String, String> _customTerms = {};

  void setCustomTerms(Map<String, String> terms) {
    _customTerms = Map.from(terms);
    glossaryVersion++;
  }

  /// Replaces glossary terms with collision-resistant placeholders
  GlossaryProtectionResult protectGlossaryTerms(String text) {
    if (text.trim().isEmpty) {
      return GlossaryProtectionResult(protectedText: text, tokenMap: {});
    }

    String currentText = text;
    final Map<String, String> tokenMap = {};
    int tokenCounter = 0;

    // Combine custom and built-in terms
    final allTerms = <String>{..._builtinTerms, ..._customTerms.keys};
    final sortedTerms = allTerms.toList()..sort((a, b) => b.length.compareTo(a.length));

    for (final term in sortedTerms) {
      final pattern = RegExp('\\b${RegExp.escape(term)}\\b', caseSensitive: false);
      if (pattern.hasMatch(currentText)) {
        currentText = currentText.replaceAllMapped(pattern, (match) {
          final matchedValue = match.group(0)!;
          final token = '__QT_GLOSSARY_${tokenCounter++}_${matchedValue.hashCode.abs()}__';
          tokenMap[token] = _customTerms[term] ?? matchedValue;
          return token;
        });
      }
    }

    return GlossaryProtectionResult(
      protectedText: currentText,
      tokenMap: tokenMap,
    );
  }

  /// Safely restores protected glossary placeholders
  String restoreGlossaryTerms(String text, Map<String, String> tokenMap) {
    if (tokenMap.isEmpty || text.trim().isEmpty) return text;

    String restored = text;
    tokenMap.forEach((token, originalValue) {
      if (restored.contains(token)) {
        restored = restored.replaceAll(token, originalValue);
      } else {
        debugPrint('[GlossaryService] Warning: token $token missing in translated output.');
      }
    });

    return restored;
  }
}
