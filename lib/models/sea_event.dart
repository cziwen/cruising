enum SeaEventType {
  notification, // 即时通知类
  decision,     // 交互决策类
}

/// 海上事件效果类型
enum SeaEventEffectType {
  durabilityChange,    // 耐久度变化
  goldChange,          // 金币变化
  progressChange,      // 航行进度变化
  speedMultiplier,     // 航速倍率（持续一段时间）
  triggerCombat,       // 触发战斗
  changeDestination,   // 更改目的地（至最近港口）
  addRandomGoods,      // 获得随机货物
  timeSkip,            // 时间流逝
}

/// 海上事件效果定义
class SeaEventEffect {
  final SeaEventEffectType type;
  final dynamic value; // 数值、倍率或具体参数
  final int? durationHours; // 持续时间（游戏小时）

  SeaEventEffect({
    required this.type,
    this.value,
    this.durationHours,
  });

  factory SeaEventEffect.fromJson(Map<String, dynamic> json) {
    return SeaEventEffect(
      type: SeaEventEffectType.values.firstWhere((e) => e.name == json['type']),
      value: json['value'],
      durationHours: json['durationHours'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'value': value,
    'durationHours': durationHours,
  };
}

/// 海上事件选项
class SeaEventChoice {
  final String id;
  final String label;
  final List<SeaEventEffect> effects;
  final String? condition; // 触发该选项的前置条件（如：附近有港口）

  SeaEventChoice({
    required this.id,
    required this.label,
    required this.effects,
    this.condition,
  });

  factory SeaEventChoice.fromJson(Map<String, dynamic> json) {
    return SeaEventChoice(
      id: json['id'],
      label: json['label'],
      effects: (json['effects'] as List).map((e) => SeaEventEffect.fromJson(e)).toList(),
      condition: json['condition'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'effects': effects.map((e) => e.toJson()).toList(),
    'condition': condition,
  };
}

/// 海上事件模型
class SeaEvent {
  final String id;
  final String title;
  final String description;
  final SeaEventType type;
  final double probability; // 触发概率 (0.0 - 1.0)
  final int cooldownHours; // 冷却时间（游戏小时）
  final double minProgress; // 最小触发进度 (0.0 - 1.0)
  final double maxProgress; // 最大触发进度 (0.0 - 1.0)
  final List<SeaEventChoice> choices;
  final String? assetPath; // 相关视觉资源（如风暴的降雨效果）

  SeaEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.probability,
    required this.cooldownHours,
    this.minProgress = 0.1,
    this.maxProgress = 0.9,
    required this.choices,
    this.assetPath,
  });

  factory SeaEvent.fromJson(Map<String, dynamic> json) {
    return SeaEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: SeaEventType.values.firstWhere((e) => e.name == json['type']),
      probability: (json['probability'] as num).toDouble(),
      cooldownHours: json['cooldownHours'] as int,
      minProgress: (json['minProgress'] as num?)?.toDouble() ?? 0.1,
      maxProgress: (json['maxProgress'] as num?)?.toDouble() ?? 0.9,
      choices: (json['choices'] as List).map((c) => SeaEventChoice.fromJson(c)).toList(),
      assetPath: json['assetPath'] ?? json['image'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'probability': probability,
    'cooldownHours': cooldownHours,
    'minProgress': minProgress,
    'maxProgress': maxProgress,
    'choices': choices.map((c) => c.toJson()).toList(),
    'assetPath': assetPath,
  };
}
