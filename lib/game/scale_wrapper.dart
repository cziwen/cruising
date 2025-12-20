import 'dart:math';
import 'package:flutter/material.dart';

/// 一个用于按比例缩放子组件的包装器
/// 基于 1920x1080 的设计尺寸
class ScaleWrapper extends StatelessWidget {
  final Widget child;
  final Size designSize;
  final bool maintainAspectRatio;

  const ScaleWrapper({
    super.key,
    required this.child,
    this.designSize = const Size(1920, 1080),
    this.maintainAspectRatio = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        // 计算缩放比例
        double scaleX = screenWidth / designSize.width;
        double scaleY = screenHeight / designSize.height;
        
        double scale;
        if (maintainAspectRatio) {
          // 保持纵横比，选择较小的缩放比例以确保内容完全可见
          scale = min(scaleX, scaleY);
        } else {
          // 不保持纵横比（通常不推荐，因为会导致形变）
          scale = min(scaleX, scaleY); // 这里还是取最小值比较安全
        }

        return Center(
          child: SizedBox(
            width: designSize.width * scale,
            height: designSize.height * scale,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: designSize.width,
                height: designSize.height,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}



