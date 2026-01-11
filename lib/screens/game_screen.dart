import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../game/game_state.dart';
import '../game/game_scene.dart';
import '../game/tavern_dialog.dart';
import '../game/pixel_progress_bar.dart';
import '../systems/trade_system.dart';
import '../systems/port_system.dart';
import '../systems/music_system.dart';
import '../game/shipyard_dialog.dart';
import '../game/settings_dialog.dart';
import '../utils/game_config_loader.dart';

class GameScreen extends StatefulWidget {
  final Map<String, dynamic>? initialSaveData;

  const GameScreen({super.key, this.initialSaveData});

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
      
      // 30 FPS 限制逻辑：如果距离上一帧时间不足 33ms，则跳过本次更新
      final dtRealSeconds = now.difference(_lastFrameTime!).inMilliseconds / 1000.0;
      if (dtRealSeconds < 0.033) {
        return;
      }
      
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
    
    // 不再手动指定 startingPort，让 GameState 内部默认选择主岛
    _gameState.initialize(ports);
    
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
