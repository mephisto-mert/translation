/// Native Windows hook'ları ile iletişim servisi
///
/// Method Channel üzerinden C++ tarafındaki global klavye/fare
/// hook'larını kontrol eder ve eventleri dinler.
///
/// Mimari: Hook'lar ayrı C++ thread'de çalışır, event'ler thread-safe
/// queue'da birikir. Dart tarafı Timer ile pollEvents çağırarak
/// queue'dan okur. Bu sayede CS2 gibi fullscreen oyunlarda bile çalışır.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Win32 Virtual Key kodları
class VkCodes {
  VkCodes._();
  static const int backspace = 0x08;
  static const int tab = 0x09;
  static const int enter = 0x0D;
  static const int escape = 0x1B;
  static const int space = 0x20;
  static const int left = 0x25;
  static const int up = 0x26;
  static const int right = 0x27;
  static const int down = 0x28;
  static const int home = 0x24;
  static const int end = 0x23;
  static const int delete = 0x2E;
  static const int f9 = 0x78;
  static const int keyY = 0x59;
  static const int keyU = 0x55;
}

/// Input modunda çeviriyi tetikleyen karakterler
const Set<String> inputTriggerChars = {'.', '!', '?', ','};

/// Minimum çeviri uzunlukları
const int minInputTextLength = 3;
const int minSelectedTextLength = 2;

/// Debounce süreleri
const Duration inputDebounce = Duration(milliseconds: 300);
const Duration bubbleDelay = Duration(milliseconds: 200);

/// Polling interval — 10ms ile ultra-düşük gecikmeli event polling
const Duration pollInterval = Duration(milliseconds: 10);

/// Navigasyon tuşları — buffer'ı temizler
const Set<int> navKeys = {
  VkCodes.left,
  VkCodes.right,
  VkCodes.up,
  VkCodes.down,
  VkCodes.home,
  VkCodes.end,
  VkCodes.delete,
};

/// Event tip sabitler (C++ ile eşleşmeli)
const String kEventTypeKey = 'key';
const String kEventTypeMouse = 'mouse';

class NativeHookService {
  static const _channel = MethodChannel('com.quicktrace/native_hooks');

  // ── Event controller'ları ──
  final _keyPressController = StreamController<KeyPressEvent>.broadcast();
  final _mouseDragEndController = StreamController<MouseDragEvent>.broadcast();

  // ── Streams ──
  Stream<KeyPressEvent> get onKeyPress => _keyPressController.stream;
  Stream<MouseDragEvent> get onMouseDragEnd => _mouseDragEndController.stream;

  bool _isListening = false;
  bool _isPolling = false;
  Timer? _pollTimer;

  NativeHookService();

  // ═══════════════════════════════════════════════════════
  // POLLING — CS2 fullscreen dahil her durumda çalışır
  // ═══════════════════════════════════════════════════════

  /// C++ queue'dan event'leri çeker ve stream'lere yayar
  Future<void> _pollEvents() async {
    if (!_isListening || _isPolling) return;
    _isPolling = true;
    try {
      final result = await _channel.invokeMethod<List>('pollEvents');
      if (result == null || result.isEmpty) return;

      for (final item in result) {
        final event = Map<String, dynamic>.from(item as Map);
        final type = event['type'] as String?;

        if (type == kEventTypeKey) {
          _keyPressController.add(KeyPressEvent(
            vkCode: event['vkCode'] as int,
            char: event['char'] as String? ?? '',
          ));
        } else if (type == kEventTypeMouse) {
          _mouseDragEndController.add(MouseDragEvent(
            x: event['x'] as int,
            y: event['y'] as int,
            distance: (event['distance'] as num).toDouble(),
          ));
        }
      }
    } on PlatformException {
      // ignore — CS2 odaklıyken bile problem olmaz
    } finally {
      _isPolling = false;
    }
  }

  /// Polling timer'ı başlat
  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollEvents());
  }

  /// Polling timer'ı durdur
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ═══════════════════════════════════════════════════════
  // HOOK KONTROL
  // ═══════════════════════════════════════════════════════

  /// Global hook'ları başlat + polling başlat
  Future<bool> startHooks() async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('startHooks');
      _isListening = result ?? false;
      if (_isListening) {
        _startPolling();
      }
      return _isListening;
    } on PlatformException {
      return false;
    }
  }

  /// Global hook'ları durdur + polling durdur
  Future<void> stopHooks() async {
    if (kIsWeb) return;
    _stopPolling();
    try {
      await _channel.invokeMethod<bool>('stopHooks');
      _isListening = false;
    } on PlatformException {
      // ignore
    }
  }

  bool get isListening => _isListening;

  // ═══════════════════════════════════════════════════════
  // CLIPBOARD
  // ═══════════════════════════════════════════════════════

  /// Clipboard'dan metin al
  Future<String> getClipboardText() async {
    if (kIsWeb) return '';
    try {
      final text = await _channel.invokeMethod<String>('getClipboardText');
      return text ?? '';
    } on PlatformException {
      return '';
    }
  }

  /// Clipboard'a metin yaz
  Future<void> setClipboardText(String text) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('setClipboardText', text);
    } on PlatformException {
      // ignore
    }
  }

  // ═══════════════════════════════════════════════════════
  // INPUT SIMULATION
  // ═══════════════════════════════════════════════════════

  /// N adet backspace gönder
  Future<void> simulateBackspace(int count) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('simulateBackspace', count);
    } on PlatformException {
      // ignore
    }
  }

  /// Ctrl+V yapıştır
  Future<void> simulatePaste() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('simulatePaste');
    } on PlatformException {
      // ignore
    }
  }

  /// Ctrl+C simüle et (kopyala)
  Future<void> simulateCopy() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('simulateCopy');
    } on PlatformException {
      // ignore
    }
  }

  /// Tek bir tuş simüle et
  Future<void> simulateKeyPress(int vkCode) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('simulateKeyPress', vkCode);
    } on PlatformException {
      // ignore
    }
  }

  /// Seçili metni clipboard üzerinden al (Ctrl+C simüle ederek)
  Future<String> getSelectedText() async {
    if (kIsWeb) return '';
    try {
      // Mevcut clipboard'u yedekle
      final oldClip = await getClipboardText();

      // Ctrl+C simüle et (C++ tarafında özel fonksiyon)
      await simulateCopy();
      await Future.delayed(const Duration(milliseconds: 150));

      final newClip = await getClipboardText();

      // Eğer clipboard değişmediyse seçim yok
      if (newClip == oldClip) return '';

      // Eski clipboard'u geri yükle
      if (oldClip.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 50));
        await setClipboardText(oldClip);
      }

      return newClip;
    } on PlatformException {
      return '';
    }
  }

  // ═══════════════════════════════════════════════════════
  // NATIVE BUBBLE TOOLTIP
  // ═══════════════════════════════════════════════════════

  /// Ekranda native Win32 tooltip penceresi göster
  Future<void> showNativeBubble(String text, int x, int y) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('showBubble', {
        'text': text,
        'x': x,
        'y': y,
      });
    } on PlatformException {
      // ignore
    }
  }

  /// Native bubble tooltip'i kapat
  Future<void> hideNativeBubble() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('hideBubble');
    } on PlatformException {
      // ignore
    }
  }

  /// Temizle
  void dispose() {
    _stopPolling();
    hideNativeBubble();
    stopHooks();
    _keyPressController.close();
    _mouseDragEndController.close();
  }
}

// ═══════════════════════════════════════════════════════
// EVENT MODELLER
// ═══════════════════════════════════════════════════════

class KeyPressEvent {
  final int vkCode;
  final String char;

  const KeyPressEvent({
    required this.vkCode,
    required this.char,
  });

  bool get isEnter => vkCode == VkCodes.enter;
  bool get isBackspace => vkCode == VkCodes.backspace;
  bool get isSpace => vkCode == VkCodes.space;
  bool get isEscape => vkCode == VkCodes.escape;
  bool get isTab => vkCode == VkCodes.tab;
  bool get isDelete => vkCode == VkCodes.delete;
  bool get isNavKey => navKeys.contains(vkCode);
  bool get isTriggerChar => char.isNotEmpty && inputTriggerChars.contains(char);
}

class MouseDragEvent {
  final int x;
  final int y;
  final double distance;

  const MouseDragEvent({
    required this.x,
    required this.y,
    required this.distance,
  });
}
