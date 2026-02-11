import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/port.dart';
import '../game_state.dart';
import '../../utils/day_night_visual_utils.dart';

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
  
  // 屏幕宽度
  double _screenWidth = 0.0;
  
  // 缓存加载失败的图像路径
  static final Set<String> _failedImagePaths = {};

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didUpdateWidget(NearBackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
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
            final previousPort = widget.gameState.previousPort;
            final destinationPort = widget.gameState.destinationPort;
            final progress = widget.gameState.dayNightSystem.dayCycleProgress;
            final colorFilter = DayNightVisualUtils.getColorFilter(progress, layerType: VisualLayerType.island);

            // 计算离开动画的偏移量和缩放
            double? exitOffset;
            double? exitScale;
            if (isAtSea && previousPort != null) {
              // 直接使用 accumulatedDistance，在切换目的地时它不再归零，因此动画会平滑继续
              final exitDistance = widget.gameState.accumulatedDistance;
              
              final currentSpeed = widget.gameState.currentSpeed;
              if (currentSpeed > 0) {
                final timeElapsedHours = exitDistance / currentSpeed;
                // 动态滚动速度与当前航速正相关
                final dynamicScrollSpeed = _scrollSpeed * (currentSpeed / 8.0);
                exitOffset = -timeElapsedHours * dynamicScrollSpeed;
                
                // 计算退出缩放：从 0.9 逐渐缩小到 0.7
                if (_screenWidth > 0) {
                  final progress = (exitOffset.abs() / _screenWidth).clamp(0.0, 1.0);
                  exitScale = 0.9 - (0.2 * progress);
                }
              }
            }

            // 计算进入动画的偏移量和缩放
            double? enterOffset;
            double? enterScale;
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
                
                // 计算进入缩放：从 0.7 逐渐放大到 0.9
                if (_screenWidth > 0) {
                  final progress = (1.0 - (enterOffset / _screenWidth)).clamp(0.0, 1.0);
                  enterScale = 0.7 + (0.2 * progress);
                }
              }
            }

            return ColorFiltered(
              colorFilter: colorFilter,
              child: Stack(
                children: [
                  // 正在离开的港口（基于航行进度）
                  if (exitOffset != null && previousPort != null && exitOffset > -_screenWidth)
                    Positioned(
                      left: exitOffset,
                      top: 0,
                      right: null,
                      bottom: 0,
                      child: SizedBox(
                        width: _screenWidth,
                        child: _buildPortImage(previousPort, scale: exitScale),
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
                        child: _buildPortImage(destinationPort, scale: enterScale),
                      ),
                    ),
                  
                  // 静态显示（不在海上且没有进行中的进入动画）
                  if (!isAtSea && currentPort != null)
                    _buildPortImage(currentPort),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPortImage(Port port, {double? scale}) {
    final imagePath = port.backgroundImage;
    
    if (_failedImagePaths.contains(imagePath)) {
      return _buildPlaceholder();
    }
    
    return SizedBox.expand(
      child: Transform.scale(
        scale: scale ?? widget.gameState.islandScale,
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
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
