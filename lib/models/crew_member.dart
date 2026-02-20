import '../l10n/app_localizations.dart';

/// 船员职业枚举
enum CrewRole {
  sailor('⛵'),
  shipwright('🔧'),
  gunner('🔫'),
  unassigned('❌');

  final String emoji;

  const CrewRole(this.emoji);

  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case CrewRole.sailor:
        return l10n.roleSailor;
      case CrewRole.shipwright:
        return l10n.roleShipwright;
      case CrewRole.gunner:
        return l10n.roleGunner;
      case CrewRole.unassigned:
        return l10n.roleUnassigned;
    }
  }

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
  final String? personality;   // 性格
  final String? specialty;     // 特长
  final String? likedItem;     // 喜欢的物品
  final String? description;   // 完整描述
  CrewRole assignedRole;       // 分配的职业
  int morale;                  // 士气 0-100
  bool isPaid;                 // 最近一次结算是否成功支付工资

  CrewMember({
    required this.name,
    required this.sailorSkill,
    required this.shipwrightSkill,
    required this.gunnerSkill,
    required this.salary,
    this.avatarPath,
    this.personality,
    this.specialty,
    this.likedItem,
    this.description,
    this.assignedRole = CrewRole.unassigned,
    this.morale = 100,  // 默认士气为100
    this.isPaid = true, // 默认已支付
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
    String? personality,
    String? specialty,
    String? likedItem,
    String? description,
    CrewRole? assignedRole,
    int? morale,
    bool? isPaid,
  }) {
    return CrewMember(
      name: name ?? this.name,
      sailorSkill: sailorSkill ?? this.sailorSkill,
      shipwrightSkill: shipwrightSkill ?? this.shipwrightSkill,
      gunnerSkill: gunnerSkill ?? this.gunnerSkill,
      salary: salary ?? this.salary,
      avatarPath: avatarPath ?? this.avatarPath,
      personality: personality ?? this.personality,
      specialty: specialty ?? this.specialty,
      likedItem: likedItem ?? this.likedItem,
      description: description ?? this.description,
      assignedRole: assignedRole ?? this.assignedRole,
      morale: morale ?? this.morale,
      isPaid: isPaid ?? this.isPaid,
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
      'personality': personality,
      'specialty': specialty,
      'likedItem': likedItem,
      'description': description,
      'assignedRole': assignedRole.toJson(),
      'morale': morale,
      'isPaid': isPaid,
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
      personality: json['personality'] as String?,
      specialty: json['specialty'] as String?,
      likedItem: json['likedItem'] as String?,
      description: json['description'] as String?,
      assignedRole: CrewRole.fromJson(json['assignedRole'] as String),
      morale: json['morale'] as int,
      isPaid: (json['isPaid'] as bool?) ?? true,
    );
  }
}


