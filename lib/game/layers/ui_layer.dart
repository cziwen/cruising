import 'package:flutter/material.dart';
import '../game_state.dart';
import '../debug_panel.dart';
import '../crew_management_dialog.dart';
import '../main_hall_dialog.dart';
import '../paper_button.dart';
import '../pixel_progress_bar.dart';
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
        if (gameState.isAtSea)
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
          // 税收提示 - 岛屿正上方 (仅限主岛)
          if (gameState.currentPort!.id == 'home_island' && gameState.homeIsland.accumulatedTax > 0)
            Positioned(
              left: islandCenterX - 60,
              top: islandCenterY - 230,
              child: _buildTaxButton(),
            ),

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
          
          // 大厅按钮 (仅限主岛)
          if (gameState.currentPort!.id == 'home_island') ...[
            // 大厅按钮 - 岛屿左下方
            Positioned(
              left: islandCenterX - 250,
              top: islandCenterY + 80,
              child: _buildIslandButton(
                '大厅',
                () => _showMainHall(context, 0),
                Colors.indigo,
              ),
            ),
          ],

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
  }

  /// 构建岛屿周围的按钮
  Widget _buildIslandButton(String text, VoidCallback? onPressed, Color color) {
    PaperButtonStyle style = PaperButtonStyle.brown;
    if (color == Colors.blue) style = PaperButtonStyle.blue;
    if (color == Colors.green) style = PaperButtonStyle.green;
    if (color == Colors.purple) style = PaperButtonStyle.gold; // Using gold for purple as a highlight
    if (color == Colors.orange) style = PaperButtonStyle.gold;
    if (color == Colors.teal) style = PaperButtonStyle.blue;
    if (color == Colors.blueGrey) style = PaperButtonStyle.brown;

    return PaperButton(
      label: text,
      onPressed: onPressed,
      style: style,
      width: 100,
      height: 40,
    );
  }

  /// 构建选择目的地按钮
  Widget _buildDestinationButton() {
    return PaperButton(
      label: '选择目的地',
      icon: const Icon(Icons.map, color: Color(0xFF4E342E), size: 20),
      onPressed: onPortSelectPressed,
      style: PaperButtonStyle.green,
      width: 120,
      height: 48,
    );
  }

  /// 显示船员管理对话框
  void _showCrewManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CrewManagementDialog(
        gameState: gameState,
      ),
    );
  }

  /// 显示大厅对话框
  void _showMainHall(BuildContext context, int initialTab) {
    showDialog(
      context: context,
      builder: (context) => MainHallDialog(
        gameState: gameState,
        initialTab: initialTab,
      ),
    );
  }

  /// 构建税收提示按钮
  Widget _buildTaxButton() {
    return GestureDetector(
      onTap: () => gameState.collectTax(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💰', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              '${gameState.homeIsland.accumulatedTax}',
              style: const TextStyle(
                color: Colors.brown,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
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
          PixelProgressBar(
            value: gameState.travelProgress,
            width: double.infinity,
            height: 32, // 背景板高度
          ),
        ],
      ),
    );
  }
}
