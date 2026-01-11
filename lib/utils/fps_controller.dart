/// 简单的帧率控制器，用于将 Flutter 的渲染频率限制在指定 FPS
class FPSController {
  static const double targetFPS = 60.0;
  static const double frameDuration = 1000 / targetFPS;
  
  static double _lastFrameTime = 0;

  /// 在 main() 中调用，用于启动低帧率模式
  /// 注意：这只是一个建议实现，Flutter 并不直接支持设置系统渲染频率
  /// 更有效的方法是在动画 Ticker 中进行节流
  static bool shouldDrawFrame(double currentTimeMillis) {
    if (currentTimeMillis - _lastFrameTime >= frameDuration) {
      _lastFrameTime = currentTimeMillis;
      return true;
    }
    return false;
  }
}
