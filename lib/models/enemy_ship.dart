/// 敌方船只数据模型
class EnemyShip {
  final String id;
  final String name;
  int durability;
  final int maxDurability;
  final double fireRatePerSecond; // 攻击频率（每秒炮数）
  final double repairRatePerSecond; // 修复频率（每秒恢复的耐久）
  final int damagePerShot; // 每次攻击造成的伤害

  EnemyShip({
    required this.id,
    required this.name,
    required this.durability,
    required this.maxDurability,
    this.fireRatePerSecond = 1.0, // 默认1炮/秒
    this.repairRatePerSecond = 2.0, // 默认2点/秒
    this.damagePerShot = 10, // 默认每次10点伤害
  });

  /// 检查是否被击沉
  bool get isSunk => durability <= 0;

  /// 造成伤害
  void takeDamage(int damage) {
    durability = (durability - damage).clamp(0, maxDurability);
  }

  /// 恢复耐久度
  void repair(double amount) {
    durability = ((durability + amount).clamp(0, maxDurability)).toInt();
  }

  /// 创建默认敌方船只
  factory EnemyShip.createDefault() {
    return EnemyShip(
      id: 'enemy_${DateTime.now().millisecondsSinceEpoch}',
      name: '海盗船',
      durability: 200,
      maxDurability: 200,
      fireRatePerSecond: 1.0, // 1炮/秒
      repairRatePerSecond: 2.0,
      damagePerShot: 10,
    );
  }

  EnemyShip copyWith({
    String? id,
    String? name,
    int? durability,
    int? maxDurability,
    double? fireRatePerSecond,
    double? repairRatePerSecond,
    int? damagePerShot,
  }) {
    return EnemyShip(
      id: id ?? this.id,
      name: name ?? this.name,
      durability: durability ?? this.durability,
      maxDurability: maxDurability ?? this.maxDurability,
      fireRatePerSecond: fireRatePerSecond ?? this.fireRatePerSecond,
      repairRatePerSecond: repairRatePerSecond ?? this.repairRatePerSecond,
      damagePerShot: damagePerShot ?? this.damagePerShot,
    );
  }
}

