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
  bool _isNewGame = false;

  /// 是否跳过新手教程（调试选项，由主菜单控制）
  static bool shouldSkipTutorial = false;

  // UI 高亮注册表：存储 ID 到 GlobalKey 的映射
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
    
    // 任务系统不主动触发通知，由 QuestOverlay 在需要时获取
    // 这样可以避免由于频繁注册导致的 build 冲突
  }

  /// 获取指定 ID 关联的 Key
  GlobalKey? getKey(String? id) {
    if (id == null) return null;
    return _registeredKeys[id];
  }

  /// 注销指定 ID 的 Key，必须是同一个 key 实例才执行注销
  void unregisterKey(String id, GlobalKey key) {
    if (_registeredKeys[id] == key) {
      _registeredKeys.remove(id);
    }
  }

  /// 清除所有注册的 Key
  void clearRegisteredKeys() {
    _registeredKeys.clear();
  }

  /// 初始化系统
  void initialize(GameState gameState, {bool isNewGame = false, bool skipTutorial = false}) {
    _gameState = gameState;
    _isNewGame = isNewGame;
    _allQuests.clear();
    _allQuests.addAll(GameConfigLoader().questsList);
    _completedQuestIds.clear();
    _activeQuest = null;

    if (_isNewGame && skipTutorial) {
      // 跳过教程：将所有以 'T' 开头的任务标记为已完成
      for (final quest in _allQuests) {
        if (quest.id.startsWith('T')) {
          _completedQuestIds.add(quest.id);
        }
      }
    }
    
    // 监听游戏状态变化
    _gameState?.addListener(_onGameStateChanged);
    
    // 检查初始触发
    _checkTriggers();
    
    // 确保不在 build 阶段直接调用 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateGamePauseState();
      notifyListeners();
    });
  }

  /// 更新游戏暂停状态：当有活跃任务且包含文本时，暂停游戏时间
  void _updateGamePauseState() {
    if (_gameState == null) return;
    
    // 如果有活跃任务且任务有文本，则暂停游戏
    final shouldPause = _activeQuest != null && _activeQuest!.text != null;
    _gameState!.setQuestPaused(shouldPause);
  }

  /// 重置系统状态（用于返回主菜单）
  void reset() {
    _gameState?.removeListener(_onGameStateChanged);
    _updateGamePauseState(); // 恢复非暂停状态
    _gameState = null;
    _allQuests.clear();
    _completedQuestIds.clear();
    _activeQuest = null;
    _pendingAction = null;
    _isNewGame = false;
    _registeredKeys.clear();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// 加载任务进度
  void loadProgress(List<String> completedIds, String? activeId) {
    _isNewGame = false;
    _completedQuestIds.clear();
    _completedQuestIds.addAll(completedIds);
    _activeQuest = null;
    if (activeId != null) {
      try {
        _activeQuest = _allQuests.firstWhere((q) => q.id == activeId);
      } catch (_) {
        _activeQuest = null;
      }
    }
    
    // 加载进度后重新检查触发器（以防 activeQuest 为空时需要触发新任务）
    _checkTriggers();
    
    _updateGamePauseState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _onGameStateChanged() {
    if (_activeQuest != null) {
      if (_evaluateFullCondition(_activeQuest!.completeWhen)) {
        completeQuest(_activeQuest!.id);
      }
    } else {
      // 如果没有活跃任务，尝试触发新的
      _checkTriggers();
    }
    _updateGamePauseState();
  }

  /// 评估完整条件（支持 &&、|| 和括号）
  bool _evaluateFullCondition(String fullCondition) {
    String condition = fullCondition.trim();
    if (condition.isEmpty) return true;

    // 1. 处理最外层括号
    // 注意：这里需要匹配配对的括号，而不是简单的 findFirst/findLast
    if (condition.startsWith('(') && condition.endsWith(')')) {
      // 检查这对括号是否覆盖了整个表达式
      int balance = 0;
      bool fullyEnclosed = true;
      for (int i = 0; i < condition.length - 1; i++) {
        if (condition[i] == '(') balance++;
        else if (condition[i] == ')') balance--;
        if (balance == 0 && i < condition.length - 1) {
          fullyEnclosed = false;
          break;
        }
      }
      if (fullyEnclosed) {
        return _evaluateFullCondition(condition.substring(1, condition.length - 1));
      }
    }

    // 2. 处理 || (最低优先级)
    // 同样需要跳过括号内的内容
    int balance = 0;
    for (int i = condition.length - 1; i >= 0; i--) {
      if (condition[i] == ')') balance++;
      else if (condition[i] == '(') balance--;
      else if (balance == 0 && i > 0 && condition.substring(i - 1, i + 1) == '||') {
        return _evaluateFullCondition(condition.substring(0, i - 1)) ||
               _evaluateFullCondition(condition.substring(i + 1));
      }
    }

    // 3. 处理 &&
    balance = 0;
    for (int i = condition.length - 1; i >= 0; i--) {
      if (condition[i] == ')') balance++;
      else if (condition[i] == '(') balance--;
      else if (balance == 0 && i > 0 && condition.substring(i - 1, i + 1) == '&&') {
        return _evaluateFullCondition(condition.substring(0, i - 1)) &&
               _evaluateFullCondition(condition.substring(i + 1));
      }
    }

    // 4. 原子条件
    return _evaluateCondition(condition);
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
      _updateGamePauseState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  bool _shouldTrigger(Quest quest) {
    return _evaluateFullCondition(quest.trigger.replaceAll('after(', 'trigger.after('));
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
      
      // 立即寻找下一个满足触发条件的任务，合并通知以减少延迟和 flickering
      for (final quest in _allQuests) {
        if (_completedQuestIds.contains(quest.id)) continue;
        if (_shouldTrigger(quest)) {
          _activeQuest = quest;
          break;
        }
      }
      
      _updateGamePauseState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// 条件评估逻辑
  bool _evaluateCondition(String condition) {
    if (_gameState == null) return false;
    final gs = _gameState!;

    // 0. 触发器专用逻辑 (重定向)
    if (condition.startsWith('on_new_game_start')) {
      return _isNewGame && _completedQuestIds.isEmpty && _activeQuest == null;
    }
    if (condition.startsWith('trigger.after(')) {
      final prevId = condition.substring(14, condition.length - 1);
      return _completedQuestIds.contains(prevId);
    }
    if (condition.startsWith('after(')) {
      // 兼容旧格式，虽然现在统一走 trigger.after
      final prevId = condition.substring(6, condition.length - 1);
      return _completedQuestIds.contains(prevId);
    }

    // 1. 特殊条件
    if (condition == "tap_anywhere") {
      // 由 UI 层通过外部调用标记完成，或者此处保持 false 等待手动触发
      return false; 
    }

    // 2. UI 面板状态 (简化处理，实际可能需要 GameState 暴露这些状态)
    if (condition.startsWith("player.gold")) {
      final val = gs.gold;
      final operator = _extractOperator(condition);
      final target = _extractTargetValue(condition);
      return _compare(val, operator, target);
    }
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
    if (condition == "ui.tradeConfirmed") {
      return gs.isTradeConfirmed;
    }
    if (condition == "ui.portList.opened") {
      return gs.isPortListOpened;
    }
    if (condition == "ui.shipyard.opened") {
      return gs.isShipyardOpened;
    }
    if (condition == "ui.hallPanel.opened") {
      return gs.isHallPanelOpened;
    }
    if (condition == "ui.homeIslandUpgraded") {
      return gs.isHomeIslandUpgraded;
    }
    if (condition == "ui.sliderInteracted") {
      return gs.isSliderInteracted;
    }
    if (condition.startsWith("ui.sliderValue")) {
      final val = gs.sliderValue;
      final operator = _extractOperator(condition);
      final target = _extractTargetValue(condition);
      return _compare(val, operator, target);
    }

    // 2.1 待交易物品 trade.pending('wood') > 0
    if (condition.startsWith("trade.pending(")) {
      final startQuote = condition.indexOf("'") + 1;
      final endQuote = condition.indexOf("'", startQuote);
      final goodsId = condition.substring(startQuote, endQuote);
      
      final count = gs.getPendingTradeQuantity(goodsId);
      final operator = _extractOperator(condition);
      final target = _extractTargetValue(condition);
      return _compare(count, operator, target);
    }

    // 3. 货物数量 cargo.count('wood') >= 10
    if (condition.startsWith("cargo.count(")) {
      // 提取单引号内部的 goodsId
      final startQuote = condition.indexOf("'") + 1;
      final endQuote = condition.indexOf("'", startQuote);
      final goodsId = condition.substring(startQuote, endQuote);
      
      final count = gs.getInventoryQuantity(goodsId);
      final operator = _extractOperator(condition);
      final target = _extractTargetValue(condition);
      return _compare(count, operator, target);
    }

    // 4. 目的地 navigation.destination == 'port_1'
    if (condition.startsWith("navigation.destination == ")) {
      // 提取单引号内部的 portId
      final startQuote = condition.indexOf("'") + 1;
      final endQuote = condition.indexOf("'", startQuote);
      if (startQuote > 0 && endQuote > startQuote) {
        final targetPortId = condition.substring(startQuote, endQuote);
        return gs.destinationPort?.id == targetPortId;
      }
      return false;
    }

    // 4.1 地图选中港口 navigation.map_selected == 'port_1'
    if (condition.startsWith("navigation.map_selected == ")) {
      final startQuote = condition.indexOf("'") + 1;
      final endQuote = condition.indexOf("'", startQuote);
      if (startQuote > 0 && endQuote > startQuote) {
        final targetPortId = condition.substring(startQuote, endQuote);
        return gs.selectedMapPortId == targetPortId;
      }
      return false;
    }

    // 5. 航行到达 navigation.arrived
    if (condition == "navigation.visited_ports_count >= ") {
      // 兼容旧的解析逻辑，提取数值进行比较
      final target = _extractTargetValue(condition);
      return gs.visitedPortCount >= target;
    }
    if (condition.startsWith("navigation.visited_ports_count")) {
      final val = gs.visitedPortCount;
      final operator = _extractOperator(condition);
      final target = _extractTargetValue(condition);
      return _compare(val, operator, target);
    }
    if (condition == "navigation.arrived") {
      return !gs.isAtSea && gs.currentPort != null && !gs.isTransitioning;
    }
    if (condition == "navigation.isAtSea") {
      return gs.isAtSea;
    }
    if (condition.startsWith("navigation.current_port == ")) {
      final startQuote = condition.indexOf("'") + 1;
      final endQuote = condition.indexOf("'", startQuote);
      if (startQuote > 0 && endQuote > startQuote) {
        final targetPortId = condition.substring(startQuote, endQuote);
        return gs.currentPort?.id == targetPortId;
      }
      return false;
    }
    if (condition.startsWith("navigation.current_port != ")) {
      final startQuote = condition.indexOf("'") + 1;
      final endQuote = condition.indexOf("'", startQuote);
      if (startQuote > 0 && endQuote > startQuote) {
        final targetPortId = condition.substring(startQuote, endQuote);
        return gs.currentPort != null && gs.currentPort?.id != targetPortId;
      }
      return false;
    }

    // 6. 船只升级
    if (condition == "ship.upgrade_count >= 1") {
      return gs.shipUpgradeCount >= 1;
    }
    if (condition == "ship.cargo_level >= 1") {
      // 这里的逻辑需要与 ShipSystem 中的 initialMaxCargo 和 cargoUpgradeAmount 保持一致
      // 初始 100，每级 100
      final cargoLevel = ((gs.ship.cargoCapacity - 100) / 100).round();
      return cargoLevel >= 1;
    }
    if (condition == "ship.level >= 1") {
      // 这里的逻辑需要与 ShipSystem.getShipLevel 保持一致
      final cargoLevel = ((gs.ship.cargoCapacity - 100) / 100).round();
      final hullLevel = ((gs.ship.maxDurability - 200) / 50).round();
      final crewLevel = gs.ship.maxCrewMemberCount - 5;
      final minLevel = [cargoLevel, hullLevel, crewLevel].reduce((a, b) => a < b ? a : b);
      return minLevel >= 1;
    }

    // 7. 主岛打开 homeIsland.opened
    if (condition == "homeIsland.opened") {
      return gs.currentPort?.id == 'home_island' && !gs.isTransitioning;
    }
    if (condition == "!homeIsland.opened") {
      return gs.currentPort?.id != 'home_island' && !gs.isTransitioning;
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

/// 任务目标高亮包装器 - 自动管理 GlobalKey 及其在任务系统中的注册
class QuestTarget extends StatefulWidget {
  final String id;
  final Widget child;

  const QuestTarget({
    super.key,
    required this.id,
    required this.child,
  });

  @override
  State<QuestTarget> createState() => _QuestTargetState();
}

class _QuestTargetState extends State<QuestTarget> {
  final GlobalKey _myKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    QuestSystem.instance.registerKey(widget.id, _myKey);
  }

  @override
  void didUpdateWidget(QuestTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      QuestSystem.instance.unregisterKey(oldWidget.id, _myKey);
      QuestSystem.instance.registerKey(widget.id, _myKey);
    }
  }

  @override
  void dispose() {
    QuestSystem.instance.unregisterKey(widget.id, _myKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _myKey,
      child: widget.child,
    );
  }
}
