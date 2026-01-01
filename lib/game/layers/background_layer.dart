import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../game_state.dart';
import 'celestial_layer.dart';

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
  final double baseDriftSpeed; // 基础漂移速度（像素/秒，船不动时也会移动）

  _BackgroundLayerConfig({
    required this.assetPath,
    required this.speedMultiplier,
    this.baseDriftSpeed = 0.0,
  });
}

class _BackgroundLayerState extends State<BackgroundLayer> {
  // 渲染顺序：从底到顶（Stack 中先添加的在底层）
  // 用户要求的顺序（从最顶到最底）：cloud1, cloud2, cloud3, wave1, wave2, wave3, underwater, background
  // 所以在 Stack 中从底到顶应该是：background, underwater, wave3, wave2, wave1, cloud3, cloud2, cloud1
  static final List<_BackgroundLayerConfig> _layers = [
    // 最底层：background (渐变背景，在 Container decoration 中)
    // 第1层：underwater (从底数第2层)
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_underwater.png',
      speedMultiplier: 0.5, // 慢（背景层）
    ),
    // 第2层：wave3
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_wave3.png',
      speedMultiplier: 0.3, // 最慢（背景层）
    ),
    // 第3层：wave2
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_wave2.png',
      speedMultiplier: 0.7, // 慢（背景层）
    ),
    // 第4层：wave1
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_wave1.png',
      speedMultiplier: 0.8, // 慢（背景层）
    ),
    // 第5层：cloud3
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_cloud3.png',
      speedMultiplier: 0.3, // 最慢（背景层）
      baseDriftSpeed: 5.0, // 基础漂移速度
    ),
    // 第6层：cloud2
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_cloud2.png',
      speedMultiplier: 0.5, // 慢（背景层）
      baseDriftSpeed: 8.0, // 基础漂移速度
    ),
    // 第7层：cloud1 (最顶层)
    _BackgroundLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_cloud1.png',
      speedMultiplier: 0.7, // 慢（背景层）
      baseDriftSpeed: 12.0, // 基础漂移速度
    ),
  ];

  // 随机初始水平偏移量（0.0 到 1.0 之间，相对于图片宽度的倍数）
  final List<double> _randomInitialOffsets = [];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    for (int i = 0; i < _layers.length; i++) {
      _randomInitialOffsets.add(random.nextDouble());
    }
  }

  // 图片显示宽度（根据屏幕高度和图片宽高比计算）
  // 根据设计文档，背景图片是 1920x1080 (16:9)
  double? _imageWidth;

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
          child: ListenableBuilder(
            listenable: widget.gameState,
            builder: (context, child) {
              return Container(
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
                      // 顺序：underwater, 天体层, wave3, wave2, wave1, cloud3, cloud2, cloud1
                      
                      // 第1层：underwater
                      _buildLayer(
                        0,
                        _layers[0],
                        displayWidth,
                        screenHeight,
                        widget.gameState,
                      ),

                      // Layer 0.5: 天体层（太阳/月亮，插入在海底背景之上，但在海浪和云朵之下）
                      CelestialLayer(gameState: widget.gameState),

                      // 其余层：wave3 到 cloud1
                      for (int i = 1; i < _layers.length; i++)
                        _buildLayer(
                          i,
                          _layers[i],
                          displayWidth,
                          screenHeight,
                          widget.gameState,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建单个背景层（包含三张图片实现无缝循环）
  Widget _buildLayer(
    int layerIndex,
    _BackgroundLayerConfig config,
    double displayWidth,
    double screenHeight,
    GameState gameState,
  ) {
    // 计算滚动偏移（背景向左移动，所以是负值）
    // 使用集中管理的 totalSailingOffset
    // 应用随机初始偏移，防止所有层一开始都对齐
    // 叠加常驻漂移速度（baseDriftSpeed * swayTime）
    double initialOffset = _randomInitialOffsets[layerIndex] * displayWidth;
    double scrollOffset = -(gameState.totalSailingOffset * config.speedMultiplier + 
                           gameState.swayTime * config.baseDriftSpeed + 
                           initialOffset);
    
    // 实现无缝循环：确保 scrollOffset 在 [-displayWidth, 0] 范围内
    if (displayWidth > 0) {
      scrollOffset = scrollOffset % displayWidth;
      if (scrollOffset > 0) scrollOffset -= displayWidth;
    }

    // 计算晃动偏移（视差规则：近大远小）
    // 左右晃动频率 2.0 rad/s，基础幅度 2 像素
    final swayX = math.sin(gameState.swayTime * 2.0) * (2.0 * config.speedMultiplier);
    // 上下浮动频率 1.2 rad/s，基础幅度 1.5 像素（同步减少，保持视差比例）
    final swayY = math.sin(gameState.swayTime * 1.2) * (1.5 * config.speedMultiplier * gameState.waveAmplitudeMultiplier);

    return Stack(
      children: [
        // 使用三张相同的图片实现无缝循环
        // 图片1：左侧
        _buildBackgroundImage(
          config.assetPath,
          displayWidth,
          screenHeight,
          -displayWidth + scrollOffset + swayX,
          swayY,
        ),
        // 图片2：中间
        _buildBackgroundImage(
          config.assetPath,
          displayWidth,
          screenHeight,
          scrollOffset + swayX,
          swayY,
        ),
        // 图片3：右侧
        _buildBackgroundImage(
          config.assetPath,
          displayWidth,
          screenHeight,
          displayWidth + scrollOffset + swayX,
          swayY,
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
    double yOffset,
  ) {
    return Positioned(
      left: xOffset,
      top: yOffset,
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
