import 'package:flutter/foundation.dart';

enum InputEventSource {
  lowLevelHook,
  rawInput,
  simulated,
}

enum InputEventType {
  keyDown,
  keyUp,
  char,
}

@immutable
class InputEvent {
  final InputEventSource source;
  final InputEventType type;
  final int vkCode;
  final int scanCode;
  final int flags;
  final String char;
  final bool isAlt;
  final bool isCtrl;
  final bool isShift;
  final int timestamp;

  const InputEvent({
    required this.source,
    required this.type,
    required this.vkCode,
    required this.scanCode,
    required this.flags,
    required this.char,
    this.isAlt = false,
    this.isCtrl = false,
    this.isShift = false,
    required this.timestamp,
  });

  bool get isModifierKey =>
      vkCode == 0x10 || // Shift
      vkCode == 0x11 || // Ctrl
      vkCode == 0x12 || // Alt
      vkCode == 0xA0 || // LShift
      vkCode == 0xA1 || // RShift
      vkCode == 0xA2 || // LCtrl
      vkCode == 0xA3 || // RCtrl
      vkCode == 0xA4 || // LAlt
      vkCode == 0xA5;   // RAlt

  bool get isBackspace => vkCode == 0x08;
  bool get isEnter => vkCode == 0x0D;
  bool get isSpace => vkCode == 0x20;
  bool get isEscape => vkCode == 0x1B;
  bool get isNavKey =>
      vkCode >= 0x21 && vkCode <= 0x28 || // PageUp/Down, End, Home, Left, Up, Right, Down
      vkCode == 0x2E;                     // Delete

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InputEvent &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          type == other.type &&
          vkCode == other.vkCode &&
          scanCode == other.scanCode &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      source.hashCode ^ type.hashCode ^ vkCode.hashCode ^ scanCode.hashCode ^ timestamp.hashCode;
}
