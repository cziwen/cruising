import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'game_state.dart';
import '../models/ship.dart';
import '../systems/ship_system.dart';
import '../systems/quest_system.dart';
import 'paper_dialog.dart';
import 'paper_button.dart';

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

    // 通知任务系统：船厂已打开
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.gameState.setShipyardOpened(true);
    });

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
    // 通知任务系统：船厂已关闭
    // 使用 addPostFrameCallback 避免在 unmount 期间触发 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.gameState.setShipyardOpened(false);
    });
    _breathingController.dispose();
    super.dispose();
  }

  void _handleUpgrade(UpgradeType type, AppLocalizations l10n) {
    final result = _shipSystem.performUpgrade(widget.gameState, type, l10n);
    
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
        SnackBar(
          content: Text(l10n.upgradeSuccess),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 500),
        ),
      );
      setState(() {}); // 刷新 UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final ship = widget.gameState.ship;
    final l10n = AppLocalizations.of(context)!;

    return PaperDialog(
      questId: 'ui.shipyardPanel',
      assetPath: 'assets/paper_ui/Sprites/Book_Desk/7.png',
      width: 1200,
      height: 800,
      child: Column(
        children: [
          // 标题栏
          _buildHeader(context, l10n),
          
          // 主要内容区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 左侧：船只属性
                  Expanded(
                    flex: 3,
                    child: _buildShipAttributes(ship, l10n),
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
              color: const Color(0xFFD7CCC8).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8D6E63).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.upgradeOptions,
                  style: const TextStyle(
                    color: Color(0xFF4E342E),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildUpgradeCard(ship, UpgradeType.cargo, l10n)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildUpgradeCard(ship, UpgradeType.hull, l10n)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildUpgradeCard(ship, UpgradeType.crew, l10n)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.anchor, color: Color(0xFF4E342E), size: 24),
          const SizedBox(width: 10),
          Text(
            l10n.shipyard,
            style: const TextStyle(
              color: Color(0xFF4E342E),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 显示玩家金币
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD7CCC8).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8D6E63)),
            ),
            child: Row(
              children: [
                const Text('💰', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${widget.gameState.gold}',
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          PaperButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Color(0xFF4E342E), size: 20),
            style: PaperButtonStyle.brown,
            width: 40,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildShipAttributes(Ship ship, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8D6E63).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shipAttributes,
            style: const TextStyle(
              color: Color(0xFF4E342E),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildAttributeRow(
            l10n.shipName,
            ship.name,
            Icons.directions_boat,
            Colors.blue[800]!,
          ),
          const SizedBox(height: 16),
          _buildAttributeRow(
            l10n.shipLevel,
            'Lv. ${_shipSystem.getShipLevel(ship)}',
            Icons.trending_up,
            Colors.purple[800]!,
          ),
          const SizedBox(height: 16),
          _buildAttributeRow(
            l10n.cargoCapacity,
            '${widget.gameState.usedCargoWeight.toStringAsFixed(1)} / ${ship.cargoCapacity} kg',
            Icons.inventory_2,
            Colors.orange[900]!,
          ),
          const SizedBox(height: 16),
          _buildAttributeRow(
            l10n.durability,
            '${ship.durability} / ${ship.maxDurability}',
            Icons.shield,
            Colors.red[900]!,
          ),
          const SizedBox(height: 16),
          _buildAttributeRow(
            l10n.crewCapacity,
            '${widget.gameState.crewManager.crewMembers.length} / ${ship.maxCrewMemberCount}',
            Icons.people,
            Colors.green[800]!,
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
                color: Color(0xFF5D4037),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF4E342E),
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
          Expanded(
            child: ClipRect(
              child: Transform.scale(
                scale: 2.0,
                child: AnimatedBuilder(
                  animation: _breathingAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _breathingAnimation.value),
                      child: child,
                    );
                  },
                  child: Image.asset(
                    ship.appearance,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(Ship ship, UpgradeType type, AppLocalizations l10n) {
    final name = _shipSystem.getUpgradeName(type, l10n);
    final description = _shipSystem.getUpgradeDescription(type, l10n);
    final cost = _shipSystem.getUpgradeCost(ship, type);
    final amount = _shipSystem.getUpgradeAmount(type);
    final isAllowedByLevel = _shipSystem.canPerformUpgrade(ship, type);
    final canAfford = widget.gameState.gold >= cost;
    final canUpgrade = isAllowedByLevel && canAfford;
    
    String valueChange = '';
    switch (type) {
      case UpgradeType.cargo:
        valueChange = '${ship.cargoCapacity} → ${ship.cargoCapacity + amount} kg';
        break;
      case UpgradeType.hull:
        valueChange = '${ship.maxDurability} → ${ship.maxDurability + amount}';
        break;
      case UpgradeType.crew:
        valueChange = '${ship.maxCrewMemberCount} → ${ship.maxCrewMemberCount + amount} ${l10n.peopleCount('')}';
        break;
    }

    final level = _shipSystem.getUpgradeLevel(ship, type);

    return QuestTarget(
      id: type == UpgradeType.cargo ? 'ui.shipyard.upgradeCargoButton' : 'ui.shipyard.upgradeButton_${type.name}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canUpgrade ? const Color(0xFF8D6E63) : Colors.red[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                'Lv.$level',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 11,
            ),
          ),
          const Spacer(),
          if (!isAllowedByLevel && level < _shipSystem.getMaxLevel())
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                _shipSystem.getLevelConstraintMessage(ship, type, l10n),
                style: TextStyle(
                  color: Colors.red[800],
                  fontSize: 10,
                ),
              ),
            ),
          Text(
            level >= _shipSystem.getMaxLevel() ? l10n.maxLevelReached : valueChange,
            style: TextStyle(
              color: level >= _shipSystem.getMaxLevel() ? Colors.orange[900] : Colors.green[800],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          PaperButton(
            onPressed: canUpgrade ? () => _handleUpgrade(type, l10n) : null,
            label: level < _shipSystem.getMaxLevel() ? l10n.upgradeCost(cost) : l10n.maxLevel,
            style: PaperButtonStyle.brown,
            width: 110,
            height: 40,
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            color: canAfford ? const Color(0xFF4E342E) : Colors.red[800],
          ),
        ),
      ],
    ),
  ),
);
}
}


