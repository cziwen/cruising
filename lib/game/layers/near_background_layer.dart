import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/port.dart';
import '../game_state.dart';

/// 近背景层 - 近距离背景（港口、岛屿等可切换元素）
/// 港口滚动速度与背景层 wave1 一致（40 像素/秒）
class NearBackgroundLayer extends StatefulWidget {
  final GameState gameState;

  const NearBackgroundLayer({
    super.key,
    required this.gameState,
  });

  @override
  State<NearBackgroundLayer> createState() => _NearBackgroundLayerState();
}

class _NearBackgroundLayerState extends State<NearBackgroundLayer> {
  // 与背景层 wave1 相同的速度: 50.0 * 0.8 = 40 像素/秒
  static const double _scrollSpeed = 40.0;
  
  // 上一次记录的港口（用于离开动画）
  Port? _lastPort;
  
  // 屏幕宽度
  double _screenWidth = 0.0;
  
  // 缓存加载失败的图像路径
  static final Set<String> _failedImagePaths = {};

  @override
  void initState() {
    super.initState();
    _lastPort = widget.gameState.currentPort;
    widget.gameState.addListener(_handleStateChange);
  }

  void _handleStateChange() {
    if (widget.gameState.currentPort != null) {
      _lastPort = widget.gameState.currentPort;
    }
    // 由于 build 中使用了 AnimatedBuilder，这里不需要手动调用 setState
  }
  
  @override
  void didUpdateWidget(NearBackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameState != widget.gameState) {
      oldWidget.gameState.removeListener(_handleStateChange);
      widget.gameState.addListener(_handleStateChange);
    }
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_handleStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenWidth = constraints.maxWidth;
        
        return AnimatedBuilder(
          animation: widget.gameState,
          builder: (context, child) {
            final isAtSea = widget.gameState.isAtSea;
            final currentPort = widget.gameState.currentPort;
            final destinationPort = widget.gameState.destinationPort;

            // 计算离开动画的偏移量
            double? exitOffset;
            if (isAtSea && _lastPort != null) {
              final accumulatedDistance = widget.gameState.accumulatedDistance;
              final currentSpeed = widget.gameState.currentSpeed;
              if (currentSpeed > 0) {
                final timeElapsedHours = accumulatedDistance / currentSpeed;
                // 动态滚动速度与当前航速正相关
                final dynamicScrollSpeed = _scrollSpeed * (currentSpeed / 8.0);
                exitOffset = -timeElapsedHours * dynamicScrollSpeed;
              }
            }

            // 计算进入动画的偏移量
            double? enterOffset;
            if (isAtSea && destinationPort != null) {
              final totalDistance = widget.gameState.totalTravelDistance;
              final accumulatedDistance = widget.gameState.accumulatedDistance;
              final currentSpeed = widget.gameState.currentSpeed;
              
              if (totalDistance > 0 && currentSpeed > 0) {
                final remainingDistance = totalDistance - accumulatedDistance;
                // 1现实秒 = 1游戏小时，所以剩余时间（小时）即为剩余时间（秒）
                final remainingTimeSeconds = remainingDistance / currentSpeed;
                // 动态滚动速度与当前航速正相关
                final dynamicScrollSpeed = _scrollSpeed * (currentSpeed / 8.0);
                enterOffset = remainingTimeSeconds * dynamicScrollSpeed;
              }
            }

            return Stack(
              children: [
                // 正在离开的港口（基于航行进度）
                if (exitOffset != null && _lastPort != null && exitOffset > -_screenWidth)
                  Positioned(
                    left: exitOffset,
                    top: 0,
                    right: null,
                    bottom: 0,
                    child: SizedBox(
                      width: _screenWidth,
                      child: _buildPortImage(_lastPort!),
                    ),
                  ),
                
                // 正在接近的港口（基于航行进度）
                if (enterOffset != null && destinationPort != null && enterOffset < _screenWidth)
                  Positioned(
                    left: enterOffset,
                    top: 0,
                    right: null,
                    bottom: 0,
                    child: SizedBox(
                      width: _screenWidth,
                      child: _buildPortImage(destinationPort),
                    ),
                  ),
                
                // 静态显示（不在海上且没有进行中的进入动画）
                if (!isAtSea && currentPort != null)
                  _buildPortImage(currentPort),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPortImage(Port port) {
    final imagePath = port.backgroundImage;
    
    if (_failedImagePaths.contains(imagePath)) {
      return _buildPlaceholder();
    }
    
    return SizedBox.expand(
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          if (!_failedImagePaths.contains(imagePath)) {
            _failedImagePaths.add(imagePath);
            debugPrint('Failed to load port image: $imagePath');
            if (kDebugMode) {
              debugPrint('Error: $error');
            }
          }
          return _buildPlaceholder();
        },
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return SizedBox.expand(
      child: Container(
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
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.landscape, size: 60, color: Colors.brown.shade700),
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
      ),
    );
  }
}
