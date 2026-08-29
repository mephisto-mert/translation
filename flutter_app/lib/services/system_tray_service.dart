/// System Tray yönetim servisi
///
/// Uygulama tray'e minimize edildiğinde ikon gösterir,
/// sağ tık menüsü ile geri açma/çıkış sağlar.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

/// System tray menü öğeleri için sabitler
class _TrayLabels {
  _TrayLabels._();
  static const String appTitle = 'QuickTrace';
  static const String showWindow = 'Göster / Show';
  static const String quit = 'Çıkış / Quit';
}

class SystemTrayService {
  final SystemTray _tray = SystemTray();
  bool _isInitialized = false;

  /// System tray'i başlat
  Future<void> init() async {
    if (kIsWeb || !Platform.isWindows) return;
    if (_isInitialized) return;

    // Exe'nin bulunduğu klasörden ikon yolunu belirle
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    // Windows exe'nin yanındaki data/flutter_assets klasöründe arayabiliriz
    // veya exe'nin kendisini kullanabiliriz
    // system_tray paketi .ico dosyası bekler
    final iconPath = '$exeDir\\app_icon.ico';

    // Varsayılan ikon dosyasını kontrol et
    final iconFile = File(iconPath);
    final finalIconPath = iconFile.existsSync() ? iconPath : '';

    try {
      await _tray.initSystemTray(
        title: _TrayLabels.appTitle,
        iconPath: finalIconPath,
        toolTip: _TrayLabels.appTitle,
      );

      // Menü oluştur
      final menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(
          label: _TrayLabels.showWindow,
          onClicked: (_) => _showWindow(),
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: _TrayLabels.quit,
          onClicked: (_) => _quitApp(),
        ),
      ]);
      await _tray.setContextMenu(menu);

      // Tray ikonuna tıklama — menü aç
      _tray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          _showWindow();
        } else if (eventName == kSystemTrayEventRightClick) {
          _tray.popUpContextMenu();
        }
      });

      _isInitialized = true;
    } catch (_) {
      // Tray başlatılamazsa uygulamanın çalışmasını engelleme
    }
  }

  /// Pencereyi tray'e gönder
  Future<void> minimizeToTray() async {
    if (kIsWeb || !Platform.isWindows) return;
    await windowManager.hide();
  }

  /// Windows notification göster (Clipboard çevirileri için)
  Future<void> showNotification({
    required String title,
    required String message,
  }) async {
    if (kIsWeb || !Platform.isWindows) return;
    if (!_isInitialized) return;
    
    try {
      // system_tray paketi ile notification göster
      // Not: Bazı Windows sürümlerinde çalışmayabilir
      await _tray.setSystemTrayInfo(
        title: title,
        toolTip: message.length > 64 ? '${message.substring(0, 61)}...' : message,
      );
    } catch (_) {
      // ignore — notification başarısız olsa bile app çalışmaya devam eder
    }
  }

  /// Pencereyi geri getir
  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setSkipTaskbar(false);
  }

  /// Uygulamayı tamamen kapat
  Future<void> _quitApp() async {
    try {
      await _tray.destroy();
    } catch (_) {
      // ignore
    }
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  void dispose() {
    if (_isInitialized) {
      try {
        _tray.destroy();
      } catch (_) {
        // ignore
      }
    }
  }
}
