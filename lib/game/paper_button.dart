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
  static const double _middleSegmentWidth = 12.0;

  List<String> _getSlicedPaths() {
    int start;
    switch (widget.style) {
      case PaperButtonStyle.brown:
      case PaperButtonStyle.red:
      case PaperButtonStyle.gold:
        start = _isPressed ? 19 : 16;
        break;
      case PaperButtonStyle.green:
        start = _isPressed ? 25 : 22;
        break;
      case PaperButtonStyle.blue:
        start = _isPressed ? 31 : 28;
        break;
      case PaperButtonStyle.square:
        return []; // Not used for square
    }
    return [
      'assets/paper_ui/Sprites/Content/4_Buttons/Sliced/$start.png',
      'assets/paper_ui/Sprites/Content/4_Buttons/Sliced/${start + 1}.png',
      'assets/paper_ui/Sprites/Content/4_Buttons/Sliced/${start + 2}.png',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final bool isSquare = widget.style == PaperButtonStyle.square;
    
    // 如果只有图标没有文字，且宽度较小，则减小内边距
    final defaultPadding = (isSquare || (widget.label == null && widget.width != null && widget.width! <= 60))
        ? const EdgeInsets.all(2)
        : const EdgeInsets.symmetric(horizontal: 19 + _middleSegmentWidth / 2, vertical: 8); // 为 43x15 区域调整并增加一个中间段宽度

    final effectivePadding = widget.padding != null
        ? widget.padding!.add(const EdgeInsets.symmetric(horizontal: _middleSegmentWidth / 2))
        : defaultPadding;

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

    // 确保宽度至少能容纳左右端盖（假设端盖是正方形，宽度等于高度）
    final double? calculatedWidth = widget.width != null 
        ? (widget.width! + (isSquare ? 0 : _middleSegmentWidth)).clamp(isSquare ? 0.0 : widget.height * 2.0, double.infinity)
        : null;

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
          width: calculatedWidth,
          height: widget.height,
          constraints: BoxConstraints(
            minWidth: isSquare ? 0.0 : widget.height * 2.0,
          ),
          decoration: isSquare
              ? BoxDecoration(
                  color: enabled
                      ? (_isPressed ? const Color(0xFFBCAAA4) : const Color(0xFFD7CCC8))
                      : const Color(0xFFD7CCC8).withValues(alpha: 0.5),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Stack(
            children: [
              if (!isSquare)
                Positioned.fill(
                  child: ClipRect(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 左侧端盖
                        Image.asset(
                          _getSlicedPaths()[0],
                          width: widget.height,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.none,
                        ),
                        // 中间平铺段
                        Expanded(
                          child: Image.asset(
                            _getSlicedPaths()[1],
                            repeat: ImageRepeat.repeatX,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                        // 右侧端盖
                        Image.asset(
                          _getSlicedPaths()[2],
                          width: widget.height,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.none,
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: effectivePadding,
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
            ],
          ),
        ),
      ),
    );
  }
}

