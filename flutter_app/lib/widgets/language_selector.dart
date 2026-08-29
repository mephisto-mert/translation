/// Bayraklı dil seçici dropdown widget
library;

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_locales.dart';

class LanguageSelectorWidget extends StatefulWidget {
  final String selectedCode;
  final String uiLang;
  final ValueChanged<String> onChanged;
  final bool showAutoDetect;

  const LanguageSelectorWidget({
    super.key,
    required this.selectedCode,
    required this.uiLang,
    required this.onChanged,
    this.showAutoDetect = true,
  });

  @override
  State<LanguageSelectorWidget> createState() => _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  LanguageItem get _selectedLang =>
      AppLocales.supportedLanguages.firstWhere(
        (l) => l.code == widget.selectedCode,
        orElse: () => AppLocales.supportedLanguages.first,
      );

  List<LanguageItem> get _filteredLangs => widget.showAutoDetect
      ? AppLocales.supportedLanguages
      : AppLocales.supportedLanguages.where((l) => l.code != 'auto').toList();

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ana buton
        Material(
          color: AppColors.bgButton,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _toggle,
            hoverColor: AppColors.bgButtonHover,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _buildFlag(_selectedLang.flag),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedLang.getName(widget.uiLang),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotateAnim,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Dropdown listesi
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: _isOpen
              ? Container(
                  margin: const EdgeInsets.only(top: 6),
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _filteredLangs.length,
                      itemBuilder: (context, index) {
                        final lang = _filteredLangs[index];
                        final isSelected = lang.code == widget.selectedCode;
                        return Material(
                          color: isSelected
                              ? AppColors.accentBlue.withOpacity(0.15)
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              widget.onChanged(lang.code);
                              _toggle();
                            },
                            hoverColor: AppColors.bgButton,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  _buildFlag(lang.flag),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      lang.getName(widget.uiLang),
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.accentBlue
                                            : AppColors.textBody,
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.accentBlue,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFlag(String code) {
    return Container(
      width: 28,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.asset(
          'assets/flags/$code.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.bgButton,
            child: const Icon(Icons.language, size: 16, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
