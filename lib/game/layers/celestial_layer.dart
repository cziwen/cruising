import 'package:flutter/material.dart';
import '../game_state.dart';
import '../../systems/day_night_system.dart';

/// 天体层（太阳/月亮）
class CelestialLayer extends StatelessWidget {
  final GameState gameState;
  final String sunImagePath;
  final String moonImagePath;

  const CelestialLayer({
    super.key,
    required this.gameState,
    this.sunImagePath = 'assets/images/onsky/sun.png',
    this.moonImagePath = 'assets/images/onsky/moon.png',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gameState,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final dayNightSystem = gameState.dayNightSystem;
        final progress = dayNightSystem.dayCycleProgress;
        final isDaytime = dayNightSystem.isDaytime;

        return Stack(
          children: [
            // 太阳
            if (isDaytime)
              _buildCelestialBody(
                context,
                sunImagePath,
                progress,
                true,
                screenSize,
              ),
            // 月亮
            if (!isDaytime)
              _buildCelestialBody(
                context,
                moonImagePath,
                progress,
                false,
                screenSize,
              ),
          ],
        );
      },
    );
  }

  Widget _buildCelestialBody(
    BuildContext context,
    String imagePath,
    double progress,
    bool isDaytime,
    Size screenSize,
  ) {
    // 太阳放大至1.5倍 (90)，月亮保持原样 (60)
    final double size = isDaytime ? 90 : 60;
    final double offset = size / 2;

    final position = CelestialBodyPosition.calculatePosition(
      progress,
      screenSize.width,
      screenSize.height,
      isDaytime,
    );
    
    final opacity = CelestialBodyPosition.getOpacity(progress, isDaytime);

    return Positioned(
      left: position.dx - offset,
      top: position.dy - offset,
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

