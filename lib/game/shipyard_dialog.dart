import 'package:flutter/material.dart';
import 'game_state.dart';
import '../models/ship.dart';
import '../systems/ship_system.dart';
import 'scale_wrapper.dart';

/// 船厂对话框 - 用于升级船只
class ShipyardDialog extends StatefulWidget {
  final GameState gameState;

  const ShipyardDialog({
    super.key,
    required this.gameState,
  });

  @override
  State<ShipyardDialog> createState() => _ShipyardDialogState();
}

class _ShipyardDialogState extends State<ShipyardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  final ShipSystem _shipSystem = ShipSystem();

  @override
  void initState() {
    super.initState();

    // 船只呼吸动画
    _breathingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  void _handleUpgrade(UpgradeType type) {
    final result = _shipSystem.performUpgrade(widget.gameState, type);
    
    if (result != null) {
      // 失败提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      // 成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('升级成功！'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
        ),
      );
      setState(() {}); // 刷新 UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final ship = widget.gameState.ship;

    return ScaleWrapper(
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 1200, // 设计尺寸
          height: 800, // 设计尺寸
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            children: [
              // 标题栏
              _buildHeader(context),
              
              // 主要内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 左侧：船只属性
                      Expanded(
                        flex: 3,
                        child: _buildShipAttributes(ship),
                      ),
                      
                      // 中央：船只展示
                      Expanded(
                        flex: 4,
                        child: _buildShipVisual(ship),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 底部：升级选项
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '升级选项',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildUpgradeCard(ship, UpgradeType.cargo)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildUpgradeCard(ship, UpgradeType.hull)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildUpgradeCard(ship, UpgradeType.crew)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.anchor, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          const Text(
            '船厂 Shipyard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 显示玩家金币
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Text('💰', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${widget.gameState.gold}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildShipAttributes(Ship ship) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '船只属性',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildAttributeRow(
            '船名',
            ship.name,
            Icons.directions_boat,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildAttributeRow(
            '载货量',
            '${ship.cargoCapacity} / ${ship.maxCargoCapacity} kg',
            Icons.inventory_2,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildAttributeRow(
            '耐久度',
            '${ship.durability} / ${ship.maxDurability}',
            Icons.shield,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildAttributeRow(
            '船员容量',
            '${widget.gameState.crewManager.crewMembers.length} / ${ship.maxCrewMemberCount}',
            Icons.people,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShipVisual(Ship ship) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _breathingAnimation.value),
                child: child,
              );
            },
            child: Image.asset(
              'assets/images/fearless-pirate-captain-ship-in-pixel-art.png',
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Lv.${ship.level}',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.black,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(Ship ship, UpgradeType type) {
    final name = _shipSystem.getUpgradeName(type);
    final description = _shipSystem.getUpgradeDescription(type);
    final cost = _shipSystem.getUpgradeCost(ship, type);
    final amount = _shipSystem.getUpgradeAmount(type);
    final canAfford = widget.gameState.gold >= cost;
    
    String valueChange = '';
    switch (type) {
      case UpgradeType.cargo:
        valueChange = '${ship.maxCargoCapacity} → ${ship.maxCargoCapacity + amount} kg';
        break;
      case UpgradeType.hull:
        valueChange = '${ship.maxDurability} → ${ship.maxDurability + amount}';
        break;
      case UpgradeType.crew:
        valueChange = '${ship.maxCrewMemberCount} → ${ship.maxCrewMemberCount + amount} 人';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAfford ? Colors.white.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            valueChange,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAfford ? () => _handleUpgrade(type) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? Colors.blue[800] : Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$cost',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canAfford ? Colors.amber : Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('[升级]'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


