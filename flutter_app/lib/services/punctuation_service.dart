/// Çevrilmiş metin için noktalama düzeltme ve akıllı biçimlendirme
///
/// Python versiyonundaki `fix_punctuation_input_mode`, `is_question`,
/// `normalize_spacing`, `split_run_on_sentences` fonksiyonlarının Dart karşılığı.
library;

// ═══════════════════════════════════════════════════════
// SABİTLER
// ═══════════════════════════════════════════════════════

/// Oyun ve sohbet jargonunda sonuna nokta konmaması gereken kısaltmalar/ifadeler
const Set<String> _chatNoPeriodExpressions = {
  'gg', 'wp', 'sa', 'as', 'brb', 'glhf', 'gl', 'hf', 'nt', 'ez', 'gh', 'ns',
  'ty', 'thx', 'pls', 'plz', 'afk', 'lol', 'lmao', 'rofl', 'omg', 'tbh', 'imo',
  'idc', 'np', 'gn', 'gm', 'g2g', 'gtg', 'mb', 'omw', 'nvm', 'k', 'ok', 'kk',
};

/// İngilizce soru başlangıç kelimeleri ve sohbet soru kısaltmaları
const Set<String> _enQuestionStarters = {
  'what', 'where', 'when', 'who', 'why', 'how', 'which', 'whose', 'whom',
  'is', 'are', 'am', 'was', 'were', 'do', 'does', 'did',
  'can', 'could', 'should', 'would', 'will', 'shall', 'may', 'might',
  'must', 'have', 'has', 'had', 'wbu', 'hbu', 'wytd',
};

/// Türkçe soru kelimeleri (günlük chat argosu dahil)
const Set<String> _trQuestionWords = {
  'neden', 'niçin', 'nasıl', 'nasılsın', 'ne', 'nerede', 'nerde', 'kim', 'hangi',
  'kaç', 'kime', 'kimden', 'neyi', 'neye', 'naber', 'nbr', 'napıyon', 'napyosun',
  'naptın', 'neredesin',
};

/// Türkçe soru ek deseni (mi, mı, mu, mü, misin, mısın, var mı, yok mu vb.)
final RegExp _trQuestionSuffix = RegExp(
  r'(mi|mı|mu|mü|misin|mısın|musun|müsün|midir|mıdır|mudur|müdür|miyim|mıyım|muyum|müyüm|miyiz|mıyız|muyuz|müyüz|var mı|yok mu)[\s.!]*$',
  caseSensitive: false,
);

class PunctuationService {
  PunctuationService._();

  /// Input Mode için gelişmiş noktalama düzeltici.
  /// Çevrilmiş metne uygun noktalama ekler, büyük harf düzeltir.
  static String fixPunctuation(String text, {String targetLang = 'en'}) {
    if (text.trim().isEmpty) return '';

    // 1. Temizle ve normalize et
    var processed = _splitRunOnSentences(text);
    processed = _normalizeSpacing(processed);

    // 2. Cümlelere ayır
    final sentences = RegExp(r'(?<=[.?!])\s+').allMatches(processed);
    final List<String> parts = [];
    int lastEnd = 0;

    for (final match in sentences) {
      parts.add(processed.substring(lastEnd, match.start + 1).trim());
      lastEnd = match.end;
    }
    if (lastEnd < processed.length) {
      parts.add(processed.substring(lastEnd).trim());
    }
    if (parts.isEmpty) parts.add(processed.trim());

    // 3. Her cümleyi düzelt
    final fixed = <String>[];
    for (var sent in parts) {
      if (sent.isEmpty) continue;

      final cleanLower = sent.trim().toLowerCase();

      // Kısa sohbet argosu ise (gg, sa, brb vb.) nokta koymadan koru
      if (_chatNoPeriodExpressions.contains(cleanLower)) {
        fixed.add(smartCapitalize(sent));
        continue;
      }

      // Büyük harfle başlat
      sent = smartCapitalize(sent);

      // Noktalama eksikse ekle
      if (!_endsWithPunctuation(sent)) {
        if (_isQuestion(sent, targetLang)) {
          sent += '?';
        } else {
          sent += '.';
        }
      }

      fixed.add(sent);
    }

    return fixed.join(' ');
  }
}

// ═══════════════════════════════════════════════════════
// YARDIMCI FONKSİYONLAR (Dosya dışından erişilmez)
// ═══════════════════════════════════════════════════════

/// Metnin sonunda noktalama işareti var mı?
bool _endsWithPunctuation(String text) {
  if (text.isEmpty) return false;
  const punctuation = {'.', '!', '?', ':'};
  return punctuation.contains(text[text.length - 1]);
}

/// Cümle soru mu?
bool _isQuestion(String sentence, String lang) {
  final clean = sentence.trim().toLowerCase();
  if (clean.isEmpty) return false;

  // Zaten ? ile bitiyorsa
  if (clean.endsWith('?')) return true;

  // Chat soru kısaltmaları (nbr, wbu, hbu)
  if (clean == 'nbr' || clean == 'wbu' || clean == 'hbu') return true;

  final words = clean.split(RegExp(r'\s+'));
  if (words.isEmpty) return false;

  // Türkçe soru kontrolü (lang=='tr' veya auto/genel)
  if (lang == 'tr' || lang == 'auto') {
    // Soru kelimeleri
    for (final word in words) {
      final stripped = word.replaceAll(RegExp(r'[.,!:]$'), '');
      if (_trQuestionWords.contains(stripped)) return true;
    }

    // Türkçe soru ekleri (mi, mı, mu, mü, geliyon mu, var mı vb.)
    if (_trQuestionSuffix.hasMatch(clean)) return true;

    // Chat konuşma dili soru kalıpları
    if (RegExp(r'\b(geliyon|gidiyon|geliyon mu|gidiyon mu|biliyon mu|yapan var mı|kim var)\b', caseSensitive: false).hasMatch(clean)) {
      return true;
    }
  }

  // İngilizce soru kontrolü (lang=='en' veya auto/genel)
  if (lang == 'en' || lang == 'auto') {
    final firstWord = words[0].replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (_enQuestionStarters.contains(firstWord)) return true;

    // Informal EN chat questions ("u ready?", "u good?", "r u...", "anyone mid?")
    if (RegExp(r'^\b(u|you|r u|are u|is anyone|anyone|anybody)\b', caseSensitive: false).hasMatch(clean)) {
      if (clean.contains('ready') || clean.contains('good') || clean.contains('mid') || clean.contains('coming') || clean.contains('there') || clean.contains('down') || clean.contains('free')) {
        return true;
      }
    }

    // Cümle içi soru ("So, do you...", "Hey, are you...") - excluding subject pronouns + am/is/are
    const midStarters = {'what', 'where', 'when', 'who', 'why', 'how', 'which', 'can', 'could', 'should', 'would', 'will'};
    for (final starter in midStarters) {
      if (clean.contains(', $starter ') || clean.contains(' $starter ')) {
        return true;
      }
    }
  }

  return false;
}

/// Bitişik cümleleri ayır (selamlaşma + soru kalıpları)
String _splitRunOnSentences(String text) {
  if (text.isEmpty) return '';

  // "Hello how are you" → "Hello. How are you"
  var result = text.replaceAllMapped(
    RegExp(r'\b(hello|hi|hey|good morning|greetings|sa)\s+(how|what|where|who|are|nbr|napıyon)\b',
        caseSensitive: false),
    (m) => '${m[1]}. ${m[2]}',
  );

  // "How are you I'm fine" → "How are you? I'm fine"
  result = result.replaceAllMapped(
    RegExp(r"\b(how are you|how is it going|nbr|napıyon)\s+(i|i'm|im|we|good|fine|iyiyim)\b",
        caseSensitive: false),
    (m) => '${m[1]}? ${m[2]}',
  );

  // "Thanks I will..." → "Thanks. I will..."
  result = result.replaceAllMapped(
    RegExp(r"\b(thanks|thank you|eyv|eyvallah)\s+(i|i'm|im|we|it|but|and|kanka)\b",
        caseSensitive: false),
    (m) => '${m[1]}. ${m[2]}',
  );

  return result;
}

/// Noktalamadan sonra boşluk yoksa ekle
String _normalizeSpacing(String text) {
  if (text.isEmpty) return '';
  return text.replaceAllMapped(
    RegExp(r'([.?!])(?=[A-Za-zığüşöçİĞÜŞÖÇ])'),
    (m) => '${m[1]} ',
  );
}

/// İlk harfi büyük yap, gerisini koru
String smartCapitalize(String text) {
  if (text.isEmpty) return '';
  return text[0].toUpperCase() + text.substring(1);
}
