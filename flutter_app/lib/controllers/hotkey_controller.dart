import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyController extends ChangeNotifier {
  bool _f9Enabled = true;

  bool get f9Enabled => _f9Enabled;

  HotkeyController() {
    _registerDefaultHotkeys();
  }

  void _registerDefaultHotkeys() async {
    if (kIsWeb) return;
    try {
      await hotKeyManager.unregisterAll();

      final f9Key = HotKey(
        key: PhysicalKeyboardKey.f9,
        scope: HotKeyScope.system,
      );

      await hotKeyManager.register(
        f9Key,
        keyDownHandler: (hotKey) {
          toggleGlobalStatus();
        },
      );
    } catch (e) {
      debugPrint('[HotkeyController] Hotkey registration error: $e');
    }
  }

  void toggleGlobalStatus() {
    _f9Enabled = !_f9Enabled;
    notifyListeners();
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      hotKeyManager.unregisterAll();
    }
    super.dispose();
  }
}
