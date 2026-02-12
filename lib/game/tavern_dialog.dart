import 'package:flutter/material.dart';
import '../models/crew_member.dart';
import 'game_state.dart';
import 'paper_dialog.dart';
import 'paper_button.dart';

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
      builder: (context) => PaperDialog(
        assetPath: 'assets/paper_ui/Sprites/Book_Desk/4.png',
        width: 400,
        height: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('招募该船员？', style: TextStyle(color: Color(0xFF4E342E), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('工资：${member.salary} 金币 / 天', style: const TextStyle(color: Color(0xFF5D4037))),
                const SizedBox(height: 8),
                Text('招募费用：$recruitmentCost 金币', style: const TextStyle(color: Color(0xFF5D4037))),
                const SizedBox(height: 8),
                Text('当前船员数：$currentCrewCount / $maxCrewCount', style: const TextStyle(color: Color(0xFF5D4037))),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PaperButton(
                  label: '再看看',
                  onPressed: () => Navigator.of(context).pop(),
                  style: PaperButtonStyle.brown,
                  width: 80,
                  height: 32,
                ),
                const SizedBox(width: 24),
                PaperButton(
                  label: '确认招募',
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
                  style: PaperButtonStyle.green,
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

  @override
  Widget build(BuildContext context) {
    final availableCrew = widget.gameState.availableTavernCrew;
    return PaperDialog(
      assetPath: 'assets/paper_ui/Sprites/Book_Desk/6.png',
      width: 1000,
      height: 800,
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.local_bar, color: Color(0xFF4E342E), size: 24),
                const SizedBox(width: 10),
                const Text(
                  '酒馆',
                  style: TextStyle(
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
          
          // 主要内容区域（左右分栏）
          Expanded(
            child: Row(
              children: [
                // 左侧：船员列表
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Color(0xFF8D6E63),
                          width: 1,
                        ),
                      ),
                    ),
                    child: availableCrew.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无可招募船员',
                              style: TextStyle(
                                color: Color(0xFF5D4037),
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
                              color: Color(0xFF5D4037),
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
              ? const Color(0xFFD7CCC8).withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5D4037)
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
                      color: Color(0xFF4E342E),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 技能和工资
                  Row(
                    children: [
                      _buildSkillChip('⛵', member.sailorSkill, Colors.blue[700]!),
                      const SizedBox(width: 4),
                      _buildSkillChip('🔧', member.shipwrightSkill, Colors.orange[800]!),
                      const SizedBox(width: 4),
                      _buildSkillChip('🔫', member.gunnerSkill, Colors.red[800]!),
                      const Spacer(),
                      Text(
                        '${member.salary}G',
                        style: const TextStyle(
                          color: Color(0xFF795548),
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
          color: const Color(0xFFD7CCC8),
          border: Border.all(
            color: const Color(0xFF8D6E63),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            displayChar,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4E342E),
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
          skill.toStringAsFixed(1),
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
                    color: Color(0xFF4E342E),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '工资：${member.salary} 金币 / 天',
                  style: const TextStyle(
                    color: Color(0xFF795548),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Color(0xFF8D6E63), height: 32),
          
          // 技能详情
          const Text(
            '技能：',
            style: TextStyle(
              color: Color(0xFF4E342E),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSkillDetailRow('⛵', '水手技能', member.sailorSkill, Colors.blue[700]!),
          const SizedBox(height: 8),
          _buildSkillDetailRow('🔧', '船工技能', member.shipwrightSkill, Colors.orange[800]!),
          const SizedBox(height: 8),
          _buildSkillDetailRow('🔫', '炮手技能', member.gunnerSkill, Colors.red[800]!),
          
          const Divider(color: Color(0xFF8D6E63), height: 32),
          
          // 描述
          const Text(
            '招募后可分配职业以提供加成（在船员管理界面）',
            style: TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCrewDescription(member),
            style: const TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          const Spacer(),
          
          // 按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PaperButton(
                onPressed: () {
                  setState(() {
                    _selectedCrew = null; // 取消选择，而不是关闭对话框
                  });
                },
                label: '取消',
                style: PaperButtonStyle.brown,
                width: 80,
                height: 32,
              ),
              const SizedBox(width: 24),
              PaperButton(
                onPressed: canRecruit
                    ? () => _recruitCrew(member)
                    : null,
                label: '招募船员',
                style: PaperButtonStyle.green,
                width: 80,
                height: 32,
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
          color: const Color(0xFFD7CCC8),
          border: Border.all(
            color: const Color(0xFF8D6E63),
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            displayChar,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4E342E),
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
              color: Color(0xFF5D4037),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          skill.toStringAsFixed(1),
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

