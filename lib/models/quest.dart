/// 任务数据模型
class Quest {
  final String id;
  final String trigger;
  final String? highlight;
  final String text;
  final String completeWhen;
  final String? onFailHint;
  final String? action;
  final bool isMandatory;

  Quest({
    required this.id,
    required this.trigger,
    this.highlight,
    required this.text,
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
      text: json['text'] as String,
      completeWhen: json['complete_when'] as String,
      onFailHint: json['on_fail_hint'] as String?,
      action: json['action'] as String?,
      isMandatory: json['is_mandatory'] as bool? ?? false,
    );
  }
}
