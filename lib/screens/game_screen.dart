import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' show exit;
import 'package:audioplayers/audioplayers.dart';
import '../game/game_state.dart';
import '../models/port.dart';
import '../game/game_scene.dart';
import '../game/debug_panel.dart';
import '../game/tavern_dialog.dart';
import '../game/pixel_progress_bar.dart';
import '../game/main_menu_overlay.dart';
import '../systems/trade_system.dart';
import '../systems/port_system.dart';
import '../systems/music_system.dart';
import '../systems/save_system.dart';
import '../systems/sea_event_system.dart';
import '../game/shipyard_dialog.dart';
import '../game/settings_dialog.dart';
import '../game/sea_event_dialog.dart';
import '../utils/game_config_loader.dart';
import '../systems/quest_system.dart';
import '../systems/app_settings_controller.dart';
import '../l10n/l10n.dart';
import 'save_load_screen.dart';

class GameScreen extends StatefulWidget {
  final Map<String, dynamic>? initialSaveData;
  final bool showMainMenuInitially;

  const GameScreen({
    super.key, 
    this.initialSaveData,
    this.showMainMenuInitially = false,
  });

  /// 预加载游戏资源（图片、音频等）
  /// 返回一个 Future，可以传递给 LoadingScreen.waitFor 来等待加载完成
  static Future<void> preload(BuildContext context) async {
    // 1. 加载游戏配置
    try {
      final configLoader = GameConfigLoader();
      await configLoader.loadConfig();
    } catch (e) {
      debugPrint('✗ Failed to load game config: $e');
    }

    // 2. 动态发现所有资源
    final List<String> imageAssets = [];
    final List<String> audioAssets = [];

    try {
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();
      
      for (final asset in allAssets) {
        final lowerAsset = asset.toLowerCase();
        // 只加载 assets/ 目录下的资源，排除其他可能的资源
        if (!lowerAsset.startsWith('assets/')) continue;
        
        if (lowerAsset.endsWith('.png') || 
            lowerAsset.endsWith('.jpg') || 
            lowerAsset.endsWith('.jpeg') || 
            lowerAsset.endsWith('.webp') || 
            lowerAsset.endsWith('.gif')) {
          imageAssets.add(asset);
        } else if (lowerAsset.endsWith('.mp3') || 
                   lowerAsset.endsWith('.wav') || 
                   lowerAsset.endsWith('.ogg')) {
          audioAssets.add(asset);
        }
      }
      debugPrint('Found ${imageAssets.length} images and ${audioAssets.length} audio files to preload.');
    } catch (e) {
      debugPrint('✗ Failed to discover assets: $e');
    }

    // 3. 预加载图片
    if (imageAssets.isNotEmpty) {
      final imageResults = await Future.wait(
        imageAssets.map((path) async {
          try {
            // 在 Web 平台上，AssetImage 可能会将路径前的 assets/ 视为重复
            // 但在其他平台上则需要完整的 assets/ 前缀。
            // 经验做法是，如果 precache 失败，尝试移除 assets/ 前缀再试一次。
            await precacheImage(AssetImage(path), context);
            return true;
          } catch (e) {
            if (!context.mounted) return false;
            try {
              if (path.startsWith('assets/')) {
                final alternativePath = path.replaceFirst('assets/', '');
                await precacheImage(AssetImage(alternativePath), context);
                return true;
              }
            } catch (_) {}
            
            // 检查错误类型，精简日志
            final errorMsg = e.toString();
            if (errorMsg.contains('Unable to load asset')) {
              // 暂时忽略 Web 上的 404 详细日志，避免刷屏
            } else {
              debugPrint('⚠ Failed to preload image: $path ($e)');
            }
            return false;
          }
        }),
        eagerError: false,
      );
      final successCount = imageResults.where((r) => r).length;
      debugPrint('✓ Image preloading complete: $successCount/${imageAssets.length} successful');
    }

    // 4. 预加载音频 (触发初始化解码)
    if (audioAssets.isNotEmpty) {
      final player = AudioPlayer();
      int audioSuccessCount = 0;
      for (final path in audioAssets) {
        try {
          // AssetSource 期望相对于 assets/ 的路径
          final sourcePath = path.replaceFirst('assets/', '');
          await player.setSource(AssetSource(sourcePath));
          audioSuccessCount++;
        } catch (e) {
          debugPrint('⚠ Failed to preload audio: $path ($e)');
        }
      }
      await player.dispose();
      debugPrint('✓ Audio preloading complete: $audioSuccessCount/${audioAssets.length} successful');
    }

    // 5. 初始化音乐系统
    MusicSystem().initialize();
    
    // 6. 预加载进度条素材
    await PixelProgressBar.preload();
    
    debugPrint('✓ All resources preloading task finished.');
  }

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  late TradeSystem _tradeSystem;
  late PortSystem _portSystem;
  Ticker? _gameLoopTicker;
  DateTime? _lastFrameTime;
  
  bool _isShowingMainMenu = false;
  bool _canContinue = false;
  
  // 过渡动画相关状态
  bool _isTransitioningToGame = false;
  bool _showCoverOverlay = false;
  bool _isShowingSeaEventDialog = false;
  int? _currentBackgroundSaveId; // 当前背景对应的存档 ID，-1 表示新游戏场景
  AppSettingsController? _appSettingsController;
  String? _lastLocaleLanguageCode;
  bool _isRelocalizing = false;

  @override
  void initState() {
    super.initState();
    _isShowingMainMenu = widget.showMainMenuInitially;
    _isTransitioningToGame = widget.showMainMenuInitially; // 初始化为 true 以配合 AnimatedOpacity 实现淡入
    _gameState = GameState();
    _tradeSystem = TradeSystem(_gameState);
    _portSystem = PortSystem(_gameState);
    
    _gameState.setGetGoodsById((goodsId) => _tradeSystem.getGoods(goodsId));
    
    // 添加 GameState 监听器
    _gameState.addListener(_onGameStateChanged);
    _gameState.isMenuMode = _isShowingMainMenu;
    
    // 监听任务系统的动作
    QuestSystem.instance.addListener(_handleQuestAction);
    
    // 监听海上事件系统
    SeaEventSystem.instance.addListener(_handleSeaEvent);
    
    // 初始化游戏状态逻辑（如果是主菜单模式，尝试加载最近存档作为背景）
    _initGameState();

    if (_isShowingMainMenu) {
      MusicSystem().playState('main_menu');
    // Delay one frame to avoid showing dialog during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isTransitioningToGame = false;
          });
        }
      });
    } else {
      // 如果不是从菜单开始，立即初始化任务系统
      QuestSystem.instance.initialize(
        _gameState, 
        isNewGame: widget.initialSaveData == null,
        skipTutorial: QuestSystem.shouldSkipTutorial,
      );
    }
    
    // 使用 Ticker 统一更新所有时间系统（每帧更新）
    // 这是游戏内唯一的计时方式，使用 dt 增量更新
    _lastFrameTime = DateTime.now();
    _gameLoopTicker = Ticker((elapsed) {
      final now = DateTime.now();
      if (_lastFrameTime == null) {
        _lastFrameTime = now;
        return;
      }
      
      // 60 FPS 限制逻辑：如果距离上一帧时间不足 16ms，则跳过本次更新
      final dtRealSeconds = now.difference(_lastFrameTime!).inMilliseconds / 1000.0;
      if (dtRealSeconds < 0.016) {
        return;
      }
      
      _lastFrameTime = now;
      
      // 使用 dt 增量更新所有时间相关系统
      _gameState.updateDayNightSystemWithDeltaTime(dtRealSeconds);
      _gameState.processAutoRepairWithDeltaTime(dtRealSeconds);
      
      // 如果正在战斗中，更新战斗系统（使用游戏时间）
      if (_gameState.isInCombat) {
        // 计算 game 时间增量（秒）
        // 使用当前的游戏时间流逝比例（在海上航行时为 60.0，在港口时为 1.0）
        // 除以 60.0 将游戏分钟转换为游戏秒
        final dtGameSeconds = dtRealSeconds * _gameState.currentTimeScale * _gameState.dayNightSystem.timeMultiplier / 60.0;
        _gameState.updateCombatWithDeltaTime(dtGameSeconds);
      }
    });
    
    // 启动游戏循环 Ticker
    _gameLoopTicker!.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appSettings = context.read<AppSettingsController>();
    if (_appSettingsController == appSettings) return;

    _appSettingsController?.removeListener(_handleAppLocaleChanged);
    _appSettingsController = appSettings;
    _lastLocaleLanguageCode = appSettings.locale.languageCode;
    _appSettingsController?.addListener(_handleAppLocaleChanged);
  }

  Future<void> _handleAppLocaleChanged() async {
    final appSettings = _appSettingsController;
    if (appSettings == null) return;
    final nextCode = appSettings.locale.languageCode;
    if (_lastLocaleLanguageCode == nextCode || _isRelocalizing) return;

    _lastLocaleLanguageCode = nextCode;
    _isRelocalizing = true;
    try {
      await GameConfigLoader().reloadForLocale(nextCode);
      _gameState.relocalizeFromConfig();
      QuestSystem.instance.reloadForLocale();
      SeaEventSystem.instance.reloadForLocale();
      _gameState.refreshTavernCrew(force: true);
      if (mounted) {
        setState(() {});
      }
    } finally {
      _isRelocalizing = false;
    }
  }

  void _handleQuestAction() {
    final pendingAction = QuestSystem.instance.pendingAction;
    if (pendingAction == null) return;

    // 支持多个动作，用 && 分隔
    final actions = pendingAction.split("&&").map((s) => s.trim());

    for (final action in actions) {
      if (action == "ui.marketPanel.close" || action == "ui.shipyard.close") {
        // 如果当前弹窗是对应面板，则关闭它
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else if (action.startsWith("port.unlock('") && action.endsWith("')")) {
        final portId = action.substring(13, action.length - 2);
        _gameState.setPortUnlocked(portId, true);
      } else if (action == "combat.unlock") {
        _gameState.setCombatUnlocked(true);
      } else if (action == "port.unlockAllExceptHome") {
        _gameState.unlockAllPortsExceptHome();
      } else if (action.startsWith("homeIsland.setTax(") && action.endsWith(")")) {
        final valueStr = action.substring(18, action.length - 1);
        final value = int.tryParse(valueStr) ?? 0;
        _gameState.setAccumulatedTax(value);
      } else if (action == "homeIsland.unlockTax") {
        _gameState.unlockHomeIslandTax();
      }
    }

    QuestSystem.instance.clearPendingAction();
  }
  void _handleSeaEvent() {
    final activeEvent = SeaEventSystem.instance.activeEvent;
    if (activeEvent == null) return;
    if (_isShowingSeaEventDialog || _gameState.isMarketOpened) return;

    // å»¶è¿Ÿä¸€å¸§æ˜¾ç¤ºï¼Œç¡®ä¿ä¸ä¼šåœ¨ build è¿‡ç¨‹ä¸­è§¦å‘
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_isShowingSeaEventDialog || _gameState.isMarketOpened) return;

      _isShowingSeaEventDialog = true;
      try {
        await SeaEventDialog.show(context, activeEvent);
      } finally {
        _isShowingSeaEventDialog = false;
      }
    });
  }

  void _onGameStateChanged() {
    if (!mounted) return;

    if (_gameState.departingCrewNames.isNotEmpty) {
      final names = _gameState.departingCrewNames.join('、');
      // 先清理，避免重复触发（listener 可能被多次调用）
      _gameState.clearDepartingCrewNames();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.crewLeftNoPay(names)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        ),
      );
    }

    // 安全地调用 setState
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void _initializeGame() {
    final configLoader = GameConfigLoader();
    final ports = configLoader.portsList;
    
    // 查找 "sea" 港口作为初始位置
    Port? seaPort;
    try {
      seaPort = ports.firstWhere((p) => p.id == 'sea');
    } catch (_) {
      seaPort = null;
    }
    
    // 初始化游戏状态，从海上开始
    _gameState.initialize(ports, startingPort: seaPort);
    
    // 初始化港口商品库存（使用配置的 s0 值）
    _gameState.initializePortGoodsStock();
  }

  Future<void> _initGameState() async {
    // 1. 如果提供了初始存档数据（如从存档管理界面跳转），直接加载
    if (widget.initialSaveData != null) {
      _gameState.initialize([]); 
      _gameState.loadFromJson(widget.initialSaveData!);
      _gameState.isMenuMode = _isShowingMainMenu;
      _checkCanContinue();
      return;
    }

    // 2. 如果是主菜单模式，尝试加载最近的存档作为背景场景
    if (_isShowingMainMenu) {
      final slots = await SaveManager.getSaveSlots();
      if (slots.isNotEmpty) {
        slots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final latestSlot = slots.first;
        try {
          final gameData = await SaveManager.loadGame(latestSlot.id);
          if (mounted) {
            setState(() {
              _gameState.loadFromJson(gameData);
              _gameState.isMenuMode = true;
              _canContinue = true;
              _currentBackgroundSaveId = latestSlot.id;
            });
          }
          return;
        } catch (e) {
          debugPrint('Failed to load latest save for background: $e');
        }
      }
    }

    // 3. 默认回退：初始化新游戏场景
    _initializeGame();
    _gameState.isMenuMode = _isShowingMainMenu;
    _currentBackgroundSaveId = -1; // 表示新游戏场景
    _checkCanContinue();
  }

  Future<void> _checkCanContinue() async {
    final slots = await SaveManager.getSaveSlots();
    if (mounted) {
      setState(() {
        _canContinue = slots.isNotEmpty;
      });
    }
  }

  Future<void> _handleNewGame() async {
    setState(() {
      _isTransitioningToGame = true;
      // 如果当前背景不是新游戏场景 (-1)，则显示遮罩
      if (_currentBackgroundSaveId != -1) {
        _showCoverOverlay = true;
      }
    });

    // 等待按钮淡出和遮罩淡入
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _gameState.isMenuMode = false;
      // 重新初始化游戏状态
      _initializeGame();
    });
    
    QuestSystem.instance.initialize(
      _gameState, 
      isNewGame: true,
      skipTutorial: QuestSystem.shouldSkipTutorial,
    );
    MusicSystem().playState(_gameState.isAtSea ? 'cruising' : 'port');

    // 更新当前背景存档 ID
    _currentBackgroundSaveId = -1;

    // 等待背景切换渲染
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _isShowingMainMenu = false;
      _isTransitioningToGame = false;
      _showCoverOverlay = false;
    });
  }

  Future<void> _handleContinueGame() async {
    try {
      final slots = await SaveManager.getSaveSlots();
      if (slots.isEmpty) return;

      slots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestSlot = slots.first;
      
      setState(() {
        _isTransitioningToGame = true;
        // 如果目标存档 ID 与当前背景存档 ID 不一致，则显示遮罩
        if (_currentBackgroundSaveId != latestSlot.id) {
          _showCoverOverlay = true;
        }
      });

      // 等待按钮淡出和遮罩淡入
      await Future.delayed(const Duration(milliseconds: 500));

      final gameData = await SaveManager.loadGame(latestSlot.id);
      
      if (mounted) {
        setState(() {
          _gameState.isMenuMode = false;
          _gameState.loadFromJson(gameData);
        });
        QuestSystem.instance.initialize(_gameState, isNewGame: false);
        MusicSystem().playState(_gameState.isAtSea ? 'cruising' : 'port');
        
        // 更新当前背景存档 ID
        _currentBackgroundSaveId = latestSlot.id;
      }

      // 等待背景切换渲染
      await Future.delayed(const Duration(milliseconds: 100));

      setState(() {
        _isShowingMainMenu = false;
        _isTransitioningToGame = false;
        _showCoverOverlay = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.loadFailed(e.toString()))),
        );
        setState(() {
          _isTransitioningToGame = false;
          _showCoverOverlay = false;
        });
      }
    }
  }

  void _handleLoadGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SaveLoadScreen(
          mode: SaveLoadMode.load,
          onLoadConfirmed: (gameData) async {
            setState(() {
              _isTransitioningToGame = true;
              // 从存档列表加载时，通常很难判断是否与当前背景一致
              // 为了保险起见，始终显示遮罩
              _showCoverOverlay = true;
            });

            // 等待按钮淡出和遮罩淡入
            await Future.delayed(const Duration(milliseconds: 500));

            setState(() {
              _gameState.isMenuMode = false;
              _gameState.loadFromJson(gameData);
            });
            QuestSystem.instance.initialize(_gameState, isNewGame: false);
            MusicSystem().playState(_gameState.isAtSea ? 'cruising' : 'port');

            // 更新当前背景存档 ID（在异步操作中，通常最近加载的就是最新的）
            final slots = await SaveManager.getSaveSlots();
            if (slots.isNotEmpty) {
              slots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              _currentBackgroundSaveId = slots.first.id;
            }

            // 等待背景切换渲染
            await Future.delayed(const Duration(milliseconds: 100));

            setState(() {
              _isShowingMainMenu = false;
              _isTransitioningToGame = false;
              _showCoverOverlay = false;
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleReturnToMainMenu() async {
    // 1. 关闭设置对话框
    Navigator.of(context).pop();

    // 检查最新存档 ID
    final slots = await SaveManager.getSaveSlots();
    int latestId = -1;
    if (slots.isNotEmpty) {
      slots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      latestId = slots.first.id;
    }

    // 如果目标背景（最新存档）与当前正显示的背景（存档 ID）一致，则不需要封面遮罩
    final bool needsCover = latestId != _currentBackgroundSaveId;

    setState(() {
      if (needsCover) {
        _showCoverOverlay = true;
      }
      _isTransitioningToGame = true; // 菜单按钮初始透明
      _isShowingMainMenu = true; // 立即标记为菜单模式
    });

    // 2. 如果需要遮罩，等待淡入动画
    if (needsCover) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 3. 重置逻辑状态
    QuestSystem.instance.reset();
    
    // 4. 更新动态背景（即使 ID 一致，也调用一下确保状态完全同步）
    await _initGameState();

    setState(() {
      _gameState.isMenuMode = true;
      _isTransitioningToGame = false; // 让菜单按钮淡入
    });

    // 5. 如果有遮罩，淡出它
    if (needsCover) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        _showCoverOverlay = false;
      });
    }
    
    MusicSystem().playState('main_menu');
  }

  void _handleExitGame() {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux)) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  void _handleTradePressed() {
    TradeSystem.showTradeDialog(context, _tradeSystem);
  }

  void _handlePortSelectPressed() {
    PortSystem.showPortSelectDialog(context, _portSystem);
  }

  void _handleUpgradePressed() {
    // TODO: 实现升级界面
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.shipUpgrade),
        content: Text(context.l10n.shipUpgradeInDev),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  void _handleMarketPressed() {
    // 市场功能（目前使用交易系统）
    TradeSystem.showTradeDialog(context, _tradeSystem);
  }

  void _handleCrewMarketPressed() {
    // 港口酒馆 - 招募船员
    showDialog(
      context: context,
      builder: (context) => TavernDialog(
        gameState: _gameState,
      ),
    );
  }

  void _handleShipyardPressed() {
    // 船厂 - 船只升级和维修
    showDialog(
      context: context,
      builder: (context) => ShipyardDialog(
        gameState: _gameState,
      ),
    );
  }

  void _handleSettingsPressed({bool fromMainMenu = false}) {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        gameState: fromMainMenu ? null : _gameState,
        onReturnToMainMenu: fromMainMenu ? null : _handleReturnToMainMenu,
      ),
    );
  }

  @override
  void dispose() {
    _appSettingsController?.removeListener(_handleAppLocaleChanged);
    QuestSystem.instance.removeListener(_handleQuestAction);
    _gameLoopTicker?.stop();
    _gameLoopTicker = null;
    _gameState.removeListener(_onGameStateChanged);
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameScene(
            gameState: _gameState,
            showUI: !_isShowingMainMenu,
            onTradePressed: _handleTradePressed,
            onPortSelectPressed: _handlePortSelectPressed,
            onUpgradePressed: _handleUpgradePressed,
            onMarketPressed: _handleMarketPressed,
            onCrewMarketPressed: _handleCrewMarketPressed,
            onShipyardPressed: _handleShipyardPressed,
            onSettingsPressed: _handleSettingsPressed,
          ),
          
          // 封面遮罩层 - 用于遮挡背景切换时的视觉跳变
          IgnorePointer(
            ignoring: !_showCoverOverlay,
            child: AnimatedOpacity(
              opacity: _showCoverOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                'assets/images/painting/Cover_0.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

      if (_isShowingMainMenu)
        AnimatedOpacity(
          opacity: _isTransitioningToGame ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 500),
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: MainMenuOverlay(
                  onNewGame: _handleNewGame,
                  onContinueGame: _handleContinueGame,
                  onLoadGame: _handleLoadGame,
                  onSettings: () => _handleSettingsPressed(fromMainMenu: true),
                  onExit: _handleExitGame,
                  canContinue: _canContinue,
                ),
              ),
            ),
          
          // 调试面板 - 始终位于最顶层，支持在菜单模式下操作
          DebugPanel(gameState: _gameState),
        ],
      ),
    );
  }
}
