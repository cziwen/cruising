import 'package:flutter/material.dart';
import 'game_state.dart';
import 'layers/background_layer.dart';
import 'layers/near_background_layer.dart';
import 'layers/ship_layer.dart';
import 'layers/foreground_wave_layer.dart';
import 'layers/ui_layer.dart';
import 'layers/time_display.dart';
import 'layers/screen_effect_layer.dart';

/// 游戏场景 - 单场景游戏视图（4层渲染）
class GameScene extends StatelessWidget {
  final GameState gameState;
  final VoidCallback? onTradePressed;
  final VoidCallback? onPortSelectPressed;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onMarketPressed;
  final VoidCallback? onCrewMarketPressed;
  final VoidCallback? onShipyardPressed;
  final VoidCallback? onSettingsPressed;

  const GameScene({
    super.key,
    required this.gameState,
    this.onTradePressed,
    this.onPortSelectPressed,
    this.onUpgradePressed,
    this.onMarketPressed,
    this.onCrewMarketPressed,
    this.onShipyardPressed,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 0: 背景层（包含 Layer 0.5 天体层）
        BackgroundLayer(gameState: gameState),
        
        // Layer 1: 近背景层（岛屿）
        NearBackgroundLayer(
          gameState: gameState,
        ),
        
        // Layer 2: 船层
        ShipLayer(gameState: gameState),
        
        // Layer 2.3: 前景波浪层（位于船之后）
        ForegroundWaveLayer(gameState: gameState),
        
        // Layer 2.5: 屏幕效果层（黑屏等）
        ScreenEffectLayer(gameState: gameState),

        // Layer 3: UI层
        UILayer(
          gameState: gameState,
          onTradePressed: onTradePressed,
          onPortSelectPressed: onPortSelectPressed,
          onUpgradePressed: onUpgradePressed,
          onMarketPressed: onMarketPressed,
          onCrewMarketPressed: onCrewMarketPressed,
          onShipyardPressed: onShipyardPressed,
          onSettingsPressed: onSettingsPressed,
        ),
        
        // Layer 3.5: 时间显示（左上角）
        TimeDisplay(gameState: gameState),
      ],
    );
  }
}

