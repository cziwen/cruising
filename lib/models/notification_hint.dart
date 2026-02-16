import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';

/// 通知文本构建器，接受 AppLocalizations 并返回最终字符串
typedef NotificationTextBuilder = String Function(AppLocalizations l10n);

/// 通知提示数据模型
class NotificationHint {
  final String id;
  final NotificationTextBuilder textBuilder;
  bool isExiting;
  final DateTime createdAt;

  NotificationHint({
    String? id,
    required this.textBuilder,
    this.isExiting = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = DateTime.now();

  /// 静态辅助方法，用于向后兼容纯字符串通知
  factory NotificationHint.text(String message, {String? id}) {
    return NotificationHint(
      id: id,
      textBuilder: (_) => message,
    );
  }

  /// 获取本地化后的消息
  String message(AppLocalizations l10n) => textBuilder(l10n);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationHint && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
