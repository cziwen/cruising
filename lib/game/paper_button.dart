import 'package:flutter/material.dart';
import '../systems/music_system.dart';

enum PaperButtonStyle {
  brown,  // 0.png, 1.png
  green,  // 2.png, 3.png
  blue,   // 4.png, 5.png
  red,    // 6.png, 7.png
  gold,   // 8.png, 9.png
}

class PaperButton extends StatefulWidget {
  final String? label;
  final Widget? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final PaperButtonStyle style;
  final double? width;
  final double height;
  final EdgeInsets? padding;
  final TextStyle? textStyle;

  const PaperButton({
    super.key,
    this.label,
    this.icon,
    this.child,
    this.onPressed,
    this.style = PaperButtonStyle.brown,
    this.width = 80,
    this.height = 32,
    this.padding,
    this.textStyle,
  });

  @override
  State<PaperButton> createState() => _PaperButtonState();
}

class _PaperButtonState extends State<PaperButton> {
  bool _isPressed = false;

  String _getAssetPath() {
    int index;
    switch (widget.style) {
      case PaperButtonStyle.brown:
        index = _isPressed ? 1 : 0;
        break;
      case PaperButtonStyle.green:
        index = _isPressed ? 3 : 2;
        break;
      case PaperButtonStyle.blue:
        index = _isPressed ? 5 : 4;
        break;
      case PaperButtonStyle.red:
        index = _isPressed ? 7 : 6;
        break;
      case PaperButtonStyle.gold:
        index = _isPressed ? 9 : 8;
        break;
    }
    return 'assets/paper_ui/Sprites/Content/4_Buttons/$index.png';
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    
    // 如果只有图标没有文字，且宽度较小，则减小内边距
    final defaultPadding = (widget.label == null && widget.width != null && widget.width! <= 60)
        ? const EdgeInsets.all(4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 4);

    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) {
          setState(() => _isPressed = false);
          MusicSystem().playSFX('button_press');
          MusicSystem().resumeMusic();
          widget.onPressed?.call();
        } : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? defaultPadding,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(_getAssetPath()),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: widget.child ?? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    if (widget.label != null) const SizedBox(width: 8),
                  ],
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: widget.textStyle ?? const TextStyle(
                        color: Color(0xFF4E342E),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

