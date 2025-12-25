import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../game_state.dart';

/// 背景层 - 远距离背景（海洋背景）
/// 在航行时（isAtSea == true）会向左滚动，模拟船只向前航行的感觉
class BackgroundLayer extends StatefulWidget {
  final GameState gameState;

  const BackgroundLayer({
    super.key,
    required this.gameState,
  });

  @override
  State<BackgroundLayer> createState() => _BackgroundLayerState();
}

/// 背景层配置
class _BackgroundLayerConfig {
  final String assetPath;
  final double speedMultiplier; // 相对于基础速度的倍数

  _BackgroundLayerConfig({
    required this.assetPath,
    required this.speedMultiplier,
  });
}

class _BackgroundLayerState extends State<BackgroundLayer> {
  // 基础滚动速度（像素/秒）
  static const double _baseScrollSpeed = 50.0;

  // 渲染顺序：从底到顶（Stack 中先添加的在底层）
  // 用户要求的顺序（从最顶到最底）：cloud1, cloud2, cloud3, wave1, wave2, wave3, underwater, background
  // 所以在 Stack 中从底到顶应该是：background, underwater, wave3, wave2, wave1, cloud3, cloud2, cloud1
  static final List<_BackgroundLayerConfig> _layers = [
    // 最底层：background (渐变背景，在 Container decoration 中)
    // 第1层：underwater (从底数第2层)
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_underwater.png',
      speedMultiplier: 2.0, // 最快
    ),
    // 第2层：wave3
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_wave3.png',
      speedMultiplier: 1.0, // 最慢
    ),
    // 第3层：wave2
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_wave2.png',
      speedMultiplier: 1.5, // 中等
    ),
    // 第4层：wave1
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_wave1.png',
      speedMultiplier: 2.0, // 最快
    ),
    // 第5层：cloud3
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_cloud3.png',
      speedMultiplier: 1.0, // 最慢
    ),
    // 第6层：cloud2
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_cloud2.png',
      speedMultiplier: 1.5, // 中等
    ),
    // 第7层：cloud1 (最顶层)
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_cloud1.png',
      speedMultiplier: 2.0, // 最快
    ),
  ];

  // 每个层的滚动偏移量（像素）
  late List<double> _scrollOffsets;

  // 图片显示宽度（根据屏幕高度和图片宽高比计算）
  // 根据设计文档，背景图片是 1920x1080 (16:9)
  double? _imageWidth;

  // Ticker 用于每帧更新
  Ticker? _ticker;

  // 上次更新时间
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    // 初始化所有层的偏移量为0
    _scrollOffsets = List.filled(_layers.length, 0.0);
    // 监听 GameState 的变化
    widget.gameState.addListener(_onGameStateChanged);
    // 初始化时检查是否需要开始滚动
    _updateScrollState();
  }

  @override
  void didUpdateWidget(BackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 gameState 引用改变，需要重新监听
    if (oldWidget.gameState != widget.gameState) {
      oldWidget.gameState.removeListener(_onGameStateChanged);
      widget.gameState.addListener(_onGameStateChanged);
      _updateScrollState();
    }
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_onGameStateChanged);
    _ticker?.stop();
    _ticker?.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    // GameState 变化时更新滚动状态
    if (mounted) {
      _updateScrollState();
    }
  }

  void _updateScrollState() {
    if (widget.gameState.isAtSea) {
      // 在海上，开始滚动
      _startScrolling();
    } else {
      // 不在海上，停止滚动
      _stopScrolling();
    }
  }

  void _startScrolling() {
    if (_ticker != null && _ticker!.isActive) {
      return; // 已经在滚动
    }

    _lastUpdateTime = DateTime.now();
    _ticker = Ticker((elapsed) {
      if (_lastUpdateTime == null) {
        _lastUpdateTime = DateTime.now();
        return;
      }

      final now = DateTime.now();
      final dt = now.difference(_lastUpdateTime!).inMilliseconds / 1000.0;
      _lastUpdateTime = now;

      if (mounted && widget.gameState.isAtSea) {
        setState(() {
          // 更新所有层的滚动偏移量（背景向左移动，所以偏移量减少）
          for (int i = 0; i < _layers.length; i++) {
            final layerSpeed = _baseScrollSpeed * _layers[i].speedMultiplier;
            _scrollOffsets[i] -= layerSpeed * dt;

            // 如果图片宽度已确定，实现无缝循环
            if (_imageWidth != null && _imageWidth! > 0) {
              // 当偏移量小于负的图片宽度时，加上图片宽度，实现无缝循环
              while (_scrollOffsets[i] <= -_imageWidth!) {
                _scrollOffsets[i] += _imageWidth!;
              }
            }
          }
        });
      }
    });
    _ticker!.start();
  }

  void _stopScrolling() {
    _ticker?.stop();
    _lastUpdateTime = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;

        // 根据设计文档，背景图片是 1920x1080 (16:9)
        // 计算实际显示的图片宽度（基于屏幕高度）
        const double imageAspectRatio = 1920.0 / 1080.0; // 16:9
        final displayWidth = _imageWidth ?? (screenHeight * imageAspectRatio);
        
        // 如果图片宽度还未初始化，设置它
        if (_imageWidth == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _imageWidth = displayWidth;
              });
            }
          });
        }

        return RepaintBoundary(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              // 备用渐变背景（如果图片加载失败）
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF87CEEB), // 天空蓝
                  const Color(0xFF4682B4), // 钢蓝色
                  const Color(0xFF1E90FF), // 道奇蓝
                ],
              ),
            ),
            child: ClipRect(
              child: Stack(
                children: [
                  // 渲染所有背景层（从底到顶）
                  // 顺序：underwater, wave3, wave2, wave1, cloud3, cloud2, cloud1
                  for (int i = 0; i < _layers.length; i++)
                    _buildLayer(
                      _layers[i],
                      displayWidth,
                      screenHeight,
                      _scrollOffsets[i],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建单个背景层（包含三张图片实现无缝循环）
  Widget _buildLayer(
    _BackgroundLayerConfig config,
    double displayWidth,
    double screenHeight,
    double scrollOffset,
  ) {
    return Stack(
      children: [
        // 使用三张相同的图片实现无缝循环
        // 图片1：左侧
        _buildBackgroundImage(
          config.assetPath,
          displayWidth,
          screenHeight,
          -displayWidth + scrollOffset,
        ),
        // 图片2：中间
        _buildBackgroundImage(
          config.assetPath,
          displayWidth,
          screenHeight,
          scrollOffset,
        ),
        // 图片3：右侧
        _buildBackgroundImage(
          config.assetPath,
          displayWidth,
          screenHeight,
          displayWidth + scrollOffset,
        ),
      ],
    );
  }

  /// 构建单个背景图片
  Widget _buildBackgroundImage(
    String assetPath,
    double displayWidth,
    double screenHeight,
    double xOffset,
  ) {
    return Positioned(
      left: xOffset,
      top: 0,
      width: displayWidth,
      height: screenHeight,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: displayWidth,
        height: screenHeight,
        errorBuilder: (context, error, stackTrace) {
          // 图片加载失败时返回空容器（不影响其他层）
          debugPrint('Failed to load background layer: $assetPath - $error');
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
