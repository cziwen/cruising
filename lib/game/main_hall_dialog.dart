import 'package:flutter/material.dart';
import 'game_state.dart';
import '../models/goods.dart';
import '../utils/game_config_loader.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1000,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
        ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.home, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  '大厅 Main Hall - Lv. ${widget.gameState.homeIsland.level}',
                  style: const TextStyle(
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
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '市政厅升级'),
              Tab(text: '岛屿仓库'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeTab() {
    final island = widget.gameState.homeIsland;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '岛屿功能升级',
            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '当所有功能均升级后，岛屿视觉等级将自动提升。',
            style: TextStyle(color: Colors.white54, fontSize: 14),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('Lv. $level', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                if (needsSync && !isMaxLevel)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('需先升级其他项', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isMaxLevel) ...[
                Text('💰 $cost', style: TextStyle(color: canAfford ? Colors.amber : Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: canUpgrade ? () => _handleUpgrade(type) : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                  child: const Text('升级', style: TextStyle(color: Colors.white)),
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
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'x $_selectedQuantity',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          Slider(
            value: _selectedQuantity.toDouble(),
            min: 1,
            max: maxQuantity.toDouble(),
            divisions: maxQuantity > 1 ? maxQuantity - 1 : 1,
            label: '$_selectedQuantity',
            onChanged: (value) {
              setState(() {
                _selectedQuantity = value.round();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedGoodsId = null;
                  });
                },
                child: const Text('取消', style: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                child: Text(isDepositing ? '确认存入' : '确认取出', style: const TextStyle(color: Colors.white)),
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
                const VerticalDivider(color: Colors.white10, width: 32),
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
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            if (isShipInventory) ...[
              const Spacer(),
              Text(
                '载重: ${widget.gameState.usedCargoWeight.toStringAsFixed(1)}/${widget.gameState.ship.cargoCapacity}kg',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('空空如也', style: TextStyle(color: Colors.white24)))
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
          color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          children: [
            if (goods?.imagePath != null)
              Image.asset(goods!.imagePath!, width: 32, height: 32)
            else
              const Icon(Icons.inventory_2, color: Colors.white54, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goods?.name ?? item.goodsId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('数量: ${item.quantity}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blue, size: 20),
          ],
        ),
      ),
    );
  }
}

