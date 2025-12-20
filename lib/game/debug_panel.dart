import 'dart:math';
import 'package:flutter/material.dart';
import 'game_state.dart';
import '../systems/save_system.dart';

/// 调试面板组件
class DebugPanel extends StatefulWidget {
  final GameState? gameState;

  const DebugPanel({super.key, this.gameState});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scale = min(screenSize.width / 1920, screenSize.height / 1080);

    return Positioned(
      top: 60 * scale,
      right: 16 * scale,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 调试面板内容
            SizeTransition(
              sizeFactor: _animation,
              axisAlignment: 1.0,
              child: Container(
              width: 200,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '调试面板',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 游戏内调试功能
                  if (widget.gameState != null) ...[
                    // 跳过航行动画开关
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '跳过航行动画',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Switch(
                          value: widget.gameState!.skipTravelAnimation,
                          onChanged: (value) {
                            widget.gameState!.setSkipTravelAnimation(value);
                          },
                          activeThumbColor: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 时间流逝开关
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '时间流逝',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Switch(
                          value: !widget.gameState!.isTimePaused,
                          onChanged: (value) {
                            widget.gameState!.setTimePaused(!value);
                          },
                          activeThumbColor: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 时间流逝倍数滑动条
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '时间倍数',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              '${widget.gameState!.timeMultiplier.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: widget.gameState!.timeMultiplier,
                          min: 0.1,
                          max: 10.0,
                          divisions: 99, // 0.1的步进
                          label: '${widget.gameState!.timeMultiplier.toStringAsFixed(1)}x',
                          onChanged: (value) {
                            widget.gameState!.setTimeMultiplier(value);
                          },
                          activeColor: Colors.orange,
                          inactiveColor: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 立即触发战斗按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.gameState!.isAtSea && !widget.gameState!.isInCombat
                            ? () {
                                widget.gameState!.triggerCombatImmediately();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          '触发战斗',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 添加金币按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.gameState!.addGold(1000);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已添加 1000 金币'),
                              duration: Duration(milliseconds: 500),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          '添加 1000 金币',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前状态: ${widget.gameState!.isAtSea ? "海上" : widget.gameState!.currentPort?.name ?? "未知"}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    if (widget.gameState!.isInCombat)
                      Text(
                        '战斗中',
                        style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    const Divider(color: Colors.white24),
                  ],

                  // 全局调试功能（删除存档）- 仅在主菜单显示（gameState 为 null）
                  if (widget.gameState == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('确认删除'),
                              content: const Text('确定要删除所有存档吗？此操作无法撤销。'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('删除', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            await SaveManager.deleteAllSaves();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('所有存档已删除')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          '删除所有存档',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
            // 切换按钮
            FloatingActionButton(
              mini: true,
              onPressed: _togglePanel,
              backgroundColor: Colors.orange,
              child: Icon(
                _isExpanded ? Icons.close : Icons.bug_report,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
