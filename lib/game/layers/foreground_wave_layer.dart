import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../game_state.dart';

/// 前景波浪层 - 位于船和岛屿之后的前景波浪
/// 在航行时（isAtSea == true）会向左滚动，模拟船只向前航行的感觉
class ForegroundWaveLayer extends StatefulWidget {
  final GameState gameState;

  const ForegroundWaveLayer({
    super.key,
    required this.gameState,
  });

  @override
  State<ForegroundWaveLayer> createState() => _ForegroundWaveLayerState();
}

/// 前景波浪层配置
class _ForegroundWaveLayerConfig {
  final String assetPath;
  final double speedMultiplier; // 相对于基础速度的倍数
  final double yOffset; // 垂直位置偏移（像素）

  _ForegroundWaveLayerConfig({
    required this.assetPath,
    required this.speedMultiplier,
    required this.yOffset,
  });
}

class _ForegroundWaveLayerState extends State<ForegroundWaveLayer> {
  // 前景波浪层配置（越靠前越快，但速度已降低）
  static final List<_ForegroundWaveLayerConfig> _layers = [
    // underwater (前景层)
    _ForegroundWaveLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_underwater.png',
      speedMultiplier: 1.5, // 降低速度
      yOffset: 150.0, // 下移150px
    ),
    // wave2_duplicate (前景波浪，向下150px)
    _ForegroundWaveLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_wave2.png',
      speedMultiplier: 1.2, // 降低速度
      yOffset: 150.0, // 向下150像素
    ),
    // wave1_duplicate (前景波浪，向下150px)
    _ForegroundWaveLayerConfig(
      assetPath: 'assets/images/background/oceanbg_0_wave1.png',
      speedMultiplier: 1.5, // 降低速度
      yOffset: 150.0, // 向下150像素
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
              return Stack(
                children: [
                  // 渲染前景波浪层（从底到顶）
                  // 顺序：underwater, wave2_duplicate, wave1_duplicate
                  for (int i = 0; i < _layers.length; i++)
                    _buildLayer(
                      i,
                      _layers[i],
                      displayWidth,
                      screenHeight,
                      widget.gameState,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// 构建单个前景波浪层（包含三张图片实现无缝循环）
  Widget _buildLayer(
    int layerIndex,
    _ForegroundWaveLayerConfig config,
    double displayWidth,
    double screenHeight,
    GameState gameState,
  ) {
    // 计算滚动偏移（背景向左移动，所以是负值）
    // 使用集中管理的 totalSailingOffset
    // 应用随机初始偏移，防止所有层一开始都对齐
    double initialOffset = _randomInitialOffsets[layerIndex] * displayWidth;
    double scrollOffset = -(gameState.totalSailingOffset * config.speedMultiplier + initialOffset);
    
    // 实现无缝循环：确保 scrollOffset 在 [-displayWidth, 0] 范围内
    if (displayWidth > 0) {
      scrollOffset = scrollOffset % displayWidth;
      if (scrollOffset > 0) scrollOffset -= displayWidth;
    }

    // 计算晃动偏移（视差规则：近大远小）
    // 左右晃动频率 2.0 rad/s，幅度 4 像素
    final swayX = math.sin(gameState.swayTime * 2.0) * (4.0 * config.speedMultiplier);
    // 上下浮动频率 1.2 rad/s，幅度 3 像素（减少浮动幅度，使其更自然）
    final swayY = math.sin(gameState.swayTime * 1.2) * (3.0 * config.speedMultiplier);

    return Stack(
      children: [
        // 使用三张相同的图片实现无缝循环
        // 图片1：左侧
        _buildWaveImage(
          config.assetPath,
          displayWidth,
          screenHeight,
          -displayWidth + scrollOffset + swayX,
          config.yOffset + swayY,
        ),
        // 图片2：中间
        _buildWaveImage(
          config.assetPath,
          displayWidth,
          screenHeight,
          scrollOffset + swayX,
          config.yOffset + swayY,
        ),
        // 图片3：右侧
        _buildWaveImage(
          config.assetPath,
          displayWidth,
          screenHeight,
          displayWidth + scrollOffset + swayX,
          config.yOffset + swayY,
        ),
      ],
    );
  }

  /// 构建单个前景波浪图片
  Widget _buildWaveImage(
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
          debugPrint('Failed to load foreground wave layer: $assetPath - $error');
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

