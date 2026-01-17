import 'package:uuid/uuid.dart';

/// 通知提示数据模型
class NotificationHint {
  final String id;
  final String message;
  bool isExiting;
  final DateTime createdAt;

  NotificationHint({
    String? id,
    required this.message,
    this.isExiting = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationHint && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
