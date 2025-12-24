import 'package:flutter/material.dart';

/// 背景层 - 远距离背景（海洋背景）
class BackgroundLayer extends StatelessWidget {
  const BackgroundLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        // 备用渐变背景（如果图片加载失败）
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF87CEEB), // 天空蓝
            const Color(0xFF4682B4), // 钢蓝色
            const Color(0xFF1E90FF), // 道奇蓝
          ],
        ),
      ),
      child: Image.asset(
        'assets/images/background/oceanbg_0.png', // 使用有效的备用图片
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // 图片加载失败时返回空容器（使用上面的渐变背景）
          debugPrint('Failed to load ocean background: $error');
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
