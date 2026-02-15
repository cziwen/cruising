import 'package:flutter/material.dart';
import '../game_state.dart';
import '../../l10n/l10n.dart';
import '../../systems/day_night_system.dart';

/// 时间显示Widget（左上角）
class TimeDisplay extends StatelessWidget {
  final GameState gameState;

  const TimeDisplay({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: gameState,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${gameState.dayNightSystem.currentTime}  ${context.l10n.seasonDay(_seasonLabel(context), gameState.dayNightSystem.currentDayOfSeason.toString())}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _seasonLabel(BuildContext context) {
    final season = gameState.dayNightSystem.currentSeason;
    final l10n = context.l10n;
    switch (season) {
      case Season.spring:
        return l10n.spring;
      case Season.summer:
        return l10n.summer;
      case Season.autumn:
        return l10n.autumn;
      case Season.winter:
        return l10n.winter;
    }
  }
}
