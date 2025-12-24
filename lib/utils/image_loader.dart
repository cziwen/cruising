import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 图像加载工具类，提供诊断和错误处理
class ImageLoader {
  /// 检查图像资源是否存在（仅用于诊断）
  static Future<bool> checkImageExists(String assetPath, BuildContext context) async {
    try {
      await precacheImage(AssetImage(assetPath), context);
      return true;
    } catch (e) {
      debugPrint('Image check failed for $assetPath: $e');
      return false;
    }
  }
  
  /// 获取平台信息用于诊断
  static String getPlatformInfo() {
    if (kIsWeb) {
      return 'Web';
    }
    // 对于非 Web 平台，使用 defaultTargetPlatform
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }
  
  /// 诊断所有图像资源
  static Future<Map<String, bool>> diagnoseImages(
    BuildContext context,
    List<String> imagePaths,
  ) async {
    final results = <String, bool>{};
    
    debugPrint('=== Image Loading Diagnosis ===');
    debugPrint('Platform: ${getPlatformInfo()}');
    debugPrint('Checking ${imagePaths.length} images...');
    
    for (final path in imagePaths) {
      final exists = await checkImageExists(path, context);
      results[path] = exists;
      debugPrint('${exists ? "✓" : "✗"} $path');
    }
    
    debugPrint('=== Diagnosis Complete ===');
    return results;
  }
}

