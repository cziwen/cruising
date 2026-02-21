// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '航行';

  @override
  String marketTitle(String portName) {
    return '市场 - $portName';
  }

  @override
  String get confirmTrade => '交易';

  @override
  String get tradeSuccess => '交易成功！';

  @override
  String get tradeUnfair => '交易不公平';

  @override
  String get merchantInventory => '商人库存';

  @override
  String get myInventory => '我的库存';

  @override
  String get playerGet => '玩家获得';

  @override
  String get playerPay => '玩家支付';

  @override
  String get receive => '换入';

  @override
  String get give => '换出';

  @override
  String get balanceOffer => '平衡';

  @override
  String get buy => '购买';

  @override
  String get sell => '出售';

  @override
  String holdAveragePrice(Object price) {
    return '持有均价: $price';
  }

  @override
  String batchAveragePrice(Object price, Object type) {
    return '$type均价: $price';
  }

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get favorMerchant => '偏向商人';

  @override
  String get favorPlayer => '偏向玩家';

  @override
  String get fairTrade => '公平交易';

  @override
  String get errorNotAtPort => '当前不在港口且未指定交易对象';

  @override
  String get errorMerchantRefuse => '商人拒绝此交易（交易偏向玩家）';

  @override
  String get errorGoldNotEnough => '金币不足';

  @override
  String errorGoodsNotEnough(Object goodsName) {
    return '$goodsName 库存不足';
  }

  @override
  String get errorCargoFull => '载货空间不足';

  @override
  String get errorMerchantGoldNotEnough => '商人金币不足';

  @override
  String errorPortStockNotEnough(Object goodsName) {
    return '$goodsName 港口库存不足';
  }

  @override
  String crewDeparted(Object names) {
    return '船员 $names 因为得不到报酬，已经在港口悄悄离开了...';
  }

  @override
  String get shipUpgrade => '船只升级';

  @override
  String get featureInDevelopment => '升级功能开发中...';

  @override
  String get ok => '确定';

  @override
  String get tavernDefaultDescription => '一位渴望出海的冒险者。';

  @override
  String crewFull(Object current, Object max) {
    return '船员已满（$current / $max）';
  }

  @override
  String goldNotEnoughRecruit(Object cost) {
    return '金币不足！需要 $cost 金币';
  }

  @override
  String get recruitConfirmTitle => '招募该船员？';

  @override
  String salaryPerDay(Object salary) {
    return '工资：$salary 金币 / 天';
  }

  @override
  String recruitmentCost(Object cost) {
    return '招募费用：$cost 金币';
  }

  @override
  String currentCrewCount(Object current, Object max) {
    return '当前船员数：$current / $max';
  }

  @override
  String get lookAround => '暂不';

  @override
  String get confirmRecruit => '确认';

  @override
  String recruitSuccess(Object name) {
    return '成功招募 $name！';
  }

  @override
  String get tavern => '酒馆';

  @override
  String get noAvailableCrew => '暂无可招募船员';

  @override
  String get selectCrewDetail => '请选择一名船员查看详情';

  @override
  String get skills => '技能详情：';

  @override
  String get sailorSkill => '水手技能';

  @override
  String get shipwrightSkill => '船工技能';

  @override
  String get gunnerSkill => '炮手技能';

  @override
  String get recruitHint => '招募后可分配职业以提供加成（在船员管理界面）';

  @override
  String get recruitCrew => '招募';

  @override
  String get upgradeSuccess => '升级成功！';

  @override
  String get upgradeOptions => '升级选项';

  @override
  String get upgradeCargoName => '扩建货仓';

  @override
  String get upgradeCargoDesc => '增加最大载货重量';

  @override
  String get upgradeHullName => '加固船体';

  @override
  String get upgradeHullDesc => '增加耐久度上限';

  @override
  String get upgradeCrewName => '扩建船员舱';

  @override
  String get upgradeCrewDesc => '增加最大船员容纳数量';

  @override
  String upgradeErrorNeedsOther(Object level) {
    return '需要先升级其他部位（其他部位需达到等级 $level）';
  }

  @override
  String get upgradeErrorMaxLevel => '已达最高等级';

  @override
  String upgradeErrorNoGold(Object cost) {
    return '金币不足，需要 $cost 金币';
  }

  @override
  String get upgradeErrorFail => '交易失败';

  @override
  String get shipyard => '船厂';

  @override
  String get shipAttributes => '船只属性';

  @override
  String get shipName => '船名';

  @override
  String get shipLevel => '船只等级';

  @override
  String get cargoCapacity => '载货量';

  @override
  String get durability => '耐久度';

  @override
  String get crewCapacity => '船员容量';

  @override
  String get maxLevelReached => '已达最高等级';

  @override
  String upgradeCost(Object cost) {
    return '💰$cost';
  }

  @override
  String get maxLevel => '已满级';

  @override
  String get newGame => '新游戏';

  @override
  String get continueGame => '继续游戏';

  @override
  String get loadGame => '读取存档';

  @override
  String get exitGame => '退出';

  @override
  String get languageSettings => '语言设置';

  @override
  String get currentLanguage => '当前语言';

  @override
  String get chinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get soundSettings => '声音设置';

  @override
  String get musicVolume => '音乐音量';

  @override
  String get sfxVolume => '音效音量';

  @override
  String get displaySettings => '显示设置';

  @override
  String get fullScreen => '全屏模式';

  @override
  String get wallpaperMode => '动态壁纸模式';

  @override
  String get windowResolution => '窗口分辨率';

  @override
  String get saveGame => '保存游戏';

  @override
  String get returnToMainMenu => '返回主菜单';

  @override
  String get close => '关闭';

  @override
  String get returnMainMenuConfirm => '未保存的进度将会丢失，确定要返回主菜单吗？';

  @override
  String get selectDestination => '选择目的地';

  @override
  String get depart => '出发';

  @override
  String get currentPort => '当前港口';

  @override
  String get settings => '设置';

  @override
  String get market => '市场';

  @override
  String get hall => '大厅';

  @override
  String get manage => '管理';

  @override
  String get map => '地图';

  @override
  String mainHallTitle(Object level) {
    return '大厅 - 等级 $level';
  }

  @override
  String get cityHallUpgrade => '市政厅升级';

  @override
  String get islandWarehouse => '岛屿仓库';

  @override
  String get islandFeatureUpgrade => '岛屿功能升级';

  @override
  String get upgradeSyncHint => '当所有功能均升级后，岛屿视觉等级将自动提升。';

  @override
  String get taxQuota => '税收额度';

  @override
  String get taxQuotaDesc => '提升每小时产生的税收金额';

  @override
  String get localEconomy => '本地经济';

  @override
  String get localEconomyDesc => '降低岛屿商店买入价格';

  @override
  String get merchantFunds => '商人资金';

  @override
  String get merchantFundsDesc => '提升本地商人最大默认金额';

  @override
  String get restockSpeed => '补货速度';

  @override
  String get restockSpeedDesc => '提升本地商人货物刷新速度与库存';

  @override
  String get needsOtherUpgrades => '需先升级其他项';

  @override
  String get myShip => '我的船只';

  @override
  String cargoWeight(Object capacity, Object used) {
    return '载重: $used/${capacity}kg';
  }

  @override
  String get emptyStorage => '空空如也';

  @override
  String get depositToWarehouse => '存入仓库';

  @override
  String get withdrawFromWarehouse => '取出到船';

  @override
  String get confirmDeposit => '确认存入';

  @override
  String get confirmWithdraw => '确认取出';

  @override
  String get depositSuccess => '存入成功！';

  @override
  String get withdrawSuccess => '取出成功！';

  @override
  String get withdrawFail => '取出失败（可能载重不足）';

  @override
  String get crewManagement => '船员管理';

  @override
  String get sailingBonus => '航速加成';

  @override
  String get autoRepair => '自动修理';

  @override
  String get fireRate => '开炮速度';

  @override
  String get noCrewHint => '暂无船员\n请在人才市场招募';

  @override
  String get unpaid => '欠薪中';

  @override
  String get dismissCrew => '解雇船员';

  @override
  String dismissConfirm(Object name) {
    return '确定要解雇 $name 吗？\n解雇后无法撤销。';
  }

  @override
  String get atSea => '海上';

  @override
  String get unknownLocation => '未知';

  @override
  String travelingTo(Object destination) {
    return '前往: $destination';
  }

  @override
  String remainingTime(Object time) {
    return '剩余: $time';
  }

  @override
  String days(Object count) {
    return '$count天';
  }

  @override
  String hours(Object count) {
    return '$count小时';
  }

  @override
  String get knots => '节';

  @override
  String get perSecond => '/秒';

  @override
  String get shotsPerSecond => '炮/秒';

  @override
  String peopleCount(Object count) {
    return '$count 人';
  }

  @override
  String get tapAnywhereToContinueHint => '-- 点击任意处继续 --';

  @override
  String notificationSalaryPaid(Object amount) {
    return '已支付今日船员工资 (共 $amount 💰)';
  }

  @override
  String notificationSalaryUnpaid(Object names) {
    return '金币不足！$names 等船员未收到工资，士气下降';
  }

  @override
  String get notificationEnteredSea => '已进入海上';

  @override
  String notificationArrivedAtPort(Object portName) {
    return '已到达 $portName';
  }

  @override
  String get notificationEncounterEnemyShip => '遭遇敌船！准备战斗';

  @override
  String notificationShipDamaged(Object amount) {
    return '船只受损：耐久度下降了 $amount';
  }

  @override
  String notificationShipRepaired(Object amount) {
    return '船只修复：耐久度恢复了 $amount';
  }

  @override
  String notificationGoldGained(Object amount) {
    return '获得金币：$amount 💰';
  }

  @override
  String notificationGoldLost(Object amount) {
    return '损失金币：$amount 💰';
  }

  @override
  String get notificationMerchantTradeStart => '正在与商船进行物资交换...';

  @override
  String notificationGoodsGained(Object count, Object goodsName) {
    return '获得物资：$goodsName x$count';
  }

  @override
  String get notificationCargoFullCannotGetGoods => '货舱已满，无法获取物资';

  @override
  String notificationCourseChangedToNearestPort(Object portName) {
    return '航道改变，正转向最近的港口：$portName';
  }

  @override
  String get roleSailor => '水手';

  @override
  String get roleShipwright => '船工';

  @override
  String get roleGunner => '炮手';

  @override
  String get roleUnassigned => '未分配';

  @override
  String get weatherCalm => '平静';

  @override
  String get weatherLightWind => '小风';

  @override
  String get weatherStorm => '风暴';

  @override
  String get seasonSpring => '春';

  @override
  String get seasonSummer => '夏';

  @override
  String get seasonAutumn => '秋';

  @override
  String get seasonWinter => '冬';

  @override
  String get autoSave => '自动存档';

  @override
  String saveSlot(Object id) {
    return '存档 $id';
  }

  @override
  String get emptySlot => '空槽位';
}
