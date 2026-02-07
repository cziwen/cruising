import 'dart:math';
import 'package:flutter/material.dart';
import 'game_state.dart';
import '../models/goods.dart';
import '../utils/game_config_loader.dart';
import 'paper_dialog.dart';
import 'paper_button.dart';
import '../systems/quest_system.dart';

/// 大厅对话框 - 用于主岛升级和仓库管理
class MainHallDialog extends StatefulWidget {
  final GameState gameState;
  final int initialTab; // 0: 升级, 1: 仓库

  const MainHallDialog({
    super.key,
    required this.gameState,
    this.initialTab = 0,
  });

  @override
  State<MainHallDialog> createState() => _MainHallDialogState();
}

class _MainHallDialogState extends State<MainHallDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 仓库管理选中状态
  String? _selectedGoodsId;
  bool _isSelectingFromShip = true;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    
    // 通知任务系统：大厅已打开
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.gameState.setHallPanelOpened(true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // 使用 addPostFrameCallback 避免在 unmount 期间触发 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.gameState.setHallPanelOpened(false);
    });
    super.dispose();
  }

  void _handleUpgrade(String type) {
    final success = widget.gameState.upgradeHomeIsland(type);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('升级成功！'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 500),
        ),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('金币不足或已达最高等级'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaperDialog(
      questId: 'ui.hallPanel',
      assetPath: 'assets/paper_ui/Sprites/Book Desk/6.png',
      width: 1000,
      height: 800,
      child: Column(
        children: [
          // 标题栏与页签
          _buildHeader(),
          
          // 内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpgradeTab(),
                _buildWarehouseTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.home, color: Color(0xFF4E342E), size: 24),
              const SizedBox(width: 10),
              Text(
                '大厅 Main Hall - Lv. ${widget.gameState.homeIsland.level}',
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
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '市政厅升级'),
            Tab(text: '岛屿仓库'),
          ],
          labelColor: const Color(0xFF4E342E),
          unselectedLabelColor: const Color(0xFF8D6E63),
          indicatorColor: const Color(0xFF5D4037),
          indicatorWeight: 3,
      ),
      const Divider(color: Color(0xFF8D6E63), thickness: 1, height: 1),
    ],
  );
}

Widget _buildUpgradeTab() {
  final island = widget.gameState.homeIsland;
  return QuestTarget(
    id: 'ui.upgradeTab',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '岛屿功能升级',
            style: TextStyle(color: Color(0xFF4E342E), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '当所有功能均升级后，岛屿视觉等级将自动提升。',
            style: TextStyle(color: Color(0xFF5D4037), fontSize: 14),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildUpgradeCard('税收额度', '提升每小时产生的税收金额', 'tax', island.taxLevel),
              _buildUpgradeCard('本地经济', '降低岛屿商店买入价格', 'economy', island.economyLevel),
              _buildUpgradeCard('商人资金', '提升本地商人最大默认金额', 'funds', island.merchantFundsLevel),
              _buildUpgradeCard('补货速度', '提升本地商人货物刷新速度与库存', 'restock', island.restockSpeedLevel),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildUpgradeCard(String title, String desc, String type, int level) {
    final island = widget.gameState.homeIsland;
    final cost = 1000 * (level + 1);
    final canAfford = widget.gameState.gold >= cost;
    final isMaxLevel = level >= 7;
    // 同步规则：当前项等级不能超过最低等级
    final needsSync = level > island.level;
    final canUpgrade = !isMaxLevel && !needsSync && canAfford;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8D6E63).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(color: Color(0xFF4E342E), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('Lv. $level', style: const TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Color(0xFF5D4037), fontSize: 12)),
                if (needsSync && !isMaxLevel)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('需先升级其他项', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isMaxLevel) ...[
                Text('💰 $cost', style: TextStyle(color: canAfford ? const Color(0xFF795548) : Colors.red[800], fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                PaperButton(
                  onPressed: canUpgrade ? () => _handleUpgrade(type) : null,
                  label: '升级',
                  style: PaperButtonStyle.brown,
                  width: 80,
                  height: 32,
                ),
              ] else
                const Text('已满级', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySlider(String goodsId, int maxQuantity, bool isDepositing) {
    if (maxQuantity <= 0) return const SizedBox.shrink();

    Goods? goods;
    try {
      goods = GameConfigLoader().getGoodsById(goodsId);
    } catch (e) {
      // 如果找不到商品，展示原始ID
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8D6E63)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (goods?.imagePath != null) ...[
                    Image.asset(goods!.imagePath!, width: 24, height: 24),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${isDepositing ? "存入仓库" : "取出到船"}: ${goods?.name ?? goodsId}',
                    style: const TextStyle(color: Color(0xFF4E342E), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'x $_selectedQuantity',
                style: const TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          Row(
            children: [
              PaperButton(
                onPressed: _selectedQuantity > 1 ? () {
                  setState(() {
                    _selectedQuantity = (max(1, _selectedQuantity - 10)).toInt();
                  });
                } : null,
                label: '-10',
                style: PaperButtonStyle.square,
                width: 28,
                height: 28,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
              ),
              const SizedBox(width: 4),
              PaperButton(
                onPressed: _selectedQuantity > 1 ? () {
                  setState(() {
                    _selectedQuantity = (max(1, _selectedQuantity - 1)).toInt();
                  });
                } : null,
                label: '-1',
                style: PaperButtonStyle.square,
                width: 28,
                height: 28,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
              ),
              Expanded(
                child: Slider(
                  value: _selectedQuantity.toDouble(),
                  min: 1,
                  max: maxQuantity.toDouble(),
                  divisions: maxQuantity > 1 ? maxQuantity - 1 : 1,
                  activeColor: const Color(0xFF5D4037),
                  inactiveColor: const Color(0xFFD7CCC8),
                  label: '$_selectedQuantity',
                  onChanged: (value) {
                    setState(() {
                      _selectedQuantity = value.round();
                    });
                  },
                ),
              ),
              PaperButton(
                onPressed: _selectedQuantity < maxQuantity ? () {
                  setState(() {
                    _selectedQuantity = (min(maxQuantity, _selectedQuantity + 1)).toInt();
                  });
                } : null,
                label: '+1',
                style: PaperButtonStyle.square,
                width: 28,
                height: 28,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
              ),
              const SizedBox(width: 4),
              PaperButton(
                onPressed: _selectedQuantity < maxQuantity ? () {
                  setState(() {
                    _selectedQuantity = (min(maxQuantity, _selectedQuantity + 10)).toInt();
                  });
                } : null,
                label: '+10',
                style: PaperButtonStyle.square,
                width: 28,
                height: 28,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PaperButton(
                onPressed: () {
                  setState(() {
                    _selectedGoodsId = null;
                  });
                },
                label: '取消',
                style: PaperButtonStyle.brown,
                width: 80,
                height: 32,
              ),
              const SizedBox(width: 8),
              PaperButton(
                onPressed: () {
                  bool success;
                  if (isDepositing) {
                    success = widget.gameState.depositToWarehouse(goodsId, _selectedQuantity);
                  } else {
                    success = widget.gameState.withdrawFromWarehouse(goodsId, _selectedQuantity);
                  }

                  if (success) {
                    setState(() {
                      _selectedGoodsId = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isDepositing ? '存入成功！' : '取出成功！'),
                        backgroundColor: Colors.green,
                        duration: const Duration(milliseconds: 500),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isDepositing ? '存入失败' : '取出失败（可能载重不足）'),
                        backgroundColor: Colors.red,
                        duration: const Duration(milliseconds: 1000),
                      ),
                    );
                  }
                },
                label: isDepositing ? '确认存入' : '确认取出',
                style: PaperButtonStyle.green,
                width: 80,
                height: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 船只库存
                Expanded(
                  child: _buildStorageColumn(
                    '我的船只',
                    widget.gameState.inventory,
                    true,
                    Icons.directions_boat,
                  ),
                ),
                const VerticalDivider(color: Color(0xFF8D6E63), width: 32),
                // 岛屿仓库
                Expanded(
                  child: _buildStorageColumn(
                    '岛屿仓库',
                    widget.gameState.warehouseInventory,
                    false,
                    Icons.warehouse,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedGoodsId != null) ...[
            const SizedBox(height: 16),
            _buildQuantitySlider(
              _selectedGoodsId!,
              _isSelectingFromShip
                  ? widget.gameState.getInventoryQuantity(_selectedGoodsId!)
                  : widget.gameState.getWarehouseQuantity(_selectedGoodsId!),
              _isSelectingFromShip,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStorageColumn(
    String title,
    List<ShipInventoryItem> items,
    bool isShipInventory,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF5D4037), size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Color(0xFF4E342E), fontSize: 18, fontWeight: FontWeight.bold)),
            if (isShipInventory) ...[
              const Spacer(),
              Text(
                '载重: ${widget.gameState.usedCargoWeight.toStringAsFixed(1)}/${widget.gameState.ship.cargoCapacity}kg',
                style: const TextStyle(color: Color(0xFF5D4037), fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('空空如也', style: TextStyle(color: Color(0xFF8D6E63))))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildStorageItem(item, isShipInventory);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStorageItem(ShipInventoryItem item, bool isShipInventory) {
    final isSelected = _selectedGoodsId == item.goodsId && _isSelectingFromShip == isShipInventory;
    Goods? goods;
    try {
      goods = GameConfigLoader().getGoodsById(item.goodsId);
    } catch (e) {
      // Ignore
    }
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedGoodsId = null;
          } else {
            _selectedGoodsId = item.goodsId;
            _isSelectingFromShip = isShipInventory;
            _selectedQuantity = 1;
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD7CCC8).withValues(alpha: 0.5) : const Color(0xFFD7CCC8).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: const Color(0xFF5D4037)) : null,
        ),
        child: Row(
          children: [
            if (goods?.imagePath != null)
              Image.asset(goods!.imagePath!, width: 32, height: 32)
            else
              const Icon(Icons.inventory_2, color: Color(0xFF8D6E63), size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goods?.name ?? item.goodsId, style: const TextStyle(color: Color(0xFF4E342E), fontWeight: FontWeight.bold)),
                  Text('数量: ${item.quantity}', style: const TextStyle(color: Color(0xFF5D4037), fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF5D4037), size: 20),
          ],
        ),
      ),
    );
  }
}

