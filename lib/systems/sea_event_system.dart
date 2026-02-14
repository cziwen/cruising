import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sea_event.dart';
import '../game/game_state.dart';
import '../utils/game_config_loader.dart';
import 'notification_system.dart';

/// 海上事件系统逻辑管理
class SeaEventSystem extends ChangeNotifier {
  // 单例模式
  static final SeaEventSystem instance = SeaEventSystem._internal();
  SeaEventSystem._internal();

  GameState? _gameState;
  GameState? get gameState => _gameState;
  final List<SeaEvent> _allEvents = [];
  
  // 正在进行的事件
  SeaEvent? _activeEvent;
  SeaEvent? get activeEvent => _activeEvent;

  // 冷却中的事件：ID -> 解锁时间（游戏小时）
  final Map<String, double> _cooldowns = {};
  
  // 单次航行事件计数
  int _eventsThisVoyage = 0;
  static const int maxEventsPerVoyage = 3;

  /// 初始化系统
  void initialize(GameState gameState) {
    _gameState = gameState;
    _allEvents.clear();
    _allEvents.addAll(GameConfigLoader().seaEventsList);
    _cooldowns.clear();
    _eventsThisVoyage = 0;
  }

  /// 检查并尝试触发海上事件
  /// [currentProgress] 航行进度 (0.0 - 1.0)
  /// [gameHours] 当前游戏内累计小时数
  SeaEvent? checkAndTriggerEvent(double currentProgress, double gameHours) {
    if (_gameState == null || _activeEvent != null) return null;
    if (_eventsThisVoyage >= maxEventsPerVoyage) return null;

    final random = Random();
    
    // 过滤出符合进度要求且不在冷却中的事件
    final availableEvents = _allEvents.where((event) {
      if (currentProgress < event.minProgress || currentProgress > event.maxProgress) {
        return false;
      }
      
      final unlockTime = _cooldowns[event.id] ?? 0.0;
      if (gameHours < unlockTime) {
        return false;
      }
      
      return true;
    }).toList();

    if (availableEvents.isEmpty) return null;

    // 随机选择一个事件进行概率判定
    final event = availableEvents[random.nextInt(availableEvents.length)];
    if (random.nextDouble() < event.probability) {
      _triggerEvent(event, gameHours);
      return event;
    }

    return null;
  }

  /// 强制触发指定 ID 的海上事件（主要用于调试）
  void triggerEventById(String eventId, {bool bypassLimits = true}) {
    if (_gameState == null) return;
    
    final event = _allEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Sea event not found: $eventId'),
    );

    if (bypassLimits) {
      // 绕过限制：手动调用 _triggerEvent，但使用当前游戏时间
      final gameHours = _gameState!.dayNightSystem.accumulatedTotalMinutes / 60.0;
      _triggerEvent(event, gameHours);
    } else {
      // 如果不绕过限制，则正常逻辑判定（此处暂不实现，调试通常需要绕过）
    }
  }

  /// 触发事件
  void _triggerEvent(SeaEvent event, double gameHours) {
    _activeEvent = event;
    _eventsThisVoyage++;
    
    // 设置冷却时间
    _cooldowns[event.id] = gameHours + event.cooldownHours;
    
    // 设置视觉效果
    if (event.assetPath != null) {
      _gameState?.setVisualEffect(event.id); // 使用事件ID作为效果标识
    }
    
    // 如果是即时通知类且只有一个选项，可以直接执行（由UI处理显示，此处仅标记状态）
    notifyListeners();
  }

  /// 执行选项效果
  void executeChoice(SeaEventChoice choice) {
    if (_gameState == null || _activeEvent == null) return;

    final random = Random();
    // 清除视觉效果
    _gameState?.setVisualEffect(null);
    
    // 如果是商船交易，触发特殊逻辑
    if (choice.id == 'merchant_trade') {
      _handleMerchantTrade();
    }

    for (final effect in choice.effects) {
      switch (effect.type) {
        case SeaEventEffectType.durabilityChange:
          int delta = 0;
          if (effect.value is List) {
            final v0 = effect.value[0] as int;
            final v1 = effect.value[1] as int;
            delta = min(v0, v1) + random.nextInt((v1 - v0).abs() + 1);
          } else {
            delta = effect.value as int;
          }
          _gameState!.ship.durability = (_gameState!.ship.durability + delta).clamp(0, _gameState!.ship.maxDurability);
          if (delta < 0) {
            NotificationSystem.instance.showNotification('船只受损：耐久度下降了 ${delta.abs()}');
          } else if (delta > 0) {
            NotificationSystem.instance.showNotification('船只修复：耐久度恢复了 $delta');
          }
          break;
          
        case SeaEventEffectType.goldChange:
          int delta = 0;
          if (effect.value is List) {
            final v0 = effect.value[0] as int;
            final v1 = effect.value[1] as int;
            delta = min(v0, v1) + random.nextInt((v1 - v0).abs() + 1);
          } else {
            delta = effect.value as int;
          }
          if (delta > 0) {
            _gameState!.addGold(delta);
            NotificationSystem.instance.showNotification('获得金币：$delta 💰');
          } else if (delta < 0) {
            _gameState!.spendGold(delta.abs());
            NotificationSystem.instance.showNotification('损失金币：${delta.abs()} 💰');
          }
          break;
          
        case SeaEventEffectType.progressChange:
          double delta = (effect.value as num).toDouble();
          _gameState!.applyEventProgressDelta(delta);
          break;
          
        case SeaEventEffectType.speedMultiplier:
          double multiplier = (effect.value as num).toDouble();
          int duration = effect.durationHours ?? 1;
          _gameState!.applyEventSpeedMultiplier(multiplier, duration);
          break;
          
        case SeaEventEffectType.triggerCombat:
          _gameState!.triggerCombatImmediately();
          break;
          
        case SeaEventEffectType.timeSkip:
          int hours = effect.value as int;
          _gameState!.applyEventTimeSkip(hours);
          break;

        case SeaEventEffectType.addRandomGoods:
          _handleAddRandomGoods(effect.value);
          break;

        case SeaEventEffectType.changeDestination:
          _handleChangeDestination();
          break;
      }
    }

    _activeEvent = null;
    notifyListeners();
  }

  void _handleMerchantTrade() {
    // 触发海上商船交易界面
    // 我们可以通过 GameState 弹出一个受限的交易对话框
    // 这里暂时简单处理为提示，后续可以扩展
    NotificationSystem.instance.showNotification('正在与商船进行秘密交易...');
    // TODO: 实现专门的海上交易对话框
  }

  void _handleAddRandomGoods(dynamic value) {
    if (_gameState == null) return;
    final random = Random();
    final allGoods = GameConfigLoader().goodsList;
    if (allGoods.isEmpty) return;

    final goods = allGoods[random.nextInt(allGoods.length)];
    int count = 1;
    if (value is List) {
      final v0 = value[0] as int;
      final v1 = value[1] as int;
      count = min(v0, v1) + random.nextInt((v1 - v0).abs() + 1);
    } else if (value is int) {
      count = value;
    }

    bool success = _gameState!.addToInventory(goods.id, count);
    if (success) {
      NotificationSystem.instance.showNotification('获得物资：${goods.name} x$count');
    } else {
      NotificationSystem.instance.showNotification('货舱已满，无法获取物资');
    }
  }

  void _handleChangeDestination() {
    if (_gameState == null) return;
    // 寻找最近的港口
    final ports = _gameState!.ports.where((p) => p.unlocked && !p.isSeaLocation).toList();
    if (ports.isEmpty) return;

    // 简单起见，随机选一个已解锁港口（或者最近的）
    final random = Random();
    final targetPort = ports[random.nextInt(ports.length)];
    
    NotificationSystem.instance.showNotification('航道改变，正转向 ${targetPort.name}');
    _gameState!.startTravelToPort(targetPort.id);
  }

  /// 重置单次航行计数
  void resetVoyageStats() {
    _eventsThisVoyage = 0;
  }
  
  /// 清除正在进行的事件
  void clearActiveEvent() {
    _activeEvent = null;
    notifyListeners();
  }
}
