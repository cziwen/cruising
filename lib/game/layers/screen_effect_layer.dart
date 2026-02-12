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
        final isStorm = gameState.currentVisualEffect == 'sea_storm';
        
        return IgnorePointer(
          // 始终忽略点击，仅作为视觉层
          ignoring: true,
          child: Stack(
            children: [
              // 渐变黑屏效果
              AnimatedContainer(
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                color: Colors.black.withValues(alpha: gameState.isFadeOut ? 1.0 : 0.0),
              ),
              
              // 风暴效果（全屏灰色滤镜）
              if (isStorm)
                AnimatedOpacity(
                  opacity: isStorm ? 1.0 : 0.0,
                  duration: const Duration(seconds: 1),
                  child: Container(
                    color: Colors.blueGrey.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}




