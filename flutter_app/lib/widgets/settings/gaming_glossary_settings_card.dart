import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/translation_controller.dart';

class GamingGlossarySettingsCard extends StatefulWidget {
  const GamingGlossarySettingsCard({super.key});

  @override
  State<GamingGlossarySettingsCard> createState() => _GamingGlossarySettingsCardState();
}

class _GamingGlossarySettingsCardState extends State<GamingGlossarySettingsCard> {
  final TextEditingController _termController = TextEditingController();
  final TextEditingController _translationController = TextEditingController();

  void _addCustomTerm() {
    final term = _termController.text.trim();
    final trans = _translationController.text.trim();
    if (term.isEmpty || trans.isEmpty) return;

    final settingsCtrl = context.read<SettingsController>();
    final currentTerms = Map<String, String>.from(settingsCtrl.settings.customGlossaryTerms);
    currentTerms[term] = trans;

    settingsCtrl.updateSettings(settingsCtrl.settings.copyWith(customGlossaryTerms: currentTerms));
    context.read<TranslationController>().glossaryService.setCustomTerms(currentTerms);

    _termController.clear();
    _translationController.clear();
  }

  void _removeTerm(String term) {
    final settingsCtrl = context.read<SettingsController>();
    final currentTerms = Map<String, String>.from(settingsCtrl.settings.customGlossaryTerms);
    currentTerms.remove(term);

    settingsCtrl.updateSettings(settingsCtrl.settings.copyWith(customGlossaryTerms: currentTerms));
    context.read<TranslationController>().glossaryService.setCustomTerms(currentTerms);
  }

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = context.watch<SettingsController>();
    final settings = settingsCtrl.settings;
    final terms = settings.customGlossaryTerms;

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
              Icon(Icons.sports_esports_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Oyuncu Terimleri ve Özel Sözlük (Gaming Glossary)',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Özel Terimleri Koru',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            subtitle: const Text('CS2/oyun terimlerinin bozulmasını engeller.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: settings.enableGlossary,
            onChanged: (val) {
              settingsCtrl.updateSettings(settings.copyWith(enableGlossary: val));
            },
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _termController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Terim (örn. clan)',
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _translationController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Karşılığı (örn. klan)',
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addCustomTerm,
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.accent),
              ),
            ],
          ),

          if (terms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: terms.entries.map((e) {
                return Chip(
                  backgroundColor: AppColors.cardBg,
                  label: Text('${e.key} -> ${e.value}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  onDeleted: () => _removeTerm(e.key),
                  deleteIconColor: Colors.redAccent,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
