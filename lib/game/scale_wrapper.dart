import 'dart:math';
import 'package:flutter/material.dart';

/// 一个用于按比例缩放子组件的包装器
/// 基于 1920x1080 的设计尺寸
class ScaleWrapper extends StatelessWidget {
  final Widget child;
  final Size designSize;
  final bool maintainAspectRatio;
  final Color? backgroundColor;

  const ScaleWrapper({
    super.key,
    required this.child,
    this.designSize = const Size(1920, 1080),
    this.maintainAspectRatio = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 安全获取 MediaQueryData
    final baseMediaQuery = MediaQuery.maybeOf(context) ?? 
                          (View.maybeOf(context) != null ? MediaQueryData.fromView(View.of(context)) : null);
    
    return Container(
      color: backgroundColor ?? Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 2. 优化尺寸获取逻辑
          double screenWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : (baseMediaQuery?.size.width ?? 0);
          double screenHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : (baseMediaQuery?.size.height ?? 0);
          
          // 3. 容错处理：尺寸不可用时直接返回 child，防止计算 scale 出错
          if (screenWidth <= 0 || screenHeight <= 0) {
            return child;
          }
          
          // 计算缩放比例
          double scaleX = screenWidth / designSize.width;
          double scaleY = screenHeight / designSize.height;
          
          // 4. 防止 Infinity 或 NaN 导致渲染崩溃
          double scale = (scaleX.isFinite && scaleY.isFinite) 
              ? (maintainAspectRatio ? min(scaleX, scaleY) : min(scaleX, scaleY))
              : 1.0;

          return Center(
            child: SizedBox(
              width: designSize.width * scale,
              height: designSize.height * scale,
              child: MediaQuery(
                data: (baseMediaQuery ?? const MediaQueryData()).copyWith(
                  size: designSize,
                  padding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: designSize.width,
                    height: designSize.height,
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
