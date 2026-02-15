import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/crew_member.dart';
import 'game_state.dart';
import 'paper_dialog.dart';
import 'paper_button.dart';

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
    final l10n = AppLocalizations.of(context)!;
    // 技能值直接对应效果值
    final sailingBonusKnots = crewManager.calculateSailingBonus(); // 直接返回节数
    final autoRepair = crewManager.calculateAutoRepair(); // 直接返回每秒修复的耐久数
    final fireRateBonus = crewManager.calculateFireRateBonus(); // 直接返回每秒炮数

    return PaperDialog(
      assetPath: 'assets/paper_ui/Sprites/Book_Desk/5.png',
      width: 800,
      height: 800,
      child: Column(
        mainAxisSize: MainAxisSize.min, // 高度随内容自适应
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF4E342E), size: 24),
                const SizedBox(width: 10),
                Text(
                  l10n.crewManagement,
                  style: const TextStyle(
                    color: Color(0xFF4E342E),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                PaperButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF4E342E), size: 20),
                  style: PaperButtonStyle.brown,
                  width: 40,
                  height: 40,
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF8D6E63), thickness: 1),

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
                      Colors.blue[800]!,
                    ),
                    _buildRoleStat(
                      CrewRole.shipwright,
                      crewManager.getShipwrightCount(),
                      Colors.orange[900]!,
                    ),
                    _buildRoleStat(
                      CrewRole.gunner,
                      crewManager.getGunnerCount(),
                      Colors.red[900]!,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 综合效果
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7CCC8).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF8D6E63).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      _buildBonusRow(
                        l10n.sailingBonus,
                        '+${sailingBonusKnots.toStringAsFixed(1)}节',
                        Colors.blue[800]!,
                      ),
                      const SizedBox(height: 6),
                      _buildBonusRow(
                        l10n.autoRepair,
                        '${autoRepair.toStringAsFixed(1)} / 秒',
                        Colors.orange[900]!,
                      ),
                      const SizedBox(height: 6),
                      _buildBonusRow(
                        l10n.fireRate,
                        '${fireRateBonus.toStringAsFixed(1)} 炮/秒',
                        Colors.red[900]!,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF8D6E63), height: 1),

          // 船员列表
          Flexible(
            child: crewManager.crewMembers.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.noCrewHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 16,
                      ),
                    ),
                  )
                : ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbColor: WidgetStateProperty.all(
                        const Color(0xFF8D6E63),
                      ),
                      trackColor: WidgetStateProperty.all(
                        const Color(0xFFD7CCC8).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      interactive: true,
                      thickness: 8,
                      radius: const Radius.circular(4),
                      child: ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 16,
                          top: 8,
                          bottom: 8,
                        ),
                        itemCount: crewManager.crewMembers.length,
                        itemBuilder: (context, index) {
                          return _buildCrewCard(crewManager.crewMembers[index], l10n);
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建职业统计项
  Widget _buildRoleStat(CrewRole role, int count, Color color) {
    return Column(
      children: [
        Text(
          role.emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          role.displayName,
          style: const TextStyle(
            color: Color(0xFF5D4037),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$count 人',
          style: TextStyle(
            color: color,
            fontSize: 16,
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
            color: Color(0xFF4E342E),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建船员卡片
  Widget _buildCrewCard(CrewMember member, AppLocalizations l10n) {
    return Card(
      color: const Color(0xFFD7CCC8).withValues(alpha: 0.3),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF8D6E63).withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(
                                color: Color(0xFF4E342E),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!member.isPaid)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.red[800]!),
                                ),
                                child: Text(
                                  l10n.unpaid,
                                  style: TextStyle(
                                    color: Colors.red[900],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        l10n.salaryPerDay(member.salary),
                        style: const TextStyle(
                          color: Color(0xFF795548),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 技能显示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSkillItem('⛵', member.sailorSkill, Colors.blue[800]!),
                      _buildSkillItem('🔧', member.shipwrightSkill, Colors.orange[900]!),
                      _buildSkillItem('🔫', member.gunnerSkill, Colors.red[900]!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 最右侧：职业分配按钮和解雇按钮
            Column(
              children: [
                _buildRoleSelector(member),
                const SizedBox(height: 12),
                PaperButton(
                  icon: const Icon(Icons.person_remove, color: Color(0xFF4E342E), size: 20),
                  onPressed: () => _showDismissConfirmation(context, member, l10n),
                  style: PaperButtonStyle.red,
                  width: 40,
                  height: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 显示解雇确认对话框
  void _showDismissConfirmation(BuildContext context, CrewMember member, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => PaperDialog(
        assetPath: 'assets/paper_ui/Sprites/Book_Desk/4.png',
        width: 400,
        height: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.dismissCrew, style: const TextStyle(color: Color(0xFF4E342E), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(l10n.dismissConfirm(member.name), 
              style: const TextStyle(color: Color(0xFF5D4037)), textAlign: TextAlign.center),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PaperButton(
                  label: l10n.cancel,
                  onPressed: () => Navigator.of(context).pop(),
                  style: PaperButtonStyle.brown,
                  width: 80,
                  height: 32,
                ),
                PaperButton(
                  label: l10n.ok,
                  onPressed: () {
                    _gameState.dismissCrewMember(member);
                    Navigator.of(context).pop();
                    setState(() {}); // 刷新列表
                  },
                  style: PaperButtonStyle.red,
                  width: 80,
                  height: 32,
                ),
              ],
            ),
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
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(
          skill.toStringAsFixed(1),
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
        color: const Color(0xFFD7CCC8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRoleColor(member.assignedRole),
          width: 2,
        ),
      ),
      child: DropdownButton<CrewRole>(
        value: member.assignedRole,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFFEFEBE9),
        style: const TextStyle(color: Color(0xFF4E342E), fontSize: 14, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        icon: Icon(
          Icons.arrow_drop_down,
          color: _getRoleColor(member.assignedRole),
        ),
        selectedItemBuilder: (BuildContext context) {
          return CrewRole.values.map((role) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(role.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  role.displayName,
                  style: const TextStyle(fontSize: 14),
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
                Text(role.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(role.displayName, style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.bold)),
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
        return Colors.blue[800]!;
      case CrewRole.shipwright:
        return Colors.orange[900]!;
      case CrewRole.gunner:
        return Colors.red[900]!;
      case CrewRole.unassigned:
        return const Color(0xFF8D6E63);
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
          color: const Color(0xFFD7CCC8),
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
          color: const Color(0xFFD7CCC8),
          border: Border.all(
            color: roleColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            displayChar,
            style: TextStyle(
              fontSize: displayChar == roleEmoji ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: roleColor,
            ),
          ),
        ),
      ),
    );
  }
}
