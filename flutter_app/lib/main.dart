import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'constants/app_colors.dart';
import 'constants/app_constants.dart';
import 'providers/translation_provider.dart';
import 'widgets/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows pencere ayarları (web'de atla)
  if (!kIsWeb) {
    await hotKeyManager.unregisterAll();
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(
        AppConstants.windowWidth,
        AppConstants.windowHeight,
      ),
      minimumSize: Size(
        AppConstants.windowMinWidth,
        AppConstants.windowMinHeight,
      ),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Quick Trace Pro',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // Pencere kapatıldığında arka planda çalışmaya devam et
      await windowManager.setPreventClose(true);
    });
  }

  runApp(const QuickTranslateApp());
}

class QuickTranslateApp extends StatelessWidget {
  const QuickTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TranslationProvider(),
      child: Consumer<TranslationProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: provider.strings['window_title'] ?? 'Quick Translate Pro',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.bgPrimary,
              textTheme: GoogleFonts.interTextTheme(
                ThemeData.dark().textTheme,
              ),
              colorScheme: const ColorScheme.dark(
                primary: AppColors.accentBlue,
                surface: AppColors.bgPrimary,
              ),
              useMaterial3: true,
            ),
            home: const _AppShell(),
          );
        },
      ),
    );
  }
}

/// Pencere kapanma olayını yakalayan wrapper
class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) windowManager.addListener(this);
  }

  @override
  void dispose() {
    if (!kIsWeb) windowManager.removeListener(this);
    super.dispose();
  }

  /// Pencere kapatılmak istendiğinde — tray'e gönder, çıkma
  @override
  void onWindowClose() async {
    // Pencereyi gizle, arka planda çalışmaya devam et
    await windowManager.hide();
    await windowManager.setSkipTaskbar(true);
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
