import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import '../game/game_state.dart';
import '../game/game_scene.dart';
import '../game/tavern_dialog.dart';
import '../systems/trade_system.dart';
import '../systems/port_system.dart';
import '../game/shipyard_dialog.dart';
import '../game/settings_dialog.dart';
import '../utils/game_config_loader.dart';

class GameScreen extends StatefulWidget {
  final Map<String, dynamic>? initialSaveData;

  const GameScreen({super.key, this.initialSaveData});

  /// 预加载游戏资源（图片等）
  /// 返回一个 Future，可以传递给 LoadingScreen.waitFor 来等待加载完成
  static Future<void> preload(BuildContext context) async {
    // 加载游戏配置
    try {
      final configLoader = GameConfigLoader();
      await configLoader.loadConfig();
    } catch (e) {
      debugPrint('✗ Failed to load game config: $e');
      // 不再重新抛出，允许应用尝试继续运行（GameConfigLoader 内部已处理为返回空列表）
    }

    // 动态从配置中获取需要预加载的图片
    final List<String> imagesToPreload = [
      // 其他固定图片
      'assets/images/buildings/village_0.png',
      'assets/images/buildings/business_port.png',
      'assets/images/buildings/exotic_village.png',
    ];

    try {
      final configLoader = GameConfigLoader();
      if (configLoader.portsList.isNotEmpty) {
        imagesToPreload.addAll(configLoader.portsList.map((p) => p.backgroundImage));
      }
      if (configLoader.goodsList.isNotEmpty) {
        imagesToPreload.addAll(configLoader.goodsList.where((g) => g.imagePath != null).map((g) => g.imagePath!));
      }
    } catch (e) {
      debugPrint('Warning: Could not extract images from config for preloading: $e');
    }

    final uniqueImagesToPreload = imagesToPreload.toSet().toList(); // 去重

    // 预加载所有图片，带错误处理
    // 在web平台上，precacheImage可能成功但实际使用时仍会失败（asset manifest问题）
    // 使用 wait 的 continueOnError 模式，确保即使某些图片失败也不影响整体流程
    final results = await Future.wait(
      uniqueImagesToPreload.map((path) async {
        try {
          // 尝试预加载图片
          await precacheImage(AssetImage(path), context);
          return true;
        } catch (e) {
          final errorMsg = e.toString();
          
          // 检查错误类型
          final isAssetNotFound = errorMsg.contains('Unable to load asset') || 
                                  errorMsg.contains('Asset not found');
          final isInvalidImageData = errorMsg.contains('Invalid image data') || 
                                     errorMsg.contains('CodecException');
          
          if (isAssetNotFound) {
            if (kIsWeb) {
              debugPrint('⚠ Web asset not found: $path');
            } else {
              debugPrint('⚠ Asset not found: $path');
            }
          } else if (isInvalidImageData) {
            debugPrint('⚠ Skipped invalid/corrupted image: $path');
          } else {
            debugPrint('✗ Failed to preload: $path');
            debugPrint('  Error: $e');
          }
          
          return false;
        }
      }),
      eagerError: false, // 不因单个错误而立即失败
    );
    
    final successCount = results.where((r) => r).length;
    final failCount = results.length - successCount;
    if (failCount > 0) {
      debugPrint('✓ Game resources loaded ($successCount/${results.length} images, $failCount failed)');
    } else {
      debugPrint('✓ Game resources loaded (${results.length} images)');
    }
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

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _tradeSystem = TradeSystem(_gameState);
    _portSystem = PortSystem(_gameState);
    
    _gameState.setGetGoodsById((goodsId) => _tradeSystem.getGoods(goodsId));
    
    if (widget.initialSaveData != null) {
      _gameState.initialize([]); // Initialize with empty to setup basic structure if needed, or rely on loadFromJson
      _gameState.loadFromJson(widget.initialSaveData!);
    } else {
      // 初始化游戏
      _initializeGame();
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
      
      // 计算 dt（实际时间增量，秒）
      final dtRealSeconds = now.difference(_lastFrameTime!).inMilliseconds / 1000.0;
      _lastFrameTime = now;
      
      // 使用 dt 增量更新所有时间相关系统
      _gameState.updateDayNightSystemWithDeltaTime(dtRealSeconds);
      _gameState.processAutoRepairWithDeltaTime(dtRealSeconds);
      
      // 如果正在战斗中，更新战斗系统（使用游戏时间）
      if (_gameState.isInCombat) {
        // 计算 game 时间增量（秒）
        // timeScale = 60.0 (1现实秒 = 60游戏分钟 = 1游戏小时)
        // 除以 60.0 将游戏分钟转换为游戏秒
        final timeScale = 60.0; // DayNightSystem.timeScale
        final dtGameSeconds = dtRealSeconds * timeScale * _gameState.dayNightSystem.timeMultiplier / 60.0;
        _gameState.updateCombatWithDeltaTime(dtGameSeconds);
      }
    });
    
    // 启动游戏循环 Ticker
    _gameLoopTicker!.start();
  }

  void _initializeGame() {
    final configLoader = GameConfigLoader();
    final ports = configLoader.portsList;
    
    _gameState.initialize(ports, startingPort: ports.isNotEmpty ? ports.first : null);
    
    // 初始化港口商品库存（使用配置的 s0 值）
    _gameState.initializePortGoodsStock();
    
    _gameState.addListener(() {
      if (_gameState.departingCrewNames.isNotEmpty) {
        final names = _gameState.departingCrewNames.join('、');
        // 先清理，避免重复触发（listener 可能被多次调用）
        _gameState.clearDepartingCrewNames();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('船员 $names 因为得不到报酬，已经在港口悄悄离开了...'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
          ),
        );
      }
      setState(() {});
    });
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
        title: const Text('船只升级'),
        content: const Text('升级功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
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

  void _handleSettingsPressed() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(gameState: _gameState),
    );
  }

  @override
  void dispose() {
    _gameLoopTicker?.stop();
    _gameLoopTicker = null;
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameScene(
        gameState: _gameState,
        onTradePressed: _handleTradePressed,
        onPortSelectPressed: _handlePortSelectPressed,
        onUpgradePressed: _handleUpgradePressed,
        onMarketPressed: _handleMarketPressed,
        onCrewMarketPressed: _handleCrewMarketPressed,
        onShipyardPressed: _handleShipyardPressed,
        onSettingsPressed: _handleSettingsPressed,
      ),
    );
  }
}
