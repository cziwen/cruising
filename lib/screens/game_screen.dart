import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
// Conditional imports for logging
import '../utils/file_logger.dart' if (dart.library.html) '../utils/web_logger.dart' as logger;
// Import File and FileMode for non-web platforms
import 'dart:io' if (dart.library.html) '../utils/io_stub.dart' show File, FileMode;
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
    // #region agent log
    final logPath = r'c:\Users\ziwen\cruising\.cursor\debug.log';
    final sessionId = 'debug-session';
    final runId = 'run1';
    final serverEndpoint = 'http://127.0.0.1:7242/ingest/047329b0-6100-4d22-b604-608ce454ff91';
    Future<void> writeLog(Map<String, dynamic> logData) async {
      // Use conditional import - same function name on both platforms
      await logger.writeLog(serverEndpoint, logPath, logData);
    }
    debugPrint('[DEBUG] Preload starting - Platform: ${kIsWeb ? "Web" : defaultTargetPlatform}');
    try {
      if (!kIsWeb) {
        // Import File and FileMode directly for non-web platforms
        final logFile = File(logPath);
        if (await logFile.exists()) {
          await logFile.writeAsString('', mode: FileMode.write);
          debugPrint('[DEBUG] Cleared log file');
        } else {
          await logFile.create(recursive: true);
          debugPrint('[DEBUG] Created log file');
        }
      } else {
        debugPrint('[DEBUG] Web platform - using HTTP logging to $serverEndpoint');
      }
      await writeLog({"id":"log_${DateTime.now().millisecondsSinceEpoch}_entry","timestamp":DateTime.now().millisecondsSinceEpoch,"location":"game_screen.dart:47","message":"preload function entry","data":{"platform":kIsWeb?"Web":defaultTargetPlatform.toString(),"totalImages":9},"sessionId":sessionId,"runId":runId,"hypothesisId":"A,B,C,D,E"});
      debugPrint('[DEBUG] Initial log entry written');
    } catch (e) {
      debugPrint('[DEBUG] Failed to initialize logging: $e');
    }
    // #endregion agent log
    
    // 加载游戏配置
    try {
      final configLoader = GameConfigLoader();
      await configLoader.loadConfig();
      debugPrint('✓ Game config loaded successfully');
    } catch (e) {
      debugPrint('✗ Failed to load game config: $e');
      // 如果配置加载失败，我们可能无法继续，但至少不要卡住
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

    // #region agent log
    try {
      for (var i = 0; i < uniqueImagesToPreload.length; i++) {
        await writeLog({"id":"log_${DateTime.now().millisecondsSinceEpoch}_pre_$i","timestamp":DateTime.now().millisecondsSinceEpoch,"location":"game_screen.dart:52","message":"before precacheImage","data":{"imagePath":uniqueImagesToPreload[i],"index":i,"total":uniqueImagesToPreload.length},"sessionId":sessionId,"runId":runId,"hypothesisId":"C"});
      }
    } catch (_) {}
    // #endregion agent log

    // 预加载所有图片，带错误处理
    // 在web平台上，precacheImage可能成功但实际使用时仍会失败（asset manifest问题）
    // 使用 wait 的 continueOnError 模式，确保即使某些图片失败也不影响整体流程
    final startTime = DateTime.now();
    final results = await Future.wait(
      uniqueImagesToPreload.map((path) async {
        final imageStartTime = DateTime.now();
        // #region agent log
        try {
          await writeLog({"id":"log_${DateTime.now().millisecondsSinceEpoch}_start_${path.hashCode}","timestamp":DateTime.now().millisecondsSinceEpoch,"location":"game_screen.dart:84","message":"precacheImage start","data":{"imagePath":path,"platform":kIsWeb?"Web":defaultTargetPlatform.toString()},"sessionId":sessionId,"runId":runId,"hypothesisId":"B,C"});
        } catch (_) {}
        // #endregion agent log

        try {
          // 尝试预加载图片
          // 注意：在web平台上，precacheImage可能只是验证路径，不实际加载数据
          await precacheImage(AssetImage(path), context);
          
          final duration = DateTime.now().difference(imageStartTime).inMilliseconds;
          
          // 在web平台上，即使precacheImage成功，实际使用时仍可能失败
          // 这是因为web构建的asset manifest可能没有包含这些文件
          if (kIsWeb) {
            debugPrint('✓ Preloaded (web): $path (may still fail at runtime if not in manifest)');
          } else {
            debugPrint('✓ Preloaded: $path');
          }
          
          // #region agent log
          try {
            await writeLog({"id":"log_${DateTime.now().millisecondsSinceEpoch}_success_${path.hashCode}","timestamp":DateTime.now().millisecondsSinceEpoch,"location":"game_screen.dart:95","message":"precacheImage success","data":{"imagePath":path,"durationMs":duration,"platform":kIsWeb?"Web":defaultTargetPlatform.toString()},"sessionId":sessionId,"runId":runId,"hypothesisId":"A,B,D"});
          } catch (_) {}
          // #endregion agent log

          return true;
        } catch (e, stackTrace) {
          final duration = DateTime.now().difference(imageStartTime).inMilliseconds;
          final errorType = e.runtimeType.toString();
          final errorMsg = e.toString();
          
          // 检查错误类型
          final isAssetNotFound = errorMsg.contains('Unable to load asset') || 
                                  errorMsg.contains('Asset not found');
          final isInvalidImageData = errorMsg.contains('Invalid image data') || 
                                     errorMsg.contains('CodecException');
          
          if (isAssetNotFound) {
            if (kIsWeb) {
              debugPrint('⚠ Web asset not found: $path');
              debugPrint('  [HYPOTHESIS B CONFIRMED] Asset may not be in web build manifest');
              debugPrint('  Solution: Run "flutter clean" and "flutter pub get", then rebuild');
            } else {
              debugPrint('⚠ Asset not found: $path');
            }
          } else if (isInvalidImageData) {
            debugPrint('⚠ Skipped invalid/corrupted image: $path');
            debugPrint('  [HYPOTHESIS A CONFIRMED] File is corrupted or invalid format');
          } else {
            debugPrint('✗ Failed to preload: $path');
            debugPrint('  Error Type: $errorType');
            debugPrint('  Error Message: $errorMsg');
          }
          debugPrint('  Duration: ${duration}ms');
          
          // #region agent log
          try {
            await writeLog({"id":"log_${DateTime.now().millisecondsSinceEpoch}_error_${path.hashCode}","timestamp":DateTime.now().millisecondsSinceEpoch,"location":"game_screen.dart:107","message":"precacheImage error","data":{"imagePath":path,"errorType":errorType,"errorMessage":errorMsg,"durationMs":duration,"isAssetNotFound":isAssetNotFound,"isInvalidImageData":isInvalidImageData,"platform":kIsWeb?"Web":defaultTargetPlatform.toString(),"stackTrace":stackTrace.toString().substring(0,stackTrace.toString().length>500?500:stackTrace.toString().length)},"sessionId":sessionId,"runId":runId,"hypothesisId":"A,B,C,D,E"});
          } catch (logErr) {
            debugPrint('  [LOG ERROR] Failed to write log: $logErr');
          }
          // #endregion agent log

          return false;
        }
      }),
      eagerError: false, // 不因单个错误而立即失败
    );
    
    final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
    final successCount = results.where((r) => r).length;
    final failCount = results.length - successCount;
    debugPrint('Preload complete: $successCount/${results.length} images loaded');
    if (failCount > 0) {
      debugPrint('Warning: $failCount images failed to load');
    }

    // #region agent log
    try {
      await writeLog({"id":"log_${DateTime.now().millisecondsSinceEpoch}_exit","timestamp":DateTime.now().millisecondsSinceEpoch,"location":"game_screen.dart:107","message":"preload function exit","data":{"successCount":successCount,"failCount":failCount,"totalImages":imagesToPreload.length,"totalDurationMs":totalDuration,"results":results},"sessionId":sessionId,"runId":runId,"hypothesisId":"A,B,C,D,E"});
    } catch (_) {}
    // #endregion agent log
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
        // 计算游戏时间增量（秒）
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

