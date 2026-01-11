import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../systems/window_controller.dart';

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
          
          // 计算缩放比例 - 统一基于高度缩放，宽度保持自适应（超宽屏支持）
          double scale = screenHeight / designSize.height;
          
    if (maintainAspectRatio && !kIsWeb) {
      double scaleX = screenWidth / designSize.width;
      double scaleY = screenHeight / designSize.height;
      scale = min(scaleX, scaleY);
      
      Widget content = Center(
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

      // 在沉浸模式下应用边缘羽化效果
      return ValueListenableBuilder<bool>(
        valueListenable: WindowController.isWallpaperModeProvider,
        builder: (context, isWallpaper, _) {
          if (!isWallpaper) return content;
          
          return ShaderMask(
            shaderCallback: (rect) {
              // 1. 水平方向羽化
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                stops: [0.0, 0.02, 0.98, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: ShaderMask(
              shaderCallback: (rect) {
                // 2. 垂直方向羽化
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                  stops: [0.0, 0.02, 0.98, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: content,
            ),
          );
        },
      );
    }

          // 超宽屏/自适应模式：高度锁定比例，宽度自由伸展
          final effectiveWidth = screenWidth / scale;
          
          Widget content = SizedBox.expand(
            child: MediaQuery(
              data: (baseMediaQuery ?? const MediaQueryData()).copyWith(
                size: Size(effectiveWidth, designSize.height),
                padding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
              ),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: SizedBox(
                  width: effectiveWidth,
                  height: designSize.height,
                  child: child,
                ),
              ),
            ),
          );

          // 在沉浸模式下应用边缘羽化效果
          return ValueListenableBuilder<bool>(
            valueListenable: WindowController.isWallpaperModeProvider,
            builder: (context, isWallpaper, _) {
              if (!isWallpaper) return content;
              
              return ShaderMask(
                shaderCallback: (rect) {
                  // 1. 水平方向羽化
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                    stops: [0.0, 0.02, 0.98, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    // 2. 垂直方向羽化
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, 0.02, 0.98, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: content,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
