import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/guidance_hint.dart';
import '../frame_animation_widget.dart';

/// 单个提示项组件
class NotificationItem extends StatefulWidget {
  final GuidanceHint hint;
  final int index;
  final VoidCallback onDismissed;

  const NotificationItem({
    super.key,
    required this.hint,
    required this.index,
    required this.onDismissed,
  });

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

enum NotificationState {
  entering,
  displayed,
  exiting,
}

class _NotificationItemState extends State<NotificationItem> {
  NotificationState _state = NotificationState.entering;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    // 入场动画延迟
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _state = NotificationState.displayed;
        });
      }
    });
  }

  @override
  void didUpdateWidget(NotificationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果系统标记该提示正在退出（由于堆栈挤压）
    if (widget.hint.isExiting && _state != NotificationState.exiting) {
      _startExitAnimation();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _handleClick() {
    if (_state == NotificationState.exiting) return;
    _startExitAnimation();
  }

  void _startExitAnimation() {
    setState(() {
      _state = NotificationState.exiting;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 提示框高度约为 80，间距 10
    const itemHeight = 90.0;
    const itemWidth = 320.0;
    
    // 入场时在右侧屏幕外
    final double rightOffset = _state == NotificationState.entering ? -itemWidth : 20.0;
    // 垂直位置根据索引计算
    final double topOffset = 60.0 + (widget.index * itemHeight);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      top: topOffset,
      right: rightOffset,
      child: GestureDetector(
        onTap: _handleClick,
        child: SizedBox(
          width: itemWidth,
          height: itemHeight,
          child: Stack(
            children: [
              // 背景或动画
              if (_state == NotificationState.exiting)
                FrameAnimationWidget(
                  basePath: 'assets/paper_ui/Sprites/Content Appear Animation/Folding & Cutout/4 Notification/1/',
                  frameCount: 23,
                  onComplete: widget.onDismissed,
                  width: itemWidth,
                  height: itemHeight,
                )
              else
                Image.asset(
                  'assets/paper_ui/Sprites/Paper UI Pack/Folding & Cutout/4 Notification/1.png',
                  width: itemWidth,
                  height: itemHeight,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),

              // 文字内容
              if (_state != NotificationState.exiting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.hint.message,
                        style: const TextStyle(
                          color: Color(0xFF4E342E),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
