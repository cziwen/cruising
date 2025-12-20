/// 船员职业枚举
enum CrewRole {
  sailor('水手', '⛵'),
  shipwright('船工', '🔧'),
  gunner('炮手', '🔫'),
  unassigned('未分配', '❌');

  final String displayName;
  final String emoji;

  const CrewRole(this.displayName, this.emoji);

  String toJson() => name;

  static CrewRole fromJson(String json) {
    return CrewRole.values.firstWhere(
      (e) => e.name == json,
      orElse: () => CrewRole.unassigned,
    );
  }
}

/// 船员数据模型
class CrewMember {
  final String name;
  final double sailorSkill;      // 水手技能 0-10（保留2位小数）
  final double shipwrightSkill;  // 船工技能 0-10（保留2位小数）
  final double gunnerSkill;      // 炮手技能 0-10（保留2位小数）
  final int salary;           // 工资（每天）
  final String? avatarPath;   // 头像路径（可选，如果为null则使用占位符）
  CrewRole assignedRole;       // 分配的职业
  int morale;                  // 士气 0-100

  CrewMember({
    required this.name,
    required this.sailorSkill,
    required this.shipwrightSkill,
    required this.gunnerSkill,
    required this.salary,
    this.avatarPath,
    this.assignedRole = CrewRole.unassigned,
    this.morale = 100,  // 默认士气为100
  });

  /// 获取指定职业的技能值
  double getSkillForRole(CrewRole role) {
    switch (role) {
      case CrewRole.sailor:
        return sailorSkill;
      case CrewRole.shipwright:
        return shipwrightSkill;
      case CrewRole.gunner:
        return gunnerSkill;
      case CrewRole.unassigned:
        return 0.0;
    }
  }

  /// 复制并修改
  CrewMember copyWith({
    String? name,
    double? sailorSkill,
    double? shipwrightSkill,
    double? gunnerSkill,
    int? salary,
    String? avatarPath,
    CrewRole? assignedRole,
    int? morale,
  }) {
    return CrewMember(
      name: name ?? this.name,
      sailorSkill: sailorSkill ?? this.sailorSkill,
      shipwrightSkill: shipwrightSkill ?? this.shipwrightSkill,
      gunnerSkill: gunnerSkill ?? this.gunnerSkill,
      salary: salary ?? this.salary,
      avatarPath: avatarPath ?? this.avatarPath,
      assignedRole: assignedRole ?? this.assignedRole,
      morale: morale ?? this.morale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sailorSkill': sailorSkill,
      'shipwrightSkill': shipwrightSkill,
      'gunnerSkill': gunnerSkill,
      'salary': salary,
      'avatarPath': avatarPath,
      'assignedRole': assignedRole.toJson(),
      'morale': morale,
    };
  }

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      name: json['name'] as String,
      sailorSkill: (json['sailorSkill'] as num).toDouble(),
      shipwrightSkill: (json['shipwrightSkill'] as num).toDouble(),
      gunnerSkill: (json['gunnerSkill'] as num).toDouble(),
      salary: json['salary'] as int,
      avatarPath: json['avatarPath'] as String?,
      assignedRole: CrewRole.fromJson(json['assignedRole'] as String),
      morale: json['morale'] as int,
    );
  }
}


