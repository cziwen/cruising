import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 视觉层类型，用于区分不同游戏元素的视觉滤镜
enum VisualLayerType {
  ocean,    // 海底和远景波浪
  island,   // 港口和岛屿
  ship,     // 玩家和敌方船只
  wave,     // 前景和近景背景波浪
  cloud,    // 所有云层
}

/// 昼夜视觉工具类
/// 用于根据昼夜进度计算亮度、对比度、饱和度以及天空颜色
class DayNightVisualUtils {
  /// 根据昼夜周期进度获取颜色滤镜矩阵
  /// [progress] 昼夜周期进度（0.0-1.0，0.0 = 日出 6:00，0.5 = 日落 18:00，1.0 = 下一个日出）
  /// [layerType] 视觉层类型，默认为 ship（最亮）
  static ColorFilter getColorFilter(double progress, {VisualLayerType layerType = VisualLayerType.ship}) {
    // 获取当前时间的亮度、饱和度和对比度
    final double brightness = _getBrightness(progress, layerType);
    final double saturation = _getSaturation(progress, layerType);
    final double contrast = _getContrast(progress, layerType);

    // 计算颜色矩阵
    return ColorFilter.matrix(_getColorMatrix(brightness, saturation, contrast));
  }

  /// 获取天空颜色渐变
  /// [progress] 昼夜周期进度
  static List<Color> getSkyGradient(double progress) {
    // 定义不同时间段的天空颜色
    // 0.0: 日出 (6:00)
    // 0.25: 正午 (12:00)
    // 0.5: 日落 (18:00)
    // 0.75: 午夜 (0:00)
    
    // 白天核心颜色
    final Color dayTop = const Color(0xFF87CEEB);    // 天空蓝
    final Color dayMiddle = const Color(0xFF4682B4); // 钢蓝色
    final Color dayBottom = const Color(0xFF1E90FF); // 道奇蓝

    // 夜晚核心颜色
    final Color nightTop = const Color(0xFF000033);    // 深蓝色
    final Color nightMiddle = const Color(0xFF00001a); // 更深的蓝色
    final Color nightBottom = const Color(0xFF00000d); // 近乎黑色

    // 黄昏/黎明核心颜色
    final Color sunsetTop = const Color(0xFF4B0082);    // 靛青色
    final Color sunsetMiddle = const Color(0xFFFF4500); // 橙红色
    final Color sunsetBottom = const Color(0xFFFFD700); // 金色

    // 根据进度进行插值计算
    if (progress < 0.1) {
      // 黎明 (6:00 - 8:24)
      final double t = progress / 0.1;
      return [
        Color.lerp(sunsetTop, dayTop, t)!,
        Color.lerp(sunsetMiddle, dayMiddle, t)!,
        Color.lerp(sunsetBottom, dayBottom, t)!,
      ];
    } else if (progress < 0.4) {
      // 白天 (8:24 - 15:36)
      return [dayTop, dayMiddle, dayBottom];
    } else if (progress < 0.5) {
      // 黄昏 (15:36 - 18:00)
      final double t = (progress - 0.4) / 0.1;
      return [
        Color.lerp(dayTop, sunsetTop, t)!,
        Color.lerp(dayMiddle, sunsetMiddle, t)!,
        Color.lerp(dayBottom, sunsetBottom, t)!,
      ];
    } else if (progress < 0.6) {
      // 入夜 (18:00 - 20:24)
      final double t = (progress - 0.5) / 0.1;
      return [
        Color.lerp(sunsetTop, nightTop, t)!,
        Color.lerp(sunsetMiddle, nightMiddle, t)!,
        Color.lerp(sunsetBottom, nightBottom, t)!,
      ];
    } else if (progress < 0.9) {
      // 夜晚 (20:24 - 3:36)
      return [nightTop, nightMiddle, nightBottom];
    } else {
      // 黎明前 (3:36 - 6:00)
      final double t = (progress - 0.9) / 0.1;
      return [
        Color.lerp(nightTop, sunsetTop, t)!,
        Color.lerp(nightMiddle, sunsetMiddle, t)!,
        Color.lerp(nightBottom, sunsetBottom, t)!,
      ];
    }
  }

  /// 获取海面颜色渐变
  /// [progress] 昼夜周期进度
  static List<Color> getSeaGradient(double progress) {
    // 基础海面颜色 (用户指定：#5e7eb5)
    final Color baseSeaColor = const Color(0xFF5E7EB5);
    
    // 白天海面颜色
    final Color dayTop = baseSeaColor; 
    final Color dayBottom = const Color(0xFF3D5A8A);

    // 夜晚海面颜色 (稍微调亮一点，避免叠加强度滤镜后过黑)
    final Color nightTop = const Color(0xFF243B5E);    
    final Color nightBottom = const Color(0xFF152238);

    // 黄昏/黎明海面颜色 (偏暖偏深的墨蓝色)
    final Color sunsetTop = const Color(0xFF2C3E50);    
    final Color sunsetBottom = const Color(0xFF1C2833);

    Color top;
    Color bottom;

    // 对齐 getSkyGradient 的 6 阶段逻辑，确保插值平滑同步
    if (progress < 0.1) {
      // 黎明 (6:00 - 8:24): 从黄昏色过渡到白天色
      final double t = progress / 0.1;
      top = Color.lerp(sunsetTop, dayTop, t)!;
      bottom = Color.lerp(sunsetBottom, dayBottom, t)!;
    } else if (progress < 0.4) {
      // 白天 (8:24 - 15:36): 保持白天色
      top = dayTop;
      bottom = dayBottom;
    } else if (progress < 0.5) {
      // 黄昏 (15:36 - 18:00): 从白天色过渡到黄昏色
      final double t = (progress - 0.4) / 0.1;
      top = Color.lerp(dayTop, sunsetTop, t)!;
      bottom = Color.lerp(dayBottom, sunsetBottom, t)!;
    } else if (progress < 0.6) {
      // 入夜 (18:00 - 20:24): 从黄昏色过渡到夜晚色
      final double t = (progress - 0.5) / 0.1;
      top = Color.lerp(sunsetTop, nightTop, t)!;
      bottom = Color.lerp(sunsetBottom, nightBottom, t)!;
    } else if (progress < 0.9) {
      // 夜晚 (20:24 - 3:36): 保持夜晚色
      top = nightTop;
      bottom = nightBottom;
    } else {
      // 黎明前 (3:36 - 6:00): 从夜晚色过渡到黄昏色
      final double t = (progress - 0.9) / 0.1;
      top = Color.lerp(nightTop, sunsetTop, t)!;
      bottom = Color.lerp(nightBottom, sunsetBottom, t)!;
    }

    // 获取全局亮度系数，用于微调
    final double brightness = _getBrightness(progress, VisualLayerType.ocean);
    
    return [
      _applyBrightness(top, brightness),
      _applyBrightness(bottom, brightness),
    ];
  }

  /// 为单个颜色应用亮度调整
  static Color _applyBrightness(Color color, double brightness) {
    return Color.fromARGB(
      color.alpha,
      (color.red * brightness).round().clamp(0, 255),
      (color.green * brightness).round().clamp(0, 255),
      (color.blue * brightness).round().clamp(0, 255),
    );
  }

  /// 获取当前亮度的计算值
  static double _getBrightness(double progress, VisualLayerType layerType) {
    final double angle = (progress - 0.25) * 2.0 * math.pi;
    final double cosVal = math.cos(angle);
    
    // 根据层级获取午夜时的最小亮度
    double minBrightness;
    switch (layerType) {
      case VisualLayerType.ocean:
        minBrightness = 0.75;
        break;
      case VisualLayerType.island:
        minBrightness = 0.9;
        break;
      case VisualLayerType.ship:
        minBrightness = 0.9;
        break;
      case VisualLayerType.wave:
        minBrightness = 0.65;
        break;
      case VisualLayerType.cloud:
        minBrightness = 0.6;
        break;
    }

    // 正午亮度固定为 1.0
    const double maxBrightness = 1.0;
    final double mid = (maxBrightness + minBrightness) / 2.0;
    final double amp = (maxBrightness - minBrightness) / 2.0;
    
    return mid + amp * cosVal;
  }

  /// 获取当前饱和度的计算值
  static double _getSaturation(double progress, VisualLayerType layerType) {
    final double angle = (progress - 0.25) * 2.0 * math.pi;
    final double cosVal = math.cos(angle);
    
    // 根据层级获取午夜时的最小饱和度
    double minSaturation;
    switch (layerType) {
      case VisualLayerType.ocean:
        minSaturation = 0.7;
        break;
      case VisualLayerType.island:
        minSaturation = 1.0;
        break;
      case VisualLayerType.ship:
        minSaturation = 1.0; // 船只不失色，保持原色
        break;
      case VisualLayerType.wave:
        minSaturation = 0.6;
        break;
      case VisualLayerType.cloud:
        minSaturation = 0.7;
        break;
    }

    const double maxSaturation = 1.0;
    final double mid = (maxSaturation + minSaturation) / 2.0;
    final double amp = (maxSaturation - minSaturation) / 2.0;
    
    return mid + amp * cosVal;
  }

  /// 获取当前对比度的计算值
  static double _getContrast(double progress, VisualLayerType layerType) {
    final double angle = (progress - 0.25) * 2.0 * math.pi;
    final double cosVal = math.cos(angle);
    
    // 根据层级获取午夜时的对比度
    double minContrast;
    switch (layerType) {
      case VisualLayerType.ocean:
        minContrast = 0.8;
        break;
      case VisualLayerType.island:
        minContrast = 1.0;
        break;
      case VisualLayerType.ship:
        minContrast = 1.0;
        break;
      case VisualLayerType.wave:
        minContrast = 0.95; // 降低对比度，不再强行突出
        break;
      case VisualLayerType.cloud:
        minContrast = 0.85;
        break;
    }

    const double maxContrast = 1.0;
    
    // 如果 minContrast > maxContrast (比如 wave)，我们需要特殊处理
    if (minContrast > maxContrast) {
        // 当 cosVal = -1 (午夜) 时返回 minContrast (1.1)
        // 当 cosVal = 1 (正午) 时返回 maxContrast (1.0)
        final double mid = (minContrast + maxContrast) / 2.0;
        final double amp = (maxContrast - minContrast) / 2.0;
        return mid + amp * cosVal;
    }

    final double mid = (maxContrast + minContrast) / 2.0;
    final double amp = (maxContrast - minContrast) / 2.0;
    
    return mid + amp * cosVal;
  }

  /// 生成颜色矩阵
  /// 基于亮度、饱和度和对比度合成一个 5x4 矩阵
  static List<double> _getColorMatrix(double brightness, double saturation, double contrast) {
    // 亮度调整矩阵
    // [ b, 0, 0, 0, 0,
    //   0, b, 0, 0, 0,
    //   0, 0, b, 0, 0,
    //   0, 0, 0, 1, 0 ]
    
    // 饱和度调整矩阵 (Luminance coefficients for Rec. 709)
    const double rWeight = 0.2126;
    const double gWeight = 0.7152;
    const double bWeight = 0.0722;
    
    final double invSat = 1.0 - saturation;
    final double R = invSat * rWeight;
    final double G = invSat * gWeight;
    final double B = invSat * bWeight;

    // 对比度调整
    final double t = (1.0 - contrast) / 2.0;

    // 组合矩阵
    // 这里我们进行一个简单的近似组合
    // 最终颜色 = (原色 * 矩阵)
    
    return <double>[
      (R + saturation) * contrast * brightness, G * contrast * brightness, B * contrast * brightness, 0, t * 255,
      R * contrast * brightness, (G + saturation) * contrast * brightness, B * contrast * brightness, 0, t * 255,
      R * contrast * brightness, G * contrast * brightness, (B + saturation) * contrast * brightness, 0, t * 255,
      0, 0, 0, 1, 0,
    ];
  }
}
