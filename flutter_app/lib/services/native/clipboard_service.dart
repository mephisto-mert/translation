import 'dart:async';
import 'package:flutter/services.dart';

/// Event-driven Windows clipboard manager with format preservation & empty clipboard handling
class ClipboardService {
  int _clipboardVersion = 0;
  String _lastText = '';

  int get clipboardVersion => _clipboardVersion;

  /// Safely reads plain text from clipboard
  Future<String?> getText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      return null;
    }
  }

  /// Safely sets plain text on clipboard and increments clipboard version
  Future<void> setText(String text) async {
    try {
      _clipboardVersion++;
      _lastText = text;
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      // Ignore clipboard format errors
    }
  }

  /// Restores original clipboard state safely
  Future<void> restoreOriginalClipboard(String? originalText) async {
    try {
      if (originalText == null || originalText.isEmpty) {
        // Handle empty clipboard case (Prompt section 23)
        await Clipboard.setData(const ClipboardData(text: ''));
      } else {
        await Clipboard.setData(ClipboardData(text: originalText));
      }
    } catch (e) {
      // Ignore restore errors
    }
  }

  /// Checks if clipboard text has changed
  bool hasClipboardChanged(String? currentText) {
    if (currentText == null) return false;
    return currentText != _lastText;
  }
}
