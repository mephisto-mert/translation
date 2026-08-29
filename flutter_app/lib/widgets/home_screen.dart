/// Ana kontrol paneli — ayarlar, çeviri geçmişi ve durum yönetimi
/// Uygulama içinde çeviri YAPILMAZ, global hook'lar ile sistem genelinde çalışır.
/// Bubble Mode tooltip'i overlay olarak gösterilir.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:window_manager/window_manager.dart';
import '../constants/app_colors.dart';
import '../providers/translation_provider.dart';
import '../services/translation_history_service.dart';
import '../widgets/setting_card.dart';
import '../widgets/language_selector.dart';
import '../widgets/settings/api_provider_settings_card.dart';
import '../widgets/settings/gaming_glossary_settings_card.dart';
import '../widgets/settings/privacy_settings_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _geminiController;
  late final TextEditingController _deepLController;
  bool _showGeminiKey = false;
  bool _showDeepLKey = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TranslationProvider>(context, listen: false);
    _geminiController = TextEditingController(text: provider.geminiApiKey);
    _deepLController = TextEditingController(text: provider.deepLApiKey);
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _deepLController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, _) {
        final s = provider.strings;

        // Hata mesajı kontrolü ve bildirim Snackbar'ı
        if (provider.lastErrorMessage != null) {
          final errMsg = provider.lastErrorMessage!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errMsg, style: const TextStyle(color: Colors.white))),
                  ],
                ),
                backgroundColor: AppColors.accentRed,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
            provider.clearLastErrorMessage();
          });
        }

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: SafeArea(
            child: Stack(
              children: [
                // ========= ANA İÇERİK =========
                _buildMainContent(context, provider, s),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
      BuildContext context, TranslationProvider provider, Map<String, String> s) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ========= CUSTOM TITLE BAR (drag area) =========
          if (!kIsWeb && Platform.isWindows) _buildCustomTitleBar(provider),

          // ========= HEADER =========
          _buildHeader(provider, s),

          const SizedBox(height: 16),

          // ========= STATUS BAR =========
          _buildStatusBar(provider, s)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.1, end: 0),

          const SizedBox(height: 20),

          // ========= İÇERİK (scrollable) =========
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ========= DİL SEÇİCİLER =========
                  _buildLanguageSelectors(provider, s)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // ========= MOD AYARLARI =========
                  _buildModeSettings(provider, s)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // ========= API ANAHTARI AYARLARI =========
                  _buildApiKeySettings(provider, s)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 250.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // ========= KISAYOL AYARLARI =========
                  _buildHotkeySettings(provider, s)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 280.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // ========= MOD AÇIKLAMALARI =========
                  _buildModeDescriptions(provider, s)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 16),

                  // ========= GÜVENLİ API VE MOTOR SEÇİMİ =========
                  const ApiProviderSettingsCard(),

                  const SizedBox(height: 16),

                  // ========= GAMING GLOSSARY =========
                  const GamingGlossarySettingsCard(),

                  const SizedBox(height: 16),

                  // ========= GİZLİLİK VE ÖNBELLİK =========
                  const PrivacySettingsCard(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ========= ALT BUTON =========
          _buildMinimizeButton(provider, s)
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms),
        ],
      ),
    );
  }

  // ───────────────────── CUSTOM TITLE BAR ─────────────────────

  Widget _buildCustomTitleBar(TranslationProvider provider) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 32,
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Spacer(),
            // Minimize
            _TitleBarButton(
              icon: Icons.remove_rounded,
              onTap: () => windowManager.minimize(),
              hoverColor: AppColors.bgButtonHover,
            ),
            const SizedBox(width: 4),
            // Maximize / Restore
            _TitleBarButton(
              icon: Icons.crop_square_rounded,
              onTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              hoverColor: AppColors.bgButtonHover,
            ),
            const SizedBox(width: 4),
            // Close → tray'e gönder
            _TitleBarButton(
              icon: Icons.close_rounded,
              onTap: () => provider.minimizeToTray(),
              hoverColor: AppColors.accentRed,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── HEADER ─────────────────────

  Widget _buildHeader(TranslationProvider provider, Map<String, String> s) {
    return Row(
      children: [
        const Text(
          'Quick Trace',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentBlue, Color(0xFF6366f1)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'PRO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),
        const Spacer(),
        // Hook durumu göstergesi
        _buildHookIndicator(provider),
        const SizedBox(width: 8),
        // Geçmiş Butonu
        Material(
          color: AppColors.bgButton,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showHistoryDialog(context, provider),
            hoverColor: AppColors.bgButtonHover,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded, size: 16, color: AppColors.accentBlue),
                  const SizedBox(width: 6),
                  Text(
                    '${provider.history.length}',
                    style: const TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // UI dil butonu
        Material(
          color: AppColors.bgButton,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: provider.toggleUiLanguage,
            hoverColor: AppColors.bgButtonHover,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                provider.uiLang == 'tr' ? 'TR 🇹🇷' : 'EN 🇺🇸',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHookIndicator(TranslationProvider provider) {
    if (!provider.hooksActive) return const SizedBox.shrink();

    final isTranslating = provider.isTranslating;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isTranslating ? AppColors.accentYellow : AppColors.accentGreen)
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isTranslating ? AppColors.accentYellow : AppColors.accentGreen)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isTranslating ? AppColors.accentYellow : AppColors.accentGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isTranslating ? AppColors.accentYellow : AppColors.accentGreen)
                      .withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isTranslating ? '⚡' : '✓',
            style: TextStyle(
              fontSize: 10,
              color: isTranslating ? AppColors.accentYellow : AppColors.accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── STATUS BAR ─────────────────────

  Widget _buildStatusBar(TranslationProvider provider, Map<String, String> s) {
    final isOnline = provider.isOnline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOnline
              ? AppColors.accentGreen.withOpacity(0.3)
              : AppColors.accentRed.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.accentGreen : AppColors.accentRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isOnline ? AppColors.accentGreen : AppColors.accentRed)
                      .withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isOnline ? s['system_online']! : s['system_offline']!,
            style: TextStyle(
              color: isOnline ? AppColors.accentGreen : AppColors.accentRed,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (provider.hooksActive)
            Text(
              provider.isTranslating
                  ? (s['translating'] ?? 'Çevriliyor...')
                  : (s['hooks_active'] ?? 'Hook\'lar Aktif'),
              style: TextStyle(
                color: provider.isTranslating
                    ? AppColors.accentYellow
                    : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────── DİL SEÇİCİLER ─────────────────────

  Widget _buildLanguageSelectors(
      TranslationProvider provider, Map<String, String> s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SettingCard(
            title: s['source_lang']!,
            child: LanguageSelectorWidget(
              selectedCode: provider.sourceLang,
              uiLang: provider.uiLang,
              onChanged: provider.setSourceLanguage,
              showAutoDetect: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 38),
          child: IconButton(
            onPressed:
                provider.sourceLang != 'auto' ? provider.swapLanguages : null,
            icon: Icon(
              Icons.swap_horiz_rounded,
              color: provider.sourceLang != 'auto'
                  ? AppColors.accentBlue
                  : AppColors.textMuted.withOpacity(0.3),
            ),
            tooltip: s['swap_languages'],
          ),
        ),
        Expanded(
          child: SettingCard(
            title: s['target_lang']!,
            child: LanguageSelectorWidget(
              selectedCode: provider.targetLang,
              uiLang: provider.uiLang,
              onChanged: provider.setTargetLanguage,
              showAutoDetect: false,
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────── MOD AYARLARI ─────────────────────

  Widget _buildModeSettings(
      TranslationProvider provider, Map<String, String> s) {
    return SettingCard(
      title: s['active_modes']!,
      child: Column(
        children: [
          _ModeSwitch(
            label: s['bubble_mode']!,
            value: provider.bubbleMode,
            onChanged: (_) => provider.toggleBubbleMode(),
            activeColor: AppColors.accentBlue,
            icon: Icons.bubble_chart_rounded,
          ),
          const SizedBox(height: 6),
          _ModeSwitch(
            label: s['input_mode']!,
            value: provider.inputMode,
            onChanged: (_) => provider.toggleInputMode(),
            activeColor: AppColors.accentGreen,
            icon: Icons.keyboard_rounded,
          ),
          const SizedBox(height: 6),
          _ModeSwitch(
            label: s['clipboard_mode']!,
            value: provider.clipboardMode,
            onChanged: (_) => provider.toggleClipboardMode(),
            activeColor: AppColors.accentYellow,
            icon: Icons.content_paste_rounded,
          ),
        ],
      ),
    );
  }

  // ───────────────────── API ANAHTARLARI AYARLARI ─────────────────────

  Widget _buildApiKeySettings(TranslationProvider provider, Map<String, String> s) {
    return SettingCard(
      title: s['api_keys']!,
      child: Column(
        children: [
          // Gemini API Key
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accentBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s['gemini_key']!,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (provider.geminiApiKey.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s['active']!,
                    style: const TextStyle(color: AppColors.accentGreen, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _geminiController,
                  obscureText: !_showGeminiKey,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: s['enter_api_key'],
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.bgButton,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_showGeminiKey ? Icons.visibility_off : Icons.visibility, size: 16, color: AppColors.textMuted),
                      onPressed: () => setState(() => _showGeminiKey = !_showGeminiKey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  provider.setGeminiApiKey(_geminiController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s['api_key_saved']!),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.accentGreen,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(s['save']!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          // DeepL API Key
          Row(
            children: [
              const Icon(Icons.translate, color: AppColors.accentYellow, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s['deepl_key']!,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (provider.deepLApiKey.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s['active']!,
                    style: const TextStyle(color: AppColors.accentGreen, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deepLController,
                  obscureText: !_showDeepLKey,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: s['enter_api_key'],
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.bgButton,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_showDeepLKey ? Icons.visibility_off : Icons.visibility, size: 16, color: AppColors.textMuted),
                      onPressed: () => setState(() => _showDeepLKey = !_showDeepLKey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  provider.setDeepLApiKey(_deepLController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s['api_key_saved']!),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.accentGreen,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(s['save']!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────── KISAYOL AYARLARI ─────────────────────

  Widget _buildHotkeySettings(TranslationProvider provider, Map<String, String> s) {
    return SettingCard(
      title: s['hotkey_settings']!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.keyboard_outlined, color: AppColors.accentBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                s['chat_keys']!,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: const [
              Chip(
                label: Text('Y', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                backgroundColor: AppColors.bgButton,
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text('U', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                backgroundColor: AppColors.bgButton,
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text('Enter', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                backgroundColor: AppColors.bgButton,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.interests_rounded, color: AppColors.accentGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                s['trigger_chars']!,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: provider.triggerChars.map((char) {
              return Chip(
                label: Text(char, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                backgroundColor: AppColors.accentGreen.withOpacity(0.15),
                side: BorderSide(color: AppColors.accentGreen.withOpacity(0.3)),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ───────────────────── MOD AÇIKLAMALARI ─────────────────────

  Widget _buildModeDescriptions(
      TranslationProvider provider, Map<String, String> s) {
    return SettingCard(
      title: s['how_to_use'] ?? 'Nasıl Kullanılır',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HintRow(
            icon: Icons.bubble_chart_rounded,
            color: AppColors.accentBlue,
            title: s['bubble_mode']!,
            description: s['bubble_desc'] ?? '',
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          _HintRow(
            icon: Icons.keyboard_rounded,
            color: AppColors.accentGreen,
            title: s['input_mode']!,
            description: s['input_desc'] ?? '',
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          _HintRow(
            icon: Icons.content_paste_rounded,
            color: AppColors.accentYellow,
            title: s['clipboard_mode']!,
            description: s['clipboard_desc'] ?? '',
          ),
        ],
      ),
    );
  }

  // ───────────────────── ALT BUTON ─────────────────────

  Widget _buildMinimizeButton(TranslationProvider provider, Map<String, String> s) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => provider.minimizeToTray(),
        icon: const Icon(Icons.minimize_rounded, size: 18),
        label: Text(s['minimize_tray']!),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, TranslationProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _TranslationHistoryModal(provider: provider);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// TRANSLATION HISTORY MODAL
// ═══════════════════════════════════════════════════════

class _TranslationHistoryModal extends StatefulWidget {
  final TranslationProvider provider;

  const _TranslationHistoryModal({required this.provider});

  @override
  State<_TranslationHistoryModal> createState() => _TranslationHistoryModalState();
}

class _TranslationHistoryModalState extends State<_TranslationHistoryModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.provider.strings;
    final items = widget.provider.searchHistory(_searchQuery);

    return Dialog(
      backgroundColor: AppColors.bgPrimary,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Container(
        width: 600,
        height: 540,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // HEADER
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppColors.accentBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  s['translation_history'] ?? 'Çeviri Geçmişi',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgButton,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} / ${TranslationHistoryService.maxHistoryCount}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
                const Spacer(),
                if (widget.provider.history.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.bgCard,
                          title: Text(
                            s['clear_history']!,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                          ),
                          content: Text(
                            s['confirm_clear_history']!,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(s['cancel']!, style: const TextStyle(color: AppColors.textMuted)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(s['clear']!, style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await widget.provider.clearHistory();
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: AppColors.accentRed),
                    label: Text(
                      s['clear_history']!,
                      style: const TextStyle(color: AppColors.accentRed, fontSize: 12),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // SEARCH BAR
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: s['search_history'],
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgCard,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ITEMS LIST
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 48,
                            color: AppColors.textMuted.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? s['no_results']! : s['history_empty']!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _HistoryItemCard(
                          item: item,
                          onDelete: () async {
                            await widget.provider.removeHistoryItem(item.id);
                            setState(() {});
                          },
                          s: s,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final TranslationHistoryItem item;
  final VoidCallback onDelete;
  final Map<String, String> s;

  const _HistoryItemCard({
    required this.item,
    required this.onDelete,
    required this.s,
  });

  Color _getEngineColor(String engine) {
    final lower = engine.toLowerCase();
    if (lower.contains('gemini')) return const Color(0xFF8b5cf6);
    if (lower.contains('deepl')) return AppColors.accentGreen;
    if (lower.contains('mymemory')) return AppColors.accentYellow;
    return AppColors.accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info row
          Row(
            children: [
              // Lang badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgButton,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.sourceLang.toUpperCase()} → ${item.targetLang.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Engine badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getEngineColor(item.engine).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getEngineColor(item.engine).withOpacity(0.3)),
                ),
                child: Text(
                  item.engine,
                  style: TextStyle(
                    color: _getEngineColor(item.engine),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Original text
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  item.originalText,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  maxLines: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                tooltip: s['copied_to_clipboard'],
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: item.originalText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s['copied_to_clipboard']!),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppColors.accentBlue,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Translated text
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  item.translatedText,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.accentBlue),
                tooltip: s['copied_to_clipboard'],
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: item.translatedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s['copied_to_clipboard']!),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppColors.accentBlue,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// TITLE BAR BUTTON
// ═══════════════════════════════════════════════════════

class _TitleBarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;

  const _TitleBarButton({
    required this.icon,
    required this.onTap,
    required this.hoverColor,
  });

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// YARDIMCI WİDGET'LAR
// ═══════════════════════════════════════════════════════

class _ModeSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final IconData icon;

  const _ModeSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: value ? activeColor : AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: value ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: activeColor,
                activeTrackColor: activeColor.withOpacity(0.3),
                inactiveThumbColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.bgButton,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _HintRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.8),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
