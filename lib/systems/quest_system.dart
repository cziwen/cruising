import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/quest.dart';
import '../game/game_state.dart';
import '../utils/game_config_loader.dart';

/// 任务系统逻辑管理
class QuestSystem extends ChangeNotifier {
  // 单例模式
  static final QuestSystem instance = QuestSystem._internal();
  QuestSystem._internal();

  GameState? _gameState;
  final List<Quest> _allQuests = [];
  final List<String> _completedQuestIds = [];
  Quest? _activeQuest;
  String? _pendingAction;

  // UI 高亮注册
  final Map<String, GlobalKey> _registeredKeys = {};

  Quest? get activeQuest => _activeQuest;
  List<String> get completedQuestIds => List.unmodifiable(_completedQuestIds);
  String? get pendingAction => _pendingAction;

  /// 清除待执行动作
  void clearPendingAction() {
    _pendingAction = null;
    notifyListeners();
  }

  /// 注册 UI 组件的 GlobalKey
  void registerKey(String id, GlobalKey key) {
    if (_registeredKeys[id] == key) return;
    _registeredKeys[id] = key;
    
    // 确保不在 build 阶段直接调用 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// 获取已注册的 Key
  GlobalKey? getKey(String id) => _registeredKeys[id];

  /// 初始化系统
  void initialize(GameState gameState) {
    _gameState = gameState;
    _allQuests.clear();
    _allQuests.addAll(GameConfigLoader().questsList);
    _completedQuestIds.clear();
    _activeQuest = null;
    
    // 监听游戏状态变化
    _gameState?.addListener(_onGameStateChanged);
    
    // 检查初始触发
    _checkTriggers();
    
    // 确保不在 build 阶段直接调用 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _onGameStateChanged() {
    if (_activeQuest != null) {
      if (_evaluateCondition(_activeQuest!.completeWhen)) {
        completeQuest(_activeQuest!.id);
      }
    } else {
      _checkTriggers();
    }
  }

  /// 检查任务触发
  void _checkTriggers() {
    bool hasChanged = false;
    for (final quest in _allQuests) {
      if (_completedQuestIds.contains(quest.id)) continue;
      if (_activeQuest?.id == quest.id) continue;

      if (_shouldTrigger(quest)) {
        _activeQuest = quest;
        hasChanged = true;
        break; // 同时只激活一个任务（简化逻辑）
      }
    }
    
    if (hasChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  bool _shouldTrigger(Quest quest) {
    final trigger = quest.trigger;
    
    // 支持多重条件判定，用 && 分割
    final parts = trigger.split('&&').map((e) => e.trim()).where((e) => e.isNotEmpty);
    
    for (final part in parts) {
      if (!_evaluateTriggerPart(part)) {
        return false;
      }
    }
    
    return true;
  }

  bool _evaluateTriggerPart(String part) {
    if (part == 'on_new_game_start') {
      return _completedQuestIds.isEmpty && _activeQuest == null;
    }
    
    if (part.startsWith('after(')) {
      final prevId = part.substring(6, part.length - 1);
      return _completedQuestIds.contains(prevId);
    }

    // 复用条件评估逻辑检查游戏状态
    return _evaluateCondition(part);
  }

  /// 处理点击任意处（用于 complete_when: "tap_anywhere"）
  void handleTapAnywhere() {
    if (_activeQuest?.completeWhen == "tap_anywhere") {
      completeQuest(_activeQuest!.id);
    }
  }

  /// 完成任务
  void completeQuest(String id) {
    if (_activeQuest?.id == id) {
      _pendingAction = _activeQuest!.action;
      _completedQuestIds.add(id);
      _activeQuest = null;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
        // 任务完成后立即检查下一个触发
        _checkTriggers();
      });
    }
  }

  /// 条件评估逻辑
  bool _evaluateCondition(String condition) {
    if (_gameState == null) return false;
    final gs = _gameState!;

    // 1. 特殊条件
    if (condition == "tap_anywhere") {
      // 由 UI 层通过外部调用标记完成，或者此处保持 false 等待手动触发
      return false; 
    }

    // 2. UI 面板状态 (简化处理，实际可能需要 GameState 暴露这些状态)
    if (condition == "ui.marketPanel.opened") {
      return gs.isMarketOpened;
    }
    if (condition == "ui.quantitySlider.opened") {
      return gs.isQuantitySliderOpened;
    }
    if (condition == "!ui.quantitySlider.opened") {
      return !gs.isQuantitySliderOpened;
    }
    if (condition == "ui.tradeBalanced") {
      return gs.isTradeBalanced;
    }
    if (condition == "ui.portList.opened") {
      return gs.isPortListOpened;
    }

    // 3. 货物数量 cargo.count('Fish') >= 10
    if (condition.startsWith("cargo.count(")) {
      final goodsId = condition.substring(13, condition.indexOf("')"));
      final count = gs.getInventoryQuantity(goodsId);
      final operator = _extractOperator(condition);
      final target = _extractTargetValue(condition);
      return _compare(count, operator, target);
    }

    // 4. 目的地 navigation.destination == 'SeaBreezePort'
    if (condition.startsWith("navigation.destination == ")) {
      final targetPortId = condition.substring(26, condition.length - 1);
      return gs.destinationPort?.id == targetPortId;
    }

    // 5. 航行到达 navigation.arrived
    if (condition == "navigation.arrived") {
      return !gs.isAtSea && gs.currentPort != null && !gs.isTransitioning;
    }
    if (condition == "navigation.isAtSea") {
      return gs.isAtSea;
    }

    // 6. 船只升级 ship.upgrade_count >= 1
    if (condition == "ship.upgrade_count >= 1") {
      return gs.shipUpgradeCount >= 1;
    }

    // 7. 主岛打开 homeIsland.opened
    if (condition == "homeIsland.opened") {
      return gs.currentPort?.id == 'home_island' && !gs.isTransitioning;
    }

    // 8. 税收领取 homeIsland.tax_collected_today == true
    if (condition == "homeIsland.tax_collected_today == true") {
      return gs.taxCollectedToday;
    }

    return false;
  }

  String _extractOperator(String condition) {
    if (condition.contains(">=")) return ">=";
    if (condition.contains("<=")) return "<=";
    if (condition.contains("==")) return "==";
    if (condition.contains(">")) return ">";
    if (condition.contains("<")) return "<";
    return "==";
  }

  int _extractTargetValue(String condition) {
    final parts = condition.split(RegExp(r'[>=<!]+'));
    if (parts.length > 1) {
      return int.tryParse(parts.last.trim()) ?? 0;
    }
    return 0;
  }

  bool _compare(int actual, String operator, int target) {
    switch (operator) {
      case ">=": return actual >= target;
      case "<=": return actual <= target;
      case "==": return actual == target;
      case ">": return actual > target;
      case "<": return actual < target;
      default: return false;
    }
  }

  @override
  void dispose() {
    _gameState?.removeListener(_onGameStateChanged);
    super.dispose();
  }
}
