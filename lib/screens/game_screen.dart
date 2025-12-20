import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'main_menu_screen.dart';
import 'loading_screen.dart';
import 'save_load_screen.dart';
import '../game/game_state.dart';
import '../game/game_scene.dart';
import '../game/tavern_dialog.dart';
import '../systems/trade_system.dart';
import '../systems/port_system.dart';
import '../game/shipyard_dialog.dart';
import '../game/settings_dialog.dart';
import '../models/port.dart';

class GameScreen extends StatefulWidget {
  final Map<String, dynamic>? initialSaveData;

  const GameScreen({super.key, this.initialSaveData});

  /// 预加载游戏资源（图片等）
  /// 返回一个 Future，可以传递给 LoadingScreen.waitFor 来等待加载完成
  static Future<void> preload(BuildContext context) async {
    // 预加载游戏中使用的图片资源
    final imagesToPreload = [
      'assets/images/oceanbackground.png',
      'assets/images/coconut_tree_island.png',
      'assets/images/pixel-pirate-ship.png',
      'assets/images/pixel-sun-icon.png',
      'assets/images/moon-in-pixel-art.png',
    ];

    // 并行预加载所有图片
    await Future.wait(
      imagesToPreload.map((path) => precacheImage(AssetImage(path), context)),
    );
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

  // 设置相关状态
  final List<Size> _resolutions = const [
    Size(1280, 720),
    Size(1920, 1080),
    Size(2560, 1440),
  ];
  Size _currentResolution = const Size(1280, 720);
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _tradeSystem = TradeSystem(_gameState);
    _portSystem = PortSystem(_gameState);
    
    // 仅在桌面端初始化状态
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.macOS)) {
      _checkFullScreenState();
    }
    
    // 设置GameState的getGoodsById函数
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

  Future<void> _checkFullScreenState() async {
    final isFullScreen = await windowManager.isFullScreen();
    if (mounted) {
      setState(() {
        _isFullScreen = isFullScreen;
      });
    }
  }

  void _initializeGame() {
    // 创建示例港口，并设置航行距离（节）
    // 8节 = 每小时（真实时间1秒）的形式距离
    // 例如：24小时 = 24 * 8 = 192节
    
    // 为每个港口配置每个商品的 alpha 和 s0
    // 起始港的商品配置
    final port1GoodsConfig = {
      'food': PortGoodsConfig(alpha: 0.05, s0: 500),
      'wood': PortGoodsConfig(alpha: 0.04, s0: 500),
      'spice': PortGoodsConfig(alpha: 0.08, s0: 300),
      'metal': PortGoodsConfig(alpha: 0.05, s0: 500),
    };
    
    // 贸易港的商品配置（可能对某些商品更敏感）
    final port2GoodsConfig = {
      'food': PortGoodsConfig(alpha: 0.06, s0: 600),
      'wood': PortGoodsConfig(alpha: 0.05, s0: 400),
      'spice': PortGoodsConfig(alpha: 0.12, s0: 250),
      'metal': PortGoodsConfig(alpha: 0.06, s0: 450),
    };
    
    // 香料港的商品配置（对香料特别敏感）
    final port3GoodsConfig = {
      'food': PortGoodsConfig(alpha: 0.04, s0: 550),
      'wood': PortGoodsConfig(alpha: 0.03, s0: 600),
      'spice': PortGoodsConfig(alpha: 0.15, s0: 20), // 香料港对香料价格更敏感
      'metal': PortGoodsConfig(alpha: 0.04, s0: 500),
    };
    
    final port1 = Port(
      id: 'port_1',
      name: '起始港',
      backgroundImage: 'assets/ports/port_1.png',
      description: '一个宁静的小港口，适合新手开始贸易之旅',
      distances: {
        'port_2': 192, // 1天 = 24小时 = 24 * 8 = 192节
        'port_3': 384, // 2天 = 48小时 = 48 * 8 = 384节
      },
      goodsConfig: port1GoodsConfig,
    );
    
    final port2 = Port(
      id: 'port_2',
      name: '贸易港',
      backgroundImage: 'assets/ports/port_2.png',
      description: '繁华的贸易中心，商品种类丰富',
      distances: {
        'port_1': 192, // 1天 = 192节
        'port_3': 216, // 1天3小时 = 27小时 = 27 * 8 = 216节
      },
      goodsConfig: port2GoodsConfig,
    );
    
    final port3 = Port(
      id: 'port_3',
      name: '香料港',
      backgroundImage: 'assets/ports/port_3.png',
      description: '以香料贸易闻名的港口',
      distances: {
        'port_1': 384, // 2天 = 384节
        'port_2': 216, // 1天3小时 = 216节
      },
      goodsConfig: port3GoodsConfig,
    );
    
    final ports = [port1, port2, port3];
    
    _gameState.initialize(ports, startingPort: ports.first);
    
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

