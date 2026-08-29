import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/translation_request.dart';
import '../services/native/clipboard_service.dart';
import '../services/native_hook_service.dart';
import 'translation_controller.dart';

class ClipboardModeController extends ChangeNotifier {
  final ClipboardService _clipboardService = ClipboardService();
  final NativeHookService _hookService;
  final TranslationController _translationController;

  Timer? _clipboardTimer;
  String _lastProcessedText = '';
  bool _enabled = true;

  bool get enabled => _enabled;

  ClipboardModeController(this._hookService, this._translationController) {
    _startMonitoring();
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (_enabled) {
      _startMonitoring();
    } else {
      _stopMonitoring();
    }
    notifyListeners();
  }

  void _startMonitoring() {
    _stopMonitoring();
    _clipboardTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) => _checkClipboard(const AppSettings()));
  }

  void _stopMonitoring() {
    _clipboardTimer?.cancel();
    _clipboardTimer = null;
  }

  Future<void> _checkClipboard(AppSettings settings) async {
    if (!_enabled || !settings.enableClipboardMode) return;

    final currentText = await _clipboardService.getText();
    if (currentText == null || currentText.trim().isEmpty) return;

    final trimmed = currentText.trim();
    if (trimmed == _lastProcessedText || trimmed.length < minSelectedTextLength) return;

    _lastProcessedText = trimmed;

    try {
      final request = TranslationRequest(
        text: trimmed,
        sourceLanguage: settings.sourceLanguage,
        targetLanguage: settings.targetLanguage,
      );

      final result = await _translationController.translate(request, settings);
      final mousePos = await _hookService.getMousePosition();
      await _hookService.showBubble(
          result.translatedText, mousePos['x'] ?? 100, mousePos['y'] ?? 100);
    } catch (e) {
      debugPrint('[ClipboardMode] Translation error: $e');
    }
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }
}
