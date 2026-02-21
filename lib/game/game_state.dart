import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/port.dart';
import '../models/ship.dart';
import '../models/goods.dart';
import '../models/crew_member.dart';
import '../models/enemy_ship.dart';
import '../models/home_island.dart';
import '../systems/crew_system.dart';
import '../systems/day_night_system.dart';
import '../systems/trade_system.dart';
import '../systems/save_system.dart';
import '../systems/music_system.dart';
import '../systems/notification_system.dart';
import '../systems/quest_system.dart';
import '../systems/sea_event_system.dart';
import '../utils/game_config_loader.dart';

import '../l10n/app_localizations.dart';

/// 天气状况枚举
enum WeatherCondition {
  calm(0), // 无影响
  lightWind(1), // 轻微加速
  storm(-2); // 减速

  final int speedModifier;

  const WeatherCondition(this.speedModifier);

  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case WeatherCondition.calm:
        return l10n.weatherCalm;
      case WeatherCondition.lightWind:
        return l10n.weatherLightWind;
      case WeatherCondition.storm:
        return l10n.weatherStorm;
    }
  }
}

/// 游戏状态管理
class GameState extends ChangeNotifier {
  // 当前港口
  Port? _currentPort;

  // 上一个港口（用于从海上选择其他港口时计算距离）
  Port? _previousPort;

  // 玩家船只
  final Ship _ship = Ship(
    id: 'ship_1',
    name: '初航号',
    cargoCapacity: 100, // 初始载货容量100kg
    durability: 200, // 默认满耐久
    maxDurability: 200,
    maxCrewMemberCount: 5,
    damagePerShot: 10,
    appearance: 'assets/images/ships/Player_ship_0.png',
  );
  
  // 用于获取商品信息的函数（由TradeSystem设置）
  Goods Function(String goodsId)? _getGoodsById;
  
  /// 设置获取商品信息的函数
  void setGetGoodsById(Goods Function(String goodsId) getGoodsById) {
    _getGoodsById = getGoodsById;
  }

  // 访问过的港口追踪
  final Set<String> _visitedPortIds = {};
  Set<String> get visitedPortIds => Set.unmodifiable(_visitedPortIds);
  int get visitedPortCount => _visitedPortIds.length;

  // 玩家金币
  int _gold = 1000;

  // 船只库存
  final List<ShipInventoryItem> _inventory = [];

  // 是否正在切换场景
  bool _isTransitioning = false;

  // 是否在海上
  bool _isAtSea = false;

  // 目标港口（航行时使用）
  Port? _destinationPort;

  // 是否跳过航行动画（调试用）
  bool _skipTravelAnimation = false;

  // 航行进度（0.0 到 1.0）
  double _travelProgress = 0.0;

  // 总航行距离（节）
  int _totalTravelDistance = 0;

  // 已航行距离（节）
  double _accumulatedDistance = 0.0;
  
  // 当前航段的起始里程点（节，用于计算本段进度）
  double _legStartDistance = 0.0;
  
  // 上次更新进度时的实际时间（用于计算 dt）
  DateTime? _lastProgressUpdateTime;
  
  // 当前累积的游戏内时间（小时，用于增量更新）
  double _accumulatedGameHours = 0.0;

  // 港口列表
  final List<Port> _ports = [];

  // 船员系统
  final ShipCrewManager _crewManager = ShipCrewManager();
  
  // 酒馆可招募船员
  List<CrewMember> _availableTavernCrew = [];
  int _lastTavernRefreshDay = -1;
  
  // maxCrewCount managed by _ship

  // 天气系统
  WeatherCondition _weather = WeatherCondition.calm;

  // 昼夜系统
  final DayNightSystem _dayNightSystem = DayNightSystem();

  // 主岛养成系统
  HomeIsland _homeIsland = HomeIsland();
  HomeIsland get homeIsland => _homeIsland;

  // 动画相关系统 (集中管理)
  double _swayTime = 0.0;
  double _totalSailingOffset = 0.0;
  double _waveAmplitudeMultiplier = 0.4; // 初始为港口时的弱幅度
  static const double _baseSailingSpeed = 8.0; // 基础航速（节）
  static const double _baseScrollSpeed = 50.0; // 基础滚动速度（像素/秒）

  // 港口价格更新跟踪
  int _lastPriceUpdateDay = 1; // 上次价格更新的日期
  static const int _priceUpdateInterval = 7; // 价格更新间隔（天）

  // 税收结算跟踪
  int _lastTaxHour = -1;

  // 是否处于菜单模式（暂停游戏时间流逝，仅保留动画）
  bool isMenuMode = false;

  // 是否处于任务对话框暂停模式（弹出对话框时暂停）
  bool _isQuestPaused = false;
  bool get isQuestPaused => _isQuestPaused;

  void setQuestPaused(bool paused) {
    if (_isQuestPaused != paused) {
      _isQuestPaused = paused;
      notifyListeners();
    }
  }

  // 进度更新 Ticker（用于每帧更新航行进度）
  Ticker? _progressTicker;
  
  // 航行完成 Completer（用于等待航行完成）
  Completer<void>? _travelCompleter;

  // 战斗系统
  bool _isInCombat = false;
  bool _isEnteringCombat = false; // 是否正在进入战斗动画中
  EnemyShip? _enemyShip;
  // 每个属性独立的累积时间（秒，游戏时间）
  double _playerAttackTimer = 0.0; // 玩家攻击累积时间
  double _enemyAttackTimer = 0.0; // 敌方攻击累积时间
  double _playerRepairTimer = 0.0; // 玩家修复累积时间
  double _enemyRepairTimer = 0.0; // 敌方修复累积时间
  double _playerShipXOffset = 0.0; // 玩家船只X偏移（战斗时向左移动）
  double _enemyShipXOffset = 1.0; // 敌方船只X偏移（从右侧滑入，1.0表示屏幕外）
  bool _isSinking = false; // 是否正在沉船
  bool _isPlayerSinking = false; // 是否是玩家沉船
  bool _isReturningFromCombat = false; // 是否正在从战斗位置归位
  bool _isFadeOut = false; // 是否正在渐变黑屏
  Port? _previousPortBeforeCombat; // 战斗前的港口（用于失败重生）

  // 视觉效果
  String? _currentVisualEffect;
  String? get currentVisualEffect => _currentVisualEffect;

  void setVisualEffect(String? effect) {
    if (_currentVisualEffect != effect) {
      _currentVisualEffect = effect;
      notifyListeners();
    }
  }

  /// 更新港口本地化信息（名称和描述）
  void updatePortLocalizations(List<Port> localizedPorts) {
    for (var i = 0; i < _ports.length; i++) {
      final oldPort = _ports[i];
      final newPort = localizedPorts.firstWhere((p) => p.id == oldPort.id, orElse: () => oldPort);
      _ports[i] = oldPort.copyWith(
        name: newPort.name,
        description: newPort.description,
      );
    }
    
    // 同时更新当前港口、目的地港口和上一个港口的引用，以确保 UI 显示正确
    if (_currentPort != null) {
      _currentPort = _ports.firstWhere((p) => p.id == _currentPort!.id, orElse: () => _currentPort!);
    }
    if (_destinationPort != null) {
      _destinationPort = _ports.firstWhere((p) => p.id == _destinationPort!.id, orElse: () => _destinationPort!);
    }
    if (_previousPort != null) {
      _previousPort = _ports.firstWhere((p) => p.id == _previousPort!.id, orElse: () => _previousPort!);
    }
    
    notifyListeners();
  }

  // 战斗事件计数器（用于触发视觉反馈）
  int _playerFireCount = 0;
  int _enemyFireCount = 0;
  int _playerHitCount = 0;
  int _enemyHitCount = 0;

  // 任务/教程系统追踪
  bool _isMarketOpened = false;
  bool _isPortListOpened = false;
  bool _isShipyardOpened = false;
  bool _isQuantitySliderOpened = false;
  bool _isSliderInteracted = false;
  int _sliderValue = 0;
  bool _isTradeBalanced = false;
  int _shipUpgradeCount = 0;
  bool _taxCollectedToday = false;
  bool _isHallPanelOpened = false;
  bool _isHomeIslandUpgraded = false;
  bool _isCombatUnlocked = false; // 战斗系统是否已解锁
  
  bool _isTradeConfirmed = false;
  
  // 地图对话框中当前选中的港口ID（用于任务系统判定）
  String? _selectedMapPortId;
  String? get selectedMapPortId => _selectedMapPortId;

  void setSelectedMapPortId(String? id) {
    if (_selectedMapPortId != id) {
      _selectedMapPortId = id;
      notifyListeners();
    }
  }

  /// 添加一个新港口（通常用于动态生成的商船）
  void addPort(Port port) {
    if (!_ports.any((p) => p.id == port.id)) {
      _ports.add(port);
      notifyListeners();
    }
  }

  /// 移除一个港口
  void removePort(String portId) {
    _ports.removeWhere((p) => p.id == portId);
    notifyListeners();
  }
  
  // 调试辅助：是否显示地图坐标
  bool _showMapCoordinates = false;
  bool get showMapCoordinates => _showMapCoordinates;

  void setShowMapCoordinates(bool value) {
    if (_showMapCoordinates != value) {
      _showMapCoordinates = value;
      notifyListeners();
    }
  }

  // 待交易物品追踪（用于任务系统判定）
  // 换入为正，换出为负
  final Map<String, int> _pendingTradeQuantities = {};
  Map<String, int> get pendingTradeQuantities => Map.unmodifiable(_pendingTradeQuantities);

  void updatePendingTradeQuantity(String goodsId, int quantity) {
    _pendingTradeQuantities[goodsId] = quantity;
    notifyListeners();
  }

  int getPendingTradeQuantity(String goodsId) {
    return _pendingTradeQuantities[goodsId] ?? 0;
  }

  void clearPendingTradeQuantities() {
    _pendingTradeQuantities.clear();
    notifyListeners();
  }

  // 最近离队的船员名单（用于向玩家展示提示）
  final List<String> _departingCrewNames = [];
  List<String> get departingCrewNames => List.unmodifiable(_departingCrewNames);

  /// 清除离队船员名单
  void clearDepartingCrewNames() {
    if (_departingCrewNames.isNotEmpty) {
      _departingCrewNames.clear();
      notifyListeners();
    }
  }

  // 调试加成
  double _debugRepairBonus = 0.0;
  double _debugFireRateBonus = 0.0;
  double _debugSpeedBonus = 0.0;
  double _debugIslandScale = 0.9; // 岛屿缩放比例，默认0.9以解决模糊问题

  // 海上事件加成
  double _eventSpeedMultiplier = 1.0;
  double _eventSpeedMultiplierRemainingHours = 0.0;

  Port? get currentPort => _currentPort;
  Port? get previousPort => _previousPort;
  Ship get ship => _ship;
  int get gold => _gold;
  List<ShipInventoryItem> get inventory => List.unmodifiable(_inventory);
  bool get isTransitioning => _isTransitioning;
  bool get isAtSea => _isAtSea;
  Port? get destinationPort => _destinationPort;
  bool get skipTravelAnimation => _skipTravelAnimation;
  double get travelProgress => _travelProgress;
  int get totalTravelDistance => _totalTravelDistance;
  double get accumulatedDistance => _accumulatedDistance;
  double get legStartDistance => _legStartDistance;

  /// 获取总航行时间（游戏内小时数）- 已废弃，保留用于兼容
  @Deprecated('使用 totalTravelDistance 和 currentSpeed 计算')
  int get totalTravelHours {
    if (_totalTravelDistance == 0 || currentSpeed == 0) return 0;
    return (_totalTravelDistance / currentSpeed).ceil();
  }

  /// 获取剩余航行时间（游戏内小时数）
  /// 基于剩余距离和当前航速计算
  int get remainingTravelHours {
    if (_totalTravelDistance == 0 || currentSpeed == 0) return 0;
    final remainingDistance = _totalTravelDistance - _accumulatedDistance;
    if (remainingDistance <= 0) return 0;
    // 剩余时间 = 剩余距离 / 当前航速
    return (remainingDistance / currentSpeed).ceil();
  }

  List<Port> get ports => List.unmodifiable(_ports);
  int get crewCount => _crewManager.crewMembers.length;
  int get maxCrewCount => _ship.maxCrewMemberCount;
  
  /// 获取当前已使用的载货量（重量，kg）
  /// 如果getGoodsById未设置，返回0.0
  double get usedCargoWeight {
    if (_getGoodsById == null) {
      return 0.0;
    }
    return _ship.getUsedCargo(_inventory, _getGoodsById!);
  }
  /// 获取平均士气（所有船员的平均士气）
  int get morale {
    final crewMembers = _crewManager.crewMembers;
    if (crewMembers.isEmpty) {
      return 100; // 没有船员时返回默认值100
    }
    final totalMorale = crewMembers.fold<int>(
      0,
      (sum, member) => sum + member.morale,
    );
    return (totalMorale / crewMembers.length).round();
  }
  WeatherCondition get weather => _weather;
  ShipCrewManager get crewManager => _crewManager;
  List<CrewMember> get availableTavernCrew => _availableTavernCrew;
  DayNightSystem get dayNightSystem => _dayNightSystem;

  /// 获取当前时间流逝比例
  /// 在海上航行时使用 cruisingTimeScale (60.0, 现实1秒=游戏1小时)
  /// 在港口时使用 portTimeScale (1.0, 现实1秒=游戏1分钟)
  double get currentTimeScale => _isAtSea ? DayNightSystem.cruisingTimeScale : DayNightSystem.portTimeScale;

  // 动画相关 getter
  double get swayTime => _swayTime;
  double get totalSailingOffset => _totalSailingOffset;
  double get waveAmplitudeMultiplier => _waveAmplitudeMultiplier;

  // 缓存当前航速（当船员、天气变化时失效）
  double? _cachedCurrentSpeed;
  WeatherCondition? _cachedSpeedWeather;

  /// 获取当前航速（节）
  /// 基础速度 + 船员加成 + 天气影响
  double get currentSpeed {
    // 检查缓存是否有效（检查天气是否变化）
    // 船员变化现在通过显式清除 _cachedCurrentSpeed 来处理
    if (_cachedCurrentSpeed != null &&
        _cachedSpeedWeather == _weather) {
      return _cachedCurrentSpeed!;
    }

    double baseSpeed = 8.0; // 基础速度8节
    int weatherModifier = _weather.speedModifier; // 天气修正

    // 使用船员系统的航速加成（直接返回节数，double类型）
    final crewBonus = _crewManager.calculateSailingBonus();

    // 移除上限限制，只保留最小值为1节
    final finalSpeed = (baseSpeed + crewBonus + weatherModifier + _debugSpeedBonus) * _eventSpeedMultiplier;
    _cachedCurrentSpeed = finalSpeed < 1.0 ? 1.0 : finalSpeed;
    _cachedSpeedWeather = _weather;
    return _cachedCurrentSpeed!;
  }

  /// 获取航速加成（节数）
  double get sailingBonusKnots => _crewManager.calculateSailingBonus();
  
  /// 获取航速加成百分比（已废弃，保留用于兼容）
  @Deprecated('使用 sailingBonusKnots 获取节数加成')
  double get sailingBonusPercent => sailingBonusKnots / 8.0 * 100; // 相对于基础速度8节的百分比

  /// 获取自动修理效率（每秒恢复的耐久）
  double get autoRepairPerSecond => _crewManager.calculateAutoRepair() + _debugRepairBonus;

  /// 获取自动修理效率（每小时恢复的耐久）- 已废弃，保留用于兼容
  @Deprecated('使用 autoRepairPerSecond')
  double get autoRepairPerHour => autoRepairPerSecond * 3600;

  /// 获取开炮速度（每秒炮数）
  /// 船员加成 + 调试加成
  double get fireRatePerSecond => _crewManager.calculateFireRateBonus() + _debugFireRateBonus;

  /// 获取开炮速度加成百分比 - 已废弃，保留用于兼容
  @Deprecated('使用 fireRatePerSecond')
  double get fireRateBonusPercent => fireRatePerSecond;

  /// 初始化游戏
  void initialize(List<Port> ports, {Port? startingPort}) {
    // ========== 完整状态重置（防止数据串连） ==========
    
    // 1. 重置玩家资源
    _gold = 1000;
    _inventory.clear();
    
    // 2. 重置主岛养成
    _homeIsland = HomeIsland();
    _homeIsland.isTaxUnlocked = false; // 确保新游戏时税收功能锁定
    
    // 3. 重置船只状态
    _ship.cargoCapacity = 100;
    _ship.maxDurability = 200;
    _ship.damagePerShot = 10;
    _ship.durability = 200; // 确保耐久度为满
    
    // 4. 重置航行状态
    _isTransitioning = false;
    _isAtSea = false;
    _destinationPort = null;
    _previousPort = null;
    _travelProgress = 0.0;
    _totalTravelDistance = 0;
    _accumulatedDistance = 0.0;
    _legStartDistance = 0.0; // 重置航段起始点
    _accumulatedGameHours = 0.0;
    _lastProgressUpdateTime = null;
    // 停止并清理航行相关的 Ticker 和 Completer
    _progressTicker?.stop();
    _progressTicker = null;
    _travelCompleter = null;
    
    // 5. 重置其他状态
    _lastTaxHour = -1;
    _departingCrewNames.clear();
    _isMarketOpened = false;
    _isPortListOpened = false;
    _isShipyardOpened = false;
    _isQuantitySliderOpened = false;
    _isSliderInteracted = false;
    _sliderValue = 0;
    _isTradeBalanced = false;
    _isTradeConfirmed = false;
    _selectedMapPortId = null;
    _shipUpgradeCount = 0;
    _taxCollectedToday = false;
    _isHallPanelOpened = false;
    _isHomeIslandUpgraded = false;
    _isCombatUnlocked = false;
    _pendingTradeQuantities.clear();
    _visitedPortIds.clear();
    
    // 6. 重置战斗相关状态
    _isInCombat = false;
    _isEnteringCombat = false;
    _enemyShip = null;
    _playerAttackTimer = 0.0;
    _enemyAttackTimer = 0.0;
    _playerRepairTimer = 0.0;
    _enemyRepairTimer = 0.0;
    _playerShipXOffset = 0.0;
    _enemyShipXOffset = 1.0;
    _isSinking = false;
    _isPlayerSinking = false;
    _isReturningFromCombat = false;
    _isFadeOut = false;
    _previousPortBeforeCombat = null;
    _playerFireCount = 0;
    _enemyFireCount = 0;
    _playerHitCount = 0;
    _enemyHitCount = 0;
    
    // 7. 重置动画相关状态
    _swayTime = 0.0;
    _totalSailingOffset = 0.0;
    _waveAmplitudeMultiplier = 0.4;
    _accumulatedRepairTime = 0.0;
    
    // 8. 重置调试加成
    _debugRepairBonus = 0.0;
    _debugFireRateBonus = 0.0;
    _debugSpeedBonus = 0.0;
    _cachedCurrentSpeed = null;
    _cachedSpeedWeather = null;
    
    // ========== 初始化游戏数据 ==========
    
    _ports.clear();
    _ports.addAll(ports);

    // 确保主岛在港口列表中（必须在重置 _homeIsland 之后调用）
    _ensureHomeIslandInPorts();

    if (startingPort != null) {
      if (startingPort.isSeaLocation) {
        _currentPort = null;
        _isAtSea = true;
        
        // 新游戏从海上开始时，上一个港口为空，这样背景就不会显示初始岛屿
        _previousPort = null;
        
        // 如果是在海上开始，设置一个初始的航行状态，让背景持续滚动
        _totalTravelDistance = 999999999;
        _accumulatedDistance = 0.0;
        _legStartDistance = 0.0;
        _lastProgressUpdateTime = DateTime.now();
        _accumulatedGameHours = 0.0;
        _travelProgress = 0.0;
      } else {
        _currentPort = startingPort;
        _isAtSea = false;
      }
    } else {
      // 默认初始在主岛
      final homeIslandPort = _ports.firstWhere((p) => p.id == 'home_island', orElse: () => _ports.first);
      _currentPort = homeIslandPort;
      _isAtSea = false;
    }

    // 初始化船员和天气
    _crewManager.clear();
    _ship.maxCrewMemberCount = 5;
    _weather = WeatherCondition.calm;

    // 初始化昼夜系统
    _dayNightSystem.reset();
    // 默认从12:00开始（正午）
    _dayNightSystem.setGameMinutes(12 * 60); // 12小时 = 720分钟

    // 初始化价格更新跟踪
    _lastPriceUpdateDay = _dayNightSystem.currentDay;
    
    // 初始化酒馆船员
    _lastTavernRefreshDay = -1;
    refreshTavernCrew();

    // 初始化海上事件系统
    SeaEventSystem.instance.initialize(this);

    // 根据状态播放音乐，不再自动暂停/恢复时间
    if (_currentPort != null) {
      MusicSystem().playState('port');
    } else {
      MusicSystem().playState('cruising');
    }

    // 确保船只耐久度为满
    _ship.durability = _ship.maxDurability;

    notifyListeners();
  }

  /// 应用海上事件带来的进度变化
  void applyEventProgressDelta(double delta) {
    if (!_isAtSea || _totalTravelDistance <= 0) return;
    
    final totalDistance = _totalTravelDistance.toDouble();
    final deltaDistance = totalDistance * delta;
    
    _accumulatedDistance = (_accumulatedDistance + deltaDistance).clamp(0.0, totalDistance);
    
    notifyListeners();
  }

  /// 应用海上事件带来的速度倍率
  void applyEventSpeedMultiplier(double multiplier, int durationHours) {
    _eventSpeedMultiplier = multiplier;
    _eventSpeedMultiplierRemainingHours = durationHours.toDouble();
    _cachedCurrentSpeed = null; // 清除缓存
    notifyListeners();
  }

  /// 应用海上事件带来的时间跳跃
  void applyEventTimeSkip(int hours) {
    _dayNightSystem.addMinutes(hours * 60);
    // 同时也需要推进航行时间累积，否则会导致距离回退或进度停滞
    if (_isAtSea && !_isInCombat) {
      final dtDistance = currentSpeed * hours;
      _accumulatedDistance = (_accumulatedDistance + dtDistance).clamp(0.0, _totalTravelDistance.toDouble());
    }
    notifyListeners();
  }

  /// 使用 dt 增量更新昼夜系统（每帧调用）
  /// [dtRealSeconds] 实际经过的秒数（从上一帧到当前帧）
  void updateDayNightSystemWithDeltaTime(double dtRealSeconds) {
    // 1. 更新动画集中管理系统
    // swayTime 始终增加，用于模拟海浪左右晃动
    _swayTime += dtRealSeconds;
    
    // 如果处于菜单模式或任务暂停模式或海上事件激活模式，跳过后续所有游戏逻辑更新（仅保留基础动画）
    if (isMenuMode || _isQuestPaused || SeaEventSystem.instance.activeEvent != null) {
      notifyListeners();
      return;
    }

    // 更新海上事件速度加成持续时间
    if (_eventSpeedMultiplierRemainingHours > 0) {
      final dtGameHours = dtRealSeconds * (currentTimeScale / 60.0); // 将现实秒转换为游戏小时
      _eventSpeedMultiplierRemainingHours -= dtGameHours;
      if (_eventSpeedMultiplierRemainingHours <= 0) {
        _eventSpeedMultiplierRemainingHours = 0;
        _eventSpeedMultiplier = 1.0;
        _cachedCurrentSpeed = null;
      }
    }

    // totalSailingOffset 仅在航行且不在战斗时增加，用于驱动背景滚动
    if (_isAtSea && !_isInCombat) {
      // 基础滚动速度与当前航速正相关
      final speedMultiplier = currentSpeed / _baseSailingSpeed;
      _totalSailingOffset += (_baseScrollSpeed * speedMultiplier) * dtRealSeconds;
    }

    // 更新海浪起伏幅度倍率（平滑过渡）
    // 在海上时目标为 1.0，在港口时目标为 0.4
    final targetMultiplier = _isAtSea ? 1.0 : 0.4;
    if ((_waveAmplitudeMultiplier - targetMultiplier).abs() > 0.001) {
      // 每秒过渡约 0.5 的幅度
      final step = 0.5 * dtRealSeconds;
      if (_waveAmplitudeMultiplier < targetMultiplier) {
        _waveAmplitudeMultiplier = (_waveAmplitudeMultiplier + step).clamp(0.4, 1.0);
      } else {
        _waveAmplitudeMultiplier = (_waveAmplitudeMultiplier - step).clamp(0.4, 1.0);
      }
    } else {
      _waveAmplitudeMultiplier = targetMultiplier;
    }

    // 2. 使用 dt 增量更新游戏时间
    final crossedMidnight = _dayNightSystem.updateWithDeltaTime(dtRealSeconds, currentTimeScale);

    // 检查是否跨越整点（用于税收结算）
    final currentHour = _dayNightSystem.currentHour;
    if (_lastTaxHour == -1) {
      _lastTaxHour = currentHour;
    } else if (currentHour != _lastTaxHour) {
      _processTaxGeneration();
      _lastTaxHour = currentHour;
    }

    // 检查是否跨越00:00（工资结算、价格更新和酒馆刷新）
    if (crossedMidnight) {
      _processSalaryPayment();
      _taxCollectedToday = false;
      
      // 检查是否需要更新港口价格（每7天更新一次）
      final currentDay = _dayNightSystem.currentDay;
      
      // 刷新酒馆船员
      refreshTavernCrew();
      
      final daysSinceLastUpdate = currentDay - _lastPriceUpdateDay;
      // 处理跨年情况
      final actualDaysSinceUpdate = daysSinceLastUpdate >= 0 
          ? daysSinceLastUpdate 
          : (DayNightSystem.daysPerYear - _lastPriceUpdateDay + currentDay);
      
      if (actualDaysSinceUpdate >= _priceUpdateInterval) {
        _updatePortPrices();
        _lastPriceUpdateDay = currentDay;
      }
    }

    notifyListeners();
  }
  
  /// 更新昼夜系统（已废弃，保留用于兼容）
  /// 现在应该使用 updateDayNightSystemWithDeltaTime() 方法
  @Deprecated('使用 updateDayNightSystemWithDeltaTime() 方法')
  void updateDayNightSystem() {
    // 为了向后兼容，保留此方法但不执行任何操作
    // 实际更新应该通过 updateDayNightSystemWithDeltaTime() 进行
  }

  /// 处理工资结算（每天00:00执行）
  void _processSalaryPayment() {
    final crewMembers = List<CrewMember>.from(_crewManager.crewMembers);
    if (crewMembers.isEmpty) return;

    // 随机打乱支付顺序，以公平决定在金币不足时谁被欠薪
    crewMembers.shuffle();

    int totalPaid = 0;
    List<String> unpaidNames = [];

    for (final member in crewMembers) {
      if (_gold >= member.salary) {
        _gold -= member.salary;
        member.isPaid = true;
        totalPaid += member.salary;
      } else {
        member.isPaid = false;
        unpaidNames.add(member.name);
      }
    }

    if (unpaidNames.isEmpty) {
      NotificationSystem.instance.showNotificationL10n((l) => l.notificationSalaryPaid(totalPaid));
    } else {
      NotificationSystem.instance.showNotificationL10n((l) => l.notificationSalaryUnpaid(unpaidNames.join("、")));
    }

    notifyListeners();
  }

  /// 重置商人资金（每7天执行一次）
  /// 如果当前资金少于初始资金，则重置为初始资金；否则保持不变
  void _resetMerchantMoney(Port port) {
    if (port.merchantMoney < port.initialMerchantMoney) {
      final portIndex = _ports.indexWhere((p) => p.id == port.id);
      if (portIndex != -1) {
        _ports[portIndex] = _ports[portIndex].setMerchantMoney(port.initialMerchantMoney);
      }
    }
  }

  /// 对单个港口的所有商品执行补货
  void _restockPortGoods(Port port) {
    final portIndex = _ports.indexWhere((p) => p.id == port.id);
    if (portIndex == -1) {
      return;
    }

    // 获取重置后的商人资金（如果已重置）
    var currentPort = _ports[portIndex];
    final merchantMoney = currentPort.merchantMoney;

    // 获取港口的补货激进程度（港口级别，所有商品共用）
    final restockingAggressiveness = currentPort.restockingAggressiveness;

    // 遍历港口的所有商品配置
    for (final entry in currentPort.goodsConfig.entries) {
      final goodsId = entry.key;
      final config = entry.value;
      final s0 = config.s0; // 期望库存
      final currentStock = currentPort.getGoodsStock(goodsId);
      final actualCurrentStock = currentStock;

      // 计算补货增量
      final delta = TradeSystem.calculateRestockingDelta(
        merchantMoney,
        actualCurrentStock,
        s0,
        restockingAggressiveness,
      );

      // 应用补货增量到实际库存
      final newStock = (actualCurrentStock + delta).clamp(0, double.infinity).toInt();
      currentPort = currentPort.setGoodsStock(goodsId, newStock);
    }
    
    // 更新港口
    _ports[portIndex] = currentPort;
  }

  /// 更新港口价格（每7天执行一次）
  /// 先重置商人资金，然后执行补货
  void _updatePortPrices() {
    for (int i = 0; i < _ports.length; i++) {
      final port = _ports[i];
      
      // 1. 首先重置商人资金
      _resetMerchantMoney(port);
      
      // 2. 执行补货逻辑（使用重置后的资金）
      _restockPortGoods(port);
    }
    notifyListeners();
  }

  // 累积的自动修理时间（秒，用于 dt 增量更新）
  double _accumulatedRepairTime = 0.0;
  
  /// 使用 dt 增量处理自动修理（每帧调用）
  /// [dtRealSeconds] 实际经过的秒数（从上一帧到当前帧）
  /// 根据船工的技能自动恢复耐久度
  void processAutoRepairWithDeltaTime(double dtRealSeconds) {
    if (isMenuMode || _isQuestPaused || SeaEventSystem.instance.activeEvent != null) return;

    final autoRepair = autoRepairPerSecond;
    if (autoRepair <= 0 || _ship.durability >= _ship.maxDurability) {
      return;
    }

    // 累积修理时间
    _accumulatedRepairTime += dtRealSeconds;
    
    // 每秒恢复一次（累积到1秒时恢复）
    if (_accumulatedRepairTime >= 1.0) {
      final repairAmount = (autoRepair * _accumulatedRepairTime).round();
      _accumulatedRepairTime -= 1.0; // 保留余数
      
      if (repairAmount > 0) {
        _ship.durability = (_ship.durability + repairAmount).clamp(
          0,
          _ship.maxDurability,
        );
        notifyListeners();
      }
    }
  }
  
  /// 处理自动修理（已废弃，保留用于兼容）
  /// 现在应该使用 processAutoRepairWithDeltaTime() 方法
  @Deprecated('使用 processAutoRepairWithDeltaTime() 方法')
  void processAutoRepair() {
    // 为了向后兼容，保留此方法但不执行任何操作
    // 实际更新应该通过 processAutoRepairWithDeltaTime() 进行
  }

  /// 设置天气
  void setWeather(WeatherCondition weather) {
    if (_weather != weather) {
      _weather = weather;
      _cachedCurrentSpeed = null; // 清除缓存
      notifyListeners();
    }
  }

  /// 设置士气（已废弃，士气现在由船员平均士气自动计算）
  @Deprecated('士气现在由船员平均士气自动计算，无需手动设置')
  void setMorale(int morale) {
    // 为了向后兼容，保留此方法但不执行任何操作
    // 士气现在通过 morale getter 自动计算所有船员的平均士气
  }

  /// 添加船员
  void addCrewMember(CrewMember member) {
    _crewManager.addCrewMember(member);
    _cachedCurrentSpeed = null; // 清除缓存
    notifyListeners();
  }

  /// 刷新酒馆可招募船员
  void refreshTavernCrew() {
    final currentDay = _dayNightSystem.currentDay;
    if (_lastTavernRefreshDay == currentDay) return;
    
    _lastTavernRefreshDay = currentDay;
    final config = GameConfigLoader().crewConfig;
    if (config.isEmpty) return;

    final random = Random();
    final count = 3 + random.nextInt(3); // 3-5个船员
    _availableTavernCrew = [];

    final firstNames = List<String>.from(config['firstNames']);
    final lastNames = List<String>.from(config['lastNames']);
    final nameSeparator = config['nameSeparator'] ?? '';
    final personalities = List<String>.from(config['personalities']);
    final specialties = List<String>.from(config['specialties']);
    final likedItems = List<String>.from(config['likedItems']);
    final descriptionFormats = List<String>.from(config['descriptionFormats']);
    final avatars = List<String>.from(config['avatars']);

    for (int i = 0; i < count; i++) {
      final firstName = firstNames[random.nextInt(firstNames.length)];
      final lastName = lastNames[random.nextInt(lastNames.length)];
      final name = '$firstName$nameSeparator$lastName';
      
      final personality = personalities[random.nextInt(personalities.length)];
      final specialty = specialties[random.nextInt(specialties.length)];
      final likedItem = likedItems[random.nextInt(likedItems.length)];
      
      String description = descriptionFormats[random.nextInt(descriptionFormats.length)];
      description = description.replaceAll('[personality]', personality);
      description = description.replaceAll('[specialty]', specialty);
      description = description.replaceAll('[likedItem]', likedItem);

      final avatarPath = avatars[random.nextInt(avatars.length)];

      final sailorSkill = _generateSkillWithCurve(10.0);   // 水手 a=10
      final shipwrightSkill = _generateSkillWithCurve(2.0); // 船工 a=2
      final gunnerSkill = _generateSkillWithCurve(6.0);     // 炮手 a=6
      
      final totalSkill = sailorSkill + shipwrightSkill + gunnerSkill;
      final salary = (totalSkill * 2.0).round() + 1 + random.nextInt(10);

      _availableTavernCrew.add(CrewMember(
        name: name,
        sailorSkill: sailorSkill,
        shipwrightSkill: shipwrightSkill,
        gunnerSkill: gunnerSkill,
        salary: salary,
        avatarPath: avatarPath,
        personality: personality,
        specialty: specialty,
        likedItem: likedItem,
        description: description,
        assignedRole: CrewRole.unassigned,
      ));
    }
    notifyListeners();
  }

  /// 使用曲线公式生成技能值
  double _generateSkillWithCurve(double a) {
    final random = Random();
    const double C = 10.0;
    final double x = random.nextDouble() * C;
    final double ratio = x / C;
    final double y = C * pow(ratio, a);
    return double.parse(y.toStringAsFixed(2));
  }

  /// 招募酒馆船员
  void recruitTavernCrew(CrewMember member) {
    if (_availableTavernCrew.contains(member)) {
      addCrewMember(member);
      _availableTavernCrew.remove(member);
      notifyListeners();
    }
  }

  /// 移除船员
  bool removeCrewMember(CrewMember member) {
    final removed = _crewManager.removeCrewMember(member);
    if (removed) {
      _cachedCurrentSpeed = null; // 清除缓存
      notifyListeners();
    }
    return removed;
  }

  /// 解雇船员（手动触发）
  void dismissCrewMember(CrewMember member) {
    if (_crewManager.removeCrewMember(member)) {
      _cachedCurrentSpeed = null;
      notifyListeners();
    }
  }

  /// 分配船员角色
  void assignCrewRole(CrewMember member, CrewRole role) {
    _crewManager.assignCrewRole(member, role);
    _cachedCurrentSpeed = null; // 清除缓存
    notifyListeners();
  }

  /// 设置跳过航行动画（调试用）
  void setSkipTravelAnimation(bool skip) {
    _skipTravelAnimation = skip;
    notifyListeners();
  }
  
  /// 设置时间流逝倍数（调试用）
  void setTimeMultiplier(double multiplier) {
    _dayNightSystem.setTimeMultiplier(multiplier);
    notifyListeners();
  }
  
  /// 获取时间流逝倍数
  double get timeMultiplier => _dayNightSystem.timeMultiplier;
  
  /// 设置时间流逝暂停/恢复（调试用）
  void setTimePaused(bool paused) {
    if (paused) {
      _dayNightSystem.pause();
    } else {
      _dayNightSystem.resume();
    }
    notifyListeners();
  }
  
  /// 获取时间流逝是否暂停
  bool get isTimePaused => _dayNightSystem.isPaused;

  // 调试加成相关 getter/setter
  double get debugRepairBonus => _debugRepairBonus;
  void setDebugRepairBonus(double value) {
    _debugRepairBonus = value;
    notifyListeners();
  }

  double get debugSpeedBonus => _debugSpeedBonus;
  void setDebugSpeedBonus(double value) {
    _debugSpeedBonus = value;
    _cachedCurrentSpeed = null; // 清除速度缓存
    notifyListeners();
  }

  double get debugFireRateBonus => _debugFireRateBonus;
  void setDebugFireRateBonus(double value) {
    _debugFireRateBonus = value;
    notifyListeners();
  }

  double get islandScale => _debugIslandScale;
  void setDebugIslandScale(double value) {
    _debugIslandScale = value;
    notifyListeners();
  }

  // 战斗相关getter
  bool get isInCombat => _isInCombat;
  bool get isEnteringCombat => _isEnteringCombat;
  EnemyShip? get enemyShip => _enemyShip;
  double get playerShipXOffset => _playerShipXOffset;
  double get enemyShipXOffset => _enemyShipXOffset;
  bool get isSinking => _isSinking;
  bool get isPlayerSinking => _isPlayerSinking;
  bool get isReturningFromCombat => _isReturningFromCombat;
  bool get isFadeOut => _isFadeOut;

  // 战斗事件计数器 getters
  int get playerFireCount => _playerFireCount;
  int get enemyFireCount => _enemyFireCount;
  int get playerHitCount => _playerHitCount;
  int get enemyHitCount => _enemyHitCount;

  // 任务系统相关 getter
  bool get isMarketOpened => _isMarketOpened;
  bool get isPortListOpened => _isPortListOpened;
  bool get isShipyardOpened => _isShipyardOpened;
  bool get isQuantitySliderOpened => _isQuantitySliderOpened;
  bool get isSliderInteracted => _isSliderInteracted;
  int get sliderValue => _sliderValue;
  bool get isTradeBalanced => _isTradeBalanced;
  int get shipUpgradeCount => _shipUpgradeCount;
  bool get taxCollectedToday => _taxCollectedToday;
  bool get isHallPanelOpened => _isHallPanelOpened;
  bool get isHomeIslandUpgraded => _isHomeIslandUpgraded;
  bool get isTradeConfirmed => _isTradeConfirmed;
  bool get isCombatUnlocked => _isCombatUnlocked;

  void setMarketOpened(bool opened) {
    if (_isMarketOpened != opened) {
      _isMarketOpened = opened;
      notifyListeners();
    }
  }

  void setPortListOpened(bool opened) {
    if (_isPortListOpened != opened) {
      _isPortListOpened = opened;
      notifyListeners();
    }
  }

  void setShipyardOpened(bool opened) {
    if (_isShipyardOpened != opened) {
      _isShipyardOpened = opened;
      notifyListeners();
    }
  }

  void setQuantitySliderOpened(bool opened) {
    if (_isQuantitySliderOpened != opened) {
      _isQuantitySliderOpened = opened;
      if (opened) {
        _isSliderInteracted = false;
        _sliderValue = 0;
      }
      notifyListeners();
    }
  }

  void setSliderInteracted(bool interacted) {
    if (_isSliderInteracted != interacted) {
      _isSliderInteracted = interacted;
      notifyListeners();
    }
  }

  void setSliderValue(int value) {
    if (_sliderValue != value) {
      _sliderValue = value;
      notifyListeners();
    }
  }

  void setTradeBalanced(bool balanced) {
    if (_isTradeBalanced != balanced) {
      _isTradeBalanced = balanced;
      notifyListeners();
    }
  }

  void setTradeConfirmed(bool confirmed) {
    if (_isTradeConfirmed != confirmed) {
      _isTradeConfirmed = confirmed;
      notifyListeners();
    }
  }

  void setHallPanelOpened(bool opened) {
    if (_isHallPanelOpened != opened) {
      _isHallPanelOpened = opened;
      notifyListeners();
    }
  }

  void setHomeIslandUpgraded(bool upgraded) {
    if (_isHomeIslandUpgraded != upgraded) {
      _isHomeIslandUpgraded = upgraded;
      notifyListeners();
    }
  }

  void setCombatUnlocked(bool unlocked) {
    if (_isCombatUnlocked != unlocked) {
      _isCombatUnlocked = unlocked;
      notifyListeners();
    }
  }

  /// 一键解锁/锁定所有港口（调试用）
  void setAllPortsUnlocked(bool unlocked) {
    bool changed = false;
    for (int i = 0; i < _ports.length; i++) {
      if (_ports[i].unlocked != unlocked) {
        _ports[i] = _ports[i].copyWith(unlocked: unlocked);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// 解锁除主岛外的所有港口
  void unlockAllPortsExceptHome() {
    bool changed = false;
    for (int i = 0; i < _ports.length; i++) {
      if (_ports[i].id != 'home_island' && !_ports[i].unlocked) {
        _ports[i] = _ports[i].copyWith(unlocked: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void incrementShipUpgradeCount() {
    _shipUpgradeCount++;
    notifyListeners();
  }

  void resetDailyTutorialFlags() {
    _taxCollectedToday = false;
    notifyListeners();
  }

  /// 寻找最近的港口 ID
  String? findNearestPortId() {
    double currentX = 0;
    double currentY = 0;
    bool hasCoords = false;

    if (_isAtSea) {
      // 在海上，通过上一个港口和目标港口插值估算当前坐标
      final startPort = _previousPort;
      final endPort = _destinationPort;

      if (startPort != null && endPort != null && startPort.mapX != null && startPort.mapY != null && endPort.mapX != null && endPort.mapY != null) {
        currentX = startPort.mapX! + (endPort.mapX! - startPort.mapX!) * _travelProgress;
        currentY = startPort.mapY! + (endPort.mapY! - startPort.mapY!) * _travelProgress;
        hasCoords = true;
      } else if (startPort != null && startPort.mapX != null && startPort.mapY != null) {
        currentX = startPort.mapX!;
        currentY = startPort.mapY!;
        hasCoords = true;
      } else if (endPort != null && endPort.mapX != null && endPort.mapY != null) {
        currentX = endPort.mapX!;
        currentY = endPort.mapY!;
        hasCoords = true;
      }
    } else {
      // 在港口，直接使用当前港口坐标
      final port = _currentPort ?? _previousPort;
      if (port != null && port.mapX != null && port.mapY != null) {
        currentX = port.mapX!;
        currentY = port.mapY!;
        hasCoords = true;
      }
    }

    String? nearestId;
    double minDistanceSq = double.infinity;

    // 获取所有候选港口（已解锁且非海上地点）
    final candidates = _ports.where((p) => !p.isSeaLocation && p.unlocked).toList();
    if (candidates.isEmpty) return null;

    if (hasCoords) {
      for (final port in candidates) {
        // 排除当前所在港口（如果已经在某个港口）
        if (!_isAtSea && port.id == (_currentPort?.id)) continue;

        if (port.mapX != null && port.mapY != null) {
          final dx = port.mapX! - currentX;
          final dy = port.mapY! - currentY;
          final distSq = dx * dx + dy * dy;

          if (distSq < minDistanceSq) {
            minDistanceSq = distSq;
            nearestId = port.id;
          }
        }
      }
    }

    // 如果无法通过坐标找到最近港口，则回退到第一个可用的已解锁港口
    return nearestId ?? candidates.first.id;
  }

  /// 开始航行到目标港口
  Future<void> startTravelToPort(String portId, {int? minDistance}) async {
    final port = _ports.firstWhere(
      (p) => p.id == portId,
      orElse: () => throw Exception('Port not found: $portId'),
    );

    if (!port.unlocked) {
      throw Exception('Port is locked: $portId');
    }

    // 如果已经在目标港口，直接返回
    if (_currentPort?.id == portId) {
      return;
    }

    // 处理"海上"特殊地点
    if (port.isSeaLocation) {
      // 保存当前港口到 _previousPort
      _previousPort = _currentPort;
      
      // 设置状态：在海上但没有目标港口
      _currentPort = null;
      _isAtSea = true;
      _destinationPort = null;
      _isTransitioning = true;
      
      // 设置无限大的距离，让玩家一直在海上航行
      _totalTravelDistance = 999999999; // 使用一个非常大的值，确保永远不会到达
      _accumulatedDistance = 0.0;
      _legStartDistance = 0.0;
      _lastProgressUpdateTime = DateTime.now();
      _accumulatedGameHours = 0.0;
      _travelProgress = 0.0;
      
      // 切换音乐
      MusicSystem().playState('cruising');
      
      // 显示通知
      NotificationSystem.instance.showNotificationL10n((l) => l.notificationEnteredSea);
      
      notifyListeners();
      
      // 启动 Ticker 来持续更新 accumulatedDistance，让岛屿持续滑出
      try {
        _progressTicker?.stop();
        
        _progressTicker = Ticker((elapsed) {
          if (_lastProgressUpdateTime == null) {
            _lastProgressUpdateTime = DateTime.now();
            return;
          }
          
          // 如果进入战斗或海上事件激活，暂停更新（不更新时间，直接返回）
          if (_isInCombat || SeaEventSystem.instance.activeEvent != null) {
            _lastProgressUpdateTime = DateTime.now();
            return;
          }
          
          final now = DateTime.now();
          final dtRealSeconds = now.difference(_lastProgressUpdateTime!).inMilliseconds / 1000.0;
          _lastProgressUpdateTime = now;
          
          final dtGameHours = dtRealSeconds;
          
          // 累积游戏内时间
          _accumulatedGameHours += dtGameHours;
          
          // 计算已航行距离：当前航速（节） × 这一帧的游戏小时数
          // 注意：当前航速可能变化（天气、船员变化），所以需要实时计算
          final currentSpeed = this.currentSpeed; // 获取当前航速（节）
          final dtDistance = currentSpeed * dtGameHours;
          _accumulatedDistance += dtDistance;
          
          // 进度计算（海上无尽航行时，进度逐渐增加到 0.5 以便触发事件）
          if (_accumulatedDistance < 240) {
            _travelProgress = (_accumulatedDistance / 480).clamp(0.0, 0.5);
          } else {
            _travelProgress = 0.5;
          }
          
          notifyListeners();
        });
        
        _progressTicker!.start();
        
        await Future.delayed(const Duration(milliseconds: 100));
        _isTransitioning = false;
        notifyListeners();
      } catch (e) {
        _isTransitioning = false;
        notifyListeners();
      }
      
      return;
    }

    // 保存当前港口用于计算航行时间
    Port? previousPort;
    // 检查是否在海上（如果是从海上选择新目的地或被事件重定向）
    final isFromSea = _isAtSea;
    if (isFromSea) {
      // 从海上选择其他港口时，使用 _previousPort
      previousPort = _previousPort;
    } else {
      // 正常情况，使用当前港口
      previousPort = _currentPort;
    }

    _destinationPort = port;
    _isTransitioning = true;

    // 离开当前港口，进入海上状态
    _currentPort = null;
    _isAtSea = true;

    // 切换音乐
    MusicSystem().playState('cruising');

    // 获取航行距离（节）
    int travelDistance = 240; // 如果 prev port 为 null，则 traveldistance 可以fallback 到 240
    if (previousPort != null) {
      // 获取航行距离（节）
      travelDistance = previousPort.getDistanceTo(portId) ?? 480;

      // 否则（prev port 不为 null），非海上地点的最小航行距离为 480 节
      if (!port.isSeaLocation && travelDistance < 480) {
        travelDistance = 480;
      }
    }

    // 应用传入的最小距离限制（如果有）
    if (minDistance != null && travelDistance < minDistance) {
      travelDistance = minDistance;
    }

    // 初始化进度（基于距离）
    // 关键修改：如果是从海上选择新目的地
    if (isFromSea) {
      // 记录本段起始里程点
      _legStartDistance = _accumulatedDistance;
      // 总目标里程 = 已走过的里程 + 新航段的距离
      _totalTravelDistance = (_accumulatedDistance + travelDistance).toInt();
      
      // 不重置 accumulatedDistance 和 accumulatedGameHours，保持平滑过渡
      _lastProgressUpdateTime = DateTime.now();
      _travelProgress = 0.0;
    } else {
      // 从港口出发，重置里程表
      _legStartDistance = 0.0;
      _totalTravelDistance = travelDistance;
      _accumulatedDistance = 0.0;
      _lastProgressUpdateTime = DateTime.now();
      _accumulatedGameHours = 0.0;
      _travelProgress = 0.0;
    }

    notifyListeners();

    // 如果启用跳过动画，直接完成
    if (_skipTravelAnimation) {
      _progressTicker?.stop();
      _progressTicker = null;
      _travelProgress = 1.0;
      notifyListeners();
      // 直接切换到目标港口
      await switchToPort(portId);
      _travelProgress = 0.0;
      _totalTravelDistance = 0;
      _accumulatedDistance = 0.0;
      _lastProgressUpdateTime = null;
      _accumulatedGameHours = 0.0;
      notifyListeners();
      return;
    }

    // 如果航行距离大于0，使用 Ticker 每帧更新进度
    try {
      if (_totalTravelDistance > 0) {
        // 停止之前的 Ticker（如果存在）
        _progressTicker?.stop();
        
        // 创建 Completer 用于等待航行完成
        _travelCompleter = Completer<void>();
        
        // 创建 Ticker 每帧更新进度
        // 基于游戏内时间，每次只更新 dt 增量
        _progressTicker = Ticker((elapsed) {
          if (_lastProgressUpdateTime == null) {
            _lastProgressUpdateTime = DateTime.now();
            return;
          }

          // 如果进入战斗或海上事件激活，暂停更新（不更新时间，直接返回）
          if (_isInCombat || SeaEventSystem.instance.activeEvent != null) {
            // 重新记录时间，避免暂停期间的时间被计入
            _lastProgressUpdateTime = DateTime.now();
            return;
          }
          
          // 计算实际时间增量 dt（秒）
          final now = DateTime.now();
          final dtRealSeconds = now.difference(_lastProgressUpdateTime!).inMilliseconds / 1000.0;
          _lastProgressUpdateTime = now;
          
          // 将实际时间增量转换为游戏内时间增量
          // 1现实秒 = 1游戏小时，所以 dt_real_seconds = dt_game_hours
          final dtGameHours = dtRealSeconds;
          
          // 累积游戏内时间
          _accumulatedGameHours += dtGameHours;
          
          // 计算已航行距离：当前航速（节） × 这一帧的游戏小时数
          // 注意：当前航速可能变化（天气、船员变化），所以需要实时计算
          final currentSpeed = this.currentSpeed; // 获取当前航速（节）
          final dtDistance = currentSpeed * dtGameHours;
          _accumulatedDistance += dtDistance;
          
          // 根据已航行距离计算进度
          final legTotal = _totalTravelDistance - _legStartDistance;
          if (_accumulatedDistance >= _totalTravelDistance) {
            _travelProgress = 1.0;
            _accumulatedDistance = _totalTravelDistance.toDouble();
            notifyListeners();
            // 停止 Ticker
            _progressTicker?.stop();
            _progressTicker = null;
            // 完成等待
            if (_travelCompleter != null && !_travelCompleter!.isCompleted) {
              _travelCompleter!.complete();
            }
          } else {
            // 基于已航行距离计算进度（从本段起点开始计算）
            if (legTotal > 0) {
              _travelProgress = ((_accumulatedDistance - _legStartDistance) / legTotal).clamp(0.0, 1.0);
            } else {
              _travelProgress = 1.0;
            }
            
            // 检查是否触发随机事件（每 1 游戏小时检查一次）
            final currentTotalHours = _accumulatedGameHours;
            final previousTotalHours = _accumulatedGameHours - dtGameHours;
            if (currentTotalHours.floor() > previousTotalHours.floor()) {
              _checkRandomEvents();
            }
            
            notifyListeners();
          }
        });
        
        // 启动 Ticker
        _progressTicker!.start();
        
        // 等待航行完成
        await _travelCompleter!.future;
      } else {
        _travelProgress = 1.0;
        notifyListeners();
      }

      // 到达目标港口
      await switchToPort(portId);
    } finally {
      // 确保无论是否发生异常，都停止 Ticker
      _progressTicker?.stop();
      _progressTicker = null;
      // 清理 Completer
      _travelCompleter = null;
    }

    // 重置进度
    _travelProgress = 0.0;
    _totalTravelDistance = 0;
    _accumulatedDistance = 0.0;
    _lastProgressUpdateTime = null;
    _accumulatedGameHours = 0.0;
    notifyListeners();
  }

  /// 切换到新港口
  Future<void> switchToPort(String portId) async {
    final port = _ports.firstWhere(
      (p) => p.id == portId,
      orElse: () => throw Exception('Port not found: $portId'),
    );

    if (!port.unlocked) {
      throw Exception('Port is locked: $portId');
    }

    _isTransitioning = true;
    notifyListeners();

    // 在正式进入港口前，检查是否有欠薪船员需要离队
    final unpaidCrew = _crewManager.crewMembers.where((m) => !m.isPaid).toList();
    if (unpaidCrew.isNotEmpty) {
      _departingCrewNames.clear();
      for (final member in unpaidCrew) {
        _departingCrewNames.add(member.name);
        _crewManager.removeCrewMember(member);
      }
      _cachedCurrentSpeed = null; // 船员变动，清除速度缓存
    }

    // 设置新港口，但保持过渡状态
    _currentPort = port;
    _previousPort = port; // 更新上一个港口
    _destinationPort = null;
    _isAtSea = false;
    _legStartDistance = 0.0; // 到达港口，重置起始点

    // 记录访问过的港口（排除海上特殊位置）
    if (!port.isSeaLocation) {
      _visitedPortIds.add(portId);
    }

    // 播放港口音乐
    MusicSystem().playState('port');

    // 显示到港提示
    NotificationSystem.instance.showNotificationL10n((l) => l.notificationArrivedAtPort(port.name));

    // 重置海上事件航程统计
    SeaEventSystem.instance.resetVoyageStats();

    notifyListeners();

    // 现在才结束过渡状态，允许显示按钮
    _isTransitioning = false;
    _travelProgress = 0.0;
    _totalTravelDistance = 0;
    _accumulatedDistance = 0.0;
    notifyListeners();

    // 自动存档
    SaveManager.autoSave(this);
  }

  /// 处理税收生成（每小时执行一次）
  void _processTaxGeneration() {
    if (_homeIsland.isTaxUnlocked) {
      _homeIsland.accumulatedTax += _homeIsland.taxAmount;
      notifyListeners();
    }
  }

  /// 领取税收
  void collectTax() {
    if (_homeIsland.isTaxUnlocked && _homeIsland.accumulatedTax > 0) {
      addGold(_homeIsland.accumulatedTax);
      _homeIsland.accumulatedTax = 0;
      _taxCollectedToday = true;
      notifyListeners();
    }
  }

  /// 强制设置积累的税收金额（仅用于任务系统或调试）
  void setAccumulatedTax(int amount) {
    if (_homeIsland.isTaxUnlocked) {
      _homeIsland.accumulatedTax = amount;
      notifyListeners();
    }
  }

  /// 解锁主岛税收功能
  void unlockHomeIslandTax() {
    if (!_homeIsland.isTaxUnlocked) {
      _homeIsland.isTaxUnlocked = true;
      notifyListeners();
    }
  }

  /// 确保主岛在港口列表中
  void _ensureHomeIslandInPorts() {
    // 1. 尝试在 ports.json 中查找母岛
    Port? configHome;
    try {
      configHome = _ports.firstWhere((p) => p.id == 'home_island');
    } catch (_) {
      configHome = null;
    }

    Port homePort;
    if (configHome != null) {
      homePort = configHome;

      // 动态构建 goodsConfig
      final Map<String, PortGoodsConfig> dynamicGoodsConfig = {};
      final level = _homeIsland.level;

      // 等级 0: 基础物资
      dynamicGoodsConfig['food'] = PortGoodsConfig(
          alpha: (0.05 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.05),
          s0: 500 + _homeIsland.restockSpeedLevel * 100,
          basePrice: 8.0);
      dynamicGoodsConfig['water'] = PortGoodsConfig(
          alpha: (0.04 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.04),
          s0: 800 + _homeIsland.restockSpeedLevel * 150,
          basePrice: 6.0);
      dynamicGoodsConfig['rum'] = PortGoodsConfig(
          alpha: (0.06 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.06),
          s0: 300 + _homeIsland.restockSpeedLevel * 50,
          basePrice: 15.0);

      // 等级 1: 建材
      if (level >= 1) {
        dynamicGoodsConfig['wood'] = PortGoodsConfig(
            alpha: (0.04 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.04),
            s0: 500 + _homeIsland.restockSpeedLevel * 100,
            basePrice: 12.0);
        dynamicGoodsConfig['stone'] = PortGoodsConfig(
            alpha: (0.05 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.05),
            s0: 400 + _homeIsland.restockSpeedLevel * 80,
            basePrice: 14.0);
      }

      // 等级 2: 材料
      if (level >= 2) {
        dynamicGoodsConfig['cloth'] = PortGoodsConfig(
            alpha: (0.04 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.04),
            s0: 500 + _homeIsland.restockSpeedLevel * 100,
            basePrice: 11.0);
        dynamicGoodsConfig['leather'] = PortGoodsConfig(
            alpha: (0.05 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.05),
            s0: 300 + _homeIsland.restockSpeedLevel * 60,
            basePrice: 16.0);
      }

      // 等级 3: 金属
      if (level >= 3) {
        dynamicGoodsConfig['metal'] = PortGoodsConfig(
            alpha: (0.05 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.05),
            s0: 500 + _homeIsland.restockSpeedLevel * 100,
            basePrice: 23.0);
      }

      // 等级 4: 香料
      if (level >= 4) {
        dynamicGoodsConfig['spice'] = PortGoodsConfig(
            alpha: (0.08 - (_homeIsland.economyLevel * 0.01)).clamp(0.01, 0.08),
            s0: 300 + _homeIsland.restockSpeedLevel * 50,
            basePrice: 28.0);
      }

      // 等级 5: 丝绸
      if (level >= 5) {
        dynamicGoodsConfig['silk'] = PortGoodsConfig(
            alpha: (0.10 - (_homeIsland.economyLevel * 0.01)).clamp(0.01, 0.10),
            s0: 200 + _homeIsland.restockSpeedLevel * 40,
            basePrice: 40.0);
      }

      // 等级 6: 象牙
      if (level >= 6) {
        dynamicGoodsConfig['ivory'] = PortGoodsConfig(
            alpha: (0.12 - (_homeIsland.economyLevel * 0.01)).clamp(0.01, 0.12),
            s0: 150 + _homeIsland.restockSpeedLevel * 30,
            basePrice: 55.0);
      }

      // 等级 7: 艺术品
      if (level >= 7) {
        dynamicGoodsConfig['artwork'] = PortGoodsConfig(
            alpha: (0.15 - (_homeIsland.economyLevel * 0.015)).clamp(0.01, 0.15),
            s0: 100 + _homeIsland.restockSpeedLevel * 20,
            basePrice: 75.0);
      }

      homePort = homePort.copyWith(goodsConfig: dynamicGoodsConfig);

      // 字段级回退：如果商人初始资金未配置（或为初始默认值），则使用动态计算
      if (homePort.initialMerchantMoney <= 1000) {
        int dynamicFunds = 1000 + _homeIsland.merchantFundsLevel * 2000;
        homePort = homePort.copyWith(
          merchantMoney: dynamicFunds,
          initialMerchantMoney: dynamicFunds,
        );
      }

      // 字段级回退：如果背景图未配置（或为默认占位符），则使用养成等级外观
      if (homePort.backgroundImage.isEmpty ||
          homePort.backgroundImage == 'assets/images/buildings/village_0.png') {
        homePort = homePort.copyWith(backgroundImage: _homeIsland.appearance);
      }
    } else {
      // 查找或创建主岛基本属性（全量动态生成，逻辑同上，由于 homePort 已经被上面 logic 覆盖，这里暂时保留备份但实际可能用不到）
      // ... (省略 else 部分，逻辑已在 if (configHome != null) 中处理)
      // 为了保持一致性，我也更新 else 分支的内容
      final Map<String, PortGoodsConfig> dynamicGoodsConfig = {};
      final level = _homeIsland.level;
      
      dynamicGoodsConfig['food'] = PortGoodsConfig(
          alpha: (0.05 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.05),
          s0: 500 + _homeIsland.restockSpeedLevel * 100,
          basePrice: 8.0);
      dynamicGoodsConfig['water'] = PortGoodsConfig(
          alpha: (0.04 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.04),
          s0: 800 + _homeIsland.restockSpeedLevel * 150,
          basePrice: 6.0);
      dynamicGoodsConfig['rum'] = PortGoodsConfig(
          alpha: (0.06 - (_homeIsland.economyLevel * 0.005)).clamp(0.01, 0.06),
          s0: 300 + _homeIsland.restockSpeedLevel * 50,
          basePrice: 15.0);

      if (level >= 1) {
        dynamicGoodsConfig['wood'] = PortGoodsConfig(alpha: 0.04, s0: 500 + _homeIsland.restockSpeedLevel * 100, basePrice: 12.0);
        dynamicGoodsConfig['stone'] = PortGoodsConfig(alpha: 0.05, s0: 400 + _homeIsland.restockSpeedLevel * 80, basePrice: 14.0);
      }
      if (level >= 2) {
        dynamicGoodsConfig['cloth'] = PortGoodsConfig(alpha: 0.04, s0: 500 + _homeIsland.restockSpeedLevel * 100, basePrice: 11.0);
        dynamicGoodsConfig['leather'] = PortGoodsConfig(alpha: 0.05, s0: 300 + _homeIsland.restockSpeedLevel * 60, basePrice: 16.0);
      }
      if (level >= 3) {
        dynamicGoodsConfig['metal'] = PortGoodsConfig(alpha: 0.05, s0: 500 + _homeIsland.restockSpeedLevel * 100, basePrice: 23.0);
      }
      if (level >= 4) {
        dynamicGoodsConfig['spice'] = PortGoodsConfig(alpha: 0.08, s0: 300 + _homeIsland.restockSpeedLevel * 50, basePrice: 28.0);
      }
      if (level >= 5) {
        dynamicGoodsConfig['silk'] = PortGoodsConfig(alpha: 0.10, s0: 200 + _homeIsland.restockSpeedLevel * 40, basePrice: 40.0);
      }
      if (level >= 6) {
        dynamicGoodsConfig['ivory'] = PortGoodsConfig(alpha: 0.12, s0: 150 + _homeIsland.restockSpeedLevel * 30, basePrice: 55.0);
      }
      if (level >= 7) {
        dynamicGoodsConfig['artwork'] = PortGoodsConfig(alpha: 0.15, s0: 100 + _homeIsland.restockSpeedLevel * 20, basePrice: 75.0);
      }

      homePort = Port(
        id: 'home_island',
        name: '我的岛屿',
        backgroundImage: _homeIsland.appearance,
        description: '这是你的私人岛屿，可以进行养成和存储。',
        unlocked: false,
        mapX: configHome?.mapX ?? 250.0,
        mapY: configHome?.mapY ?? 350.0,
        distances: {
          'port_1': 480, // 默认到起始港较近
        },
        goodsConfig: dynamicGoodsConfig,
        merchantMoney: 1000 + _homeIsland.merchantFundsLevel * 2000,
        initialMerchantMoney: 1000 + _homeIsland.merchantFundsLevel * 2000,
      );
    }

    // 2. 建立双向距离连接
    final homeDistances = Map<String, int>.from(homePort.distances);

    for (int i = 0; i < _ports.length; i++) {
      final port = _ports[i];
      if (port.id == 'home_island') continue;

      // 如果已定义则使用现有距离，否则进行计算
      int? distanceToHome = homeDistances[port.id];
      if (distanceToHome == null) {
        if (port.id == 'port_1') {
          distanceToHome = 480;
        } else if (port.distances.containsKey('port_1')) {
          distanceToHome = port.distances['port_1']! + 480;
        } else {
          distanceToHome = 1200;
        }
      }

      // 更新其他港口到主岛的距离
      final newDistances = Map<String, int>.from(port.distances);
      newDistances['home_island'] = distanceToHome;
      _ports[i] = port.copyWith(distances: newDistances);

      // 同时更新主岛到该港口的距离，防止瞬间移动
      homeDistances[port.id] = distanceToHome;
    }

    // 3. 将带有完整距离图的主岛更新到列表中
    final finalHomePort = homePort.copyWith(distances: homeDistances);
    final index = _ports.indexWhere((p) => p.id == 'home_island');
    if (index != -1) {
      _ports[index] = finalHomePort;
    } else {
      _ports.add(finalHomePort);
    }
  }

  void setPortUnlocked(String portId, bool unlocked) {
    final portIndex = _ports.indexWhere((p) => p.id == portId);
    if (portIndex != -1) {
      if (_ports[portIndex].unlocked != unlocked) {
        _ports[portIndex] = _ports[portIndex].copyWith(unlocked: unlocked);
        notifyListeners();
      }
    }
  }

  /// 升级主岛功能
  bool upgradeHomeIsland(String type) {
    int currentLevel = 0;
    
    switch (type) {
      case 'tax': currentLevel = _homeIsland.taxLevel; break;
      case 'economy': currentLevel = _homeIsland.economyLevel; break;
      case 'funds': currentLevel = _homeIsland.merchantFundsLevel; break;
      case 'restock': currentLevel = _homeIsland.restockSpeedLevel; break;
      default: return false;
    }

    if (currentLevel >= 7) return false;

    // 同步规则：每个选项都不可单独超越其他选项一级。
    // 即：当前等级不能大于岛屿的最低等级（level 属性返回的就是四个等级的最小值）
    if (currentLevel > _homeIsland.level) return false;

    // 升级花费逻辑：1000 * (level + 1)
    int cost = 1000 * (currentLevel + 1);

    if (spendGold(cost)) {
      switch (type) {
        case 'tax': _homeIsland.taxLevel++; break;
        case 'economy': _homeIsland.economyLevel++; break;
        case 'funds': _homeIsland.merchantFundsLevel++; break;
        case 'restock': _homeIsland.restockSpeedLevel++; break;
      }
      
      // 标记主岛已升级（用于任务系统）
      _isHomeIslandUpgraded = true;

      // 升级后更新主岛港口属性
      _ensureHomeIslandInPorts();
      
      // 确保新解锁的物资能够立即初始化库存
      initializePortGoodsStock();
      
      // 如果当前就在主岛，更新当前港口引用
      if (_currentPort?.id == 'home_island') {
        _currentPort = _ports.firstWhere((p) => p.id == 'home_island');
      }
      
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 获取仓库库存
  List<ShipInventoryItem> get warehouseInventory => List.unmodifiable(_homeIsland.warehouseInventory);

  /// 获取仓库中商品数量
  int getWarehouseQuantity(String goodsId) {
    try {
      final item = _homeIsland.warehouseInventory.firstWhere((item) => item.goodsId == goodsId);
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  /// 将商品从船只存入仓库
  bool depositToWarehouse(String goodsId, int quantity) {
    final inventoryQuantity = getInventoryQuantity(goodsId);
    if (inventoryQuantity < quantity) return false;

    // 获取当前货物的均价
    final sourceItem = _inventory.firstWhere((item) => item.goodsId == goodsId);
    final currentAveragePrice = sourceItem.averagePurchasePrice;

    if (removeFromInventory(goodsId, quantity)) {
      final existingItemIndex = _homeIsland.warehouseInventory.indexWhere(
        (item) => item.goodsId == goodsId,
      );

      if (existingItemIndex != -1) {
        _homeIsland.warehouseInventory[existingItemIndex].add(quantity, currentAveragePrice);
      } else {
        _homeIsland.warehouseInventory.add(ShipInventoryItem(
          goodsId: goodsId,
          quantity: quantity,
          averagePurchasePrice: currentAveragePrice,
        ));
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 从仓库取出商品到船只
  bool withdrawFromWarehouse(String goodsId, int quantity) {
    final warehouseQuantity = getWarehouseQuantity(goodsId);
    if (warehouseQuantity < quantity) return false;

    // 获取仓库中货物的均价
    final warehouseItem = _homeIsland.warehouseInventory.firstWhere((item) => item.goodsId == goodsId);
    final currentAveragePrice = warehouseItem.averagePurchasePrice;

    // 检查船只载货空间
    if (_getGoodsById == null) return false;
    final goods = _getGoodsById!(goodsId);
    final weight = quantity * goods.weight;
    if (!_ship.hasEnoughCargo(_inventory, weight, _getGoodsById!)) return false;

    if (addToInventory(goodsId, quantity, purchasePrice: currentAveragePrice)) {
      final itemIndex = _homeIsland.warehouseInventory.indexWhere((item) => item.goodsId == goodsId);
      if (itemIndex != -1) {
        _homeIsland.warehouseInventory[itemIndex].remove(quantity);
        if (_homeIsland.warehouseInventory[itemIndex].quantity == 0) {
          _homeIsland.warehouseInventory.removeAt(itemIndex);
        }
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 添加金币
  void addGold(int amount) {
    _gold += amount;
    notifyListeners();
  }

  /// 消费金币
  bool spendGold(int amount) {
    if (_gold >= amount) {
      _gold -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 添加商品到库存
  /// [goodsId] 商品ID
  /// [quantity] 数量
  /// [getGoodsById] 可选：获取商品信息的函数，如果不提供则使用内部设置的函数
  /// [purchasePrice] 可选：本次购买的单价，用于计算持有均价
  bool addToInventory(
    String goodsId,
    int quantity, {
    Goods Function(String goodsId)? getGoodsById,
    double? purchasePrice,
  }) {
    // 使用传入的getGoodsById或内部设置的函数
    final getGoods = getGoodsById ?? _getGoodsById;
    if (getGoods == null) {
      throw Exception('getGoodsById function not set. Call setGetGoodsById() first.');
    }
    
    final goods = getGoods(goodsId);
    final additionalWeight = quantity * goods.weight;
    
    // 检查载货空间（如果重量为0，直接允许）
    if (additionalWeight > 0) {
      if (!_ship.hasEnoughCargo(_inventory, additionalWeight, getGoods)) {
        return false;
      }
    }

    final existingItemIndex = _inventory.indexWhere((item) => item.goodsId == goodsId);

    if (existingItemIndex != -1) {
      _inventory[existingItemIndex].add(quantity, purchasePrice);
    } else {
      _inventory.add(ShipInventoryItem(
        goodsId: goodsId,
        quantity: quantity,
        averagePurchasePrice: purchasePrice ?? 0.0,
      ));
    }

    notifyListeners();
    return true;
  }

  /// 从库存移除商品
  bool removeFromInventory(String goodsId, int quantity) {
    final item = _inventory.firstWhere(
      (item) => item.goodsId == goodsId,
      orElse: () => throw Exception('Goods not in inventory: $goodsId'),
    );

    if (item.quantity < quantity) {
      return false;
    }

    item.remove(quantity);

    if (item.quantity == 0) {
      _inventory.remove(item);
    }

    notifyListeners();
    return true;
  }

  /// 获取库存中商品数量
  int getInventoryQuantity(String goodsId) {
    try {
      final item = _inventory.firstWhere((item) => item.goodsId == goodsId);
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  /// 强制通知更新
  void notifyUpdate() {
    notifyListeners();
  }

  /// 升级船只载货量
  bool upgradeCargoCapacity(int amount, int cost) {
    if (spendGold(cost)) {
      _ship.upgradeMaxCargo(amount);
      _shipUpgradeCount++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 升级船只耐久度
  bool upgradeDurability(int amount, int cost) {
    if (spendGold(cost)) {
      _ship.upgradeMaxDurability(amount);
      _shipUpgradeCount++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 获取指定港口指定商品的库存
  /// 如果不存在，返回对应商品的 S₀ 值（从港口配置获取）
  int getPortGoodsStock(String portId, String goodsId, {int defaultS0 = 0}) {
    final portIndex = _ports.indexWhere((p) => p.id == portId);
    if (portIndex == -1) {
      return defaultS0;
    }
    final port = _ports[portIndex];
    final stock = port.getGoodsStock(goodsId);
    if (stock > 0) {
      return stock;
    }
    // 如果库存为0，尝试从配置获取 s0
    final config = port.getGoodsConfig(goodsId);
    return config?.s0 ?? defaultS0;
  }

  /// 更新指定港口指定商品的库存
  void updatePortGoodsStock(String portId, String goodsId, int newStock) {
    final portIndex = _ports.indexWhere((p) => p.id == portId);
    if (portIndex == -1) {
      return;
    }
    _ports[portIndex] = _ports[portIndex].setGoodsStock(goodsId, newStock);
    notifyListeners();
  }

  /// 更新指定港口的商人资金
  void updatePortMerchantMoney(String portId, int newMoney) {
    final portIndex = _ports.indexWhere((p) => p.id == portId);
    if (portIndex == -1) {
      return;
    }
    _ports[portIndex] = _ports[portIndex].setMerchantMoney(newMoney);
    notifyListeners();
  }

  /// 初始化港口商品库存（在游戏初始化时调用）
  /// 如果库存为0，使用配置的 s0 值初始化
  /// 同时初始化价格基准库存和商人资金
  void initializePortGoodsStock() {
    for (int i = 0; i < _ports.length; i++) {
      final port = _ports[i];
      // 遍历所有已配置的商品
      for (final goodsId in port.goodsConfig.keys) {
        final config = port.getGoodsConfig(goodsId);
        if (config != null) {
          // 仅当库存映射中完全没有该商品的键时，才进行初始化（例如新解锁的物资）
          // 已经存在的物资（即使当前库存为 0）不应被重置为 s₀
          if (!port.goodsStock.containsKey(goodsId)) {
            _ports[i] = _ports[i].setGoodsStock(goodsId, config.s0);
          }
        }
      }
      
      // 初始化商人资金：如果未设置，将 merchantMoney 设置为与 initialMerchantMoney 相同的值
      if (port.merchantMoney != port.initialMerchantMoney) {
        _ports[i] = _ports[i].setMerchantMoney(port.initialMerchantMoney);
      }
    }
    notifyListeners();
  }

  /// 开始战斗
  void startCombat() {
    if (_isInCombat) return;

    // 保存当前港口（用于失败重生）
    _previousPortBeforeCombat = _currentPort;

    // 创建敌方船只
    _enemyShip = EnemyShip.createDefault();

    // 设置战斗状态
    _isInCombat = true;
    _isSinking = false;
    _isPlayerSinking = false;
    _isFadeOut = false;
    // 重置所有计时器
    _playerAttackTimer = 0.0;
    _enemyAttackTimer = 0.0;
    _playerRepairTimer = 0.0;
    _enemyRepairTimer = 0.0;

    // 重置战斗事件计数器
    _playerFireCount = 0;
    _enemyFireCount = 0;
    _playerHitCount = 0;
    _enemyHitCount = 0;

    // 暂停航行进度更新
    _progressTicker?.stop();

    // 启动玩家船只左移动画
    _animatePlayerShipToCombatPosition();

    // 启动敌方船只滑入动画
    _animateEnemyShipEnter();

    MusicSystem().playState('combat');

    // 显示战斗提示
    NotificationSystem.instance.showNotificationL10n((l) => l.notificationEncounterEnemyShip);

    notifyListeners();
  }

  /// 玩家船只移动到战斗位置（向左移动）
  Future<void> _animatePlayerShipToCombatPosition() async {
    _isEnteringCombat = true;
    _playerShipXOffset = 0.0; // 确保初始位置在中央
    notifyListeners();

    // 等待动画完成（1.5秒）
    await Future.delayed(const Duration(milliseconds: 1500));
    
    _playerShipXOffset = -150.0; // 动画结束后，设置最终偏移
    _isEnteringCombat = false;
    notifyListeners();
  }

  /// 敌方船只滑入动画
  void _animateEnemyShipEnter() {
    // 从右侧滑入（1.0表示屏幕外右侧，0.0表示正常位置）
    _enemyShipXOffset = 1.0;
    notifyListeners();

    // 使用Future.delayed模拟动画，实际应该使用AnimationController
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_isInCombat) {
        // 向右移动150像素，与玩家船只对称（玩家向左150，敌方向右150）
        _enemyShipXOffset = 0.15; // 约150像素的偏移（相对于屏幕宽度）
        notifyListeners();
      }
    });
  }

  /// 使用游戏时间增量更新战斗状态
  /// [dtGameSeconds] 游戏时间增量（秒）
  /// 由主游戏循环调用，确保使用统一的游戏时钟
  void updateCombatWithDeltaTime(double dtGameSeconds) {
    if (isMenuMode || _isQuestPaused || SeaEventSystem.instance.activeEvent != null) return;

    if (!_isInCombat || _enemyShip == null || _isSinking || _isEnteringCombat) {
      return;
    }

    // 调用内部更新方法
    _updateCombat(dtGameSeconds);
  }

  /// 更新战斗状态（内部方法）
  /// [dt] 游戏时间增量（秒）
  void _updateCombat(double dt) {
    if (!_isInCombat || _enemyShip == null || _isSinking) {
      return;
    }

    // 玩家攻击：按照真实频率触发（例如5炮/秒 = 0.2秒/炮）
    final playerFireRate = fireRatePerSecond;
    if (playerFireRate > 0) {
      _playerAttackTimer += dt;
      final attackInterval = 1.0 / playerFireRate; // 每次攻击的间隔（秒）
      
      // 当累积时间达到触发间隔时，执行攻击
      while (_playerAttackTimer >= attackInterval) {
        _enemyShip!.takeDamage(_ship.damagePerShot);
        _playerAttackTimer -= attackInterval;
        _playerFireCount++;
        _enemyHitCount++;
        notifyListeners();
      }
    }

    // 敌方攻击：按照真实频率触发
    final enemyFireRate = _enemyShip!.fireRatePerSecond;
    if (enemyFireRate > 0) {
      _enemyAttackTimer += dt;
      final attackInterval = 1.0 / enemyFireRate; // 每次攻击的间隔（秒）
      
      // 当累积时间达到触发间隔时，执行攻击
      while (_enemyAttackTimer >= attackInterval) {
        _ship.durability = (_ship.durability - _enemyShip!.damagePerShot).clamp(0, _ship.maxDurability);
        _enemyAttackTimer -= attackInterval;
        _enemyFireCount++;
        _playerHitCount++;
        notifyListeners();
      }
    }

    // 玩家修复：按照真实频率触发（例如2点/秒 = 0.5秒/点）
    final playerRepairRate = autoRepairPerSecond;
    if (playerRepairRate > 0 && _ship.durability < _ship.maxDurability) {
      _playerRepairTimer += dt;
      final repairInterval = 1.0 / playerRepairRate; // 每次修复的间隔（秒）
      
      // 当累积时间达到触发间隔时，执行修复
      while (_playerRepairTimer >= repairInterval && _ship.durability < _ship.maxDurability) {
        _ship.durability = (_ship.durability + 1).clamp(0, _ship.maxDurability);
        _playerRepairTimer -= repairInterval;
        notifyListeners();
      }
    }

    // 敌方修复：按照真实频率触发
    final enemyRepairRate = _enemyShip!.repairRatePerSecond;
    if (enemyRepairRate > 0 && _enemyShip!.durability < _enemyShip!.maxDurability) {
      _enemyRepairTimer += dt;
      final repairInterval = 1.0 / enemyRepairRate; // 每次修复的间隔（秒）
      
      // 当累积时间达到触发间隔时，执行修复
      while (_enemyRepairTimer >= repairInterval && _enemyShip!.durability < _enemyShip!.maxDurability) {
        _enemyShip!.repair(1.0);
        _enemyRepairTimer -= repairInterval;
        notifyListeners();
      }
    }

    // 检查战斗结果
    if (_enemyShip!.isSunk) {
      // 玩家获胜
      _handleCombatVictory();
    } else if (_ship.durability <= 0) {
      // 玩家失败
      _handleCombatDefeat();
    }
  }

  /// 处理战斗胜利
  Future<void> _handleCombatVictory() async {
    if (!_isInCombat) return;

    _isSinking = true;
    _isPlayerSinking = false;
    notifyListeners();

    MusicSystem().playState('victory');

    // 敌方船只沉船动画
    await _animateEnemyShipSinking();

    // 开始归位动画（设置状态，让 ShipLayer 处理动画）
    _isReturningFromCombat = true;
    notifyListeners();

    // 等待归位动画完成（1.5秒）
    await Future.delayed(const Duration(milliseconds: 1500));

    // 清理战斗状态
    _endCombat();

    // 恢复正常场景（玩家船只回到中央）
    _playerShipXOffset = 0.0;
    _enemyShipXOffset = 1.0;
    _enemyShip = null;
    _isReturningFromCombat = false;

    // 恢复航行进度更新（如果还在航行中）
    if (_isAtSea) {
      // 恢复航行进度更新
      if (_totalTravelDistance > 0 && _travelProgress < 1.0) {
        _resumeTravelProgress();
      }
    }

    notifyListeners();
  }

  /// 处理战斗失败
  Future<void> _handleCombatDefeat() async {
    if (!_isInCombat) return;

    _isSinking = true;
    _isPlayerSinking = true;
    notifyListeners();

    MusicSystem().playState('defeat');

    // 启动沉船动画等待（但不阻塞黑屏启动）
    final sinkingFuture = _animatePlayerShipSinking();

    // 延迟500ms后启动渐变黑屏（总时长2.5s，与沉船过程重叠）
    await Future.delayed(const Duration(milliseconds: 500));
    
    _isFadeOut = true;
    notifyListeners();

    // 等待黑屏动画完成（2s）
    await Future.delayed(const Duration(seconds: 2));

    // 确保沉船动画也已完成
    await sinkingFuture;

    // 重生在出发前的港口（此时屏幕全黑）
    await _respawnAtPreviousPort();
    
    // 渐变恢复屏幕
    _isFadeOut = false;
    notifyListeners();
  }

  /// 敌方船只沉船动画
  Future<void> _animateEnemyShipSinking() async {
    // 沉船动画在ShipLayer中实现，这里只等待动画完成
    await Future.delayed(const Duration(seconds: 2));
  }

  /// 玩家船只沉船动画
  Future<void> _animatePlayerShipSinking() async {
    // 沉船动画在ShipLayer中实现，这里只等待动画完成
    await Future.delayed(const Duration(seconds: 2));
  }

  /// 重生在出发前的港口
  Future<void> _respawnAtPreviousPort() async {
    // 恢复船只耐久度到最大值
    _ship.durability = _ship.maxDurability;

    // 清理战斗状态
    _endCombat();

    // 停止航行
    _progressTicker?.stop();
    _progressTicker = null;
    _isAtSea = false;
    _isTransitioning = false;
    _travelProgress = 0.0;
    _totalTravelDistance = 0;
    _accumulatedDistance = 0.0;
    _lastProgressUpdateTime = null;
    _accumulatedGameHours = 0.0;
    _destinationPort = null;

    // 重置到出发前的港口
    if (_previousPortBeforeCombat != null) {
      _currentPort = _previousPortBeforeCombat;
      _previousPortBeforeCombat = null;
    } else if (_ports.isNotEmpty) {
      // 如果没有之前的港口，回到第一个港口
      _currentPort = _ports.first;
    }

    // 恢复船只位置
    _playerShipXOffset = 0.0;
    _enemyShipXOffset = 1.0;
    _enemyShip = null;
    _isSinking = false;
    _isPlayerSinking = false;
    _isReturningFromCombat = false;
    // _isFadeOut 由调用者控制

    notifyListeners();
  }

  /// 恢复航行进度更新
  void _resumeTravelProgress() {
    if (_progressTicker != null && _progressTicker!.isActive) {
      return; // 已经在运行
    }

    if (_totalTravelDistance == 0 || _travelProgress >= 1.0) {
      // 如果已经完成，完成 completer（如果存在）
      if (_travelCompleter != null && !_travelCompleter!.isCompleted) {
        _travelCompleter!.complete();
      }
      return; // 没有航行或已经完成
    }

    if (_isInCombat) {
      return; // 如果还在战斗中，不恢复
    }

    // 重新记录时间，避免战斗期间的时间被计入
    _lastProgressUpdateTime = DateTime.now();

    // 创建 Ticker 每帧更新进度
    _progressTicker = Ticker((elapsed) {
      if (_lastProgressUpdateTime == null) {
        _lastProgressUpdateTime = DateTime.now();
        return;
      }

      // 如果进入战斗或海上事件激活，暂停更新（不更新时间，直接返回）
      if (_isInCombat || SeaEventSystem.instance.activeEvent != null) {
        // 重新记录时间，避免暂停期间的时间被计入
        _lastProgressUpdateTime = DateTime.now();
        return;
      }

      // 计算实际时间增量 dt（秒）
      final now = DateTime.now();
      final dtRealSeconds = now.difference(_lastProgressUpdateTime!).inMilliseconds / 1000.0;
      _lastProgressUpdateTime = now;

      // 将实际时间增量转换为游戏内时间增量
      final dtGameHours = dtRealSeconds;

      // 累积游戏内时间
      _accumulatedGameHours += dtGameHours;

      // 计算已航行距离：当前航速（节） × 这一帧的游戏小时数
      final currentSpeed = this.currentSpeed;
      final dtDistance = currentSpeed * dtGameHours;
      _accumulatedDistance += dtDistance;

      // 根据已航行距离计算进度
      final legTotal = _totalTravelDistance - _legStartDistance;
      if (_accumulatedDistance >= _totalTravelDistance) {
        _travelProgress = 1.0;
        _accumulatedDistance = _totalTravelDistance.toDouble();
        notifyListeners();
        // 停止 Ticker
        _progressTicker?.stop();
        _progressTicker = null;
        // 完成 completer（如果存在）
        if (_travelCompleter != null && !_travelCompleter!.isCompleted) {
          _travelCompleter!.complete();
        }
      } else {
        if (legTotal > 0) {
          _travelProgress = ((_accumulatedDistance - _legStartDistance) / legTotal).clamp(0.0, 1.0);
        } else {
          _travelProgress = 1.0;
        }

        // 检查是否触发随机事件（每 1 游戏小时检查一次）
        final currentTotalHours = _accumulatedGameHours;
        final previousTotalHours = _accumulatedGameHours - dtGameHours;
        if (currentTotalHours.floor() > previousTotalHours.floor()) {
          _checkRandomEvents();
        }

        notifyListeners();
      }
    });

    // 启动 Ticker
    _progressTicker!.start();
  }

  /// 结束战斗
  void _endCombat() {
    _isInCombat = false;
    // 重置所有计时器
    _playerAttackTimer = 0.0;
    _enemyAttackTimer = 0.0;
    _playerRepairTimer = 0.0;
    _enemyRepairTimer = 0.0;
    
    // 战斗结束后重置航行事件计数，或者根据需求保留
    // SeaEventSystem.instance.resetVoyageStats(); 
  }

  /// 检查随机事件（包括战斗和海上随机事件）
  void _checkRandomEvents() {
    if (_isInCombat || !_isAtSea || SeaEventSystem.instance.activeEvent != null) return;

    // 1. 优先尝试触发海上随机事件
    final gameHours = _dayNightSystem.accumulatedTotalMinutes / 60.0;
    final seaEvent = SeaEventSystem.instance.checkAndTriggerEvent(_travelProgress, gameHours);
    
    if (seaEvent != null) {
      // 触发了海上事件，不再检查战斗
      notifyListeners();
      return;
    }

    // 2. 如果没触发海上事件，且战斗已解锁，检查战斗触发
    if (!_isCombatUnlocked) return;

    // 随机触发战斗（每 1 游戏小时约 5% 概率，保持原有逻辑密度）
    final random = Random();
    if (random.nextDouble() < 0.05) {
      startCombat();
    }
  }

  /// 立即触发战斗（调试用）
  /// 如果不在战斗中且在海上，立即开始战斗
  void triggerCombatImmediately() {
    if (_isInCombat || !_isAtSea) return;
    startCombat();
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPortId': _currentPort?.id,
      'ship': _ship.toJson(),
      'gold': _gold,
      'inventory': _inventory.map((item) => item.toJson()).toList(),
      'isTransitioning': _isTransitioning,
      'isAtSea': _isAtSea,
      'destinationPortId': _destinationPort?.id,
      'travelProgress': _travelProgress,
      'totalTravelDistance': _totalTravelDistance,
      'accumulatedDistance': _accumulatedDistance,
      'accumulatedGameHours': _accumulatedGameHours,
      'ports': _ports.map((port) => port.toJson()).toList(),
      'crewMembers': _crewManager.crewMembers.map((m) => m.toJson()).toList(),
      'weather': _weather.name,
      'dayNightSystem': _dayNightSystem.toJson(),
      'lastPriceUpdateDay': _lastPriceUpdateDay,
      'availableTavernCrew': _availableTavernCrew.map((m) => m.toJson()).toList(),
      'lastTavernRefreshDay': _lastTavernRefreshDay,
      'homeIsland': _homeIsland.toJson(),
      'lastTaxHour': _lastTaxHour,
      'visitedPortIds': _visitedPortIds.toList(),
      'completedQuestIds': QuestSystem.instance.completedQuestIds,
      'activeQuestId': QuestSystem.instance.activeQuest?.id,
      'isCombatUnlocked': _isCombatUnlocked,
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    // 1. 恢复基础状态
    _gold = json['gold'] as int;
    _isTransitioning = json['isTransitioning'] as bool;
    _isAtSea = json['isAtSea'] as bool;
    _travelProgress = (json['travelProgress'] as num).toDouble();
    _totalTravelDistance = json['totalTravelDistance'] as int;
    _accumulatedDistance = (json['accumulatedDistance'] as num).toDouble();
    _accumulatedGameHours = (json['accumulatedGameHours'] as num).toDouble();
    _lastPriceUpdateDay = json['lastPriceUpdateDay'] as int;

    // 如果加载后是在海上航行状态，且航行未完成，则恢复进度更新
    if (_isAtSea && _totalTravelDistance > 0 && _travelProgress < 1.0) {
      // 延迟一帧调用，确保环境已初始化
      Future.microtask(() => _resumeTravelProgress());
    }
    _lastTavernRefreshDay = (json['lastTavernRefreshDay'] as int?) ?? -1;
    _lastTaxHour = (json['lastTaxHour'] as int?) ?? -1;
    
    // 恢复访问过的港口
    _visitedPortIds.clear();
    final visitedPorts = json['visitedPortIds'] as List?;
    if (visitedPorts != null) {
      _visitedPortIds.addAll(visitedPorts.cast<String>());
    }
    
    // 恢复任务系统进度
    final completedQuestIds = (json['completedQuestIds'] as List?)?.cast<String>() ?? [];
    final activeQuestId = json['activeQuestId'] as String?;
    QuestSystem.instance.loadProgress(completedQuestIds, activeQuestId);

    // 2. 恢复酒馆船员
    _availableTavernCrew.clear();
    final tavernCrewList = json['availableTavernCrew'] as List?;
    if (tavernCrewList != null) {
      for (final crewJson in tavernCrewList) {
        _availableTavernCrew.add(CrewMember.fromJson(crewJson as Map<String, dynamic>));
      }
    }

    // 3. 恢复船员系统
    _crewManager.clear();
    final crewList = json['crewMembers'] as List;
    for (final crewJson in crewList) {
      _crewManager.addCrewMember(CrewMember.fromJson(crewJson as Map<String, dynamic>));
    }

    // 4. 恢复船只状态
    final shipJson = json['ship'] as Map<String, dynamic>;
    // 由于 _ship 是 final，我们需要手动更新它的属性
    _ship.cargoCapacity = shipJson['cargoCapacity'] as int;
    _ship.durability = shipJson['durability'] as int;
    _ship.maxDurability = shipJson['maxDurability'] as int;
    _ship.maxCrewMemberCount = shipJson['maxCrewMemberCount'] as int;
    _ship.damagePerShot = (shipJson['damagePerShot'] as int?) ?? 10;

    // 5. 恢复库存
    _inventory.clear();
    final inventoryList = json['inventory'] as List;
    for (final itemJson in inventoryList) {
      _inventory.add(ShipInventoryItem.fromJson(itemJson as Map<String, dynamic>));
    }

    // 6. 恢复港口列表
    _ports.clear();
    final portsList = json['ports'] as List;
    for (final portJson in portsList) {
      _ports.add(Port.fromJson(portJson as Map<String, dynamic>));
    }

    // 恢复主岛养成数据
    if (json.containsKey('homeIsland')) {
      _homeIsland = HomeIsland.fromJson(json['homeIsland'] as Map<String, dynamic>);
    }
    // 确保加载后港口列表包含正确的主岛配置
    _ensureHomeIslandInPorts();

    // 恢复当前港口和目标港口引用
    final currentPortId = json['currentPortId'] as String?;
    if (currentPortId != null) {
      try {
        _currentPort = _ports.firstWhere((p) => p.id == currentPortId);
      } catch (e) {
        print('Warning: Current port $currentPortId not found in ports list');
        _currentPort = null;
      }
    } else {
      _currentPort = null;
    }

    final destinationPortId = json['destinationPortId'] as String?;
    if (destinationPortId != null) {
      try {
        _destinationPort = _ports.firstWhere((p) => p.id == destinationPortId);
      } catch (e) {
         print('Warning: Destination port $destinationPortId not found in ports list');
        _destinationPort = null;
      }
    } else {
      _destinationPort = null;
    }

    // 7. 恢复天气
    final weatherName = json['weather'] as String;
    try {
      _weather = WeatherCondition.values.firstWhere((e) => e.name == weatherName);
    } catch (_) {
      _weather = WeatherCondition.calm;
    }

    // 8. 恢复昼夜系统
    _dayNightSystem.loadFromJson(json['dayNightSystem'] as Map<String, dynamic>);
    
    // 恢复战斗系统解锁状态
    _isCombatUnlocked = json['isCombatUnlocked'] as bool? ?? false;
    
    // 重置 UI 判定标志
    _isTradeConfirmed = false;
    
    // 清除缓存
    _cachedCurrentSpeed = null;
    _cachedSpeedWeather = null;

    notifyListeners();
  }

  @override
  void dispose() {
    // 停止并清理 Ticker
    _progressTicker?.stop();
    _progressTicker = null;
    super.dispose();
  }
}
