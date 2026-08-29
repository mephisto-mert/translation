/// Ana uygulama state yönetimi — Provider pattern
library;

import 'dart:async';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../constants/app_constants.dart';
import '../constants/app_locales.dart';
import '../services/translation_service.dart';
import '../services/native_hook_service.dart';
import '../services/punctuation_service.dart';
import '../services/settings_service.dart';
import '../services/system_tray_service.dart';
import '../services/translation_history_service.dart';
import '../services/native/foreground_window_service.dart';

typedef _BeepC = Int32 Function(Uint32 dwFreq, Uint32 dwDuration);
typedef _BeepDart = int Function(int dwFreq, int dwDuration);

void _playWindowsBeep(int type) {
  if (kIsWeb) return;
  runZonedGuarded(() async {
    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final beep = kernel32.lookupFunction<_BeepC, _BeepDart>('Beep');
      
      if (type == 1) { // ON: Yükselen iki ses (800Hz -> 1200Hz)
        beep(800, 70);
        await Future.delayed(const Duration(milliseconds: 15));
        beep(1200, 90);
      } else if (type == 0) { // OFF: Düşen iki ses (1000Hz -> 500Hz)
        beep(1000, 70);
        await Future.delayed(const Duration(milliseconds: 15));
        beep(500, 90);
      } else if (type == 2) { // SWAP / CYCLE: İki hızlı tık sesi (700Hz -> 1100Hz)
        beep(700, 50);
        await Future.delayed(const Duration(milliseconds: 10));
        beep(1100, 50);
      }
    } catch (_) { }
  }, (e, s) {});
}

class TranslationProvider extends ChangeNotifier {
  late final NativeHookService _hookService;
  late final SettingsService _settingsService;
  late final SystemTrayService _trayService;
  late final TranslationHistoryService _historyService;

  String _uiLang = AppConstants.defaultUiLang;
  String _sourceLang = AppConstants.defaultSourceLang;
  String _targetLang = AppConstants.defaultTargetLang;

  bool _bubbleMode = true;
  bool _inputMode = true;
  bool _clipboardMode = false;
  bool _isOnline = false;
  bool _hooksActive = false;
  bool _isTranslating = false;
  String? _lastErrorMessage;

  final StringBuffer _typedBuffer = StringBuffer();
  bool _isTypingReplacement = false;
  bool _isExecutingSimulatedKeys = false;
  bool _replacementCancelled = false;
  DateTime _lastTriggerTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastF9ToggleTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _isChatMode = false;

  // F9 global toggle — tüm özellikleri aç/kapat
  bool _allFeaturesActive = true;

  // Çeviri sırasında kullanıcının bastığı ekstra tuş sayısı
  // (OS'e giden ama buffer'a eklenmeyen karakterler)
  int _extraCharsDuringTranslation = 0;
  int _currentRequestId = 0;

  // Timers
  Timer? _statusTimer;
  Timer? _clipboardTimer;
  String _lastClipboardText = '';
  DateTime? _lastTranslationTime;
  static const Duration _clipboardCooldown = Duration(seconds: 2);

  // Hotkey ayarları
  List<int> _chatKeys = [89, 85, 13]; // Y, U, Enter
  Set<String> _triggerChars = {'.', '!', '?', ','};

  // API Keys (Loaded securely from Windows DPAPI)
  String _geminiApiKey = '';
  String _deepLApiKey = '';

  late final ForegroundWindowService _foregroundService;

  TranslationProvider() {
    _hookService = NativeHookService();
    _settingsService = SettingsService();
    _trayService = SystemTrayService();
    _historyService = TranslationHistoryService();
    _foregroundService = ForegroundWindowService();
    _initialize();
  }

  Future<void> _initialize() async {
    await _settingsService.init();
    await _historyService.init();
    await TranslationService.loadCacheFromStorage();
    await _loadSavedSettings();
    if (!kIsWeb) await _trayService.init();
    await checkConnection();
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(AppConstants.statusCheckInterval, (_) => checkConnection());
    if (!kIsWeb) {
      await _startNativeHooks();
      await _registerHotkeys();
    }
  }

  Future<void> _registerHotkeys() async {
    // Alt + DownArrow for cycling target language
    HotKey cycleLangHotKey = HotKey(
      key: PhysicalKeyboardKey.arrowDown,
      modifiers: [HotKeyModifier.alt],
      scope: HotKeyScope.system,
    );
    await hotKeyManager.register(
      cycleLangHotKey,
      keyDownHandler: (hotKey) {
        cycleTargetLanguage();
      },
    );
  }

  Future<void> _loadSavedSettings() async {
    _sourceLang = _settingsService.sourceLang;
    _targetLang = _settingsService.targetLang;
    _uiLang = _settingsService.uiLang;
    _bubbleMode = _settingsService.bubbleMode;
    _inputMode = _settingsService.inputMode;
    _clipboardMode = _settingsService.clipboardMode;
    _chatKeys = _settingsService.chatKeys;
    _triggerChars = _settingsService.triggerChars.toSet();
    _geminiApiKey = await _settingsService.geminiApiKey;
    _deepLApiKey = await _settingsService.deepLApiKey;
    
    // API key'leri translation service'e yükle
    TranslationService.geminiApiKey = _geminiApiKey.isEmpty ? null : _geminiApiKey;
    TranslationService.deepLApiKey = _deepLApiKey.isEmpty ? null : _deepLApiKey;
    
    if (_clipboardMode) _startClipboardMonitor();
    notifyListeners();
  }

  Future<void> _startNativeHooks() async {
    final success = await _hookService.startHooks();
    _hooksActive = success;
    if (success) {
      _hookService.onKeyPress.listen(_handleKeyPress);
      _hookService.onMouseDragEnd.listen(_handleMouseDragEnd);
    }
    notifyListeners();
  }

  void _handleKeyPress(KeyPressEvent event) {
    // F9 = Global toggle — tüm özellikleri aç/kapat (200ms debounce ile)
    if (event.vkCode == VkCodes.f9) {
      final now = DateTime.now();
      if (now.difference(_lastF9ToggleTime) > const Duration(milliseconds: 200)) {
        _lastF9ToggleTime = now;
        _toggleAllFeatures();
      }
      return;
    }
    
    // Tüm özellikler veya input modu kapalıysa işlem yapma
    if (!_allFeaturesActive || !_inputMode) return;
    
    // Kendi simülasyon tuşlarımız (backspace, paste, space) gelirse yok say
    if (_isExecutingSimulatedKeys) return;

    // Çeviri API isteği devam ederken gelen tuşlar (OS'e yazılan ekstra tuşlar)
    if (_isTypingReplacement) {
      if (event.isEscape || event.isEnter || event.isNavKey) {
        _replacementCancelled = true;
      } else if (event.isBackspace) {
        _extraCharsDuringTranslation--;
      } else if (event.char.isNotEmpty) {
        _extraCharsDuringTranslation++;
      }
      return;
    }
    
    // CS2 / In-game Chat Mode tuşları (Y, U, Enter)
    if (_chatKeys.isNotEmpty) {
      if (!_isChatMode) {
        if (_chatKeys.contains(event.vkCode)) {
          _isChatMode = true;
          _typedBuffer.clear();
        }
        return;
      }
      
      if (event.isEscape || event.isEnter) {
        _isChatMode = false;
        _typedBuffer.clear();
        return;
      }
    }
    
    // Navigasyon tuşları buffer'ı temizler
    if (event.isNavKey || event.isEscape) {
      _typedBuffer.clear();
      return;
    }

    // Space tuşu kontrolü (noktalama sonrası space basıldığında çeviriyi tetikle)
    if (event.isSpace) {
      final bufferContent = _typedBuffer.toString();
      if (bufferContent.isNotEmpty) {
        final lastChar = bufferContent[bufferContent.length - 1];
        if (lastChar == '.' || lastChar == '!' || lastChar == '?' || lastChar == ',') {
          final now = DateTime.now();
          if (now.difference(_lastTriggerTime) >= inputDebounce) {
            _lastTriggerTime = now;
            _typedBuffer.clear();
            _processInputTranslation(bufferContent, true);
            return;
          }
        }
      }
    }
    
    // Tetikleyici karakterleri ayarlardan al (., !, ?, comma vb.)
    if (event.char.isNotEmpty && _triggerChars.contains(event.char)) {
      _typedBuffer.write(event.char);
      final text = _typedBuffer.toString();
      if (text.length >= minInputTextLength) {
        final now = DateTime.now();
        if (now.difference(_lastTriggerTime) >= inputDebounce) {
          _lastTriggerTime = now;
          _typedBuffer.clear();
          _processInputTranslation(text, false);
          return;
        }
      }
      return;
    }
    
    // Backspace kontrolü (buffer boşken güvenli işlem)
    if (event.isBackspace) {
      final current = _typedBuffer.toString();
      if (current.isNotEmpty) {
        _typedBuffer.clear();
        _typedBuffer.write(current.substring(0, current.length - 1));
      } else {
        _typedBuffer.clear();
      }
      return;
    }
    
    if (event.char.isNotEmpty) {
      _typedBuffer.write(event.char);
    }
  }

  Future<void> _processInputTranslation(String text, bool deleteExtraSpace) async {
    final targetHwnd = _foregroundService.getCurrentForegroundHwnd();
    final requestId = ++_currentRequestId;
    _isTypingReplacement = true;
    _isExecutingSimulatedKeys = false;
    _replacementCancelled = false;
    _extraCharsDuringTranslation = 0;
    _isTranslating = true;
    notifyListeners();

    try {
      final originalLength = text.length;
      final trimmedText = text.trimLeft();
      final cleanText = trimmedText.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleanText.isEmpty) return;
      
      final result = await TranslationService.translate(
        text: cleanText,
        source: _sourceLang,
        target: _targetLang,
      );
      
      // Stale response & Foreground Window safety check (Section 23: cancel if Alt+Tabbed)
      if (requestId != _currentRequestId ||
          _replacementCancelled ||
          !_allFeaturesActive ||
          !_foregroundService.isTargetWindowStillFocused(targetHwnd)) {
        return;
      }

      // Kullanıcının bekleme süresince yazdığı net ekstra karakter sayısı
      final extraChars = _extraCharsDuringTranslation;

      // Simülasyon moduna geç — gelen kendi hook tuşlarımızı yok sayacağız
      _isExecutingSimulatedKeys = true;

      // Silinecek backspace sayısını hesapla
      int deleteCount = originalLength + extraChars + (deleteExtraSpace ? 1 : 0);
      if (deleteCount < 0) deleteCount = 0;

      if (deleteCount > 0) {
        await _hookService.simulateBackspace(deleteCount);
      }
      
      String finalText = text;
      if (result.text.isNotEmpty && result.text.toLowerCase() != cleanText.toLowerCase()) {
        finalText = PunctuationService.fixPunctuation(result.text.trim(), targetLang: _targetLang);
        await _recordHistoryItem(
          originalText: cleanText,
          translatedText: finalText,
          sourceLang: result.detectedSourceLang ?? _sourceLang,
          targetLang: _targetLang,
          engine: _formatEngineName(result.engine),
        );
      }

      await _hookService.setClipboardText(finalText);
      await Future.delayed(const Duration(milliseconds: 40));
      await _hookService.simulatePaste();
      await Future.delayed(const Duration(milliseconds: 60));

      // Her zaman çeviriden sonra boşluk ekle — cümleler arası kusursuz boşluk
      await _hookService.simulateKeyPress(VkCodes.space);
    } catch (e) {
      _reportError(strings['error_translation_failed'] ?? 'Çeviri motoru yanıt vermedi');
    } finally {
      _lastTranslationTime = DateTime.now();
      _extraCharsDuringTranslation = 0;
      _isExecutingSimulatedKeys = false;
      _replacementCancelled = false;
      _isTypingReplacement = false;
      _isTranslating = false;
      notifyListeners();
    }
  }

  void _handleMouseDragEnd(MouseDragEvent event) {
    if (!_allFeaturesActive || !_bubbleMode) return;
    Future.delayed(bubbleDelay, () => _performBubbleTranslation(event.x, event.y));
  }

  Future<void> _performBubbleTranslation(int x, int y) async {
    try {
      final selectedText = await _hookService.getSelectedText();
      if (selectedText.isEmpty || selectedText.trim().length < minSelectedTextLength) return;
      _isTranslating = true;
      notifyListeners();
      final result = await TranslationService.translate(
        text: selectedText.trim(), source: _sourceLang, target: _targetLang,
      );
      if (result.text.isNotEmpty && result.text.toLowerCase() != selectedText.trim().toLowerCase()) {
        _isOnline = true;
        await _hookService.showNativeBubble(result.text, x, y);
        await _recordHistoryItem(
          originalText: selectedText.trim(),
          translatedText: result.text,
          sourceLang: result.detectedSourceLang ?? _sourceLang,
          targetLang: _targetLang,
          engine: _formatEngineName(result.engine),
        );
      }
    } catch (e) {
      _reportError(strings['error_translation_failed'] ?? 'Çeviri motoru yanıt vermedi');
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════
  // CLIPBOARD MONITOR
  // ═══════════════════════════════════════════════════════

  void _startClipboardMonitor() {
    _stopClipboardMonitor();
    _clipboardTimer = Timer.periodic(AppConstants.clipboardCheckInterval, (_) => _checkClipboard());
  }

  void _stopClipboardMonitor() {
    _clipboardTimer?.cancel();
    _clipboardTimer = null;
  }

  Future<void> _checkClipboard() async {
    if (!_clipboardMode || _isTypingReplacement) return;
    // Son çeviriden 2 saniye geçmeden clipboard kontrol etme
    // — kendi yazdığımız çeviri metnini tekrar çevirmeyelim
    if (_lastTranslationTime != null &&
        DateTime.now().difference(_lastTranslationTime!) < _clipboardCooldown) {
      return;
    }
    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipData?.text?.trim() ?? '';
      
      if (text.isEmpty || 
          text.length < AppConstants.minClipboardTextLength ||
          text == _lastClipboardText) {
        return;
      }
      
      _lastClipboardText = text;
      _translateClipboard(text);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _translateClipboard(String text) async {
    try {
      _isTranslating = true;
      notifyListeners();
      
      final result = await TranslationService.translate(
        text: text,
        source: _sourceLang,
        target: _targetLang,
      );
      
      if (result.text.isNotEmpty && result.text.toLowerCase() != text.toLowerCase()) {
        // Native notification göster (sistem tray üzerinden)
        await _trayService.showNotification(
          title: 'Çeviri',
          message: result.text,
        );
        await _recordHistoryItem(
          originalText: text,
          translatedText: result.text,
          sourceLang: result.detectedSourceLang ?? _sourceLang,
          targetLang: _targetLang,
          engine: _formatEngineName(result.engine),
        );
      }
    } catch (e) {
      _reportError(strings['error_translation_failed'] ?? 'Çeviri motoru yanıt vermedi');
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════
  // API KEY MANAGEMENT
  // ═══════════════════════════════════════════════════════

  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key.trim();
    await _settingsService.setGeminiApiKey(_geminiApiKey);
    TranslationService.geminiApiKey = _geminiApiKey.isEmpty ? null : _geminiApiKey;
    notifyListeners();
  }

  Future<void> setDeepLApiKey(String key) async {
    _deepLApiKey = key.trim();
    await _settingsService.setDeepLApiKey(_deepLApiKey);
    TranslationService.deepLApiKey = _deepLApiKey.isEmpty ? null : _deepLApiKey;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════
  // HOTKEY MANAGEMENT
  // ═══════════════════════════════════════════════════════

  Future<void> setChatKeys(List<int> keys) async {
    _chatKeys = keys;
    await _settingsService.setChatKeys(keys);
    notifyListeners();
  }

  Future<void> setTriggerChars(List<String> chars) async {
    _triggerChars = chars.toSet();
    await _settingsService.setTriggerChars(chars);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════
  // F9 GLOBAL TOGGLE
  // ═══════════════════════════════════════════════════════

  bool get allFeaturesActive => _allFeaturesActive;

  void _toggleAllFeatures() {
    _allFeaturesActive = !_allFeaturesActive;
    if (!_allFeaturesActive) {
      _isChatMode = false;
      _typedBuffer.clear();
      _isTranslating = false;
      _isTypingReplacement = false;
      _isExecutingSimulatedKeys = false;
    }
    notifyListeners();
    _playWindowsBeep(_allFeaturesActive ? 1 : 0);
    if (!kIsWeb) {
      _trayService.showNotification(
        title: 'Quick Trace Pro',
        message: _allFeaturesActive
            ? (_uiLang == 'tr' ? '✅ Tüm Özellikler Aktif' : '✅ All Features Active')
            : (_uiLang == 'tr' ? '⏸️ Tüm Özellikler Duraklatıldı' : '⏸️ All Features Paused'),
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // HISTORY & ERROR HELPERS
  // ═══════════════════════════════════════════════════════

  List<TranslationHistoryItem> get history => _historyService.history;

  List<TranslationHistoryItem> searchHistory(String query) {
    return _historyService.searchHistory(query);
  }

  Future<void> clearHistory() async {
    await _historyService.clearHistory();
    notifyListeners();
  }

  Future<void> removeHistoryItem(String id) async {
    await _historyService.removeItem(id);
    notifyListeners();
  }

  Future<void> _recordHistoryItem({
    required String originalText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
    required String engine,
  }) async {
    await _historyService.addHistory(
      originalText: originalText,
      translatedText: translatedText,
      sourceLang: sourceLang,
      targetLang: targetLang,
      engine: engine,
    );
    notifyListeners();
  }

  String _formatEngineName(TranslationEngine? engine) {
    if (engine == null) return 'Google';
    switch (engine) {
      case TranslationEngine.google:
        return 'Google';
      case TranslationEngine.myMemory:
        return 'MyMemory';
      case TranslationEngine.gemini:
        return 'Gemini AI';
      case TranslationEngine.deepL:
        return 'DeepL';
    }
  }

  String? get lastErrorMessage => _lastErrorMessage;

  void clearLastErrorMessage() {
    _lastErrorMessage = null;
    notifyListeners();
  }

  void _reportError(String message) {
    _lastErrorMessage = message;
    notifyListeners();
    if (!kIsWeb) {
      _trayService.showNotification(
        title: _uiLang == 'tr' ? 'Çeviri Uyarısı' : 'Translation Alert',
        message: message,
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════

  Future<void> minimizeToTray() async { if (!kIsWeb) await _trayService.minimizeToTray(); }
  void hideBubble() { if (!kIsWeb) _hookService.hideNativeBubble(); }

  Future<void> checkConnection() async {
    final wasOnline = _isOnline;
    _isOnline = await TranslationService.checkConnection();
    if (wasOnline && !_isOnline) {
      _reportError(strings['error_offline'] ?? 'İnternet bağlantısı yok.');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _clipboardTimer?.cancel();
    _stopClipboardMonitor();
    if (!kIsWeb) {
      hotKeyManager.unregisterAll();
      _hookService.dispose();
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // GETTERS & TOGGLES
  // ═══════════════════════════════════════════════════════

  String get uiLang => _uiLang;
  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  bool get bubbleMode => _bubbleMode;
  bool get inputMode => _inputMode;
  bool get clipboardMode => _clipboardMode;
  bool get isOnline => _isOnline;
  bool get hooksActive => _hooksActive;
  bool get isTranslating => _isTranslating;
  List<int> get chatKeys => _chatKeys;
  Set<String> get triggerChars => _triggerChars;
  String get geminiApiKey => _geminiApiKey;
  String get deepLApiKey => _deepLApiKey;
  Map<String, String> get strings => AppLocales.strings[_uiLang]!;
  SystemTrayService get trayService => _trayService;

  void toggleUiLanguage() { 
    _uiLang = _uiLang == 'tr' ? 'en' : 'tr'; 
    _settingsService.setUiLang(_uiLang); 
    notifyListeners(); 
  }
  
  void setSourceLanguage(String code) { 
    _sourceLang = code; 
    _settingsService.setSourceLang(code); 
    notifyListeners(); 
  }
  
  void setTargetLanguage(String code) { 
    _targetLang = code; 
    _settingsService.setTargetLang(code); 
    notifyListeners(); 
  }
  
  void toggleBubbleMode() { 
    _bubbleMode = !_bubbleMode; 
    _settingsService.setBubbleMode(_bubbleMode); 
    notifyListeners(); 
  }
  
  void toggleInputMode() { 
    _inputMode = !_inputMode; 
    _settingsService.setInputMode(_inputMode); 
    notifyListeners(); 
  }
  
  void toggleClipboardMode() {
    _clipboardMode = !_clipboardMode;
    _settingsService.setClipboardMode(_clipboardMode);
    if (_clipboardMode) {
      _startClipboardMonitor();
    } else {
      _stopClipboardMonitor();
    }
    notifyListeners();
  }
  
  void swapLanguages() { 
    if (_sourceLang != 'auto') { 
      final temp = _sourceLang; 
      _sourceLang = _targetLang; 
      _targetLang = temp; 
      notifyListeners(); 
      _playWindowsBeep(2);
    } 
  }

  void cycleTargetLanguage() {
    final languages = AppLocales.supportedLanguages.where((lang) => lang.code != 'auto').map((l) => l.code).toList();
    int currentIndex = languages.indexOf(_targetLang);
    if (currentIndex == -1) currentIndex = 0;
    
    int nextIndex = (currentIndex + 1) % languages.length;
    final nextLang = languages[nextIndex];
    setTargetLanguage(nextLang);
    _playWindowsBeep(2);
    
    _trayService.showNotification(
      title: uiLang == 'tr' ? 'Hedef Dil Değişti' : 'Target Language Changed',
      message: AppLocales.supportedLanguages.firstWhere((l) => l.code == nextLang).getName(_uiLang),
    );
  }
}
