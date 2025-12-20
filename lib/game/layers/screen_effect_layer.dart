import 'package:flutter/material.dart';
import '../game_state.dart';

/// 屏幕效果层 - 处理全屏视觉效果（如渐变黑屏）
/// 位于船层之上，UI层之下
class ScreenEffectLayer extends StatelessWidget {
  final GameState gameState;

  const ScreenEffectLayer({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gameState,
      builder: (context, child) {
        return IgnorePointer(
          // 始终忽略点击，仅作为视觉层
          ignoring: true,
          child: AnimatedContainer(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            color: Colors.black.withOpacity(gameState.isFadeOut ? 1.0 : 0.0),
          ),
        );
      },
    );
  }
}




