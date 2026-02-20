import 'package:flutter/material.dart';
import '../game_state.dart';

/// 动画时钟组件
/// 根据游戏内时间显示对应的精灵帧
class AnimatedClock extends StatelessWidget {
  final GameState gameState;
  final double? size;

  const AnimatedClock({
    super.key,
    required this.gameState,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gameState,
      builder: (context, child) {
        final dayNight = gameState.dayNightSystem;
        final minutes = dayNight.gameMinutes % 1440;

        String folder;
        int frameIndex;

        // 时间映射逻辑:
        // 1 Dawn: 06:00 - 12:00 (360 - 720)
        // 2 Day: 12:00 - 18:00 (720 - 1080)
        // 3 Noon: 18:00 - 00:00 (1080 - 1440)
        // 4 Night: 00:00 - 06:00 (0 - 360)

        if (minutes >= 360 && minutes < 720) {
          folder = '1_Dawn';
          frameIndex = ((minutes - 360) / 36).floor() + 1;
        } else if (minutes >= 720 && minutes < 1080) {
          folder = '2_Day';
          frameIndex = ((minutes - 720) / 36).floor() + 1;
        } else if (minutes >= 1080 && minutes < 1440) {
          folder = '3_Noon';
          frameIndex = ((minutes - 1080) / 36).floor() + 1;
        } else {
          // 00:00 - 06:00
          folder = '4_Night';
          frameIndex = (minutes / 36).floor() + 1;
        }

        // 确保帧索引在 1-10 之间
        frameIndex = frameIndex.clamp(1, 10);

        final spritePath = 'assets/paper_ui/Sprites/Day_n_Night_Cycle/Full/$folder/$frameIndex.png';
        const bgPath = 'assets/paper_ui/Sprites/Content/5_Holders/2.png';

        final background = Image.asset(
          bgPath,
          width: size,
          height: size,
          fit: size != null ? BoxFit.contain : null,
          filterQuality: FilterQuality.none,
        );

        final sprite = Image.asset(
          spritePath,
          width: size != null ? size! * 0.7 : null,
          height: size != null ? size! * 0.7 : null,
          fit: size != null ? BoxFit.contain : null,
          filterQuality: FilterQuality.none,
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            background,
            sprite,
          ],
        );
      },
    );
  }
}
