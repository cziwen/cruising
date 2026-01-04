import 'dart:math';
import 'goods.dart';

/// 主岛养成系统数据模型
class HomeIsland {
  // 升级等级 (0-7)
  int taxLevel = 0;          // 税收等级
  int economyLevel = 0;      // 本地经济等级（物价）
  int merchantFundsLevel = 0; // 商人资金等级
  int restockSpeedLevel = 0;  // 补货速度等级

  // 累积税收
  int accumulatedTax = 0;
  
  // 仓库库存
  List<ShipInventoryItem> warehouseInventory = [];

  HomeIsland({
    this.taxLevel = 0,
    this.economyLevel = 0,
    this.merchantFundsLevel = 0,
    this.restockSpeedLevel = 0,
    this.accumulatedTax = 0,
    List<ShipInventoryItem>? warehouseInventory,
  }) : warehouseInventory = warehouseInventory ?? [];

  /// 岛屿总等级 = 所有 4 个子项升级等级的最小值
  int get level => [
        taxLevel,
        economyLevel,
        merchantFundsLevel,
        restockSpeedLevel,
      ].reduce(min).clamp(0, 7);

  /// 获取当前等级对应的背景图片路径
  String get appearance => 'assets/images/buildings/village_$level.png';

  /// 获取当前等级的税收额度（每小时产出）
  int get taxAmount => taxLevel + 1;

  Map<String, dynamic> toJson() {
    return {
      'taxLevel': taxLevel,
      'economyLevel': economyLevel,
      'merchantFundsLevel': merchantFundsLevel,
      'restockSpeedLevel': restockSpeedLevel,
      'accumulatedTax': accumulatedTax,
      'warehouseInventory': warehouseInventory.map((item) => item.toJson()).toList(),
    };
  }

  factory HomeIsland.fromJson(Map<String, dynamic> json) {
    return HomeIsland(
      taxLevel: json['taxLevel'] as int? ?? 0,
      economyLevel: json['economyLevel'] as int? ?? 0,
      merchantFundsLevel: json['merchantFundsLevel'] as int? ?? 0,
      restockSpeedLevel: json['restockSpeedLevel'] as int? ?? 0,
      accumulatedTax: json['accumulatedTax'] as int? ?? 0,
      warehouseInventory: (json['warehouseInventory'] as List?)
          ?.map((item) => ShipInventoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  HomeIsland copyWith({
    int? taxLevel,
    int? economyLevel,
    int? merchantFundsLevel,
    int? restockSpeedLevel,
    int? accumulatedTax,
    List<ShipInventoryItem>? warehouseInventory,
  }) {
    return HomeIsland(
      taxLevel: taxLevel ?? this.taxLevel,
      economyLevel: economyLevel ?? this.economyLevel,
      merchantFundsLevel: merchantFundsLevel ?? this.merchantFundsLevel,
      restockSpeedLevel: restockSpeedLevel ?? this.restockSpeedLevel,
      accumulatedTax: accumulatedTax ?? this.accumulatedTax,
      warehouseInventory: warehouseInventory ?? this.warehouseInventory,
    );
  }
}



