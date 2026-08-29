import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/input_event.dart';
import '../models/replacement_state.dart';
import '../models/translation_request.dart';
import '../services/native/foreground_window_service.dart';
import '../services/native_hook_service.dart';
import 'translation_controller.dart';

class InputModeController extends ChangeNotifier {
  final NativeHookService _hookService;
  final TranslationController _translationController;
  final ForegroundWindowService _foregroundWindowService = ForegroundWindowService();

  ReplacementContext _context = ReplacementContext();
  final StringBuffer _typedBuffer = StringBuffer();
  Timer? _debounceTimer;
  bool _isChatMode = false;
  bool _isExecutingReplacement = false;
  int _extraCharsDuringTranslation = 0;

  ReplacementContext get context => _context;
  bool get isChatMode => _isChatMode;

  InputModeController(this._hookService, this._translationController) {
    _hookService.onKeyPress.listen(_handleKeyPress);
  }

  void _handleKeyPress(KeyPressEvent event) {
    if (_isExecutingReplacement) return;

    final inputEvent = InputEvent(
      source: InputEventSource.lowLevelHook,
      type: event.char.isNotEmpty ? InputEventType.char : InputEventType.keyDown,
      vkCode: event.vkCode,
      scanCode: 0,
      flags: 0,
      char: event.char,
      isAlt: event.isAlt,
      isCtrl: event.isCtrl,
      isShift: event.isShift,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    if (inputEvent.isModifierKey || inputEvent.isAlt || inputEvent.isCtrl) return;

    if (_context.state == ReplacementState.translating) {
      if (inputEvent.char.isNotEmpty || inputEvent.isSpace) {
        _extraCharsDuringTranslation++;
      } else if (inputEvent.isBackspace && _extraCharsDuringTranslation > 0) {
        _extraCharsDuringTranslation--;
      }
      return;
    }

    if (inputEvent.isNavKey || inputEvent.isEscape || inputEvent.isEnter) {
      _resetBuffer();
      return;
    }

    if (inputEvent.isBackspace) {
      _debounceTimer?.cancel();
      final current = _typedBuffer.toString();
      if (current.isNotEmpty) {
        _typedBuffer.clear();
        _typedBuffer.write(current.substring(0, current.length - 1));
      }
      return;
    }

    if (inputEvent.isSpace) {
      final content = _typedBuffer.toString();
      if (content.isNotEmpty) {
        final lastChar = content[content.length - 1];
        if (inputTriggerChars.contains(lastChar)) {
          _typedBuffer.write(' ');
          _startDebounceTimer(_typedBuffer.toString(), true, const AppSettings());
          return;
        }
      }
    }

    if (inputEvent.char.isNotEmpty) {
      _typedBuffer.write(inputEvent.char);
      _debounceTimer?.cancel();

      final currentText = _typedBuffer.toString();
      final lastChar = currentText[currentText.length - 1];

      if (inputTriggerChars.contains(lastChar)) {
        _startDebounceTimer(currentText, false, const AppSettings());
      }
    }
  }

  void _startDebounceTimer(String text, bool immediate, AppSettings settings) {
    _debounceTimer?.cancel();
    if (immediate) {
      _processInputTranslation(text, settings);
    } else {
      _debounceTimer = Timer(inputDebounce, () => _processInputTranslation(text, settings));
    }
  }

  Future<void> _processInputTranslation(String originalText, AppSettings settings) async {
    if (originalText.trim().length < minInputTextLength) return;

    final targetHwnd = _foregroundWindowService.getCurrentForegroundHwnd();
    _extraCharsDuringTranslation = 0;

    _context = ReplacementContext(
      state: ReplacementState.translating,
      originalInput: originalText,
      targetHwnd: targetHwnd,
    );
    notifyListeners();

    try {
      final request = TranslationRequest(
        text: originalText.trim(),
        sourceLanguage: settings.sourceLanguage,
        targetLanguage: settings.targetLanguage,
      );

      final result = await _translationController.translate(request, settings);

      _context = _context.copyWith(state: ReplacementState.validatingTargetWindow);
      notifyListeners();

      if (!_foregroundWindowService.isTargetWindowStillFocused(targetHwnd)) {
        debugPrint('[InputMode] Target window focus lost! Cancelling replacement injection.');
        _context = _context.copyWith(
          state: ReplacementState.cancelled,
          errorMessage: 'Focus changed during translation',
        );
        _resetBuffer();
        notifyListeners();
        return;
      }

      _isExecutingReplacement = true;
      _context = _context.copyWith(
        state: ReplacementState.replacing,
        translatedResult: result.translatedText,
      );
      notifyListeners();

      final deleteCount = originalText.length + _extraCharsDuringTranslation;
      await _hookService.simulateBackspace(deleteCount);
      await _hookService.setClipboardText('${result.translatedText} ');
      await _hookService.simulatePaste();

      _context = _context.copyWith(state: ReplacementState.completed);
      _resetBuffer();
    } catch (e) {
      _context = _context.copyWith(
        state: ReplacementState.failed,
        errorMessage: e.toString(),
      );
      _resetBuffer();
    } finally {
      await Future.delayed(const Duration(milliseconds: 50));
      _isExecutingReplacement = false;
      notifyListeners();
    }
  }

  void _resetBuffer() {
    _typedBuffer.clear();
    _isChatMode = false;
    _extraCharsDuringTranslation = 0;
    _debounceTimer?.cancel();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
