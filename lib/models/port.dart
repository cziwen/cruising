/// 港口商品配置（每个港口对每个商品的独立配置）
class PortGoodsConfig {
  final double alpha; // 价格敏感度（0.01 ~ 0.99）
  final int s0; // 正常库存基准
  final double basePrice; // 基础价格（P₀）

  PortGoodsConfig({
    required this.alpha,
    required this.s0,
    required this.basePrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'alpha': alpha,
      's0': s0,
      'basePrice': basePrice,
    };
  }

  factory PortGoodsConfig.fromJson(Map<String, dynamic> json) {
    return PortGoodsConfig(
      alpha: (json['alpha'] as num).toDouble(),
      s0: json['s0'] as int,
      basePrice: (json['basePrice'] as num).toDouble(),
    );
  }
}

/// 港口数据模型
class Port {
  final String id;
  final String name;
  final String backgroundImage;
  final String description;
  final bool unlocked;
  // 航行距离映射：目标港口ID -> 距离（节）
  final Map<String, int> distances;
  // 商品库存映射：商品ID -> 库存量（实际库存，交易时更新）
  final Map<String, int> goodsStock;
  // 价格基准库存映射：商品ID -> 库存量（用于价格计算，每7天更新一次）
  final Map<String, int> priceBaseStock;
  // 商品配置映射：商品ID -> 配置（alpha 和 s0）
  final Map<String, PortGoodsConfig> goodsConfig;
  // 商人当前资金
  final int merchantMoney;
  // 商人初始资金（每7天重置的基准值）
  final int initialMerchantMoney;

  Port({
    required this.id,
    required this.name,
    required this.backgroundImage,
    required this.description,
    this.unlocked = true,
    Map<String, int>? distances,
    Map<String, int>? goodsStock,
    Map<String, int>? priceBaseStock,
    Map<String, PortGoodsConfig>? goodsConfig,
    this.merchantMoney = 1000,
    this.initialMerchantMoney = 1000,
  })  : distances = distances ?? {},
        goodsStock = goodsStock ?? {},
        priceBaseStock = priceBaseStock ?? {},
        goodsConfig = goodsConfig ?? {};

  /// 获取到目标港口的航行距离（节）
  int? getDistanceTo(String targetPortId) {
    return distances[targetPortId];
  }

  /// 获取到目标港口的航行时间（小时数）- 已废弃，保留用于兼容
  @Deprecated('使用 getDistanceTo 获取距离（节）')
  int? getTravelTimeTo(String targetPortId) {
    return distances[targetPortId];
  }

  /// 获取指定商品的库存
  int getGoodsStock(String goodsId) {
    return goodsStock[goodsId] ?? 0;
  }

  /// 设置指定商品的库存（返回新的 Port 实例）
  Port setGoodsStock(String goodsId, int stock) {
    final newGoodsStock = Map<String, int>.from(goodsStock);
    newGoodsStock[goodsId] = stock;
    return copyWith(goodsStock: newGoodsStock);
  }

  /// 获取指定商品的配置（alpha 和 s0）
  PortGoodsConfig? getGoodsConfig(String goodsId) {
    return goodsConfig[goodsId];
  }

  /// 设置指定商品的配置（返回新的 Port 实例）
  Port setGoodsConfig(String goodsId, PortGoodsConfig config) {
    final newGoodsConfig = Map<String, PortGoodsConfig>.from(goodsConfig);
    newGoodsConfig[goodsId] = config;
    return copyWith(goodsConfig: newGoodsConfig);
  }

  /// 获取指定商品的价格基准库存（用于价格计算）
  int getPriceBaseStock(String goodsId) {
    return priceBaseStock[goodsId] ?? 0;
  }

  /// 设置指定商品的价格基准库存（返回新的 Port 实例）
  /// 每7天更新时调用，将价格基准库存更新为当前实际库存
  Port setPriceBaseStock(String goodsId, int stock) {
    final newPriceBaseStock = Map<String, int>.from(priceBaseStock);
    newPriceBaseStock[goodsId] = stock;
    return copyWith(priceBaseStock: newPriceBaseStock);
  }

  /// 更新所有商品的价格基准库存为当前实际库存（每7天更新时调用）
  Port updateAllPriceBaseStock() {
    final newPriceBaseStock = <String, int>{};
    for (final goodsId in goodsStock.keys) {
      newPriceBaseStock[goodsId] = goodsStock[goodsId] ?? 0;
    }
    // 对于有配置但没有库存的商品，使用配置的 s0
    for (final entry in goodsConfig.entries) {
      if (!newPriceBaseStock.containsKey(entry.key)) {
        newPriceBaseStock[entry.key] = entry.value.s0;
      }
    }
    return copyWith(priceBaseStock: newPriceBaseStock);
  }

  /// 设置商人资金（返回新的 Port 实例）
  Port setMerchantMoney(int money) {
    return copyWith(merchantMoney: money);
  }

  Port copyWith({
    String? id,
    String? name,
    String? backgroundImage,
    String? description,
    bool? unlocked,
    Map<String, int>? distances,
    Map<String, int>? goodsStock,
    Map<String, int>? priceBaseStock,
    Map<String, PortGoodsConfig>? goodsConfig,
    int? merchantMoney,
    int? initialMerchantMoney,
  }) {
    return Port(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      description: description ?? this.description,
      unlocked: unlocked ?? this.unlocked,
      distances: distances ?? this.distances,
      goodsStock: goodsStock ?? this.goodsStock,
      priceBaseStock: priceBaseStock ?? this.priceBaseStock,
      goodsConfig: goodsConfig ?? this.goodsConfig,
      merchantMoney: merchantMoney ?? this.merchantMoney,
      initialMerchantMoney: initialMerchantMoney ?? this.initialMerchantMoney,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'backgroundImage': backgroundImage,
      'description': description,
      'unlocked': unlocked,
      'distances': distances,
      'goodsStock': goodsStock,
      'priceBaseStock': priceBaseStock,
      'goodsConfig': goodsConfig.map((key, value) => MapEntry(key, value.toJson())),
      'merchantMoney': merchantMoney,
      'initialMerchantMoney': initialMerchantMoney,
    };
  }

  factory Port.fromJson(Map<String, dynamic> json) {
    return Port(
      id: json['id'] as String,
      name: json['name'] as String,
      backgroundImage: json['backgroundImage'] as String,
      description: json['description'] as String,
      unlocked: json['unlocked'] as bool? ?? true,
      distances: json['distances'] != null ? Map<String, int>.from(json['distances'] as Map) : null,
      goodsStock: json['goodsStock'] != null ? Map<String, int>.from(json['goodsStock'] as Map) : null,
      priceBaseStock: json['priceBaseStock'] != null ? Map<String, int>.from(json['priceBaseStock'] as Map) : null,
      goodsConfig: json['goodsConfig'] != null 
        ? (json['goodsConfig'] as Map).map(
            (key, value) => MapEntry(key as String, PortGoodsConfig.fromJson(value as Map<String, dynamic>)),
          )
        : null,
      merchantMoney: json['merchantMoney'] as int? ?? 1000,
      initialMerchantMoney: json['initialMerchantMoney'] as int? ?? 1000,
    );
  }
}

