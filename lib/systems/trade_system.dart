import 'dart:math';
import 'package:flutter/material.dart';
import '../models/goods.dart';
import '../models/port.dart';
import '../game/game_state.dart';
import '../game/scale_wrapper.dart';
import '../utils/game_config_loader.dart';

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
        // 如果库存为0，使用配置的 s0 作为当前库存
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
      // 如果库存为0，使用配置的 s0 作为当前库存
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

    return ScaleWrapper(
      child: Dialog(
        backgroundColor: Colors.white,
        child: Container(
          width: 900,
          height: 700,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '交易 - ${currentPort.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),

            // 主要内容区域
            Expanded(
              child: Row(
                children: [
                  // 左侧：商人库存（大格）
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '商人库存',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              // 过滤商人库存，只显示库存 > 0 的商品
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
                                  
                                  // 金币特殊处理
                                  int actualStock;
                                  if (goods.id == 'gold') {
                                    // 金币也要减去pending中要从商人库存减去的数量
                                    actualStock = (port.merchantMoney - _getPendingMerchantStockAdjustment(goods.id)).clamp(0, double.infinity).toInt();
                                  } else {
                                    final portStock = port.getGoodsStock(goods.id);
                                    final config = port.getGoodsConfig(goods.id);
                                    final baseStock = portStock > 0 ? portStock : (config?.s0 ?? 50);
                                    // 减去pending中要从商人库存减去的数量
                                    actualStock = (baseStock - _getPendingMerchantStockAdjustment(goods.id)).clamp(0, double.infinity).toInt();
                                  }

                                  final isSelected = _selectedMerchantGoodsId == goods.id;
                                  
                                  return GoodsSlot(
                                    goods: goods,
                                    quantity: actualStock,
                                    isLarge: true,
                                    isSelected: isSelected,
                                    onTap: actualStock > 0
                                        ? () {
                                            setState(() {
                                              if (_selectedMerchantGoodsId == goods.id) {
                                                _selectedMerchantGoodsId = null;
                                                _selectedPlayerGoodsId = null;
                                              } else {
                                                _selectedMerchantGoodsId = goods.id;
                                                _selectedPlayerGoodsId = null;
                                                _selectedQuantity = 1;
                                              }
                                            });
                                          }
                                        : null,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        // 滑块面板（在 GridView 下方）
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

                  // 中间：待换入和待换出区域（水平排列）
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // 价值显示
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    '玩家换入价值',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    _pendingTrade.playerReceivedValue.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const Text('↔', style: TextStyle(fontSize: 20)),
                              Column(
                                children: [
                                  const Text(
                                    '玩家换出价值',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    _pendingTrade.playerGivenValue.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 待换入和待换出区域
                        Expanded(
                          child: Row(
                            children: [
                              // 待换入区域
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 只显示1个格子
                                    if (_pendingTrade.itemsToReceive.isNotEmpty)
                                Builder(
                                  builder: (context) {
                                    final item = _pendingTrade.itemsToReceive[0];
                                    Goods? goods;
                                    try {
                                      goods = widget.tradeSystem.getGoodsList()
                                          .firstWhere((g) => g.id == item.goodsId);
                                    } catch (e) {
                                      // 如果找不到商品（可能是金币），使用null
                                      goods = null;
                                    }
                                    return GoodsSlot(
                                      goods: goods,
                                      quantity: item.quantity,
                                      isLarge: false,
                                      onRemove: () {
                                        setState(() {
                                          _pendingTrade.itemsToReceive.removeAt(0);
                                        });
                                      },
                                    );
                                  },
                                )
                              else
                                const GoodsSlot(isLarge: false),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // 待换出区域
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 只显示1个格子
                                    if (_pendingTrade.itemsToGive.isNotEmpty)
                                      Builder(
                                        builder: (context) {
                                          final item = _pendingTrade.itemsToGive[0];
                                          Goods? goods;
                                          try {
                                            goods = widget.tradeSystem.getGoodsList()
                                                .firstWhere((g) => g.id == item.goodsId);
                                          } catch (e) {
                                            // 如果找不到商品（可能是金币），使用null
                                            goods = null;
                                          }
                                          return GoodsSlot(
                                            goods: goods,
                                            quantity: item.quantity,
                                            isLarge: false,
                                            onRemove: () {
                                              setState(() {
                                                _pendingTrade.itemsToGive.removeAt(0);
                                              });
                                            },
                                          );
                                        },
                                      )
                                    else
                                      const GoodsSlot(isLarge: false),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 右侧：玩家库存（大格）
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '玩家库存',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Builder(
                              builder: (context) {
                                // 计算预览载货量（考虑pending物品）
                                final currentWeight = gameState.usedCargoWeight;
                                final receiveWeight = _pendingTrade.getTotalReceiveWeight();
                                final giveWeight = _pendingTrade.getTotalGiveWeight();
                                final previewWeight = currentWeight - giveWeight + receiveWeight;
                                
                                // 判断是否有pending物品（预览状态）
                                final hasPending = receiveWeight > 0 || giveWeight > 0;
                                
                                // 选择显示重量和颜色
                                final displayWeight = hasPending ? previewWeight : currentWeight;
                                final capacity = gameState.ship.cargoCapacity;
                                
                                Color weightColor;
                                if (hasPending) {
                                  // 有pending物品时，用黄色表示预览状态
                                  if (previewWeight > capacity) {
                                    weightColor = Colors.red; // 预览超载
                                  } else if (previewWeight > capacity * 0.9) {
                                    weightColor = Colors.orange; // 预览接近满载
                                  } else {
                                    weightColor = Colors.amber; // 预览正常（黄色表示未入库）
                                  }
                                } else {
                                  // 无pending物品时，正常颜色
                                  weightColor = currentWeight > capacity * 0.9
                                      ? Colors.red
                                      : currentWeight > capacity * 0.7
                                          ? Colors.orange
                                          : Colors.blue;
                                }
                                
                                return Text(
                                  '${displayWeight.toStringAsFixed(1)}/${capacity}kg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: weightColor,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              // 过滤玩家库存，只显示数量 > 0 的商品
                              final playerGoodsList = goodsList.where((goods) {
                                int inventoryQuantity;
                                if (goods.id == 'gold') {
                                  final baseGold = gameState.gold;
                                  inventoryQuantity = (baseGold - _getPendingPlayerStockAdjustment(goods.id)).clamp(0, double.infinity).toInt();
                                } else {
                                  final baseQuantity = gameState.getInventoryQuantity(goods.id);
                                  inventoryQuantity = (baseQuantity - _getPendingPlayerStockAdjustment(goods.id)).clamp(0, double.infinity).toInt();
                                }
                                return inventoryQuantity > 0;
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
                                  
                                  // 金币特殊处理
                                  int inventoryQuantity;
                                  if (goods.id == 'gold') {
                                    // 金币也要减去pending中要从玩家库存减去的数量
                                    final baseGold = gameState.gold;
                                    inventoryQuantity = (baseGold - _getPendingPlayerStockAdjustment(goods.id)).clamp(0, double.infinity).toInt();
                                  } else {
                                    final baseQuantity = gameState.getInventoryQuantity(goods.id);
                                    // 减去pending中要从玩家库存减去的数量
                                    inventoryQuantity = (baseQuantity - _getPendingPlayerStockAdjustment(goods.id)).clamp(0, double.infinity).toInt();
                                  }

                                  final isSelected = _selectedPlayerGoodsId == goods.id;

                                  return GoodsSlot(
                                    goods: goods,
                                    quantity: inventoryQuantity,
                                    isLarge: true,
                                    isSelected: isSelected,
                                    onTap: inventoryQuantity > 0
                                        ? () {
                                            setState(() {
                                              if (_selectedPlayerGoodsId == goods.id) {
                                                _selectedPlayerGoodsId = null;
                                                _selectedMerchantGoodsId = null;
                                              } else {
                                                _selectedPlayerGoodsId = goods.id;
                                                _selectedMerchantGoodsId = null;
                                                _selectedQuantity = 1;
                                              }
                                            });
                                          }
                                        : null,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        // 滑块面板（在 GridView 下方）
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

            // 天平进度条
            TradeBalanceBar(favor: favor),

            const SizedBox(height: 16),

            // 确认交易按钮
            Center(
              child: ElevatedButton(
                onPressed: (_pendingTrade.itemsToReceive.isNotEmpty ||
                            _pendingTrade.itemsToGive.isNotEmpty) &&
                        isAcceptable
                    ? () => _executeTrade()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAcceptable ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  isAcceptable
                      ? '确认交易'
                      : '交易不可接受（偏向玩家）',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
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
    // 从pending的itemsToReceive中查找该商品（玩家要从商人那里获得的）
    try {
      final pendingItem = _pendingTrade.itemsToReceive.firstWhere(
        (item) => item.goodsId == goodsId,
      );
      return pendingItem.quantity;
    } catch (e) {
      return 0;
    }
  }

  /// 获取pending中要从玩家库存减去的数量
  int _getPendingPlayerStockAdjustment(String goodsId) {
    // 从pending的itemsToGive中查找该商品（玩家要给商人的）
    try {
      final pendingItem = _pendingTrade.itemsToGive.firstWhere(
        (item) => item.goodsId == goodsId,
      );
      return pendingItem.quantity;
    } catch (e) {
      return 0;
    }
  }

  /// 构建滑块面板（在 GridView 下方显示）
  Widget _buildSliderPanel(String goodsId, int maxQuantity, bool isBuying, String portId) {
    if (maxQuantity <= 0) return const SizedBox.shrink();
    
    final goods = widget.tradeSystem.getGoodsList().firstWhere((g) => g.id == goodsId);
    
    // 获取已pending的数量
    final existingPendingQuantity = isBuying
        ? _getPendingMerchantStockAdjustment(goodsId)
        : _getPendingPlayerStockAdjustment(goodsId);
    
    // 计算可用的最大数量（总库存 - 已pending数量）
    final availableMaxQuantity = (maxQuantity - existingPendingQuantity).clamp(1, maxQuantity);
    
    // 计算新增价格（只计算新追加的部分）
    double addPriceCalculator(int addQty) {
      if (isBuying) {
        // 从当前库存减去已pending后，计算新增数量的增量价格
        return widget.tradeSystem.calculateIncrementalBuyPrice(
          portId,
          goodsId,
          addQty, // 只计算新增数量
          pendingStockAdjustment: existingPendingQuantity,
        );
      } else {
        // 对于出售，价格是固定的，直接乘以新增数量
        final price = widget.tradeSystem.getPortGoodsPrice(
          portId,
          goodsId,
          pendingStockAdjustment: existingPendingQuantity,
        );
        return price.sellPrice * addQty; // 只计算新增数量
      }
    }

    // 计算总价格（用于 _addToPending）
    double totalPriceCalculator(int addQty) {
      final totalQty = existingPendingQuantity + addQty;
      if (isBuying) {
        // 从原始库存开始，计算总数量的增量价格
        return widget.tradeSystem.calculateIncrementalBuyPrice(
          portId,
          goodsId,
          totalQty,
          pendingStockAdjustment: 0, // 从原始库存开始计算
        );
      } else {
        final price = widget.tradeSystem.getPortGoodsPrice(
          portId,
          goodsId,
          pendingStockAdjustment: 0,
        );
        return price.sellPrice * totalQty;
      }
    }

    final addPrice = addPriceCalculator(_selectedQuantity); // 新增价格（用于显示）
    final totalPrice = totalPriceCalculator(_selectedQuantity); // 总价格（用于 _addToPending）

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isBuying ? "购买" : "出售"}: ${goods.name}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                'x $_selectedQuantity',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 滑块（显示新增数量）
          Slider(
            value: _selectedQuantity.toDouble(),
            min: 1,
            max: availableMaxQuantity.toDouble(),
            divisions: availableMaxQuantity > 1 ? availableMaxQuantity - 1 : 1,
            label: '$_selectedQuantity',
            onChanged: (value) {
              setState(() {
                _selectedQuantity = value.round();
              });
            },
          ),
          const SizedBox(height: 8),
          // 总价和按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '总价: ${addPrice.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedMerchantGoodsId = null;
                        _selectedPlayerGoodsId = null;
                        _selectedQuantity = 1;
                      });
                    },
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _addToPending(goodsId, _selectedQuantity, isBuying, totalPrice, portId);
                      setState(() {
                        _selectedMerchantGoodsId = null;
                        _selectedPlayerGoodsId = null;
                        _selectedQuantity = 1;
                      });
                    },
                    child: const Text('确认'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 添加到pending列表（数量叠加）
  void _addToPending(String goodsId, int addQuantity, bool isBuying, double addTotalPrice, String portId) {
    setState(() {
      if (isBuying) {
        // 添加到待换入
        final existingIndex = _pendingTrade.itemsToReceive.indexWhere((item) => item.goodsId == goodsId);
        if (existingIndex >= 0) {
          // 叠加数量
          final existingItem = _pendingTrade.itemsToReceive[existingIndex];
          final newQuantity = existingItem.quantity + addQuantity;
          
          // 重新计算总价（基于总数量，考虑库存变化）
          // pendingAdjustment应该是已pending的数量（不包括当前物品，因为我们要重新计算总价）
          // 但是_getPendingMerchantStockAdjustment已经包含了当前物品，所以需要减去
          final pendingAdjustment = _getPendingMerchantStockAdjustment(goodsId) - existingItem.quantity;
          // 基于总数量重新计算增量价格（会从当前库存减去pendingAdjustment后开始计算newQuantity个物品）
          final newTotalPrice = widget.tradeSystem.calculateIncrementalBuyPrice(
            portId,
            goodsId,
            newQuantity,
            pendingStockAdjustment: pendingAdjustment,
          );
          
          final price = widget.tradeSystem.getPortGoodsPrice(
            portId,
            goodsId,
            pendingStockAdjustment: pendingAdjustment,
          );
          final unitPrice = price.buyPrice;
          
          _pendingTrade.itemsToReceive[existingIndex] = PendingTradeItem(
            goodsId: goodsId,
            quantity: newQuantity,
            isBuying: true,
            unitPrice: unitPrice,
            totalPrice: newTotalPrice,
          );
        } else {
          // 新物品，直接添加
          final price = widget.tradeSystem.getPortGoodsPrice(
            portId,
            goodsId,
            pendingStockAdjustment: _getPendingMerchantStockAdjustment(goodsId),
          );
          final unitPrice = price.buyPrice;
          
          if (_pendingTrade.itemsToReceive.isEmpty) {
            _pendingTrade.itemsToReceive.add(
              PendingTradeItem(
                goodsId: goodsId,
                quantity: addQuantity,
                isBuying: true,
                unitPrice: unitPrice,
                totalPrice: addTotalPrice,
              ),
            );
          } else {
            _pendingTrade.itemsToReceive[0] = PendingTradeItem(
              goodsId: goodsId,
              quantity: addQuantity,
              isBuying: true,
              unitPrice: unitPrice,
              totalPrice: addTotalPrice,
            );
          }
        }
      } else {
        // 添加到待换出
        final existingIndex = _pendingTrade.itemsToGive.indexWhere((item) => item.goodsId == goodsId);
        if (existingIndex >= 0) {
          // 叠加数量
          final existingItem = _pendingTrade.itemsToGive[existingIndex];
          final newQuantity = existingItem.quantity + addQuantity;
          
          // 重新计算总价（基于总数量）
          final pendingAdjustment = _getPendingPlayerStockAdjustment(goodsId) - existingItem.quantity;
          final price = widget.tradeSystem.getPortGoodsPrice(
            portId,
            goodsId,
            pendingStockAdjustment: pendingAdjustment,
          );
          final newTotalPrice = price.sellPrice * newQuantity;
          final unitPrice = price.sellPrice;
          
          _pendingTrade.itemsToGive[existingIndex] = PendingTradeItem(
            goodsId: goodsId,
            quantity: newQuantity,
            isBuying: false,
            unitPrice: unitPrice,
            totalPrice: newTotalPrice,
          );
        } else {
          // 新物品，直接添加
          final price = widget.tradeSystem.getPortGoodsPrice(
            portId,
            goodsId,
            pendingStockAdjustment: _getPendingPlayerStockAdjustment(goodsId),
          );
          final unitPrice = price.sellPrice;
          
          if (_pendingTrade.itemsToGive.isEmpty) {
            _pendingTrade.itemsToGive.add(
              PendingTradeItem(
                goodsId: goodsId,
                quantity: addQuantity,
                isBuying: false,
                unitPrice: unitPrice,
                totalPrice: addTotalPrice,
              ),
            );
          } else {
            _pendingTrade.itemsToGive[0] = PendingTradeItem(
              goodsId: goodsId,
              quantity: addQuantity,
              isBuying: false,
              unitPrice: unitPrice,
              totalPrice: addTotalPrice,
            );
          }
        }
      }
    });
  }


  void _executeTrade() {
    final result = widget.tradeSystem.executePendingTrade(_pendingTrade);
    if (result == null) {
      // 成功
      setState(() {
        // 刷新UI
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('交易成功！')),
      );
    } else {
      // 失败
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('交易失败: $result')),
      );
    }
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
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: goods != null
              ? (isSelected ? Colors.blue.shade100 : Colors.blue.shade50)
              : Colors.grey.shade100,
        ),
        child: goods == null
            ? const Center(
                child: Icon(Icons.add, color: Colors.grey),
              )
            : Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (goods!.imagePath != null)
                          Image.asset(
                            goods!.imagePath!,
                            width: size * 0.4,
                            height: size * 0.4,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.category,
                              size: size * 0.4,
                              color: Colors.blue.shade300,
                            ),
                          )
                        else
                          Icon(
                            goods!.id == 'gold' ? Icons.monetization_on : Icons.category,
                            size: size * 0.4,
                            color: Colors.blue.shade300,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          goods!.name,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$quantity',
                          style: TextStyle(
                            fontSize: fontSize - 2,
                            color: Colors.grey.shade700,
                          ),
                        ),
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
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
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
  final double favor; // -1.0 到 1.0

  const TradeBalanceBar({
    super.key,
    required this.favor,
  });

  @override
  Widget build(BuildContext context) {
    // 将 favor (-1.0 到 1.0) 转换为进度条位置 (0.0 到 1.0)
    // favor = -1.0 -> position = 0.0 (完全左侧)
    // favor = 0.0 -> position = 0.5 (中间)
    // favor = 1.0 -> position = 1.0 (完全右侧)
    final position = (favor + 1.0) / 2.0;

    String statusText;
    Color statusColor;
    if (favor < -0.1) {
      statusText = '偏向商人';
      statusColor = Colors.red;
    } else if (favor > 0.1) {
      statusText = '偏向玩家';
      statusColor = Colors.blue;
    } else {
      statusText = '公平交易';
      statusColor = Colors.green;
    }

    return Column(
      children: [
        Container(
          height: 30,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              // 背景
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: Colors.grey.shade200,
                ),
              ),
              // 填充部分
              FractionallySizedBox(
                widthFactor: position,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: statusColor.withOpacity(0.5),
                  ),
                ),
              ),
              // 中间平衡点
              Center(
                child: Container(
                  width: 4,
                  height: 30,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('←偏向商人', style: TextStyle(fontSize: 10)),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const Text('偏向玩家→', style: TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

