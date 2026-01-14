import 'dart:math';
import 'package:flutter/material.dart';
import '../models/goods.dart';
import '../models/port.dart';
import '../game/game_state.dart';
import '../utils/game_config_loader.dart';
import '../game/paper_dialog.dart';
import '../game/paper_button.dart';

/// 待交易物品
class PendingTradeItem {
  final String goodsId;
  final int quantity;
  final bool isBuying; // true=换入（从商人获得），false=换出（给商人）
  final double unitPrice; // 保留用于向后兼容，实际不再使用
  final double totalPrice; // 增量计算的总价

  PendingTradeItem({
    required this.goodsId,
    required this.quantity,
    required this.isBuying,
    required this.unitPrice,
    required this.totalPrice,
  });
}

/// 待交易集合
class PendingTrade {
  final List<PendingTradeItem> itemsToReceive = []; // 玩家要换入的物品（从商人那里获得）
  final List<PendingTradeItem> itemsToGive = []; // 玩家要换出的物品（给商人）
  final TradeSystem? tradeSystem; // 用于获取商品基础价格

  PendingTrade({this.tradeSystem});

  /// 计算玩家换出的总价值（基于实际价格，考虑库存变化）
  double get playerGivenValue {
    double value = 0.0;
    for (final item in itemsToGive) {
      if (item.goodsId == 'gold') {
        value += item.quantity; // 金币1:1
      } else {
        // 使用实际计算的总价（考虑库存变化）
        value += item.totalPrice;
      }
    }
    return value;
  }

  /// 计算玩家换入的总价值（基于实际价格，考虑库存变化）
  double get playerReceivedValue {
    double value = 0.0;
    for (final item in itemsToReceive) {
      if (item.goodsId == 'gold') {
        value += item.quantity; // 金币1:1
      } else {
        // 使用实际计算的总价（考虑库存变化）
        value += item.totalPrice;
      }
    }
    return value;
  }

  /// 计算交易偏向
  /// 返回 -1.0 到 1.0，-1.0=完全偏向商人，0.0=公平，1.0=完全偏向玩家
  /// 基于交换价值差异：偏向 = (换入价值 - 换出价值) / 总价值
  double calculateTradeFavor() {
    final given = playerGivenValue;
    final received = playerReceivedValue;
    final valueDiff = received - given;

    if (given == 0 && received == 0) return 0.0;
    if (given == 0) return 1.0; // 完全偏向玩家（玩家没换出）
    if (received == 0) return -1.0; // 完全偏向商人（玩家没换入）

    final totalValue = given + received;
    // 换入价值 > 换出价值 = 偏向玩家，换入价值 < 换出价值 = 偏向商人
    return valueDiff / totalValue;
  }

  /// 判断商人是否接受交易
  /// 商人只接受偏向自己（favor < 0）或公平（favor == 0）的交易
  bool isTradeAcceptable() {
    final favor = calculateTradeFavor();
    return favor <= 0.0;
  }

  /// 计算待换入物品的总重量（kg）
  double getTotalReceiveWeight() {
    if (tradeSystem == null) return 0.0;
    double totalWeight = 0.0;
    for (final item in itemsToReceive) {
      if (item.goodsId != 'gold') {
        final goods = tradeSystem!.getGoods(item.goodsId);
        totalWeight += item.quantity * goods.weight;
      }
    }
    return totalWeight;
  }

  /// 计算待换出物品释放的总重量（kg）
  double getTotalGiveWeight() {
    if (tradeSystem == null) return 0.0;
    double totalWeight = 0.0;
    for (final item in itemsToGive) {
      if (item.goodsId != 'gold') {
        final goods = tradeSystem!.getGoods(item.goodsId);
        totalWeight += item.quantity * goods.weight;
      }
    }
    return totalWeight;
  }

  void clear() {
    itemsToReceive.clear();
    itemsToGive.clear();
  }
}

/// 贸易系统 - 简化的买卖界面
class TradeSystem {
  final GameState gameState;
  final GameConfigLoader _configLoader = GameConfigLoader();
  
  // 商品列表由加载器提供
  List<Goods> get _goodsList => _configLoader.goodsList;

  TradeSystem(this.gameState);

  /// 计算补货增量
  /// [merchantMoney] 商人资金（m）
  /// [currentStock] 当前库存（sT）
  /// [expectedStock] 期望库存（s0）
  /// 返回补货增量（delta），正数表示增加库存，负数表示减少库存
  static int calculateRestockingDelta(int merchantMoney, int currentStock, int expectedStock) {
    if (currentStock > expectedStock) {
      // 库存过多，减少库存
      // delta = -ceil(2 * ln(1+m) * (sT - s0))
      final value = 2 * log(1 + merchantMoney) * (currentStock - expectedStock);
      final delta = -value.ceil();
      return delta;
    } else if (currentStock < expectedStock) {
      // 库存不足，增加库存
      // delta = ceil(ln(1+m) * (s0 - sT))
      final value = log(1 + merchantMoney) * (expectedStock - currentStock);
      final delta = value.ceil();
      return delta;
    } else {
      // 库存正好，不变化
      return 0;
    }
  }

  /// 获取商品列表
  List<Goods> getGoodsList() {
    return List.unmodifiable(_goodsList);
  }

  /// 根据商品ID获取商品
  Goods _getGoods(String goodsId) {
    return _goodsList.firstWhere((g) => g.id == goodsId);
  }

  /// 根据商品ID获取商品（公开方法，供PendingTrade使用）
  Goods getGoods(String goodsId) {
    return _getGoods(goodsId);
  }

  /// 获取港口商品价格
  /// [pendingStockAdjustment] pending物品对库存的调整（要从库存中减去的数量）
  PortGoodsPrice getPortGoodsPrice(String portId, String goodsId, {int pendingStockAdjustment = 0}) {
    // 金币特殊处理：价格永远是1:1
    if (goodsId == 'gold') {
      return PortGoodsPrice(
        portId: portId,
        goodsId: goodsId,
        buyPrice: 1.0,
        sellPrice: 1.0,
        stock: 0, // 金币库存由实际资金决定
      );
    }

    // 获取港口信息
    final port = gameState.ports.firstWhere(
      (p) => p.id == portId,
      orElse: () => throw Exception('Port not found: $portId'),
    );
    
    // 获取港口对该商品的配置（alpha 和 s0）
    final config = port.getGoodsConfig(goodsId);
    if (config == null) {
      throw Exception('Goods config not found for port $portId, goods $goodsId');
    }
    
    // 获取价格基准库存（用于价格计算，每7天更新一次）
    final priceBaseS = port.getPriceBaseStock(goodsId);
    final S0 = config.s0; // 正常库存基准
    // 如果价格基准库存为0，使用 s0 作为默认值
    // 考虑pending物品对库存的影响
    final actualStock = ((priceBaseS > 0 ? priceBaseS : S0) - pendingStockAdjustment).clamp(0, double.infinity).toInt();
    
    // 获取商品参数
    final P0 = config.basePrice; // 基础价格从港口配置获取
    final alpha = config.alpha; // 价格敏感度（从港口配置获取）
    
    // 计算商人的出售价（玩家购买价）：P_sell = P₀ · e^(-α((S - S₀)/100))
    final merchantSellPrice = P0 * exp(-alpha * ((actualStock - S0) / 100));
    
    // 计算商人的收购价（玩家出售价）：P_buy = P_sell * (1 - α)²
    final merchantBuyPrice = merchantSellPrice * (1 - alpha) * (1 - alpha);
    
    return PortGoodsPrice(
      portId: portId,
      goodsId: goodsId,
      buyPrice: merchantSellPrice, // 玩家买入价格 = 商人出售价
      sellPrice: merchantBuyPrice,  // 玩家卖出价格 = 商人收购价
      stock: actualStock,
    );
  }

  /// 计算增量购买价格（每个商品的价格基于前一个商品购买后的库存）
  /// [portId] 港口ID
  /// [goodsId] 商品ID
  /// [quantity] 购买数量
  /// [pendingStockAdjustment] pending物品对库存的调整（要从库存中减去的数量）
  /// 返回购买指定数量商品的总价，每个商品的价格基于前一个商品购买后的库存计算
  double calculateIncrementalBuyPrice(String portId, String goodsId, int quantity, {int pendingStockAdjustment = 0}) {
    // 金币特殊处理：总价 = quantity（1:1）
    if (goodsId == 'gold') {
      return quantity.toDouble();
    }

    // 获取港口信息
    final port = gameState.ports.firstWhere(
      (p) => p.id == portId,
      orElse: () => throw Exception('Port not found: $portId'),
    );

    // 获取港口对该商品的配置（alpha 和 s0）
    final config = port.getGoodsConfig(goodsId);
    if (config == null) {
      throw Exception('Goods config not found for port $portId, goods $goodsId');
    }

    // 获取价格基准库存（用于价格计算，每7天更新一次）
    final priceBaseS = port.getPriceBaseStock(goodsId);
    final S0 = config.s0; // 正常库存基准
    // 如果价格基准库存为0，使用 s0 作为默认值
    // 考虑pending物品对库存的影响
    int currentStock = ((priceBaseS > 0 ? priceBaseS : S0) - pendingStockAdjustment).clamp(0, double.infinity).toInt();

    // 获取商品参数
    final P0 = config.basePrice; // 基础价格从港口配置获取
    final alpha = config.alpha; // 价格敏感度
    

    // 计算增量总价：每个商品的价格基于前一个商品购买后的库存
    double totalPrice = 0.0;
    for (int i = 0; i < quantity; i++) {
      // 计算当前库存下的价格：P_sell = P₀ · e^(-α((currentStock - S₀)/100))
      final price = P0 * exp(-alpha * ((currentStock - S0) / 100));
      totalPrice += price;
      // 减少库存（为下一个商品计算）
      currentStock = ((currentStock - 1).clamp(0, double.infinity)).toInt();
    }

    return totalPrice;
  }

  /// 购买商品
  bool buyGoods(String goodsId, int quantity) {
    if (gameState.currentPort == null) return false;
    
    final portId = gameState.currentPort!.id;
    final price = getPortGoodsPrice(portId, goodsId);
    final totalCost = (price.buyPrice * quantity).round();
    
    // 检查金币
    if (gameState.gold < totalCost) {
      return false;
    }
    
    // 检查载货空间（基于重量）
    final goods = _getGoods(goodsId);
    final additionalWeight = quantity * goods.weight;
    // 如果重量为0（如金币），不需要检查载货空间
    if (additionalWeight > 0) {
      if (!gameState.ship.hasEnoughCargo(
        gameState.inventory,
        additionalWeight,
        _getGoods,
      )) {
        return false;
      }
    }
    
    // 执行购买
    if (gameState.spendGold(totalCost)) {
      final success = gameState.addToInventory(goodsId, quantity, getGoodsById: _getGoods);
      if (success) {
        // 购买成功后，减少港口库存
        final port = gameState.ports.firstWhere((p) => p.id == portId);
        final currentStock = port.getGoodsStock(goodsId);
        final config = port.getGoodsConfig(goodsId);
        // 如果库存为0，使用配置 of s0 作为当前库存
        final actualCurrentStock = currentStock > 0 ? currentStock : (config?.s0 ?? 50);
        final newStock = (actualCurrentStock - quantity).clamp(0, double.infinity).toInt();
        gameState.updatePortGoodsStock(portId, goodsId, newStock);
        
        // 商人获得金币
        gameState.updatePortMerchantMoney(portId, port.merchantMoney + totalCost);
      }
      return success;
    }
    
    return false;
  }

  /// 出售商品
  bool sellGoods(String goodsId, int quantity) {
    if (gameState.currentPort == null) return false;
    
    final portId = gameState.currentPort!.id;
    
    // 检查库存
    final inventoryQuantity = gameState.getInventoryQuantity(goodsId);
    if (inventoryQuantity < quantity) {
      return false;
    }
    
    final price = getPortGoodsPrice(portId, goodsId);
    final totalEarn = (price.sellPrice * quantity).round();
    
    // 执行出售
    if (gameState.removeFromInventory(goodsId, quantity)) {
      gameState.addGold(totalEarn);
      // 出售成功后，增加港口库存
      final port = gameState.ports.firstWhere((p) => p.id == portId);
      final currentStock = port.getGoodsStock(goodsId);
      final config = port.getGoodsConfig(goodsId);
      // 如果库存为0，使用配置 of s0 作为当前库存
      final actualCurrentStock = currentStock > 0 ? currentStock : (config?.s0 ?? 50);
      final newStock = actualCurrentStock + quantity;
      gameState.updatePortGoodsStock(portId, goodsId, newStock);
      
      // 商人支付金币（确保不为负）
      final newMerchantMoney = (port.merchantMoney - totalEarn).clamp(0, double.infinity).toInt();
      gameState.updatePortMerchantMoney(portId, newMerchantMoney);
      return true;
    }
    
    return false;
  }

  /// 执行pending交易（基于交换机制）
  /// 返回执行结果消息，如果失败返回错误消息
  String? executePendingTrade(PendingTrade pendingTrade) {
    if (gameState.currentPort == null) {
      return '当前不在港口';
    }

    // 检查交易是否可接受
    if (!pendingTrade.isTradeAcceptable()) {
      return '商人拒绝此交易（交易偏向玩家）';
    }

    final portId = gameState.currentPort!.id;
    final port = gameState.ports.firstWhere((p) => p.id == portId);

    // 检查玩家是否有足够的物品换出
    for (final item in pendingTrade.itemsToGive) {
      if (item.goodsId == 'gold') {
        if (gameState.gold < item.quantity) {
          return '金币不足';
        }
      } else {
        final inventoryQuantity = gameState.getInventoryQuantity(item.goodsId);
        if (inventoryQuantity < item.quantity) {
          return '${_getGoods(item.goodsId).name} 库存不足';
        }
      }
    }

    // 检查玩家是否有足够的载货空间（基于重量）
    // 计算换出物品释放的重量
    double totalGiveWeight = 0.0;
    for (final item in pendingTrade.itemsToGive) {
      if (item.goodsId != 'gold') {
        final goods = _getGoods(item.goodsId);
        totalGiveWeight += item.quantity * goods.weight;
      }
    }
    // 计算换入物品需要的重量
    double totalReceiveWeight = 0.0;
    for (final item in pendingTrade.itemsToReceive) {
      if (item.goodsId != 'gold') {
        final goods = _getGoods(item.goodsId);
        totalReceiveWeight += item.quantity * goods.weight;
      }
    }
    // 计算移除换出物品后的剩余空间
    final currentUsedCargo = gameState.ship.getUsedCargo(gameState.inventory, _getGoods);
    final spaceAfterGive = gameState.ship.cargoCapacity.toDouble() - (currentUsedCargo - totalGiveWeight);
    // 检查剩余空间是否足够容纳换入的物品
    if (totalReceiveWeight > spaceAfterGive) {
      return '载货空间不足';
    }

    // 检查商人是否有足够的物品换出
    for (final item in pendingTrade.itemsToReceive) {
      if (item.goodsId == 'gold') {
        if (port.merchantMoney < item.quantity) {
          return '商人金币不足';
        }
      } else {
        final portStock = port.getGoodsStock(item.goodsId);
        final config = port.getGoodsConfig(item.goodsId);
        final actualStock = portStock > 0 ? portStock : (config?.s0 ?? 50);
        if (actualStock < item.quantity) {
          return '${_getGoods(item.goodsId).name} 港口库存不足';
        }
      }
    }

    // 执行交换：玩家换出的物品 → 给商人
    for (final item in pendingTrade.itemsToGive) {
      if (item.goodsId == 'gold') {
        gameState.spendGold(item.quantity);
        // 获取最新的port对象
        final updatedPort = gameState.ports.firstWhere((p) => p.id == portId);
        gameState.updatePortMerchantMoney(portId, updatedPort.merchantMoney + item.quantity);
      } else {
        if (gameState.removeFromInventory(item.goodsId, item.quantity)) {
          // 获取最新的port对象
          final updatedPort = gameState.ports.firstWhere((p) => p.id == portId);
          // 使用实际库存（goodsStock），如果不存在则从0开始
          final currentStock = updatedPort.getGoodsStock(item.goodsId);
          final newStock = currentStock + item.quantity;
          gameState.updatePortGoodsStock(portId, item.goodsId, newStock);
        }
      }
    }

    // 执行交换：玩家换入的物品 ← 从商人
    for (final item in pendingTrade.itemsToReceive) {
      if (item.goodsId == 'gold') {
        gameState.addGold(item.quantity);
        // 获取最新的port对象
        final updatedPort = gameState.ports.firstWhere((p) => p.id == portId);
        gameState.updatePortMerchantMoney(portId, updatedPort.merchantMoney - item.quantity);
      } else {
        if (gameState.addToInventory(item.goodsId, item.quantity, getGoodsById: _getGoods)) {
          // 获取最新的port对象
          final updatedPort = gameState.ports.firstWhere((p) => p.id == portId);
          // 使用实际库存（goodsStock），确保库存不会为负
          final currentStock = updatedPort.getGoodsStock(item.goodsId);
          final newStock = (currentStock - item.quantity).clamp(0, double.infinity).toInt();
          gameState.updatePortGoodsStock(portId, item.goodsId, newStock);
        }
      }
    }

    // 清空pending列表
    pendingTrade.clear();
    return null; // 成功
  }

  /// 显示交易界面
  static void showTradeDialog(BuildContext context, TradeSystem tradeSystem) {
    showDialog(
      context: context,
      builder: (context) => _TradeDialog(tradeSystem: tradeSystem),
    );
  }
}

/// 交易界面对话框
class _TradeDialog extends StatefulWidget {
  final TradeSystem tradeSystem;

  const _TradeDialog({required this.tradeSystem});

  @override
  State<_TradeDialog> createState() => _TradeDialogState();
}

class _TradeDialogState extends State<_TradeDialog> {
  late final PendingTrade _pendingTrade;
  
  // 当前选中的货物（用于显示滑块）
  String? _selectedMerchantGoodsId; // 商人库存中选中的货物
  String? _selectedPlayerGoodsId; // 玩家库存中选中的货物
  int _selectedQuantity = 1; // 当前选中的数量

  @override
  void initState() {
    super.initState();
    _pendingTrade = PendingTrade(tradeSystem: widget.tradeSystem);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = widget.tradeSystem.gameState;
    final goodsList = widget.tradeSystem.getGoodsList();
    final currentPort = gameState.currentPort;

    if (currentPort == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('当前不在港口'),
        ),
      );
    }

    final port = gameState.ports.firstWhere((p) => p.id == currentPort.id);
    final favor = _pendingTrade.calculateTradeFavor();
    final isAcceptable = _pendingTrade.isTradeAcceptable();

    return PaperDialog(
      assetPath: 'assets/paper_ui/Sprites/Book Desk/7.png',
      width: 1000,
      height: 800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '交易 Trade - ${currentPort.name}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4E342E),
                ),
              ),
              PaperButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF4E342E), size: 20),
                style: PaperButtonStyle.brown,
                width: 40,
                height: 40,
              ),
            ],
          ),
          const Divider(color: Color(0xFF8D6E63)),

          // 主要内容区域
          Expanded(
            child: Row(
              children: [
                // 左侧：商人库存
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '商人库存 Merchant',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildMerchantInventory(goodsList, port),
                      ),
                      if (_selectedMerchantGoodsId != null)
                        _buildSliderPanel(
                          _selectedMerchantGoodsId!,
                          _getMerchantStock(port, _selectedMerchantGoodsId!),
                          true,
                          currentPort.id,
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // 中间：天平与待交易
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildValueDisplay(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildPendingArea(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // 右侧：玩家库存
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlayerHeader(gameState),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildPlayerInventory(gameState, goodsList),
                      ),
                      if (_selectedPlayerGoodsId != null)
                        _buildSliderPanel(
                          _selectedPlayerGoodsId!,
                          _getPlayerStock(_selectedPlayerGoodsId!),
                          false,
                          currentPort.id,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          TradeBalanceBar(favor: favor),
          const SizedBox(height: 16),

          // 平衡报价按钮
          Center(
            child: PaperButton(
              onPressed: _canBalanceTrade() ? () => _balanceTrade() : null,
              label: '平衡报价',
              style: PaperButtonStyle.brown,
              width: 100,
              height: 40,
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _canBalanceTrade() ? const Color(0xFF4E342E) : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 确认按钮
          Center(
            child: PaperButton(
              onPressed: (_pendingTrade.itemsToReceive.isNotEmpty ||
                          _pendingTrade.itemsToGive.isNotEmpty) &&
                      isAcceptable
                  ? () => _executeTrade()
                  : null,
              label: isAcceptable ? '确认交易' : '交易不公平',
              style: isAcceptable ? PaperButtonStyle.green : PaperButtonStyle.brown,
              width: 120,
              height: 48,
              textStyle: const TextStyle(
                fontSize: 18,
                color: Color(0xFF4E342E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantInventory(List<Goods> goodsList, Port port) {
    final merchantGoodsList = goodsList.where((goods) {
      int actualStock;
      if (goods.id == 'gold') {
        actualStock = (port.merchantMoney - _getPendingMerchantStockAdjustment(goods.id)).clamp(0, double.infinity).toInt();
      } else {
        final portStock = port.getGoodsStock(goods.id);
        final config = port.getGoodsConfig(goods.id);
        final baseStock = portStock > 0 ? portStock : (config?.s0 ?? 50);
        actualStock = (baseStock - _getPendingMerchantStockAdjustment(goods.id)).clamp(0, double.infinity).toInt();
      }
      return actualStock > 0;
    }).toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: merchantGoodsList.length,
      itemBuilder: (context, index) {
        final goods = merchantGoodsList[index];
        final portStock = port.getGoodsStock(goods.id);
        final config = port.getGoodsConfig(goods.id);
        final baseStock = (goods.id == 'gold')
            ? port.merchantMoney
            : (portStock > 0 ? portStock : (config?.s0 ?? 50));
        int actualStock = (baseStock - _getPendingMerchantStockAdjustment(goods.id))
            .clamp(0, double.infinity)
            .toInt();

        return GoodsSlot(
          goods: goods,
          quantity: actualStock,
          isSelected: _selectedMerchantGoodsId == goods.id,
          onTap: () => setState(() {
            _selectedMerchantGoodsId = _selectedMerchantGoodsId == goods.id ? null : goods.id;
            _selectedPlayerGoodsId = null;
            _selectedQuantity = 1;
          }),
        );
      },
    );
  }

  Widget _buildPlayerInventory(GameState gameState, List<Goods> goodsList) {
    final playerGoodsList = goodsList.where((goods) {
      int qty = goods.id == 'gold' 
          ? gameState.gold 
          : gameState.getInventoryQuantity(goods.id);
      qty -= _getPendingPlayerStockAdjustment(goods.id);
      return qty > 0;
    }).toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: playerGoodsList.length,
      itemBuilder: (context, index) {
        final goods = playerGoodsList[index];
        int qty = (goods.id == 'gold' ? gameState.gold : gameState.getInventoryQuantity(goods.id)) - _getPendingPlayerStockAdjustment(goods.id);

        return GoodsSlot(
          goods: goods,
          quantity: qty,
          isSelected: _selectedPlayerGoodsId == goods.id,
          onTap: () => setState(() {
            _selectedPlayerGoodsId = _selectedPlayerGoodsId == goods.id ? null : goods.id;
            _selectedMerchantGoodsId = null;
            _selectedQuantity = 1;
          }),
        );
      },
    );
  }

  Widget _buildValueDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8D6E63)),
      ),
      child: Column(
        children: [
          _buildValueRow('玩家获得', _pendingTrade.playerReceivedValue, Colors.green[800]!),
          const Divider(color: Color(0xFF8D6E63)),
          _buildValueRow('玩家支付', _pendingTrade.playerGivenValue, Colors.blue[800]!),
        ],
      ),
    );
  }

  Widget _buildValueRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037))),
        Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPendingArea() {
    return Row(
      children: [
        Expanded(child: _buildPendingColumn('换入', _pendingTrade.itemsToReceive, true)),
        const VerticalDivider(color: Color(0xFF8D6E63)),
        Expanded(child: _buildPendingColumn('换出', _pendingTrade.itemsToGive, false)),
      ],
    );
  }

  Widget _buildPendingColumn(String title, List<PendingTradeItem> items, bool isReceive) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFD7CCC8).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8D6E63).withValues(alpha: 0.3)),
            ),
            child: const Center(child: Icon(Icons.add, color: Color(0xFF8D6E63))),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final goods = widget.tradeSystem.getGoods(item.goodsId);
                return GoodsSlot(
                  goods: goods,
                  quantity: item.quantity,
                  isLarge: false,
                  onRemove: () => setState(() => items.removeAt(index)),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerHeader(GameState gameState) {
    final currentWeight = gameState.usedCargoWeight;
    final previewWeight = currentWeight - _pendingTrade.getTotalGiveWeight() + _pendingTrade.getTotalReceiveWeight();
    final capacity = gameState.ship.cargoCapacity;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('玩家库存 Player', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
        Text(
          '${previewWeight.toStringAsFixed(1)}/$capacity kg',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: previewWeight > capacity ? Colors.red[800] : const Color(0xFF5D4037),
          ),
        ),
      ],
    );
  }

  /// 获取商人库存
  int _getMerchantStock(Port port, String goodsId) {
    if (goodsId == 'gold') {
      return port.merchantMoney;
    } else {
      final portStock = port.getGoodsStock(goodsId);
      final config = port.getGoodsConfig(goodsId);
      return portStock > 0 ? portStock : (config?.s0 ?? 50);
    }
  }

  /// 获取玩家库存（用于滑块面板的原始数量）
  int _getPlayerStock(String goodsId) {
    if (goodsId == 'gold') {
      return widget.tradeSystem.gameState.gold;
    } else {
      return widget.tradeSystem.gameState.getInventoryQuantity(goodsId);
    }
  }

  /// 获取pending中要从商人库存减去的数量
  int _getPendingMerchantStockAdjustment(String goodsId) {
    try {
      final pendingItem = _pendingTrade.itemsToReceive.firstWhere((item) => item.goodsId == goodsId);
      return pendingItem.quantity;
    } catch (e) {
      return 0;
    }
  }

  /// 获取pending中要从玩家库存减去的数量
  int _getPendingPlayerStockAdjustment(String goodsId) {
    try {
      final pendingItem = _pendingTrade.itemsToGive.firstWhere((item) => item.goodsId == goodsId);
      return pendingItem.quantity;
    } catch (e) {
      return 0;
    }
  }

  /// 构建滑块面板
  Widget _buildSliderPanel(String goodsId, int maxQuantity, bool isBuying, String portId) {
    if (maxQuantity <= 0) return const SizedBox.shrink();
    final goods = widget.tradeSystem.getGoodsList().firstWhere((g) => g.id == goodsId);
    final existingPendingQuantity = isBuying ? _getPendingMerchantStockAdjustment(goodsId) : _getPendingPlayerStockAdjustment(goodsId);
    final availableMaxQuantity = (maxQuantity - existingPendingQuantity).clamp(1, maxQuantity);
    
    double addPrice = isBuying 
        ? widget.tradeSystem.calculateIncrementalBuyPrice(portId, goodsId, _selectedQuantity, pendingStockAdjustment: existingPendingQuantity)
        : widget.tradeSystem.getPortGoodsPrice(portId, goodsId, pendingStockAdjustment: existingPendingQuantity).sellPrice * _selectedQuantity;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8D6E63), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${isBuying ? "购买" : "出售"}: ${goods.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
              Text('x $_selectedQuantity', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
            ],
          ),
          Slider(
            value: _selectedQuantity.toDouble(),
            min: 1,
            max: availableMaxQuantity.toDouble(),
            divisions: availableMaxQuantity > 1 ? availableMaxQuantity - 1 : 1,
            activeColor: const Color(0xFF5D4037),
            inactiveColor: const Color(0xFF8D6E63).withValues(alpha: 0.3),
            onChanged: (v) => setState(() => _selectedQuantity = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('估值: ${addPrice.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
              Row(
                children: [
                  PaperButton(
                    onPressed: () => setState(() => _selectedMerchantGoodsId = _selectedPlayerGoodsId = null),
                    label: '取消',
                    style: PaperButtonStyle.brown,
                    width: 80,
                    height: 32,
                  ),
                  const SizedBox(width: 8),
                  PaperButton(
                    onPressed: () {
                      _addToPending(goodsId, _selectedQuantity, isBuying, portId);
                      setState(() => _selectedMerchantGoodsId = _selectedPlayerGoodsId = null);
                    },
                    label: '确认',
                    style: PaperButtonStyle.brown,
                    width: 80,
                    height: 32,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addToPending(String goodsId, int addQuantity, bool isBuying, String portId) {
    setState(() {
      _internalAddToPending(goodsId, addQuantity, isBuying, portId);
    });
  }

  void _internalAddToPending(String goodsId, int addQuantity, bool isBuying, String portId) {
    final items = isBuying ? _pendingTrade.itemsToReceive : _pendingTrade.itemsToGive;
    final idx = items.indexWhere((item) => item.goodsId == goodsId);
    
    if (idx >= 0) {
      final newQty = items[idx].quantity + addQuantity;
      double newTotal = isBuying 
          ? widget.tradeSystem.calculateIncrementalBuyPrice(portId, goodsId, newQty)
          : widget.tradeSystem.getPortGoodsPrice(portId, goodsId).sellPrice * newQty;
      items[idx] = PendingTradeItem(goodsId: goodsId, quantity: newQty, isBuying: isBuying, unitPrice: 0, totalPrice: newTotal);
    } else {
      double total = isBuying 
          ? widget.tradeSystem.calculateIncrementalBuyPrice(portId, goodsId, addQuantity)
          : widget.tradeSystem.getPortGoodsPrice(portId, goodsId).sellPrice * addQuantity;
      items.add(PendingTradeItem(goodsId: goodsId, quantity: addQuantity, isBuying: isBuying, unitPrice: 0, totalPrice: total));
    }
  }

  void _executeTrade() {
    final result = widget.tradeSystem.executePendingTrade(_pendingTrade);
    if (result == null) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('交易成功！'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('交易失败: $result'), backgroundColor: Colors.red));
    }
  }

  /// 判断是否可以平衡报价
  bool _canBalanceTrade() {
    // 1. 至少有一方提供了物品或金币
    if (_pendingTrade.itemsToReceive.isEmpty && _pendingTrade.itemsToGive.isEmpty) return false;
    
    // 2. 当前交易尚未平衡
    final favor = _pendingTrade.calculateTradeFavor();
    if (favor == 0) return false; // 已经公平
    
    final gameState = widget.tradeSystem.gameState;
    final portId = gameState.currentPort!.id;
    final port = gameState.ports.firstWhere((p) => p.id == portId);

    if (favor > 0) {
      // 玩家欠账 (玩家获得 > 玩家支付)：检查玩家库存
      final availableGold = gameState.gold - _getPendingPlayerStockAdjustment('gold');
      if (availableGold > 0) return true;
      
      for (final goods in widget.tradeSystem.getGoodsList()) {
        if (goods.id == 'gold') continue;
        final qty = gameState.getInventoryQuantity(goods.id) - _getPendingPlayerStockAdjustment(goods.id);
        if (qty > 0) return true;
      }
    } else {
      // 商人欠账 (玩家支付 > 玩家获得)：检查商人库存
      final availableGold = port.merchantMoney - _getPendingMerchantStockAdjustment('gold');
      if (availableGold > 0) return true;
      
      for (final goods in widget.tradeSystem.getGoodsList()) {
        if (goods.id == 'gold') continue;
        final qty = _getMerchantStock(port, goods.id) - _getPendingMerchantStockAdjustment(goods.id);
        if (qty > 0) return true;
      }
    }
    
    return false;
  }

  /// 执行平衡报价逻辑
  void _balanceTrade() {
    setState(() {
      final gameState = widget.tradeSystem.gameState;
      final portId = gameState.currentPort!.id;
      final port = gameState.ports.firstWhere((p) => p.id == portId);
      double deficit = _pendingTrade.playerReceivedValue - _pendingTrade.playerGivenValue;
      
      if (deficit == 0) return;

      if (deficit > 0) {
        // --- 玩家欠账 (玩家获得 > 玩家支付) ---
        // 1. 优先使用金币
        final availableGold = gameState.gold - _getPendingPlayerStockAdjustment('gold');
        if (availableGold > 0) {
          final goldToUse = min(deficit.ceil(), availableGold);
          if (goldToUse > 0) {
            _internalAddToPending('gold', goldToUse, false, portId);
            deficit = _pendingTrade.playerReceivedValue - _pendingTrade.playerGivenValue;
          }
        }

        // 2. 如果仍有差额，使用其他物品
        if (deficit > 0.1) {
          final otherGoods = widget.tradeSystem.getGoodsList()
              .where((g) => g.id != 'gold' && (gameState.getInventoryQuantity(g.id) - _getPendingPlayerStockAdjustment(g.id)) > 0)
              .toList();
          
          // 按单价降序排列，尝试用最少的格子补齐
          otherGoods.sort((a, b) {
            final priceA = widget.tradeSystem.getPortGoodsPrice(portId, a.id).sellPrice;
            final priceB = widget.tradeSystem.getPortGoodsPrice(portId, b.id).sellPrice;
            return priceB.compareTo(priceA);
          });

          for (final goods in otherGoods) {
            if (deficit <= 0.1) break;
            
            final availableQty = gameState.getInventoryQuantity(goods.id) - _getPendingPlayerStockAdjustment(goods.id);
            final unitPrice = widget.tradeSystem.getPortGoodsPrice(portId, goods.id).sellPrice;
            
            if (unitPrice <= 0) continue;
            
            // 需要的数量 = ceil(剩余差额 / 单价)
            int qtyNeeded = (deficit / unitPrice).ceil();
            int qtyToUse = min(qtyNeeded, availableQty);
            
            if (qtyToUse > 0) {
              _internalAddToPending(goods.id, qtyToUse, false, portId);
              deficit = _pendingTrade.playerReceivedValue - _pendingTrade.playerGivenValue;
            }
          }
        }
      } else {
        // --- 商人欠账 (玩家支付 > 玩家获得) ---
        double merchantDeficit = -deficit; // 玩家付多了，商人需要补足价值给玩家
        
        // 1. 优先使用金币
        final availableGold = port.merchantMoney - _getPendingMerchantStockAdjustment('gold');
        if (availableGold > 0) {
          // 商人提供的价值不能超过差额，否则会导致交易不公平 (favor > 0)，所以用 floor
          final goldToUse = min(merchantDeficit.floor(), availableGold);
          if (goldToUse > 0) {
            _internalAddToPending('gold', goldToUse, true, portId);
            merchantDeficit = _pendingTrade.playerGivenValue - _pendingTrade.playerReceivedValue;
          }
        }

        // 2. 如果仍有差额，使用其他物品 (需检查玩家载货空间)
        if (merchantDeficit > 0.1) {
          final otherGoods = widget.tradeSystem.getGoodsList()
              .where((g) => g.id != 'gold' && (_getMerchantStock(port, g.id) - _getPendingMerchantStockAdjustment(g.id)) > 0)
              .toList();
          
          // 按单价降序排列
          otherGoods.sort((a, b) {
            final priceA = widget.tradeSystem.getPortGoodsPrice(portId, a.id).buyPrice;
            final priceB = widget.tradeSystem.getPortGoodsPrice(portId, b.id).buyPrice;
            return priceB.compareTo(priceA);
          });

          final capacity = gameState.ship.cargoCapacity;

          for (final goods in otherGoods) {
            if (merchantDeficit <= 0.1) break;
            
            int availableQty = _getMerchantStock(port, goods.id) - _getPendingMerchantStockAdjustment(goods.id);
            
            while (availableQty > 0 && merchantDeficit > 0.1) {
              // 检查载货空间
              final currentWeight = gameState.usedCargoWeight;
              final previewWeight = currentWeight - _pendingTrade.getTotalGiveWeight() + _pendingTrade.getTotalReceiveWeight();
              if (previewWeight + goods.weight > capacity) break;

              // 计算下一个货物的价格 (基于当前 pending 调整)
              final nextPrice = widget.tradeSystem.getPortGoodsPrice(
                portId, 
                goods.id, 
                pendingStockAdjustment: _getPendingMerchantStockAdjustment(goods.id)
              ).buyPrice;
              
              // 不能让商人亏本 (总获得 < 总支付)，所以添加后的价格不能超过剩余差额
              if (nextPrice > merchantDeficit + 0.1) break;

              _internalAddToPending(goods.id, 1, true, portId);
              merchantDeficit = _pendingTrade.playerGivenValue - _pendingTrade.playerReceivedValue;
              availableQty--;
            }
          }
        }
      }
    });
  }
}

/// 物品格组件
class GoodsSlot extends StatelessWidget {
  final Goods? goods;
  final int quantity;
  final bool isLarge;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const GoodsSlot({
    super.key,
    this.goods,
    this.quantity = 0,
    this.isLarge = true,
    this.isSelected = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 80.0 : 60.0;
    final fontSize = isLarge ? 12.0 : 10.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF5D4037) : const Color(0xFF8D6E63).withValues(alpha: 0.5),
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFFD7CCC8) : const Color(0xFFD7CCC8).withValues(alpha: 0.3),
        ),
        child: goods == null
            ? const Center(child: Icon(Icons.add, color: Color(0xFF8D6E63), size: 24))
            : Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (goods!.imagePath != null)
                          Image.asset(goods!.imagePath!, width: size * 0.5, height: size * 0.5, fit: BoxFit.contain)
                        else
                          Icon(goods!.id == 'gold' ? Icons.monetization_on : Icons.category, size: size * 0.5, color: const Color(0xFF8D6E63)),
                        const SizedBox(height: 2),
                        Text(goods!.name, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xFF4E342E)), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                        Text('x$quantity', style: TextStyle(fontSize: fontSize - 2, color: const Color(0xFF5D4037))),
                      ],
                    ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// 天平进度条组件
class TradeBalanceBar extends StatelessWidget {
  final double favor;

  const TradeBalanceBar({super.key, required this.favor});

  @override
  Widget build(BuildContext context) {
    Color color = favor < -0.1 ? Colors.red[800]! : (favor > 0.1 ? Colors.blue[800]! : Colors.green[800]!);
    String text = favor < -0.1 ? '偏向商人' : (favor > 0.1 ? '偏向玩家' : '公平交易');

    return Column(
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8D6E63), width: 2),
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFD7CCC8).withValues(alpha: 0.3),
          ),
          child: Stack(
            children: [
              Center(child: Container(width: 4, height: 20, color: const Color(0xFF5D4037))),
              Align(
                alignment: Alignment(favor, 0),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('← 偏向商人', style: TextStyle(fontSize: 10, color: Color(0xFF5D4037))),
            Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            const Text('偏向玩家 →', style: TextStyle(fontSize: 10, color: Color(0xFF5D4037))),
          ],
        ),
      ],
    );
  }
}
