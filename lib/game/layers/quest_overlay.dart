import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../systems/quest_system.dart';
import '../../models/quest.dart';
import '../../l10n/l10n.dart';

/// 任务/引导层 - 显示任务提示和高亮指引
class QuestOverlay extends StatelessWidget {
  const QuestOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuestSystem>(
      builder: (context, questSystem, child) {
        final activeQuest = questSystem.activeQuest;
        if (activeQuest == null) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final highlightRect = _getHighlightRect(context, activeQuest, questSystem);

            return Stack(
              children: [
                // 黑色半透明背景 + 高亮切割
                _buildBackground(context, activeQuest, highlightRect),

                // 任务文本框
                _buildQuestText(context, activeQuest, highlightRect, constraints.maxHeight),
                
                // 点击监听（如果 completeWhen 是 tap_anywhere）
                if (activeQuest.completeWhen == 'tap_anywhere')
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => questSystem.handleTapAnywhere(),
                      behavior: HitTestBehavior.opaque,
                    ),
                  ),
              ],
            );
          }
        );
      },
    );
  }

  /// 计算高亮区域的位置和大小
  Rect? _getHighlightRect(BuildContext context, Quest quest, QuestSystem qs) {
    if (quest.highlight == null || quest.highlight == 'none') return null;
    
    final key = qs.getKey(quest.highlight);
    if (key == null || key.currentContext == null) return null;

    final RenderBox? renderBox = key.currentContext!.findRenderObject() as RenderBox?;
    final overlayRenderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlayRenderBox == null || !renderBox.attached) return null;

    try {
      final size = renderBox.size;
      // 使用 ancestor 参数计算相对于 Overlay 的坐标，解决 ScaleWrapper 缩放后的偏移问题
      final position = renderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
      return position & size;
    } catch (e) {
      return null;
    }
  }

  Widget _buildBackground(BuildContext context, Quest quest, Rect? highlightRect) {
    if (quest.highlight == 'none') {
      return const SizedBox.shrink();
    }

    if (quest.highlight == null) {
      return IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
        ),
      );
    }

    if (highlightRect == null) {
      // 如果 Key 还没准备好，先不显示任何遮罩，避免拦截掉所有点击
      return const SizedBox.shrink();
    }

    final padding = EdgeInsets.only(
      top: quest.paddingTop ?? quest.highlightPadding ?? 8,
      bottom: quest.paddingBottom ?? quest.highlightPadding ?? 8,
      left: quest.paddingLeft ?? quest.highlightPadding ?? 8,
      right: quest.paddingRight ?? quest.highlightPadding ?? 8,
    );

    return Stack(
      children: [
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _HighlightPainter(
              rect: highlightRect,
              color: Colors.black.withValues(alpha: 0.7),
              padding: padding,
            ),
          ),
        ),
        // 如果是强制引导，屏蔽除高亮区域外的点击
        if (quest.isMandatory)
          _InteractionBlocker(
            highlightRect: highlightRect,
            padding: padding,
          ),
      ],
    );
  }

  Widget _buildQuestText(BuildContext context, Quest quest, Rect? highlightRect, double maxHeight) {
    if (quest.text == null) return const SizedBox.shrink();

    bool useTop = false;
    if (highlightRect != null) {
      // 动态定位：如果高亮目标在屏幕下半部分，提示文字显示在上方；否则显示在下方
      if (highlightRect.center.dy > maxHeight / 2) {
        useTop = true;
      }
    }

    return Positioned(
      top: useTop ? 120 : null,
      bottom: useTop ? null : 120, // 在状态栏上方或下方
      left: 20,
      right: 20,
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6CA).withValues(alpha: 0.95), // 纸张颜色
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8D6E63), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quest.text!,
                  style: const TextStyle(
                    color: Color(0xFF4E342E),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (quest.completeWhen == 'tap_anywhere') ...[
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.tapAnywhereToContinue,
                    style: TextStyle(
                      color: Color(0xFF8D6E63),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final Rect rect;
  final Color color;
  final EdgeInsets padding;

  _HighlightPainter({
    required this.rect, 
    required this.color,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 使用 saveLayer 创建一个图层，以便使用 BlendMode.clear 进行镂空
    canvas.saveLayer(Offset.zero & size, Paint());

    // 先绘制背景色
    canvas.drawRect(Offset.zero & size, Paint()..color = color);

    // 计算实际的高亮矩形（应用 padding）
    final highlightedRect = Rect.fromLTRB(
      rect.left - padding.left,
      rect.top - padding.top,
      rect.right + padding.right,
      rect.bottom + padding.bottom,
    );

    // 使用 BlendMode.clear 挖孔，确保高亮区域完全透明（镂空效果）
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightedRect, const Radius.circular(8)),
      Paint()..blendMode = BlendMode.clear,
    );

    canvas.restore();
    
    // 绘制高亮边框
    final borderPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectAndRadius(highlightedRect, const Radius.circular(8)), borderPaint);
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) => 
      rect != oldDelegate.rect || color != oldDelegate.color || padding != oldDelegate.padding;
}

/// 用于在强制引导时屏蔽非高亮区域的点击
class _InteractionBlocker extends StatelessWidget {
  final Rect highlightRect;
  final EdgeInsets padding;

  const _InteractionBlocker({
    required this.highlightRect,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    // 这里的 rect 应该和 _HighlightPainter 中的一致，包含 padding
    final rect = Rect.fromLTRB(
      highlightRect.left - padding.left,
      highlightRect.top - padding.top,
      highlightRect.right + padding.right,
      highlightRect.bottom + padding.bottom,
    );
    
    return Stack(
      children: [
        // 上方屏蔽
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: rect.top > 0 ? rect.top : 0,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
        // 下方屏蔽
        Positioned(
          top: rect.bottom,
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
        // 左侧屏蔽
        Positioned(
          top: rect.top > 0 ? rect.top : 0,
          left: 0,
          width: rect.left > 0 ? rect.left : 0,
          height: rect.height,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
        // 右侧屏蔽
        Positioned(
          top: rect.top > 0 ? rect.top : 0,
          left: rect.right,
          right: 0,
          height: rect.height,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
      ],
    );
  }
}
