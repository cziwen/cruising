import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/game_config_loader.dart';
import 'paper_dialog.dart';
import 'paper_button.dart';

/// 语言选择对话框
class LanguageDialog extends StatelessWidget {
  const LanguageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return PaperDialog(
      assetPath: 'assets/paper_ui/Sprites/Book_Desk/4.png',
      width: 400,
      height: 350,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Text(
            l10n.languageSettings,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4E342E),
            ),
          ),
          const SizedBox(height: 40),
          
          // 语言选项
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return Column(
                children: [
                  _buildLanguageOption(
                    context,
                    label: l10n.chinese,
                    localeCode: 'zh',
                    currentLocaleCode: localeProvider.locale.languageCode,
                    onTap: () => _updateLocale(context, localeProvider, 'zh'),
                  ),
                  const SizedBox(height: 20),
                  _buildLanguageOption(
                    context,
                    label: l10n.english,
                    localeCode: 'en',
                    currentLocaleCode: localeProvider.locale.languageCode,
                    onTap: () => _updateLocale(context, localeProvider, 'en'),
                  ),
                ],
              );
            },
          ),
          
          const Spacer(),
          
          // 关闭按钮
          PaperButton(
            label: l10n.close,
            onPressed: () => Navigator.of(context).pop(),
            style: PaperButtonStyle.brown,
            width: 100,
            height: 40,
          ),
        ],
      ),
    );
  }

  void _updateLocale(BuildContext context, LocaleProvider provider, String langCode) {
    if (provider.locale.languageCode != langCode) {
      final newLocale = Locale(langCode);
      provider.setLocale(newLocale);
      // 重新加载配置数据
      GameConfigLoader().loadConfig(locale: newLocale);
    }
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String label,
    required String localeCode,
    required String currentLocaleCode,
    required VoidCallback onTap,
  }) {
    final isSelected = currentLocaleCode == localeCode;

    return PaperButton(
      label: label,
      onPressed: onTap,
      style: isSelected ? PaperButtonStyle.blue : PaperButtonStyle.brown,
      width: 180,
      height: 48,
      textStyle: TextStyle(
        fontSize: 18,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: const Color(0xFF4E342E),
      ),
    );
  }
}
