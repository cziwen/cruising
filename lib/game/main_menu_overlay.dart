import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';
import '../utils/version_constants.dart';
import 'paper_button.dart';

class MainMenuOverlay extends StatelessWidget {
  final VoidCallback onNewGame;
  final VoidCallback onContinueGame;
  final VoidCallback onLoadGame;
  final VoidCallback onSettings;
  final VoidCallback onExit;
  final bool canContinue;

  const MainMenuOverlay({
    super.key,
    required this.onNewGame,
    required this.onContinueGame,
    required this.onLoadGame,
    required this.onSettings,
    required this.onExit,
    this.canContinue = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 标题
              Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(5.0, 5.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              
              // 菜单按钮
              _buildMenuButton(
                context,
                label: l10n.newGame,
                onPressed: onNewGame,
              ),
              const SizedBox(height: 20),
              
              if (canContinue) ...[
                _buildMenuButton(
                  context,
                  label: l10n.continueGame,
                  onPressed: onContinueGame,
                  isSecondary: true,
                ),
                const SizedBox(height: 20),
              ],
              
              _buildMenuButton(
                context,
                label: l10n.loadGame,
                onPressed: onLoadGame,
                isSecondary: true,
              ),
              const SizedBox(height: 20),
              
              _buildMenuButton(
                context,
                label: l10n.settings,
                onPressed: onSettings,
              ),
              const SizedBox(height: 20),
              
              // 仅在非 Web 平台显示退出按钮
              if (!kIsWeb) 
                _buildMenuButton(
                  context,
                  label: l10n.exitGame,
                  onPressed: onExit,
                ),
            ],
          ),
        ),
        
        // 版本号 - 左下角
        Positioned(
          left: 20,
          bottom: 20,
          child: Text(
            'v${VersionConstants.gameVersion}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              shadows: const [
                Shadow(
                  blurRadius: 4.0,
                  color: Colors.black,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return PaperButton(
      width: 160,
      height: 64,
      label: label,
      onPressed: onPressed,
      style: isSecondary ? PaperButtonStyle.blue : PaperButtonStyle.brown,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4E342E),
      ),
    );
  }
}
