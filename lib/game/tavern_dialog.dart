import 'package:flutter/material.dart';
import '../models/crew_member.dart';
import 'game_state.dart';

/// 港口酒馆对话框 - 用于招募船员
class TavernDialog extends StatefulWidget {
  final GameState gameState;

  const TavernDialog({
    super.key,
    required this.gameState,
  });

  @override
  State<TavernDialog> createState() => _TavernDialogState();
}

class _TavernDialogState extends State<TavernDialog> {
  CrewMember? _selectedCrew;

  @override
  void initState() {
    super.initState();
    // 初始选中第一个可招募船员（如果有）
    if (widget.gameState.availableTavernCrew.isNotEmpty) {
      _selectedCrew = widget.gameState.availableTavernCrew.first;
    }
  }

  /// 获取角色描述
  String _getCrewDescription(CrewMember member) {
    if (member.description != null) {
      return member.description!;
    }
    return '一位渴望出海的冒险者。';
  }

  /// 招募船员
  void _recruitCrew(CrewMember member) {
    final recruitmentCost = member.salary * 10;
    final currentCrewCount = widget.gameState.crewManager.crewMembers.length;
    final maxCrewCount = widget.gameState.maxCrewCount;

    // 检查条件
    if (currentCrewCount >= maxCrewCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('船员已满（$currentCrewCount / $maxCrewCount）'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.gameState.gold < recruitmentCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('金币不足！需要 $recruitmentCost 金币'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('招募该船员？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('工资：${member.salary} 金币 / 天'),
            const SizedBox(height: 8),
            Text('招募费用：$recruitmentCost 金币'),
            const SizedBox(height: 8),
            Text('当前船员数：$currentCrewCount / $maxCrewCount'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('再看看'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭确认对话框
              
              // 扣除招募费用
              widget.gameState.spendGold(recruitmentCost);
              
              // 招募船员
              widget.gameState.recruitTavernCrew(member);
              
              // 更新本地选中状态
              setState(() {
                if (widget.gameState.availableTavernCrew.isEmpty) {
                  _selectedCrew = null;
                } else {
                  _selectedCrew = widget.gameState.availableTavernCrew.first;
                }
              });
              
              // 显示成功提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('成功招募 ${member.name}！'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('确认招募'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCrew = widget.gameState.availableTavernCrew;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
          width: 1000, // 设计尺寸
          height: 800, // 设计尺寸
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_bar, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      '港口酒馆 Tavern',
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
              
              // 主要内容区域（左右分栏）
              Expanded(
                child: Row(
                  children: [
                    // 左侧：船员列表
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: availableCrew.isEmpty
                            ? const Center(
                                child: Text(
                                  '暂无可招募船员',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: availableCrew.length,
                                itemBuilder: (context, index) {
                                  final crew = availableCrew[index];
                                  final isSelected = crew == _selectedCrew;
                                  return _buildCrewListItem(crew, isSelected);
                                },
                              ),
                      ),
                    ),
                    
                    // 右侧：船员详情
                    Expanded(
                      flex: 3,
                      child: _selectedCrew == null
                          ? const Center(
                              child: Text(
                                '请选择一名船员查看详情',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : _buildCrewDetail(_selectedCrew!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  /// 构建船员列表项
  Widget _buildCrewListItem(CrewMember member, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCrew = member;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.purple.withValues(alpha: 0.3)
              : Colors.grey[800]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.purple
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // 头像
            _buildSmallAvatar(member),
            const SizedBox(width: 12),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 姓名
                  Text(
                    member.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 技能和工资
                  Row(
                    children: [
                      _buildSkillChip('⛵', member.sailorSkill, Colors.cyan),
                      const SizedBox(width: 4),
                      _buildSkillChip('🔧', member.shipwrightSkill, Colors.orange),
                      const SizedBox(width: 4),
                      _buildSkillChip('🔫', member.gunnerSkill, Colors.red),
                      const Spacer(),
                      Text(
                        '${member.salary}G',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建小头像
  Widget _buildSmallAvatar(CrewMember member) {
    if (member.avatarPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          member.avatarPath!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(50, 20, member.name),
        ),
      );
    }
    return _buildPlaceholderAvatar(50, 20, member.name);
  }

  Widget _buildPlaceholderAvatar(double size, double fontSize, String name) {
    final displayChar = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.3),
          border: Border.all(
            color: Colors.purple.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            displayChar,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建技能标签
  Widget _buildSkillChip(String emoji, double skill, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(
          skill.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建船员详情
  Widget _buildCrewDetail(CrewMember member) {
    final recruitmentCost = member.salary * 10;
    final currentCrewCount = widget.gameState.crewManager.crewMembers.length;
    final maxCrewCount = widget.gameState.maxCrewCount;
    final canRecruit = widget.gameState.gold >= recruitmentCost &&
                       currentCrewCount < maxCrewCount;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 大头像和姓名
          Center(
            child: Column(
              children: [
                _buildLargeAvatar(member),
                const SizedBox(height: 12),
                Text(
                  member.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '工资：${member.salary} 金币 / 天',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24, height: 32),
          
          // 技能详情
          const Text(
            '技能：',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSkillDetailRow('⛵', '水手技能', member.sailorSkill, Colors.cyan),
          const SizedBox(height: 8),
          _buildSkillDetailRow('🔧', '船工技能', member.shipwrightSkill, Colors.orange),
          const SizedBox(height: 8),
          _buildSkillDetailRow('🔫', '炮手技能', member.gunnerSkill, Colors.red),
          
          const Divider(color: Colors.white24, height: 32),
          
          // 描述
          const Text(
            '招募后可分配职业以提供加成（在船员管理界面）',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCrewDescription(member),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          const Spacer(),
          
          // 按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCrew = null; // 取消选择，而不是关闭对话框
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.white54),
                  ),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: canRecruit
                      ? () => _recruitCrew(member)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '招募船员',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建大头像
  Widget _buildLargeAvatar(CrewMember member) {
    if (member.avatarPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          member.avatarPath!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderLargeAvatar(member.name),
        ),
      );
    }
    return _buildPlaceholderLargeAvatar(member.name);
  }

  Widget _buildPlaceholderLargeAvatar(String name) {
    final displayChar = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.3),
          border: Border.all(
            color: Colors.purple.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            displayChar,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建技能详情行
  Widget _buildSkillDetailRow(String emoji, String label, double skill, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          skill.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

