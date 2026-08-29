import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/translation_controller.dart';
import '../../models/translation_request.dart';

class ApiProviderSettingsCard extends StatefulWidget {
  const ApiProviderSettingsCard({super.key});

  @override
  State<ApiProviderSettingsCard> createState() => _ApiProviderSettingsCardState();
}

class _ApiProviderSettingsCardState extends State<ApiProviderSettingsCard> {
  final TextEditingController _geminiKeyController = TextEditingController();
  final TextEditingController _deeplKeyController = TextEditingController();

  String _geminiStatus = '';
  String _deeplStatus = '';
  bool _testingGemini = false;
  bool _testingDeepL = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  void _loadKeys() async {
    final settingsCtrl = context.read<SettingsController>();
    final gKey = await settingsCtrl.getGeminiApiKey();
    final dKey = await settingsCtrl.getDeepLApiKey();

    if (mounted) {
      setState(() {
        _geminiKeyController.text = gKey ?? '';
        _deeplKeyController.text = dKey ?? '';
      });
    }
  }

  void _testGeminiConnection() async {
    final key = _geminiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() => _geminiStatus = 'Lütfen bir API anahtarı girin');
      return;
    }

    setState(() {
      _testingGemini = true;
      _geminiStatus = 'Test ediliyor...';
    });

    final settingsCtrl = context.read<SettingsController>();
    final translationCtrl = context.read<TranslationController>();
    await settingsCtrl.setGeminiApiKey(key);
    if (!mounted) return;
    await translationCtrl.reloadCredentials();
    if (!mounted) return;

    try {
      final request = TranslationRequest(
        text: 'hello',
        sourceLanguage: 'en',
        targetLanguage: 'tr',
        preferredEngine: 'gemini',
      );
      final result = await translationCtrl.translate(request, settingsCtrl.settings);

      if (mounted) {
        setState(() {
          _testingGemini = false;
          _geminiStatus = '✓ Bağlantı Başarılı (${result.latency.inMilliseconds}ms)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testingGemini = false;
          _geminiStatus = '✗ Bağlantı Başarısız: $e';
        });
      }
    }
  }

  void _testDeepLConnection() async {
    final key = _deeplKeyController.text.trim();
    if (key.isEmpty) {
      setState(() => _deeplStatus = 'Lütfen bir API anahtarı girin');
      return;
    }

    setState(() {
      _testingDeepL = true;
      _deeplStatus = 'Test ediliyor...';
    });

    final settingsCtrl = context.read<SettingsController>();
    final translationCtrl = context.read<TranslationController>();
    await settingsCtrl.setDeepLApiKey(key);
    if (!mounted) return;
    await translationCtrl.reloadCredentials();
    if (!mounted) return;

    try {
      final request = TranslationRequest(
        text: 'hello',
        sourceLanguage: 'en',
        targetLanguage: 'tr',
        preferredEngine: 'deepl',
      );
      final result = await translationCtrl.translate(request, settingsCtrl.settings);

      if (mounted) {
        setState(() {
          _testingDeepL = false;
          _deeplStatus = '✓ Bağlantı Başarılı (${result.latency.inMilliseconds}ms)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testingDeepL = false;
          _deeplStatus = '✗ Bağlantı Başarısız: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Çeviri Motorları & Güvenli API Depolama (DPAPI)',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gemini Field
          const Text('Google Gemini API Key',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _geminiKeyController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Gemini API Key (e.g. AIza...)',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _testingGemini ? null : _testGeminiConnection,
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: Text(_testingGemini ? 'Test...' : 'Test Et'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          if (_geminiStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _geminiStatus,
                style: TextStyle(
                  color: _geminiStatus.contains('Başarılı')
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // DeepL Field
          const Text('DeepL API Key',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deeplKeyController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx:fx',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _testingDeepL ? null : _testDeepLConnection,
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: Text(_testingDeepL ? 'Test...' : 'Test Et'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          if (_deeplStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _deeplStatus,
                style: TextStyle(
                  color: _deeplStatus.contains('Başarılı')
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
