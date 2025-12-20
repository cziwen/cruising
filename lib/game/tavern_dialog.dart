import 'dart:math';
import 'package:flutter/material.dart';
import '../models/crew_member.dart';
import 'game_state.dart';
import 'scale_wrapper.dart';

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
  late List<CrewMember> _availableCrew;
  CrewMember? _selectedCrew;
  final Random _random = Random();

  // 预定义的中文姓名池
  static const List<String> _namePool = [
    '杰克', '汤姆', '强尼', '老汤姆', '火枪手', '水手长', '老水手',
    '铁匠', '炮手', '舵手', '大副', '二副', '水手', '船工',
    '老船长', '新兵', '老兵', '海盗', '商人', '冒险家',
    '史密斯', '约翰', '威廉', '詹姆斯', '查尔斯', '罗伯特',
    '李明', '王强', '张伟', '刘洋', '陈军', '杨帆',
  ];

  // 角色描述池（用于风格化）
  static const List<String> _descriptionPool = [
    '一位经验丰富的老水手，曾在多个海域航行。',
    '年轻但充满活力的新兵，渴望在海上证明自己。',
    '技艺精湛的船工，擅长修理各种船只。',
    '神枪手，能在远距离精准命中目标。',
    '曾经的海盗，现在寻求合法的工作。',
    '来自远方的冒险家，拥有独特的技能。',
    '沉默寡言的工匠，但手艺精湛。',
    '热情开朗的水手，总能给船员带来欢乐。',
  ];

  @override
  void initState() {
    super.initState();
    _generateAvailableCrew();
  }

  /// 生成可招募的船员列表
  void _generateAvailableCrew() {
    final count = 3 + _random.nextInt(3); // 3-5个船员
    _availableCrew = [];
    final existingNames = widget.gameState.crewManager.crewMembers
        .map((m) => m.name)
        .toSet();

    for (int i = 0; i < count; i++) {
      String name;
      int attempts = 0;
      // 确保姓名不重复
      do {
        name = _namePool[_random.nextInt(_namePool.length)];
        attempts++;
        if (attempts > 100) {
          // 如果尝试太多次，添加序号
          name = '${name}_${_random.nextInt(1000)}';
          break;
        }
      } while (existingNames.contains(name) || 
               _availableCrew.any((c) => c.name == name));

      // 使用曲线公式生成技能值：y = C ⋅ (x / C)^a
      // C = 10 (cap), x = [0, 10] 随机数
      // 水手 a=10, 船工 a=2, 炮手 a=6
      final sailorSkill = _generateSkillWithCurve(10.0);   // 水手 a=10
      final shipwrightSkill = _generateSkillWithCurve(2.0); // 船工 a=2
      final gunnerSkill = _generateSkillWithCurve(6.0);     // 炮手 a=6
      
      // 计算工资：总技能值 × 2.0 + 基础工资（1-10随机）
      final totalSkill = sailorSkill + shipwrightSkill + gunnerSkill;
      final salary = (totalSkill * 2.0).round() + 1 + _random.nextInt(10);

      _availableCrew.add(CrewMember(
        name: name,
        sailorSkill: sailorSkill,
        shipwrightSkill: shipwrightSkill,
        gunnerSkill: gunnerSkill,
        salary: salary,
        assignedRole: CrewRole.unassigned,
      ));
    }
    // 不默认选中任何船员，让用户自己选择
  }

  /// 使用曲线公式生成技能值
  /// 公式：y = C ⋅ (x / C)^a
  /// C = 10 (cap), x = [0, 10] 随机数, a = 曲度参数
  /// 返回保留2位小数的double值
  double _generateSkillWithCurve(double a) {
    const double C = 10.0; // cap值
    final double x = _random.nextDouble() * C; // [0, 10] 随机数
    
    // 计算 y = C ⋅ (x / C)^a
    final double ratio = x / C; // [0, 1]
    final double y = C * pow(ratio, a);
    
    // 保留2位小数
    return double.parse(y.toStringAsFixed(2));
  }

  /// 获取角色描述
  String _getCrewDescription(CrewMember member) {
    // 根据技能值选择描述（技能值上限现在是10）
    final maxSkill = [
      member.sailorSkill,
      member.shipwrightSkill,
      member.gunnerSkill,
    ].reduce((a, b) => a > b ? a : b);
    
    if (maxSkill == member.sailorSkill && member.sailorSkill > 5.0) {
      return '一位经验丰富的老水手，曾在多个海域航行。';
    } else if (maxSkill == member.shipwrightSkill && member.shipwrightSkill > 5.0) {
      return '技艺精湛的船工，擅长修理各种船只。';
    } else if (maxSkill == member.gunnerSkill && member.gunnerSkill > 5.0) {
      return '神枪手，能在远距离精准命中目标。';
    }
    
    // 随机选择一个描述
    return _descriptionPool[_random.nextInt(_descriptionPool.length)];
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
              
              // 添加船员
              widget.gameState.addCrewMember(member);
              
              // 从可招募列表中移除
              setState(() {
                _availableCrew.remove(member);
                if (_availableCrew.isEmpty) {
                  _selectedCrew = null;
                } else {
                  _selectedCrew = _availableCrew.first;
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
    return ScaleWrapper(
      child: Dialog(
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
                        child: _availableCrew.isEmpty
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
                                itemCount: _availableCrew.length,
                                itemBuilder: (context, index) {
                                  final crew = _availableCrew[index];
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
    final displayChar = member.name.isNotEmpty
        ? member.name[0].toUpperCase()
        : '?';
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 50,
        height: 50,
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
            style: const TextStyle(
              fontSize: 20,
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
    final displayChar = member.name.isNotEmpty
        ? member.name[0].toUpperCase()
        : '?';
    
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

