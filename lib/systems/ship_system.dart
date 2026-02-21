import 'dart:math';
import '../game/game_state.dart';
import '../models/ship.dart';
import '../l10n/app_localizations.dart';

/// 升级类型
enum UpgradeType {
  cargo,
  hull,
  crew,
}

/// 船只系统 - 管理船只升级和属性计算
class ShipSystem {
  // 升级数值配置
  static const int cargoUpgradeAmount = 100;
  static const int hullUpgradeAmount = 50;
  static const int crewUpgradeAmount = 1;

  // 基础成本配置
  static const int baseCargoCost = 500;
  static const int baseHullCost = 400;
  static const int baseCrewCost = 800;

  // 成本增长率 (每次升级增加 50%)
  static const double costMultiplier = 1.5;

  // 初始属性 (用于计算升级等级)
  static const int initialMaxCargo = 100;
  static const int initialMaxDurability = 200;
  static const int initialMaxCrew = 5;

  /// 获取船只整体等级 (三个属性等级的最小值)
  int getShipLevel(Ship ship) {
    final cargoLevel = getUpgradeLevel(ship, UpgradeType.cargo);
    final hullLevel = getUpgradeLevel(ship, UpgradeType.hull);
    final crewLevel = getUpgradeLevel(ship, UpgradeType.crew);
    return [cargoLevel, hullLevel, crewLevel].reduce((a, b) => a < b ? a : b);
  }

  /// 获取当前升级等级
  int getUpgradeLevel(Ship ship, UpgradeType type) {
    switch (type) {
      case UpgradeType.cargo:
        return ((ship.cargoCapacity - initialMaxCargo) / cargoUpgradeAmount).round();
      case UpgradeType.hull:
        return ((ship.maxDurability - initialMaxDurability) / hullUpgradeAmount).round();
      case UpgradeType.crew:
        return (ship.maxCrewMemberCount - initialMaxCrew);
    }
  }

  /// 获取升级成本
  int getUpgradeCost(Ship ship, UpgradeType type) {
    int level = getUpgradeLevel(ship, type);
    int baseCost;
    
    switch (type) {
      case UpgradeType.cargo:
        baseCost = baseCargoCost;
        break;
      case UpgradeType.hull:
        baseCost = baseHullCost;
        break;
      case UpgradeType.crew:
        baseCost = baseCrewCost;
        break;
    }
    
    // 成本 = 基础成本 * (1.2 ^ 当前等级)
    return (baseCost * pow(costMultiplier, level)).floor();
  }

  /// 获取升级效果描述
  String getUpgradeDescription(UpgradeType type, AppLocalizations l10n) {
    switch (type) {
      case UpgradeType.cargo:
        return l10n.upgradeCargoDesc;
      case UpgradeType.hull:
        return l10n.upgradeHullDesc;
      case UpgradeType.crew:
        return l10n.upgradeCrewDesc;
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
  String getUpgradeName(UpgradeType type, AppLocalizations l10n) {
    switch (type) {
      case UpgradeType.cargo:
        return l10n.upgradeCargoName;
      case UpgradeType.hull:
        return l10n.upgradeHullName;
      case UpgradeType.crew:
        return l10n.upgradeCrewName;
    }
  }

  /// 检查是否可以进行该项升级
  bool canPerformUpgrade(Ship ship, UpgradeType type) {
    final currentLevel = getUpgradeLevel(ship, type);
    
    // 假设最高等级为 6 (对应 Player_ship_6.png)
    if (currentLevel >= 6) return false;

    final cargoLevel = getUpgradeLevel(ship, UpgradeType.cargo);
    final hullLevel = getUpgradeLevel(ship, UpgradeType.hull);
    final crewLevel = getUpgradeLevel(ship, UpgradeType.crew);

    int minOtherLevel;
    switch (type) {
      case UpgradeType.cargo:
        minOtherLevel = (hullLevel < crewLevel) ? hullLevel : crewLevel;
        break;
      case UpgradeType.hull:
        minOtherLevel = (cargoLevel < crewLevel) ? cargoLevel : crewLevel;
        break;
      case UpgradeType.crew:
        minOtherLevel = (cargoLevel < hullLevel) ? cargoLevel : hullLevel;
        break;
    }

    // 只有当前等级不高于其他项的最低等级时，才允许升级 (保证同步)
    return currentLevel <= minOtherLevel;
  }

  /// 获取最大等级限制 (当前硬编码为 6，对应 Player_ship_6.png)
  int getMaxLevel() => 6;

  /// 获取升级类型等级限制描述
  String getLevelConstraintMessage(Ship ship, UpgradeType type, AppLocalizations l10n) {
    final currentLevel = getUpgradeLevel(ship, type);
    if (currentLevel >= getMaxLevel()) return l10n.upgradeErrorMaxLevel;
    return l10n.upgradeErrorNeedsOther(currentLevel);
  }

  /// 执行升级
  /// 返回 null 表示成功，否则返回错误信息
  String? performUpgrade(GameState gameState, UpgradeType type, AppLocalizations l10n) {
    final ship = gameState.ship;
    final currentLevel = getUpgradeLevel(ship, type);

    // 检查等级限制：其他升级选项必须达到与当前选项相同的等级
    final cargoLevel = getUpgradeLevel(ship, UpgradeType.cargo);
    final hullLevel = getUpgradeLevel(ship, UpgradeType.hull);
    final crewLevel = getUpgradeLevel(ship, UpgradeType.crew);

    int minOtherLevel;
    switch (type) {
      case UpgradeType.cargo:
        minOtherLevel = (hullLevel < crewLevel) ? hullLevel : crewLevel;
        break;
      case UpgradeType.hull:
        minOtherLevel = (cargoLevel < crewLevel) ? cargoLevel : crewLevel;
        break;
      case UpgradeType.crew:
        minOtherLevel = (cargoLevel < hullLevel) ? cargoLevel : hullLevel;
        break;
    }

    if (currentLevel > minOtherLevel) {
      return l10n.upgradeErrorNeedsOther(currentLevel);
    }

    final cost = getUpgradeCost(ship, type);
    
    // 检查金币
    if (gameState.gold < cost) {
      return l10n.upgradeErrorNoGold(cost);
    }

    // 扣除金币
    if (!gameState.spendGold(cost)) {
       return l10n.upgradeErrorFail;
    }

    // 应用升级
    switch (type) {
      case UpgradeType.cargo:
        ship.upgradeMaxCargo(cargoUpgradeAmount);
        break;
      case UpgradeType.hull:
        ship.upgradeMaxDurability(hullUpgradeAmount);
        break;
      case UpgradeType.crew:
        ship.upgradeMaxCrew(crewUpgradeAmount);
        break;
    }
    
    // 更新船只外观：只有当所有升级都达到下一级时才更换图片
    final newCargoLevel = getUpgradeLevel(ship, UpgradeType.cargo);
    final newHullLevel = getUpgradeLevel(ship, UpgradeType.hull);
    final newCrewLevel = getUpgradeLevel(ship, UpgradeType.crew);
    
    final minLevel = [newCargoLevel, newHullLevel, newCrewLevel].reduce((a, b) => a < b ? a : b);
    final appearanceLevel = minLevel.clamp(0, getMaxLevel());
    ship.appearance = 'assets/images/ships/Player_ship_$appearanceLevel.png';
    
    // 通知更新
    gameState.incrementShipUpgradeCount();
    return null; // 成功
  }
}

