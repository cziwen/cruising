import 'goods.dart';

/// 船只数据模型
class Ship {
  final String id;
  final String name;
  int cargoCapacity; // 最大载货容量（kg）
  int durability;
  int maxDurability;
  int maxCrewMemberCount;
  int damagePerShot; // 单次攻击伤害
  String appearance;

  Ship({
    required this.id,
    required this.name,
    required this.cargoCapacity,
    this.durability = 100,
    required this.maxDurability,
    this.maxCrewMemberCount = 5,
    this.damagePerShot = 10,
    this.appearance = 'default',
  });

  /// 获取当前已使用的载货量（重量，kg）
  /// [inventory] 库存列表
  /// [getGoodsById] 根据商品ID获取商品信息的函数
  double getUsedCargo(
    List<ShipInventoryItem> inventory,
    Goods Function(String goodsId) getGoodsById,
  ) {
    return inventory.fold<double>(
      0.0,
      (sum, item) {
        final goods = getGoodsById(item.goodsId);
        // 金币重量为0，不占用载货空间
        return sum + (item.quantity * goods.weight);
      },
    );
  }

  /// 获取剩余载货量（重量，kg）
  double getRemainingCargo(
    List<ShipInventoryItem> inventory,
    Goods Function(String goodsId) getGoodsById,
  ) {
    return cargoCapacity - getUsedCargo(inventory, getGoodsById);
  }

  /// 检查是否有足够载货空间
  /// [inventory] 库存列表
  /// [additionalWeight] 需要添加的重量（kg）
  /// [getGoodsById] 根据商品ID获取商品信息的函数
  bool hasEnoughCargo(
    List<ShipInventoryItem> inventory,
    double additionalWeight,
    Goods Function(String goodsId) getGoodsById,
  ) {
    // 如果重量为0（如金币），直接返回true
    if (additionalWeight <= 0) {
      return true;
    }
    return getRemainingCargo(inventory, getGoodsById) >= additionalWeight;
  }

  /// 升级最大载货量
  void upgradeMaxCargo(int amount) {
    cargoCapacity += amount;
  }

  /// 升级最大耐久度
  void upgradeMaxDurability(int amount) {
    maxDurability += amount;
    durability += amount; // 同时增加当前耐久度
  }

  /// 升级最大船员容量
  void upgradeMaxCrew(int amount) {
    maxCrewMemberCount += amount;
  }

  Ship copyWith({
    String? id,
    String? name,
    int? cargoCapacity,
    int? durability,
    int? maxDurability,
    int? maxCrewMemberCount,
    int? damagePerShot,
    String? appearance,
  }) {
    return Ship(
      id: id ?? this.id,
      name: name ?? this.name,
      cargoCapacity: cargoCapacity ?? this.cargoCapacity,
      durability: durability ?? this.durability,
      maxDurability: maxDurability ?? this.maxDurability,
      maxCrewMemberCount: maxCrewMemberCount ?? this.maxCrewMemberCount,
      damagePerShot: damagePerShot ?? this.damagePerShot,
      appearance: appearance ?? this.appearance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cargoCapacity': cargoCapacity,
      'durability': durability,
      'maxDurability': maxDurability,
      'maxCrewMemberCount': maxCrewMemberCount,
      'damagePerShot': damagePerShot,
      'appearance': appearance,
    };
  }

  factory Ship.fromJson(Map<String, dynamic> json) {
    return Ship(
      id: json['id'] as String,
      name: json['name'] as String,
      cargoCapacity: json['cargoCapacity'] as int,
      durability: json['durability'] as int,
      maxDurability: json['maxDurability'] as int,
      maxCrewMemberCount: json['maxCrewMemberCount'] as int,
      damagePerShot: (json['damagePerShot'] as int?) ?? 10,
      appearance: json['appearance'] as String,
    );
  }
}
