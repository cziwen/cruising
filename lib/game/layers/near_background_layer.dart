import 'package:flutter/material.dart';
import '../../models/port.dart';

/// 近背景层 - 近距离背景（港口、岛屿等可切换元素）
class NearBackgroundLayer extends StatefulWidget {
  final Port? currentPort;
  final bool isTransitioning;
  final bool isAtSea;

  const NearBackgroundLayer({
    super.key,
    required this.currentPort,
    this.isTransitioning = false,
    this.isAtSea = false,
  });

  @override
  State<NearBackgroundLayer> createState() => _NearBackgroundLayerState();
}

class _NearBackgroundLayerState extends State<NearBackgroundLayer>
    with SingleTickerProviderStateMixin {
  Port? _previousPort;
  Port? _nextPort;
  bool _wasAtSea = false;
  bool _willBeAtSea = false;
  late AnimationController _controller;
  late Animation<Offset> _currentAnimation;
  late Animation<Offset> _nextAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 当前背景向左移出的动画
    _currentAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0), // 向左移出屏幕
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // 新背景从右侧移入的动画
    _nextAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // 从右侧开始
      end: Offset.zero, // 移动到中心
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.currentPort != null) {
      _previousPort = widget.currentPort;
      _nextPort = null;
    }
    _wasAtSea = widget.isAtSea;
  }

  @override
  void didUpdateWidget(NearBackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 检查状态变化：港口变化或海上状态变化
    final portChanged = oldWidget.currentPort?.id != widget.currentPort?.id;
    final seaStateChanged = oldWidget.isAtSea != widget.isAtSea;
    
    if (portChanged || seaStateChanged) {
      _previousPort = oldWidget.currentPort;
      _nextPort = widget.currentPort;
      _wasAtSea = oldWidget.isAtSea;
      _willBeAtSea = widget.isAtSea;
      
      // 重置并启动动画
      _controller.reset();
      _controller.forward().then((_) {
        // 动画完成后，更新状态
        if (mounted) {
          setState(() {
            _previousPort = widget.currentPort;
            _nextPort = null;
            _wasAtSea = widget.isAtSea;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 背景层保持透明，只显示岛屿图像
    // 如果正在动画，显示岛屿切换效果
    if (_controller.isAnimating) {
      return Stack(
        children: [
          // 当前岛屿（向左移出）
          if (!_wasAtSea && _previousPort != null)
            SlideTransition(
              position: _currentAnimation,
              child: _buildIslandOnly(_previousPort!),
            ),
          // 新岛屿（从右侧移入）
          if (!_willBeAtSea && _nextPort != null)
            SlideTransition(
              position: _nextAnimation,
              child: _buildIslandOnly(_nextPort!),
            ),
        ],
      );
    }

    // 没有动画时，显示当前岛屿（如果不在海上）
    if (widget.isAtSea || widget.currentPort == null) {
      return const SizedBox.shrink();
    }

    return _buildIslandOnly(widget.currentPort!);
  }

  /// 只构建岛屿图像（不包含背景）
  Widget _buildIslandOnly(Port port) {
    return Stack(
      children: [
        // 岛屿图片 - 与船在同一水平高度
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: const Offset(0, 40), // 向下移动40像素，使岛屿底部与船中心对齐
            child: _buildIslandImage(),
          ),
        ),
      ],
    );
  }

  /// 构建岛屿图片，带错误处理
  Widget _buildIslandImage() {
    return Image.asset(
      'assets/images/coconut_tree_island.png',
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      width: 400, // 设置固定宽度，避免过宽
      height: 300,
      gaplessPlayback: true, // 避免切换时的闪烁
      filterQuality: FilterQuality.medium, // 优化性能
      errorBuilder: (context, error, stackTrace) {
        // 图片加载失败时的备用显示
        debugPrint('Failed to load island image: $error');
        debugPrint('Stack trace: $stackTrace');
        return Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF8B7355).withValues(alpha: 0.0),
                const Color(0xFF8B7355).withValues(alpha: 0.5),
                const Color(0xFF654321),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.landscape,
                  size: 60,
                  color: Colors.brown.shade700,
                ),
                const SizedBox(height: 8),
                Text(
                  '岛屿',
                  style: TextStyle(
                    color: Colors.brown.shade900,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}