import 'package:flutter/material.dart';
import '../systems/music_system.dart';

enum PaperButtonStyle {
  brown,  // 0.png, 1.png
  green,  // 2.png, 3.png
  blue,   // 4.png, 5.png
  red,    // 6.png, 7.png
  gold,   // 8.png, 9.png
  square, // Small square button without image asset
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
  final Alignment alignment;
  final double? minFontSize;
  final double? maxFontSize;

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
    this.alignment = Alignment.center,
    this.minFontSize,
    this.maxFontSize,
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
      case PaperButtonStyle.square:
        index = 0; // Fallback, though we won't use it for square
        break;
    }
    return 'assets/paper_ui/Sprites/Content/4_Buttons/$index.png';
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final bool isSquare = widget.style == PaperButtonStyle.square;
    
    // 如果只有图标没有文字，且宽度较小，则减小内边距
    final defaultPadding = (isSquare || (widget.label == null && widget.width != null && widget.width! <= 60))
        ? const EdgeInsets.all(2)
        : const EdgeInsets.symmetric(horizontal: 19, vertical: 8); // 为 43x15 区域调整

    final textStyle = widget.textStyle ?? const TextStyle(
      color: Color(0xFF4E342E),
      fontSize: 14, // 从 16 减小
      fontWeight: FontWeight.bold,
    );

    final minFontSize = widget.minFontSize ?? 8.0;
    final maxFontSize = widget.maxFontSize ?? textStyle.fontSize ?? 14.0;

    String processedLabel = widget.label ?? '';
    bool isMultiLine = false;
    double effectiveMaxFontSize = maxFontSize;

    // Rule: length > 8, reduce font size
    if (processedLabel.length > 8) {
      effectiveMaxFontSize = maxFontSize * 0.9; // 16 -> 14.4
    }

    // Rule: length > 9 and has spaces, wrap to 2 lines
    if (processedLabel.length > 9 && processedLabel.contains(' ')) {
      final words = processedLabel.split(' ');
      if (words.length >= 2) {
        // Find the best split point to balance line lengths
        int mid = (processedLabel.length / 2).floor();
        int bestSpaceIndex = -1;
        int minDiff = processedLabel.length;

        for (int i = 0; i < processedLabel.length; i++) {
          if (processedLabel[i] == ' ') {
            int diff = (i - mid).abs();
            if (diff < minDiff) {
              minDiff = diff;
              bestSpaceIndex = i;
            }
          }
        }

        if (bestSpaceIndex != -1) {
          processedLabel = processedLabel.substring(0, bestSpaceIndex) +
              '\n' +
              processedLabel.substring(bestSpaceIndex + 1);
          isMultiLine = true;
          // Rule: 2 lines, dramatically reduce font size
          effectiveMaxFontSize = maxFontSize * 0.75; // 16 -> 12
        }
      }
    }

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
          decoration: isSquare
              ? BoxDecoration(
                  color: enabled
                      ? (_isPressed ? const Color(0xFFBCAAA4) : const Color(0xFFD7CCC8))
                      : const Color(0xFFD7CCC8).withValues(alpha: 0.5),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                )
              : BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_getAssetPath()),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  ),
                ),
          child: Align(
            alignment: widget.alignment,
            child: widget.child ?? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  if (widget.label != null) const SizedBox(width: 4),
                ],
                if (widget.label != null)
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        processedLabel,
                        textAlign: TextAlign.center,
                        style: textStyle.copyWith(
                          fontSize: effectiveMaxFontSize,
                          height: isMultiLine ? 1.0 : null,
                        ).copyWith(fontSize: effectiveMaxFontSize.clamp(minFontSize, effectiveMaxFontSize)),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

