import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../game_state.dart';

/// 船层 - 船只，支持战斗模式
class ShipLayer extends StatefulWidget {
  final GameState gameState;

  const ShipLayer({
    super.key,
    required this.gameState,
  });

  @override
  State<ShipLayer> createState() => _ShipLayerState();
}

class _ShipLayerState extends State<ShipLayer>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  
  // 敌方船只滑入动画
  AnimationController? _enemySlideController;
  Animation<Offset>? _enemySlideAnimation;
  
  // 沉船动画
  AnimationController? _sinkingController;
  Animation<double>? _sinkingAnimation;

  // 玩家归位动画
  AnimationController? _playerReturnController;
  Animation<double>? _playerReturnAnimation;

  // 玩家进入战斗动画
  AnimationController? _playerEnterController;
  Animation<double>? _playerEnterAnimation;
  
  // 缓存加载失败的图像路径，避免重复尝试
  static final Set<String> _failedImagePaths = {};

  @override
  void initState() {
    super.initState();
    
    // 玩家船只呼吸动画
    _breathingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    // 监听战斗状态变化
    widget.gameState.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_onGameStateChanged);
    _breathingController.dispose();
    _enemySlideController?.dispose();
    _sinkingController?.dispose();
    _playerReturnController?.dispose();
    _playerEnterController?.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    if (!mounted) return;

    // 处理敌方船只滑入动画
    if (widget.gameState.isInCombat && _enemySlideController == null) {
      _startEnemySlideAnimation();
    } else if (!widget.gameState.isInCombat && _enemySlideController != null) {
      _enemySlideController?.dispose();
      _enemySlideController = null;
      _enemySlideAnimation = null;
    }

    // 处理玩家进入战斗动画
    if (widget.gameState.isEnteringCombat && _playerEnterController == null) {
      _startPlayerEnterAnimation();
    } else if (!widget.gameState.isEnteringCombat && _playerEnterController != null) {
      _playerEnterController?.dispose();
      _playerEnterController = null;
      _playerEnterAnimation = null;
    }

    // 处理沉船动画
    if (widget.gameState.isSinking && _sinkingController == null) {
      _startSinkingAnimation();
    } else if (!widget.gameState.isSinking && _sinkingController != null) {
      // 沉船动画结束后清理
      _sinkingController?.dispose();
      _sinkingController = null;
      _sinkingAnimation = null;
    }

    // 处理玩家归位动画
    if (widget.gameState.isReturningFromCombat && _playerReturnController == null) {
      _startPlayerReturnAnimation();
    } else if (!widget.gameState.isReturningFromCombat && _playerReturnController != null) {
      _playerReturnController?.dispose();
      _playerReturnController = null;
      _playerReturnAnimation = null;
    }
  }

  void _startEnemySlideAnimation() {
    _enemySlideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _enemySlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // 从右侧屏幕外
      end: Offset.zero, // 正常位置
    ).animate(CurvedAnimation(
      parent: _enemySlideController!,
      curve: Curves.easeInOut,
    ));

    _enemySlideController!.forward();
  }

  void _startPlayerEnterAnimation() {
    _playerEnterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _playerEnterAnimation = Tween<double>(
      begin: 0.0,
      end: -150.0,
    ).animate(CurvedAnimation(
      parent: _playerEnterController!,
      curve: Curves.easeInOut,
    ));

    _playerEnterController!.forward();
  }

  void _startSinkingAnimation() {
    _sinkingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _sinkingAnimation = Tween<double>(
      begin: 0.0,
      end: 800.0, // 向下移动800像素（足够移出屏幕）
    ).animate(CurvedAnimation(
      parent: _sinkingController!,
      curve: Curves.easeIn,
    ));

    _sinkingController!.forward();
  }

  void _startPlayerReturnAnimation() {
    _playerReturnController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _playerReturnAnimation = Tween<double>(
      begin: -150.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _playerReturnController!,
      curve: Curves.easeInOut,
    ));

    _playerReturnController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 AnimatedBuilder 监听 GameState 的变化，确保实时更新
    return AnimatedBuilder(
      animation: widget.gameState,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        
        return Stack(
          children: [
            // 玩家船只
            _buildPlayerShip(screenSize),
            
            // 敌方船只（战斗时显示）
            if (widget.gameState.isInCombat && widget.gameState.enemyShip != null)
              _buildEnemyShip(screenSize),
          ],
        );
      },
    );
  }

  /// 构建玩家船只
  Widget _buildPlayerShip(Size screenSize) {
    // 如果正在进入战斗且动画已初始化，使用动画值
    if (widget.gameState.isEnteringCombat && _playerEnterAnimation != null) {
      return AnimatedBuilder(
        animation: _playerEnterAnimation!,
        builder: (context, child) {
          return _buildPlayerShipAtPosition(screenSize, _playerEnterAnimation!.value);
        },
      );
    }

    // 如果正在归位且动画已初始化，使用动画值
    if (widget.gameState.isReturningFromCombat && _playerReturnAnimation != null) {
      return AnimatedBuilder(
        animation: _playerReturnAnimation!,
        builder: (context, child) {
          return _buildPlayerShipAtPosition(screenSize, _playerReturnAnimation!.value);
        },
      );
    }
    
    // 否则使用状态中的偏移值
    return _buildPlayerShipAtPosition(screenSize, widget.gameState.playerShipXOffset);
  }

  /// 在指定位置构建玩家船只
  Widget _buildPlayerShipAtPosition(Size screenSize, double xOffset) {
    // 动画位移
    double animateY = _breathingAnimation.value * widget.gameState.waveAmplitudeMultiplier;
    if (widget.gameState.isSinking && widget.gameState.isPlayerSinking) {
      animateY += _sinkingAnimation?.value ?? 0.0;
    }

    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(xOffset, animateY),
        child: _buildShipImage(
          widget.gameState.ship.appearance,
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  /// 构建敌方船只
  Widget _buildEnemyShip(Size screenSize) {
    // 计算敌方船只位置
    // 向右移动150像素，与玩家船只对称（玩家向左150，敌方向右150）
    final slideX = (_enemySlideAnimation != null) ? (_enemySlideAnimation!.value.dx * screenSize.width) : 0.0;
    double xOffset = 150.0 + slideX;
    
    // 动画位移 (呼吸动画 + 沉船动画)
    double animateY = _breathingAnimation.value * widget.gameState.waveAmplitudeMultiplier;
    
    // 如果敌方正在沉船，添加沉船动画
    if (widget.gameState.isSinking && !widget.gameState.isPlayerSinking) {
      animateY += _sinkingAnimation?.value ?? 0.0;
    }

    return Positioned.fill(
      child: Stack(
        children: [
          // 敌方船只图片 - 全屏
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(xOffset, animateY),
              child: Transform.scale(
                scaleX: -1,
                child: _buildShipImage(
                  widget.gameState.enemyShip?.appearance ?? 'assets/images/ships/single_sail_0.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          // 敌方船只信息（显示在图片上方）
          Positioned(
            left: screenSize.width / 2 + xOffset - 100,
            top: screenSize.height / 2 - 100, // 与原位置相近
            child: _buildEnemyShipInfo(),
          ),
        ],
      ),
    );
  }

  /// 构建敌方船只信息（简单2排字）
  Widget _buildEnemyShipInfo() {
    final enemyShip = widget.gameState.enemyShip;
    if (enemyShip == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一行：血量
          Text(
            '${enemyShip.durability}/${enemyShip.maxDurability}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 第二行：攻击频率和修复频率
          Text(
            '${enemyShip.fireRatePerSecond.toStringAsFixed(1)}炮/秒  ${enemyShip.repairRatePerSecond.toStringAsFixed(1)}修/秒',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建船只图片
  Widget _buildShipImage(String imagePath, {BoxFit fit = BoxFit.contain}) {
    // 如果这个路径之前加载失败过，直接返回备用显示
    if (_failedImagePaths.contains(imagePath)) {
      return _buildShipPlaceholder();
    }
    
    return Image.asset(
      imagePath,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        // 只打印一次错误，并缓存失败的路径
        if (!_failedImagePaths.contains(imagePath)) {
          _failedImagePaths.add(imagePath);
          debugPrint('Failed to load ship image: $imagePath');
          debugPrint('Error: $error');
          if (kDebugMode) {
            debugPrint('Stack trace: $stackTrace');
          }
        }
        return _buildShipPlaceholder();
      },
    );
  }
  
  /// 构建船只占位符
  Widget _buildShipPlaceholder() {
    return Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 船体
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF654321),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              // 船帆
              Positioned(
                top: 10,
                left: 50,
                child: Container(
                  width: 20,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8DC),
                    border: Border.all(color: Colors.brown, width: 2),
                  ),
                ),
              ),
            ],
          ),
        );
  }
}
