import '../game/game_state.dart';
import '../models/ship.dart';

/// 升级类型
enum UpgradeType {
  cargo,
  hull,
  crew,
}

/// 船只系统 - 管理船只升级和属性计算
class ShipSystem {
  // 升级数值配置
  static const int cargoUpgradeAmount = 30;
  static const int hullUpgradeAmount = 50;
  static const int crewUpgradeAmount = 1;

  // 基础成本配置
  static const int baseCargoCost = 500;
  static const int baseHullCost = 400;
  static const int baseCrewCost = 800;

  // 成本递增系数 (每级增加的成本)
  static const int cargoCostIncrement = 100;
  static const int hullCostIncrement = 100;
  static const int crewCostIncrement = 500;

  // 初始属性 (用于计算升级等级)
  static const int initialMaxCargo = 100;
  static const int initialMaxDurability = 200;
  static const int initialMaxCrew = 5;

  /// 获取升级成本
  int getUpgradeCost(Ship ship, UpgradeType type) {
    int level = 0;
    
    switch (type) {
      case UpgradeType.cargo:
        // 计算当前是第几级升级: (当前最大载货量 - 初始值) / 单次提升量
        level = ((ship.maxCargoCapacity - initialMaxCargo) / cargoUpgradeAmount).floor();
        return baseCargoCost + (level * cargoCostIncrement);
        
      case UpgradeType.hull:
        level = ((ship.maxDurability - initialMaxDurability) / hullUpgradeAmount).floor();
        return baseHullCost + (level * hullCostIncrement);
        
      case UpgradeType.crew:
        level = (ship.maxCrewMemberCount - initialMaxCrew);
        return baseCrewCost + (level * crewCostIncrement);
    }
  }

  /// 获取升级效果描述
  String getUpgradeDescription(UpgradeType type) {
    switch (type) {
      case UpgradeType.cargo:
        return '增加最大载货重量';
      case UpgradeType.hull:
        return '增加耐久度上限';
      case UpgradeType.crew:
        return '增加最大船员容纳数量';
    }
  }

  /// 获取升级增加的数值
  int getUpgradeAmount(UpgradeType type) {
    switch (type) {
      case UpgradeType.cargo:
        return cargoUpgradeAmount;
      case UpgradeType.hull:
        return hullUpgradeAmount;
      case UpgradeType.crew:
        return crewUpgradeAmount;
    }
  }

  /// 获取升级名称
  String getUpgradeName(UpgradeType type) {
    switch (type) {
      case UpgradeType.cargo:
        return '扩建货仓';
      case UpgradeType.hull:
        return '加固船体';
      case UpgradeType.crew:
        return '扩建船员舱';
    }
  }

  /// 执行升级
  /// 返回 null 表示成功，否则返回错误信息
  String? performUpgrade(GameState gameState, UpgradeType type) {
    final cost = getUpgradeCost(gameState.ship, type);
    
    // 检查金币
    if (gameState.gold < cost) {
      return '金币不足，需要 $cost 金币';
    }

    // 扣除金币
    if (!gameState.spendGold(cost)) {
       return '交易失败';
    }

    // 应用升级
    switch (type) {
      case UpgradeType.cargo:
        gameState.ship.upgradeMaxCargo(cargoUpgradeAmount);
        break;
      case UpgradeType.hull:
        gameState.ship.upgradeMaxDurability(hullUpgradeAmount);
        break;
      case UpgradeType.crew:
        gameState.ship.upgradeMaxCrew(crewUpgradeAmount);
        break;
    }
    
    // 通知更新
    gameState.notifyUpdate();
    return null; // 成功
  }
}

