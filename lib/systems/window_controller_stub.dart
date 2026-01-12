import 'package:flutter/foundation.dart';

class WindowController {
  /// 全局沉浸模式状态
  static final ValueNotifier<bool> isWallpaperModeProvider = ValueNotifier<bool>(false);

  static bool get isWallpaperMode => isWallpaperModeProvider.value;

  /// 进入无边框沉浸模式 (Stub)
  static void embedInDesktop() {
    debugPrint('embedInDesktop is not supported on this platform.');
  }

  /// 恢复普通窗口模式 (Stub)
  static void restoreWindow() {
    debugPrint('restoreWindow is not supported on this platform.');
  }
}
