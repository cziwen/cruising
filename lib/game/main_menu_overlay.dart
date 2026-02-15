import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'paper_button.dart';
import '../l10n/l10n.dart';

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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 标题
          const Text(
            'Cruising',
            style: TextStyle(
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
            label: context.l10n.newGame,
            onPressed: onNewGame,
          ),
          const SizedBox(height: 20),
          
          if (canContinue) ...[
            _buildMenuButton(
              context,
              label: context.l10n.continueGame,
              onPressed: onContinueGame,
              isSecondary: true,
            ),
            const SizedBox(height: 20),
          ],
          
          _buildMenuButton(
            context,
            label: context.l10n.loadSave,
            onPressed: onLoadGame,
            isSecondary: true,
          ),
          const SizedBox(height: 20),
          
          _buildMenuButton(
            context,
            label: context.l10n.settings,
            onPressed: onSettings,
          ),
          const SizedBox(height: 20),
          
          // 仅在非 Web 平台显示退出按钮
          if (!kIsWeb) 
            _buildMenuButton(
              context,
              label: context.l10n.exitGame,
              onPressed: onExit,
            ),
        ],
      ),
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
