import 'package:flutter/material.dart';
import '../game_state.dart';

/// 双行状态栏组件
/// 显示游戏核心资源和运营状态信息
class StatusBar extends StatelessWidget {
  final GameState gameState;

  const StatusBar({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth / 20).clamp(10.0, 14.0); // 自适应字体大小
    final iconSize = (screenWidth / 22).clamp(16.0, 20.0); // 自适应图标大小

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 第一行：核心资源
            _buildFirstRow(context, fontSize, iconSize),
            const SizedBox(height: 6),
            // 第二行：运营与航行状态
            _buildSecondRow(context, fontSize, iconSize),
          ],
        ),
      ),
    );
  }

  /// 构建第一行：金币、位置、载货量、船员数量
  Widget _buildFirstRow(BuildContext context, double fontSize, double iconSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 金币
        Flexible(
          flex: 1,
          child: _buildStatItem(
            icon: Icons.monetization_on,
            label: '${gameState.gold}',
            iconSize: iconSize,
            fontSize: fontSize,
            valueColor: Colors.amber,
          ),
        ),
        
        // 当前位置
        Expanded(
          flex: 2,
          child: Center(
            child: _buildLocationItem(
              fontSize: fontSize,
              iconSize: iconSize,
            ),
          ),
        ),
        
        // 载货量
        Flexible(
          flex: 1,
          child: _buildStatItem(
            icon: Icons.inventory_2,
            label: '${gameState.usedCargoWeight.toStringAsFixed(1)}/${gameState.ship.cargoCapacity}kg',
            iconSize: iconSize,
            fontSize: fontSize,
            valueColor: Colors.blue,
          ),
        ),
        
        // 船员数量
        Flexible(
          flex: 1,
          child: _buildStatItem(
            icon: Icons.people,
            label: '${gameState.crewCount}/${gameState.maxCrewCount}(${gameState.morale})',
            iconSize: iconSize,
            fontSize: fontSize * 0.85, // 稍微小一点以适应更多文本
            valueColor: Colors.green,
          ),
        ),
      ],
    );
  }

  /// 构建第二行：船只耐久、修复速度、炮火攻击力、航速
  Widget _buildSecondRow(BuildContext context, double fontSize, double iconSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 船只耐久
        Flexible(
          flex: 1,
          child: _buildStatItem(
            icon: Icons.build,
            label: '${gameState.ship.durability}/${gameState.ship.maxDurability}',
            iconSize: iconSize,
            fontSize: fontSize,
            valueColor: Colors.orange,
          ),
        ),
        
        // 修复速度
        Flexible(
          flex: 1,
          child: _buildStatItem(
            icon: Icons.build_circle,
            label: '${gameState.autoRepairPerSecond.toStringAsFixed(1)}/秒',
            iconSize: iconSize,
            fontSize: fontSize,
            valueColor: Colors.orangeAccent,
          ),
        ),
        
        // 炮火攻击力
        Flexible(
          flex: 1,
          child: _buildStatItem(
            icon: Icons.gps_fixed,
            label: '${gameState.fireRatePerSecond.toStringAsFixed(1)} 炮/秒',
            iconSize: iconSize,
            fontSize: fontSize,
            valueColor: Colors.red,
          ),
        ),
        
        // 航速
        Flexible(
          flex: 1,
          child: _buildStatItem(
            icon: Icons.sailing,
            label: '${gameState.currentSpeed}节',
            iconSize: iconSize,
            fontSize: fontSize,
            valueColor: Colors.cyan,
          ),
        ),
      ],
    );
  }

  /// 构建统计项（图标 + 文本）
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required double iconSize,
    required double fontSize,
    required Color valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: valueColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// 构建位置显示项
  Widget _buildLocationItem({
    required double fontSize,
    required double iconSize,
  }) {
    String locationText;
    if (gameState.isAtSea) {
      locationText = '海上';
    } else if (gameState.currentPort != null) {
      locationText = gameState.currentPort!.name;
    } else {
      locationText = '未知';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          size: iconSize,
          color: Colors.white.withOpacity(0.9),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            locationText,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

}

