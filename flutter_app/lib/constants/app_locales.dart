/// Çoklu dil desteği - TR/EN arayüz stringleri ve dil eşlemeleri
library;

class AppLocales {
  AppLocales._();

  static const Map<String, Map<String, String>> strings = {
    'tr': {
      'window_title': 'Hızlı Çeviri Pro',
      'system_online': 'Sistem Çevrimiçi & Hazır',
      'system_offline': 'Çevrimdışı - Bağlantıyı Kontrol Et',
      'checking_connection': 'Bağlantı kontrol ediliyor...',
      'source_lang': 'KAYNAK DİL',
      'target_lang': 'HEDEF DİL',
      'active_modes': 'AKTİF MODLAR',
      'bubble_mode': 'Baloncuk Modu (Fare)',
      'input_mode': 'Giriş Modu (Klavye)',
      'clipboard_mode': 'Clipboard Monitör',
      'minimize_tray': 'Simge Durumuna Küçült',
      'ui_language': 'ARAYÜZ DİLİ',
      'swap_languages': 'Dilleri Değiştir',
      'how_to_use': 'NASIL KULLANILIR',
      'bubble_desc': 'Herhangi bir uygulamada metin seçin → çeviri baloncuğu fare yanında belirir.',
      'input_desc': 'Herhangi bir uygulamada yazın, nokta/ünlem/enter\'a basınca metin otomatik çevrilerek değiştirilir.',
      'clipboard_desc': 'Panoya kopyalanan her metin otomatik olarak çevrilir ve bildirim gösterilir.',
      'translating': 'Çevriliyor...',
      'hooks_active': 'Hook\'lar Aktif',
      'api_keys': 'API ANAHTARLARI',
      'gemini_key': 'Gemini API Anahtarı',
      'deepl_key': 'DeepL API Anahtarı',
      'optional': 'İsteğe Bağlı',
      'save': 'Kaydet',
      'hotkey_settings': 'KISAYOL & TETİKLEYİCİ AYARLARI',
      'chat_keys': 'Chat Açma Tuşları',
      'trigger_chars': 'Çeviri Tetikleyici Karakterler',
      'translation_history': 'Çeviri Geçmişi',
      'history_empty': 'Henüz kaydedilmiş çeviri yok',
      'search_history': 'Geçmişte ara (metin, dil veya motor)...',
      'clear_history': 'Geçmişi Temizle',
      'confirm_clear_history': 'Tüm çeviri geçmişi silinsin mi?',
      'copied_to_clipboard': 'Panoya kopyalandı!',
      'original': 'Orijinal',
      'translation': 'Çeviri',
      'engine': 'Motor',
      'delete': 'Sil',
      'cancel': 'İptal',
      'clear': 'Temizle',
      'no_results': 'Eşleşen sonuç bulunamadı',
      'api_key_saved': 'API anahtarı başarıyla kaydedildi.',
      'error_offline': 'İnternet bağlantısı yok. Çeviri yapılamıyor.',
      'error_translation_failed': 'Çeviri motoru yanıt vermedi veya hata oluştu.',
      'enter_api_key': 'API Anahtarını Girin',
      'active': 'Aktif',
      'default': 'Varsayılan',
    },
    'en': {
      'window_title': 'Quick Translate Pro',
      'system_online': 'System Online & Ready',
      'system_offline': 'Offline - Check Connection',
      'checking_connection': 'Checking connection...',
      'source_lang': 'SOURCE LANGUAGE',
      'target_lang': 'TARGET LANGUAGE',
      'active_modes': 'ACTIVE MODES',
      'bubble_mode': 'Bubble Mode (Mouse)',
      'input_mode': 'Input Mode (Keyboard)',
      'clipboard_mode': 'Clipboard Monitor',
      'minimize_tray': 'Minimize to Tray',
      'ui_language': 'INTERFACE LANGUAGE',
      'swap_languages': 'Swap Languages',
      'how_to_use': 'HOW TO USE',
      'bubble_desc': 'Select text in any application → translation bubble appears near the cursor.',
      'input_desc': 'Type in any application, press period/exclamation/enter and the text is automatically replaced with its translation.',
      'clipboard_desc': 'Any text copied to clipboard is automatically translated and shown as a notification.',
      'translating': 'Translating...',
      'hooks_active': 'Hooks Active',
      'api_keys': 'API KEYS',
      'gemini_key': 'Gemini API Key',
      'deepl_key': 'DeepL API Key',
      'optional': 'Optional',
      'save': 'Save',
      'hotkey_settings': 'HOTKEY & TRIGGER SETTINGS',
      'chat_keys': 'Chat Open Keys',
      'trigger_chars': 'Translation Trigger Characters',
      'translation_history': 'Translation History',
      'history_empty': 'No translation history recorded yet',
      'search_history': 'Search history (text, lang, or engine)...',
      'clear_history': 'Clear History',
      'confirm_clear_history': 'Are you sure you want to clear all translation history?',
      'copied_to_clipboard': 'Copied to clipboard!',
      'original': 'Original',
      'translation': 'Translation',
      'engine': 'Engine',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'clear': 'Clear',
      'no_results': 'No matching results found',
      'api_key_saved': 'API key saved successfully.',
      'error_offline': 'No internet connection. Cannot translate.',
      'error_translation_failed': 'Translation engine did not respond or encountered an error.',
      'enter_api_key': 'Enter API Key',
      'active': 'Active',
      'default': 'Default',
    },
  };

  /// Desteklenen diller listesi — (kod, TR ismi, EN ismi, bayrak dosyası)
  static const List<LanguageItem> supportedLanguages = [
    LanguageItem(code: 'auto', nameTr: 'Otomatik Algıla', nameEn: 'Auto Detect', flag: 'auto'),
    LanguageItem(code: 'tr', nameTr: 'Türkçe', nameEn: 'Turkish', flag: 'tr'),
    LanguageItem(code: 'en', nameTr: 'İngilizce', nameEn: 'English', flag: 'en'),
    LanguageItem(code: 'de', nameTr: 'Almanca', nameEn: 'German', flag: 'de'),
    LanguageItem(code: 'fr', nameTr: 'Fransızca', nameEn: 'French', flag: 'fr'),
    LanguageItem(code: 'es', nameTr: 'İspanyolca', nameEn: 'Spanish', flag: 'es'),
    LanguageItem(code: 'it', nameTr: 'İtalyanca', nameEn: 'Italian', flag: 'it'),
    LanguageItem(code: 'ru', nameTr: 'Rusça', nameEn: 'Russian', flag: 'ru'),
    LanguageItem(code: 'ja', nameTr: 'Japonca', nameEn: 'Japanese', flag: 'ja'),
    LanguageItem(code: 'zh-CN', nameTr: 'Çince', nameEn: 'Chinese', flag: 'zh-CN'),
    LanguageItem(code: 'ar', nameTr: 'Arapça', nameEn: 'Arabic', flag: 'ar'),
    LanguageItem(code: 'pt', nameTr: 'Portekizce', nameEn: 'Portuguese', flag: 'pt'),
    LanguageItem(code: 'ko', nameTr: 'Korece', nameEn: 'Korean', flag: 'ko'),
    LanguageItem(code: 'nl', nameTr: 'Felemenkçe', nameEn: 'Dutch', flag: 'nl'),
    LanguageItem(code: 'pl', nameTr: 'Lehçe', nameEn: 'Polish', flag: 'pl'),
    LanguageItem(code: 'hi', nameTr: 'Hintçe', nameEn: 'Hindi', flag: 'hi'),
    LanguageItem(code: 'id', nameTr: 'Endonezce', nameEn: 'Indonesian', flag: 'id'),
    LanguageItem(code: 'uk', nameTr: 'Ukraynaca', nameEn: 'Ukrainian', flag: 'uk'),
    LanguageItem(code: 'el', nameTr: 'Yunanca', nameEn: 'Greek', flag: 'el'),
    LanguageItem(code: 'cs', nameTr: 'Çekçe', nameEn: 'Czech', flag: 'cs'),
    LanguageItem(code: 'sv', nameTr: 'İsveççe', nameEn: 'Swedish', flag: 'sv'),
    LanguageItem(code: 'vi', nameTr: 'Vietnamca', nameEn: 'Vietnamese', flag: 'vi'),
    LanguageItem(code: 'th', nameTr: 'Tayca', nameEn: 'Thai', flag: 'th'),
  ];

  static Map<String, String> getStrings(String uiLang) =>
      strings[uiLang] ?? strings['tr']!;
}

class LanguageItem {
  final String code;
  final String nameTr;
  final String nameEn;
  final String flag;

  const LanguageItem({
    required this.code,
    required this.nameTr,
    required this.nameEn,
    required this.flag,
  });

  String getName(String uiLang) => uiLang == 'tr' ? nameTr : nameEn;
}
