import '../models/crew_member.dart';

/// 船员管理器
/// 负责管理船员列表和计算各项加成
class ShipCrewManager {
  final List<CrewMember> _crewMembers = [];

  // 加成系数（可调参）
  // 注意：技能值直接对应效果值，不需要系数转换
  // sailorSkill 直接对应节数加成（例如：sailorSkill = 5 表示增加5节）
  // shipwrightSkill 直接对应每秒修复的耐久数（例如：shipwrightSkill = 10 表示每秒修复10点）
  // gunnerSkill 直接对应每秒炮数（例如：gunnerSkill = 5 表示每秒5炮）

  // 缓存：避免重复计算
  Map<CrewRole, List<CrewMember>>? _roleCache;
  double? _cachedSailingBonus;
  double? _cachedAutoRepair;
  double? _cachedFireRateBonus;
  int? _cachedTotalSalary;

  List<CrewMember> get crewMembers => List.unmodifiable(_crewMembers);

  /// 清除缓存（当船员列表或分配发生变化时调用）
  void _invalidateCache() {
    _roleCache = null;
    _cachedSailingBonus = null;
    _cachedAutoRepair = null;
    _cachedFireRateBonus = null;
    _cachedTotalSalary = null;
  }

  /// 添加船员
  void addCrewMember(CrewMember member) {
    _crewMembers.add(member);
    _invalidateCache();
  }

  /// 移除船员
  bool removeCrewMember(CrewMember member) {
    final removed = _crewMembers.remove(member);
    if (removed) {
      _invalidateCache();
    }
    return removed;
  }

  /// 更新船员分配
  void assignCrewRole(CrewMember member, CrewRole role) {
    final index = _crewMembers.indexOf(member);
    if (index != -1) {
      _crewMembers[index].assignedRole = role;
      _invalidateCache();
    }
  }

  /// 获取指定职业的船员列表（带缓存）
  List<CrewMember> getCrewByRole(CrewRole role) {
    // 如果缓存不存在，构建缓存
    _roleCache ??= {
      for (final role in CrewRole.values)
        role: _crewMembers.where((member) => member.assignedRole == role).toList(),
    };
    return _roleCache![role]!;
  }

  /// 计算航速加成（节数）
  /// 返回增加的节数（直接对应水手技能值总和）
  /// 例如：技能值5 = 增加5节，技能值10 = 增加10节
  double calculateSailingBonus() {
    // 使用缓存避免重复计算
    if (_cachedSailingBonus != null) {
      return _cachedSailingBonus!;
    }

    final sailors = getCrewByRole(CrewRole.sailor);
    if (sailors.isEmpty) {
      _cachedSailingBonus = 0.0;
      return 0.0;
    }

    final totalSkill = sailors.fold<double>(
      0.0,
      (sum, member) => sum + member.sailorSkill,
    );

    // 技能值直接对应节数加成
    _cachedSailingBonus = totalSkill;
    return totalSkill;
  }

  /// 计算自动修理效率（每秒恢复的耐久值）
  /// 返回每秒恢复的耐久点数（直接对应船工技能值总和）
  /// 例如：技能值10 = 每秒10点，技能值20 = 每秒20点
  double calculateAutoRepair() {
    // 使用缓存避免重复计算
    if (_cachedAutoRepair != null) {
      return _cachedAutoRepair!;
    }

    final shipwrights = getCrewByRole(CrewRole.shipwright);
    if (shipwrights.isEmpty) {
      _cachedAutoRepair = 0.0;
      return 0.0;
    }

    final totalSkill = shipwrights.fold<double>(
      0.0,
      (sum, member) => sum + member.shipwrightSkill,
    );

    // 技能值直接对应每秒恢复的耐久数
    _cachedAutoRepair = totalSkill.toDouble();
    return _cachedAutoRepair!;
  }

  /// 计算开炮速度（每秒炮数）
  /// 返回每秒可以发射的炮数（直接对应炮手技能值总和）
  /// 例如：技能值5 = 每秒5炮，技能值10 = 每秒10炮
  double calculateFireRateBonus() {
    // 使用缓存避免重复计算
    if (_cachedFireRateBonus != null) {
      return _cachedFireRateBonus!;
    }

    final gunners = getCrewByRole(CrewRole.gunner);
    if (gunners.isEmpty) {
      _cachedFireRateBonus = 0.0;
      return 0.0;
    }

    final totalSkill = gunners.fold<double>(
      0.0,
      (sum, member) => sum + member.gunnerSkill,
    );

    // 技能值直接对应每秒炮数
    _cachedFireRateBonus = totalSkill.toDouble();
    return _cachedFireRateBonus!;
  }

  /// 获取各职业的船员数量
  int getSailorCount() => getCrewByRole(CrewRole.sailor).length;
  int getShipwrightCount() => getCrewByRole(CrewRole.shipwright).length;
  int getGunnerCount() => getCrewByRole(CrewRole.gunner).length;

  /// 计算总工资（每天）
  int calculateTotalSalary() {
    // 使用缓存避免重复计算
    if (_cachedTotalSalary != null) {
      return _cachedTotalSalary!;
    }

    _cachedTotalSalary = _crewMembers.fold<int>(
      0,
      (sum, member) => sum + member.salary,
    );
    return _cachedTotalSalary!;
  }

  /// 清空所有船员
  void clear() {
    _crewMembers.clear();
    _invalidateCache();
  }
}

