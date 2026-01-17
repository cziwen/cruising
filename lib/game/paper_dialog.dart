import 'package:flutter/material.dart';
import '../systems/music_system.dart';

/// 纸质风格对话框包装器
class PaperDialog extends StatefulWidget {
  final Widget child;
  final String assetPath;
  final double? width;
  final double? height;
  final EdgeInsets padding;

  const PaperDialog({
    super.key,
    required this.child,
    required this.assetPath,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(40.0), // 默认内边距以避开纸张边缘
  });

  @override
  State<PaperDialog> createState() => _PaperDialogState();
}

class _PaperDialogState extends State<PaperDialog> {
  @override
  void initState() {
    super.initState();
    // 播放打开面板音效
    MusicSystem().playSFX('panel_open');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        key: widget.key, // 将 Key 绑定到内部 Container
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(widget.assetPath),
            fit: BoxFit.fill,
          ),
        ),
        padding: widget.padding,
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFF4E342E), // 深褐色，适合纸张背景
            fontSize: 16,
            fontFamily: 'Roboto', // 或者游戏使用的像素字体
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
