import 'package:uuid/uuid.dart';

/// 指引提示数据模型
class GuidanceHint {
  final String id;
  final String message;
  bool isExiting;
  final DateTime createdAt;

  GuidanceHint({
    String? id,
    required this.message,
    this.isExiting = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuidanceHint && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
