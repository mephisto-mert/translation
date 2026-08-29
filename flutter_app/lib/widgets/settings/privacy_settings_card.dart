import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../controllers/history_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/translation_controller.dart';

class PrivacySettingsCard extends StatelessWidget {
  const PrivacySettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = context.watch<SettingsController>();
    final settings = settingsCtrl.settings;

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
              Icon(Icons.security_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gizlilik & Önbellek Ayarları',
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
            title: const Text('Çeviri Geçmişini Kaydet',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            subtitle: const Text('Son 50 çeviriyi yerel cihazda saklar.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: settings.enableHistory,
            onChanged: (val) {
              settingsCtrl.updateSettings(settings.copyWith(enableHistory: val));
            },
          ),
          SwitchListTile(
            title: const Text('Yerel Çeviri Önbelleği (LRU Cache)',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            subtitle: const Text('Aynı cümleler tekrar çevrilirken API harcamaz.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: settings.enablePersistentCache,
            onChanged: (val) {
              settingsCtrl.updateSettings(settings.copyWith(enablePersistentCache: val));
            },
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await context.read<TranslationController>().cache.clearAllCache();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yerel çeviri önbelleği temizlendi.')),
                    );
                  }
                },
                icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                label: const Text('Önbelleği Temizle'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.read<HistoryController>().clearHistory();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Çeviri geçmişi temizlendi.')),
                    );
                  }
                },
                icon: const Icon(Icons.history_toggle_off_rounded, size: 16),
                label: const Text('Geçmişi Temizle'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
