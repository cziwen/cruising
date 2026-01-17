import 'package:flutter/foundation.dart';
import '../models/notification_hint.dart';

/// 通知系统逻辑管理
/// 负责提示队列的维护和堆栈逻辑（最多3个提示）
class NotificationSystem extends ChangeNotifier {
  // 单例模式
  static final NotificationSystem instance = NotificationSystem._internal();
  NotificationSystem._internal();

  final List<NotificationHint> _activeHints = [];
  
  /// 当前活跃的提示列表
  List<NotificationHint> get activeHints => List.unmodifiable(_activeHints);

  /// 显示一个新的提示
  void showNotification(String message) {
    final newHint = NotificationHint(message: message);
    
    // 堆栈逻辑：如果已经有3个提示，将最旧的一个标记为退出
    if (_activeHints.where((h) => !h.isExiting).length >= 3) {
      // 找到第一个不在退出状态的提示
      final oldestActive = _activeHints.firstWhere((h) => !h.isExiting);
      oldestActive.isExiting = true;
    }
    
    _activeHints.add(newHint);
    notifyListeners();
  }

  /// 标记一个提示正在退出（例如被新提示挤掉或手动触发）
  void markAsExiting(String id) {
    final index = _activeHints.indexWhere((h) => h.id == id);
    if (index != -1 && !_activeHints[index].isExiting) {
      _activeHints[index].isExiting = true;
      notifyListeners();
    }
  }

  /// 彻底移除一个提示（在动画播放完成后由 UI 组件调用）
  void removeHint(String id) {
    _activeHints.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  /// 清除所有提示
  void clearAll() {
    _activeHints.clear();
    notifyListeners();
  }
}
