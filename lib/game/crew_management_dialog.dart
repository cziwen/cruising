import 'package:flutter/material.dart';
import '../models/crew_member.dart';
import 'game_state.dart';

/// 船员管理对话框
class CrewManagementDialog extends StatefulWidget {
  final GameState gameState;

  const CrewManagementDialog({
    super.key,
    required this.gameState,
  });

  @override
  State<CrewManagementDialog> createState() => _CrewManagementDialogState();
}

class _CrewManagementDialogState extends State<CrewManagementDialog> {
  late GameState _gameState;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _gameState = widget.gameState;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crewManager = _gameState.crewManager;
    // 技能值直接对应效果值
    final sailingBonusKnots = crewManager.calculateSailingBonus(); // 直接返回节数
    final autoRepair = crewManager.calculateAutoRepair(); // 直接返回每秒修复的耐久数
    final fireRateBonus = crewManager.calculateFireRateBonus(); // 直接返回每秒炮数

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
          width: 800, // 设计尺寸
          // 移除固定高度，使用约束来限制最大高度
          constraints: const BoxConstraints(
            maxHeight: 900, // 设计最大高度
          ),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 高度随内容自适应
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      '船员管理',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // 顶部统计区域
              Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // 分配情况
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRoleStat(
                          CrewRole.sailor,
                          crewManager.getSailorCount(),
                          Colors.cyan,
                        ),
                        _buildRoleStat(
                          CrewRole.shipwright,
                          crewManager.getShipwrightCount(),
                          Colors.orange,
                        ),
                        _buildRoleStat(
                          CrewRole.gunner,
                          crewManager.getGunnerCount(),
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 综合效果
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildBonusRow(
                            '航速加成',
                            '+${sailingBonusKnots.toStringAsFixed(1)}节',
                            Colors.cyan,
                          ),
                          const SizedBox(height: 6),
                          _buildBonusRow(
                            '自动修理',
                            '${autoRepair.toStringAsFixed(1)} / 秒',
                            Colors.orange,
                          ),
                          const SizedBox(height: 6),
                          _buildBonusRow(
                            '开炮速度',
                            '${fireRateBonus.toStringAsFixed(1)} 炮/秒',
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white24, height: 1),

              // 船员列表
              Flexible(
                // Flexible 配合 mainAxisSize.min 可以让 Column 随内容高度变化，但不会超过最大约束
                child: crewManager.crewMembers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          '暂无船员\n请在人才市场招募',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thumbColor: WidgetStateProperty.all(
                            Colors.grey[400]!, // 灰色滚动条
                          ),
                          trackColor: WidgetStateProperty.all(
                            Colors.grey[800]!.withValues(alpha: 0.3), // 轨道颜色
                          ),
                        ),
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true, // 始终显示滚动条
                          interactive: true, // 允许拖拽滚动条
                          thickness: 8, // 滚动条宽度
                          radius: const Radius.circular(4), // 滚动条圆角
                          child: ListView.builder(
                            controller: _scrollController,
                            shrinkWrap: true, // 允许 ListView 根据内容决定高度
                            padding: const EdgeInsets.only(
                              left: 8,
                              right: 16, // 右边留出滚动条空间
                              top: 8,
                              bottom: 8,
                            ),
                            itemCount: crewManager.crewMembers.length,
                            itemBuilder: (context, index) {
                              return _buildCrewCard(crewManager.crewMembers[index]);
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
  }

  /// 构建职业统计项
  Widget _buildRoleStat(CrewRole role, int count, Color color) {
    return Column(
      children: [
        Text(
          role.emoji,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          role.displayName,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        Text(
          '$count 人',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建加成显示行
  Widget _buildBonusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建船员卡片
  Widget _buildCrewCard(CrewMember member) {
    return Card(
      color: Colors.grey[800]?.withValues(alpha: 0.8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：方块头像
            _buildAvatar(member),
            const SizedBox(width: 12),
            // 中间：姓名、工资、技能值
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 姓名和工资
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '工资：${member.salary} / 天',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 技能显示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSkillItem('⛵', member.sailorSkill, Colors.cyan),
                      _buildSkillItem('🔧', member.shipwrightSkill, Colors.orange),
                      _buildSkillItem('🔫', member.gunnerSkill, Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 最右侧：职业分配按钮
            _buildRoleSelector(member),
          ],
        ),
      ),
    );
  }

  /// 构建技能项
  Widget _buildSkillItem(String emoji, double skill, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          skill.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建职业选择器
  Widget _buildRoleSelector(CrewMember member) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[700]?.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRoleColor(member.assignedRole).withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getRoleColor(member.assignedRole).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<CrewRole>(
        value: member.assignedRole,
        underline: const SizedBox(),
        dropdownColor: Colors.grey[800],
        style: const TextStyle(color: Colors.white, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        icon: Icon(
          Icons.arrow_drop_down,
          color: _getRoleColor(member.assignedRole),
        ),
        selectedItemBuilder: (BuildContext context) {
          return CrewRole.values.map((role) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(role.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  role.displayName,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            );
          }).toList();
        },
        items: CrewRole.values.map((role) {
          return DropdownMenuItem<CrewRole>(
            value: role,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(role.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(role.displayName),
              ],
            ),
          );
        }).toList(),
        onChanged: (CrewRole? newRole) {
          if (newRole != null) {
            setState(() {
              _gameState.assignCrewRole(member, newRole);
            });
          }
        },
      ),
    );
  }

  /// 获取职业颜色
  Color _getRoleColor(CrewRole role) {
    switch (role) {
      case CrewRole.sailor:
        return Colors.cyan;
      case CrewRole.shipwright:
        return Colors.orange;
      case CrewRole.gunner:
        return Colors.red;
      case CrewRole.unassigned:
        return Colors.grey;
    }
  }

  /// 构建头像
  Widget _buildAvatar(CrewMember member) {
    // 如果有头像路径，尝试加载图片
    if (member.avatarPath != null && member.avatarPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 80,
          height: 80,
          color: _getRoleColor(member.assignedRole).withValues(alpha: 0.3),
          child: Image.asset(
            member.avatarPath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // 如果图片加载失败，显示占位符
              return _buildAvatarPlaceholder(member);
            },
          ),
        ),
      );
    }
    
    // 使用占位符
    return _buildAvatarPlaceholder(member);
  }

  /// 构建头像占位符
  Widget _buildAvatarPlaceholder(CrewMember member) {
    // 根据职业选择不同的颜色和图标
    final roleColor = _getRoleColor(member.assignedRole);
    final roleEmoji = member.assignedRole.emoji;
    
    // 使用名字的首字符作为占位符，如果没有则使用职业图标
    final displayChar = member.name.isNotEmpty 
        ? member.name[0].toUpperCase() 
        : roleEmoji;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: roleColor.withValues(alpha: 0.3),
          border: Border.all(
            color: roleColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(
              displayChar,
              style: TextStyle(
                fontSize: displayChar == roleEmoji ? 32 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

