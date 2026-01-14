import 'package:flutter/material.dart';

/// 序列帧动画播放器
/// 负责加载并按顺序播放指定路径下的图片序列
class FrameAnimationWidget extends StatefulWidget {
  final String basePath;
  final int frameCount;
  final Duration frameDuration;
  final VoidCallback? onComplete;
  final bool loop;
  final double? width;
  final double? height;

  const FrameAnimationWidget({
    super.key,
    required this.basePath,
    required this.frameCount,
    this.frameDuration = const Duration(milliseconds: 33), // 约30fps
    this.onComplete,
    this.loop = false,
    this.width,
    this.height,
  });

  @override
  State<FrameAnimationWidget> createState() => _FrameAnimationWidgetState();
}

class _FrameAnimationWidgetState extends State<FrameAnimationWidget> {
  int _currentFrame = 1;
  late final Stream<int> _frameStream;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _frameStream = Stream<int>.periodic(widget.frameDuration, (count) => count + 1);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _frameStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          int frame = snapshot.data!;
          if (frame > widget.frameCount) {
            if (widget.loop) {
              frame = (frame - 1) % widget.frameCount + 1;
            } else {
              frame = widget.frameCount;
              if (!_isCompleted) {
                _isCompleted = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onComplete?.call();
                });
              }
            }
          }
          _currentFrame = frame;
        }

        return Image.asset(
          '${widget.basePath}$_currentFrame.png',
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          // 像素风保持清晰
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
        );
      },
    );
  }
}
