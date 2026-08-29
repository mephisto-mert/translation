import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'constants/app_colors.dart';
import 'constants/app_constants.dart';
import 'controllers/bubble_mode_controller.dart';
import 'controllers/clipboard_mode_controller.dart';
import 'controllers/history_controller.dart';
import 'controllers/hotkey_controller.dart';
import 'controllers/input_mode_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/translation_controller.dart';
import 'providers/translation_provider.dart';
import 'services/native_hook_service.dart';
import 'widgets/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await hotKeyManager.unregisterAll();
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(AppConstants.windowWidth, AppConstants.windowHeight),
      minimumSize: Size(AppConstants.windowMinWidth, AppConstants.windowMinHeight),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Quick Trace Pro',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });
  }

  final nativeHookService = NativeHookService();
  await nativeHookService.startHooks();

  runApp(QuickTranslateApp(hookService: nativeHookService));
}

class QuickTranslateApp extends StatelessWidget {
  final NativeHookService hookService;

  const QuickTranslateApp({super.key, required this.hookService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NativeHookService>.value(value: hookService),
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => TranslationController()),
        ChangeNotifierProxyProvider<TranslationController, InputModeController>(
          create: (ctx) => InputModeController(
            hookService,
            ctx.read<TranslationController>(),
          ),
          update: (ctx, transCtrl, prev) => prev!,
        ),
        ChangeNotifierProxyProvider<TranslationController, BubbleModeController>(
          create: (ctx) => BubbleModeController(
            hookService,
            ctx.read<TranslationController>(),
          ),
          update: (ctx, transCtrl, prev) => prev!,
        ),
        ChangeNotifierProxyProvider<TranslationController, ClipboardModeController>(
          create: (ctx) => ClipboardModeController(
            hookService,
            ctx.read<TranslationController>(),
          ),
          update: (ctx, transCtrl, prev) => prev!,
        ),
        ChangeNotifierProvider(create: (_) => HotkeyController()),
        ChangeNotifierProvider(create: (_) => HistoryController()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
      ],
      child: MaterialApp(
        title: 'Quick Trace Pro',
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
      ),
    );
  }
}

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

  @override
  void onWindowClose() async {
    await windowManager.hide();
    await windowManager.setSkipTaskbar(true);
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
