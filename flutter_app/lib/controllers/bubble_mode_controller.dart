import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/translation_request.dart';
import '../services/native_hook_service.dart';
import 'translation_controller.dart';

class BubbleModeController extends ChangeNotifier {
  final NativeHookService _hookService;
  final TranslationController _translationController;
  Timer? _bubbleDelayTimer;
  bool _enabled = true;

  bool get enabled => _enabled;

  BubbleModeController(this._hookService, this._translationController) {
    _hookService.onMouseDragEnd.listen(_onDragEnd);
  }

  void _onDragEnd(MouseDragEvent event) {
    _handleMouseDragEnd(event, const AppSettings());
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    notifyListeners();
  }

  void _handleMouseDragEnd(MouseDragEvent event, AppSettings settings) async {
    if (!_enabled || !settings.enableBubbleMode) return;

    _bubbleDelayTimer?.cancel();
    _bubbleDelayTimer = Timer(const Duration(milliseconds: 200), () async {
      await _hookService.simulateCopy();
      await Future.delayed(const Duration(milliseconds: 50));

      final selectedText = await _hookService.getClipboardText();
      if (selectedText.trim().length < minSelectedTextLength) return;

      try {
        final request = TranslationRequest(
          text: selectedText.trim(),
          sourceLanguage: settings.sourceLanguage,
          targetLanguage: settings.targetLanguage,
        );

        final result = await _translationController.translate(request, settings);
        await _hookService.showBubble(result.translatedText, event.x, event.y);
      } catch (e) {
        debugPrint('[BubbleMode] Translation failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _bubbleDelayTimer?.cancel();
    super.dispose();
  }
}
