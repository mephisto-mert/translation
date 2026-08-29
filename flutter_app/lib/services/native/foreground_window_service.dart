import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:ffi/ffi.dart';

typedef _GetForegroundWindowC = IntPtr Function();
typedef _GetForegroundWindowDart = int Function();

typedef _GetWindowThreadProcessIdC = Uint32 Function(IntPtr hWnd, Pointer<Uint32> lpdwProcessId);
typedef _GetWindowThreadProcessIdDart = int Function(int hWnd, Pointer<Uint32> lpdwProcessId);

/// Service to capture and validate target foreground window identity
class ForegroundWindowService {
  _GetForegroundWindowDart? _getForegroundWindow;
  _GetWindowThreadProcessIdDart? _getWindowThreadProcessId;
  bool _initialized = false;

  ForegroundWindowService() {
    _initFfi();
  }

  void _initFfi() {
    if (kIsWeb) return;
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      _getForegroundWindow = user32
          .lookupFunction<_GetForegroundWindowC, _GetForegroundWindowDart>('GetForegroundWindow');
      _getWindowThreadProcessId = user32.lookupFunction<_GetWindowThreadProcessIdC,
          _GetWindowThreadProcessIdDart>('GetWindowThreadProcessId');
      _initialized = true;
    } catch (e) {
      debugPrint('[ForegroundWindowService] FFI Init Error: $e');
    }
  }

  /// Get active foreground window HWND handle
  int getCurrentForegroundHwnd() {
    if (!_initialized || _getForegroundWindow == null) return 0;
    try {
      return _getForegroundWindow!();
    } catch (e) {
      return 0;
    }
  }

  /// Get active foreground window Process ID
  int getCurrentProcessId() {
    if (!_initialized || _getWindowThreadProcessId == null) return 0;
    final hwnd = getCurrentForegroundHwnd();
    if (hwnd == 0) return 0;

    final pidPtr = calloc<Uint32>();
    try {
      _getWindowThreadProcessId!(hwnd, pidPtr);
      return pidPtr.value;
    } finally {
      calloc.free(pidPtr);
    }
  }

  /// Verifies whether target window is still the active foreground window
  bool isTargetWindowStillFocused(int targetHwnd) {
    if (targetHwnd == 0) return true; // If HWND capture failed, fallback safely
    final currentHwnd = getCurrentForegroundHwnd();
    return currentHwnd == targetHwnd;
  }
}
