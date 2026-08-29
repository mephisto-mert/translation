class PunctuationEngine {
  // Regex to detect protected literal structures
  static final RegExp _urlRegex =
      RegExp(r'https?://[^\s/$.?#].[^\s]*|www\.[^\s]+', caseSensitive: false);
  static final RegExp _emailRegex =
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', caseSensitive: false);
  static final RegExp _decimalRegex = RegExp(r'\b\d+\.\d+\b');
  static final RegExp _versionRegex = RegExp(r'\bv?\d+\.\d+(\.\d+)?\b', caseSensitive: false);
  static final RegExp _filePathRegex =
      RegExp(r'([a-zA-Z]:\\[^:<>"|?*\n\r]+)|(/[^/<>"|?*\n\r]+)+');
  static final RegExp _abbrevRegex =
      RegExp(r'\b(mr|dr|prof|vs|etc|e\.g|i\.e)\.\b', caseSensitive: false);

  /// Polish translated text without corrupting URLs, decimals, paths, or abbreviations
  static String processPunctuationAndSlang(String text) {
    if (text.trim().isEmpty) return text;

    // Check if string contains protected URL, email, path, decimal, or version
    if (_urlRegex.hasMatch(text) && text.trim().startsWith('http')) return text;
    if (_emailRegex.hasMatch(text) && text.contains('@')) return text;
    if (_filePathRegex.hasMatch(text) && text.contains('\\')) return text;
    if (_decimalRegex.hasMatch(text) || _versionRegex.hasMatch(text) || _abbrevRegex.hasMatch(text)) {
      // Preserve decimals and versions
    }

    String result = text.trim();

    // Natural Gamer Slang Pattern Mappings
    final slangReplacements = [
      RegExp(r"\b(ok|okay)[,\s]+i\s*(am|'m)?\s*coming[,\s]+(brother|bro)\b", caseSensitive: false),
      "Got it, on my way bro!",
      RegExp(r"\bi\s*(am|'m)?\s*coming[,\s]+(brother|bro)\b", caseSensitive: false),
      "on my way bro!",
      RegExp(r"\b(ok|okay)[,\s]+i\s*(am|'m)?\s*coming\b", caseSensitive: false),
      "Got it, on my way!",
      RegExp(r"\bi\s*(am|'m)?\s*coming\b", caseSensitive: false),
      "on my way",
      RegExp(r"\b(tamam|tmm|tm|ok|okay)\s+geliyorum\b", caseSensitive: false),
      "Got it, on my way!",
      RegExp(r"\bgeliyorum[,\s]+(brother|bro)\b", caseSensitive: false),
      "on my way bro!",
      RegExp(r"\bgeliyorum\b", caseSensitive: false),
      "on my way",
      RegExp(r"\b(ok|okay)[,\s]+(brother|bro)\b", caseSensitive: false),
      "Got it bro!",
      RegExp(r"\bmy\s+brother\b", caseSensitive: false),
      "bro",
      RegExp(r"\b(hello|hi)[,\s]+(brother|my brother|bro)\b", caseSensitive: false),
      "yo bro",
      RegExp(r"\b(thanks|thank you)[,\s]+(brother|my brother|bro)\b", caseSensitive: false),
      "thx bro",
      RegExp(r"\b(good job|well done)[,\s]+(brother|my brother|bro)\b", caseSensitive: false),
      "gj bro",
      RegExp(r"\b(see you|goodbye)[,\s]+(brother|my brother|bro)\b", caseSensitive: false),
      "cya bro",
      RegExp(r"\bhow\s+are\s+you[,\s]+(brother|my brother|bro)\b", caseSensitive: false),
      "how u doin bro",
      RegExp(r"\bwhat\s*(is|'s|s)\s+the\s+news\b", caseSensitive: false),
      "what's up",
      RegExp(r"\bpeace\s+be\s+upon\s+you\b", caseSensitive: false),
      "yo",
      RegExp(r"\bwhat\s+(are\s+you|r\s+u)\s+doing\b", caseSensitive: false),
      "whatcha doin",
      RegExp(r"\b(do\s+not|don't)\s+worry\b", caseSensitive: false),
      "no worries",
      RegExp(r"\bby\s+the\s+way\b", caseSensitive: false),
      "btw",
      RegExp(r"\bno\s+problem[,\s]+(brother|bro)\b", caseSensitive: false),
      "no prob bro",
      RegExp(r"\bbrother\b", caseSensitive: false),
      "bro",
    ];

    for (int i = 0; i < slangReplacements.length; i += 2) {
      final pattern = slangReplacements[i] as RegExp;
      final replacement = slangReplacements[i + 1] as String;
      result = result.replaceAll(pattern, replacement);
    }

    return result;
  }
}
