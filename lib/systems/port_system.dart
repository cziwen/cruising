import 'package:flutter/material.dart';
import '../models/port.dart';
import '../game/game_state.dart';
import '../game/paper_dialog.dart';
import '../game/paper_button.dart';
import 'quest_system.dart';

/// 港口系统 - 管理港口列表和切换
class PortSystem {
  final GameState gameState;

  PortSystem(this.gameState);

  /// 获取可访问的港口列表
  List<Port> getAvailablePorts() {
    var ports = gameState.ports.where((port) => port.unlocked).toList();

    // 如果当前在海上，过滤掉“海上”目的地和上一个出发港口
    if (gameState.isAtSea) {
      ports = ports.where((port) {
        // 不允许在海上时再次选择“海上”
        if (port.isSeaLocation) return false;
        // 不允许选择上一个出发的港口
        if (gameState.previousPort != null && port.id == gameState.previousPort!.id) {
          return false;
        }
        return true;
      }).toList();
    }

    // 将主岛放在第一个选项
    ports.sort((a, b) {
      if (a.id == 'home_island') return -1;
      if (b.id == 'home_island') return 1;
      return 0;
    });
    return ports;
  }

  /// 显示港口选择界面
  static void showPortSelectDialog(BuildContext context, PortSystem portSystem) {
    showDialog(
      context: context,
      builder: (context) => _PortSelectDialog(portSystem: portSystem),
    );
  }
}

/// 港口选择界面对话框
class _PortSelectDialog extends StatefulWidget {
  final PortSystem portSystem;

  const _PortSelectDialog({required this.portSystem});

  @override
  State<_PortSelectDialog> createState() => _PortSelectDialogState();
}

class _PortSelectDialogState extends State<_PortSelectDialog> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.portSystem.gameState.setPortListOpened(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 移除 mounted 检查，确保状态重置
      widget.portSystem.gameState.setPortListOpened(false);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availablePorts = widget.portSystem.getAvailablePorts();
    final currentPort = widget.portSystem.gameState.currentPort;

    return PaperDialog(
      assetPath: 'assets/paper_ui/Sprites/Book Desk/4.png',
      width: 500,
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择目的地 Select Destination',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4E342E),
                ),
              ),
              PaperButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF4E342E), size: 20),
                style: PaperButtonStyle.brown,
                width: 40,
                height: 40,
              ),
            ],
          ),
          const Divider(color: Color(0xFF8D6E63)),
          
          // 港口列表
          Expanded(
            child: ListView.builder(
              itemCount: availablePorts.length,
              itemBuilder: (context, index) {
                final port = availablePorts[index];
                final isCurrentPort = port.id == currentPort?.id;
                final isSeaLocation = port.isSeaLocation;

                // 准备高亮 ID
                final rowKeyId = 'ui.portRow(\'${port.id}\')';
                final actionKeyId = 'ui.portDepartButton(\'${port.id}\')';
                
                // 主岛特殊处理（向下兼容旧 ID）
                final isHomeIslandRow = port.id == 'home_island';
                
                Widget content = Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isCurrentPort 
                      ? const Color(0xFFD7CCC8).withValues(alpha: 0.5) 
                      : isSeaLocation
                          ? const Color(0xFFB3E5FC).withValues(alpha: 0.3) // 海上地点使用浅蓝色背景
                          : const Color(0xFFD7CCC8).withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isCurrentPort 
                          ? const Color(0xFF5D4037) 
                          : isSeaLocation
                              ? const Color(0xFF0277BD) // 海上地点使用蓝色边框
                              : const Color(0xFF8D6E63).withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isSeaLocation ? Icons.waves : Icons.location_on, 
                      color: isCurrentPort 
                          ? const Color(0xFF5D4037) 
                          : isSeaLocation
                              ? const Color(0xFF0277BD) // 海上地点使用蓝色图标
                              : const Color(0xFF8D6E63),
                    ),
                    title: Text(
                      port.name,
                      style: const TextStyle(color: Color(0xFF4E342E), fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      port.description,
                      style: const TextStyle(color: Color(0xFF5D4037), fontSize: 12),
                    ),
                    trailing: isCurrentPort
                        ? const Text(
                            '当前港口',
                            style: TextStyle(
                              color: Color(0xFF5D4037),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : QuestTarget(
                            id: actionKeyId,
                            child: PaperButton(
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                navigator.pop();
                                Future.microtask(() async {
                                  try {
                                    await widget.portSystem.gameState.startTravelToPort(port.id);
                                  } catch (e) {
                                    debugPrint('航行失败: $e');
                                  }
                                });
                              },
                              label: '出发',
                              style: PaperButtonStyle.brown,
                              width: 80,
                              height: 32,
                            ),
                          ),
                  ),
                );

                // 包装整行为 QuestTarget
                if (isHomeIslandRow) {
                  // 主岛行同时支持两个 ID
                  content = QuestTarget(
                    id: 'ui.homeIslandButton',
                    child: QuestTarget(
                      id: rowKeyId,
                      child: content,
                    ),
                  );
                } else {
                  content = QuestTarget(
                    id: rowKeyId,
                    child: content,
                  );
                }

                return content;
              },
            ),
          ),
        ],
      ),
    );
  }
}

