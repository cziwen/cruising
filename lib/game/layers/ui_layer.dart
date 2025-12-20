import 'package:flutter/material.dart';
import '../game_state.dart';
import '../debug_panel.dart';
import '../crew_management_dialog.dart';
import 'status_bar.dart';

/// UI层 - 界面元素（按钮、菜单、信息显示等）
class UILayer extends StatelessWidget {
  final GameState gameState;
  final VoidCallback? onTradePressed;
  final VoidCallback? onPortSelectPressed;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onMarketPressed;
  final VoidCallback? onCrewMarketPressed;
  final VoidCallback? onShipyardPressed;
  final VoidCallback? onSettingsPressed;

  const UILayer({
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
    // 使用 AnimatedBuilder 监听 GameState 的变化，确保实时更新
    return AnimatedBuilder(
      animation: gameState,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final centerX = screenSize.width / 2;
        final centerY = screenSize.height / 2;
        
        // 岛屿位置（与near_background_layer中的位置对齐）
        // 岛屿中心在屏幕中心向下40像素，岛屿大小约400x300
        final islandCenterX = centerX;
        final islandCenterY = centerY + 40;
        
        return Stack(
      children: [
        // 顶部航行进度条（仅在海上航行时显示）
        if (gameState.isAtSea && gameState.totalTravelDistance > 0)
          Positioned(
            top: 0,
            left: 180,  // 左侧留出更多空间，避免与左上角时间显示冲突
            right: 16,  // 右侧留出边距
            child: _buildTravelProgressBar(),
          ),
        
        // 底部状态栏（新设计）
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: StatusBar(gameState: gameState),
        ),
        
        // 岛屿周围的交互按钮（仅在非过渡且不在海上时显示）
        if (!gameState.isTransitioning && !gameState.isAtSea && gameState.currentPort != null) ...[
          // 市场按钮 - 岛屿左侧
          Positioned(
            left: islandCenterX - 250,
            top: islandCenterY - 50,
            child: _buildIslandButton(
              '市场',
              onMarketPressed ?? onTradePressed,
              Colors.blue,
            ),
          ),
          // 港口酒馆按钮 - 岛屿左上方
          Positioned(
            left: islandCenterX - 220,
            top: islandCenterY - 150,
            child: _buildIslandButton(
              '港口酒馆',
              onCrewMarketPressed,
              Colors.purple,
            ),
          ),
          // 设置按钮 - 岛屿右上方 (与酒馆对称)
          Positioned(
            left: islandCenterX + 220,
            top: islandCenterY - 150,
            child: _buildIslandButton(
              '设置',
              onSettingsPressed,
              Colors.blueGrey,
            ),
          ),
          // 船厂按钮 - 岛屿右侧（代替升级）
          Positioned(
            left: islandCenterX + 150,
            top: islandCenterY - 50,
            child: _buildIslandButton(
              '船厂',
              onShipyardPressed ?? onUpgradePressed,
              Colors.orange,
            ),
          ),
          // 船员管理按钮 - 岛屿右下方（船只旁边）
          Positioned(
            left: islandCenterX + 120,
            top: islandCenterY + 80,
            child: _buildIslandButton(
              '船员管理',
              () => _showCrewManagement(context),
              Colors.teal,
            ),
          ),
        ],
        
        // 选择目的地按钮 - 右下角（仅在非过渡且不在海上时显示）
        if (!gameState.isTransitioning && !gameState.isAtSea)
          Positioned(
            bottom: 80,
            right: 16,
            child: _buildDestinationButton(),
          ),
        
        // 调试面板
        DebugPanel(gameState: gameState),
        ],
      );
      },
    );
  }


  /// 构建岛屿周围的按钮
  Widget _buildIslandButton(String text, VoidCallback? onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建选择目的地按钮
  Widget _buildDestinationButton() {
    return FloatingActionButton.extended(
      onPressed: onPortSelectPressed,
      backgroundColor: Colors.green,
      icon: const Icon(Icons.map, color: Colors.white),
      label: const Text(
        '选择目的地',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 显示船员管理对话框
  void _showCrewManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CrewManagementDialog(
        crewManager: gameState.crewManager,
      ),
    );
  }

  /// 构建航行进度条
  Widget _buildTravelProgressBar() {
    final remainingHours = gameState.remainingTravelHours;
    final destinationName = gameState.destinationPort?.name ?? '目的地';
    
    // 将小时数转换为"X天Y小时"格式
    final days = remainingHours ~/ 24;
    final hours = remainingHours % 24;
    String remainingTimeText;
    if (days > 0 && hours > 0) {
      remainingTimeText = '$days天$hours小时';
    } else if (days > 0) {
      remainingTimeText = '$days天';
    } else {
      remainingTimeText = '$hours小时';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 目的地和剩余时间
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '前往: $destinationName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '剩余: $remainingTimeText',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: gameState.travelProgress,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
