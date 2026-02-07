/// 任务数据模型
class Quest {
  final String id;
  final String trigger;
  final String? highlight;
  final double? highlightPadding; // 通用高亮边距
  final double? paddingTop;      // 顶部边距
  final double? paddingBottom;   // 底部边距
  final double? paddingLeft;     // 左侧边距
  final double? paddingRight;    // 右侧边距
  final bool? barrierDismissible; // 对话框是否可点击外部关闭
  final String? text;
  final String completeWhen;
  final String? onFailHint;
  final String? action;
  final bool isMandatory;

  Quest({
    required this.id,
    required this.trigger,
    this.highlight,
    this.highlightPadding,
    this.paddingTop,
    this.paddingBottom,
    this.paddingLeft,
    this.paddingRight,
    this.barrierDismissible,
    this.text,
    required this.completeWhen,
    this.onFailHint,
    this.action,
    this.isMandatory = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trigger': trigger,
      'highlight': highlight,
      'highlight_padding': highlightPadding,
      'padding_top': paddingTop,
      'padding_bottom': paddingBottom,
      'padding_left': paddingLeft,
      'padding_right': paddingRight,
      'barrier_dismissible': barrierDismissible,
      'text': text,
      'complete_when': completeWhen,
      'on_fail_hint': onFailHint,
      'action': action,
      'is_mandatory': isMandatory,
    };
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String,
      trigger: json['trigger'] as String,
      highlight: json['highlight'] as String?,
      highlightPadding: (json['highlight_padding'] as num?)?.toDouble(),
      paddingTop: (json['padding_top'] as num?)?.toDouble(),
      paddingBottom: (json['padding_bottom'] as num?)?.toDouble(),
      paddingLeft: (json['padding_left'] as num?)?.toDouble(),
      paddingRight: (json['padding_right'] as num?)?.toDouble(),
      barrierDismissible: json['barrier_dismissible'] as bool?,
      text: json['text'] as String?,
      completeWhen: json['complete_when'] as String,
      onFailHint: json['on_fail_hint'] as String?,
      action: json['action'] as String?,
      isMandatory: json['is_mandatory'] as bool? ?? false,
    );
  }
}
