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

class _BackgroundLayerState extends State<BackgroundLayer> {
  // 滚动速度（像素/秒）
  static const double _scrollSpeed = 50.0;

  // 当前滚动偏移量（像素）
  double _scrollOffset = 0.0;

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
          // 更新滚动偏移量（背景向左移动，所以偏移量减少）
          _scrollOffset -= _scrollSpeed * dt;

          // 如果图片宽度已确定，实现无缝循环
          if (_imageWidth != null && _imageWidth! > 0) {
            // 当偏移量小于负的图片宽度时，加上图片宽度，实现无缝循环
            while (_scrollOffset <= -_imageWidth!) {
              _scrollOffset += _imageWidth!;
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
                  // 使用三张相同的图片实现无缝循环
                  // 图片1：左侧
                  _buildBackgroundImage(
                    displayWidth,
                    screenHeight,
                    -displayWidth + _scrollOffset,
                  ),
                  // 图片2：中间
                  _buildBackgroundImage(
                    displayWidth,
                    screenHeight,
                    _scrollOffset,
                  ),
                  // 图片3：右侧
                  _buildBackgroundImage(
                    displayWidth,
                    screenHeight,
                    displayWidth + _scrollOffset,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundImage(
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
        'assets/images/background/oceanbg_0.png',
        fit: BoxFit.cover,
        width: displayWidth,
        height: screenHeight,
        errorBuilder: (context, error, stackTrace) {
          // 图片加载失败时返回空容器（使用上面的渐变背景）
          debugPrint('Failed to load ocean background: $error');
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
