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
      builder: (context) => _MapPortSelectDialog(portSystem: portSystem),
    );
  }
}

/// 地图式港口选择界面对话框
class _MapPortSelectDialog extends StatefulWidget {
  final PortSystem portSystem;

  const _MapPortSelectDialog({required this.portSystem});

  @override
  State<_MapPortSelectDialog> createState() => _MapPortSelectDialogState();
}

class _MapPortSelectDialogState extends State<_MapPortSelectDialog> {
  String? hoveredPortId;
  String? selectedPortId;
  Offset? mousePosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.portSystem.gameState.setPortListOpened(true);
      // 同步初始选中的港口（如果有的话，虽然通常开始时没有）
      widget.portSystem.gameState.setSelectedMapPortId(selectedPortId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.portSystem.gameState.setPortListOpened(false);
      widget.portSystem.gameState.setSelectedMapPortId(null);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availablePorts = widget.portSystem.getAvailablePorts();
    final currentPort = widget.portSystem.gameState.currentPort;

    // 地图原始尺寸
    const double mapOriginalWidth = 1344.0;
    const double mapOriginalHeight = 768.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 计算缩放比例，保持长宽比
          double scale = (constraints.maxWidth / mapOriginalWidth);
          if (mapOriginalHeight * scale > constraints.maxHeight) {
            scale = constraints.maxHeight / mapOriginalHeight;
          }

          final double displayWidth = mapOriginalWidth * scale;
          final double displayHeight = mapOriginalHeight * scale;

          return Container(
            width: displayWidth,
            height: displayHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MouseRegion(
                onHover: (event) {
                  if (widget.portSystem.gameState.showMapCoordinates) {
                    setState(() {
                      mousePosition = event.localPosition;
                    });
                  }
                },
                onExit: (_) {
                  setState(() {
                    mousePosition = null;
                  });
                },
                child: Stack(
                  children: [
                    // 地图背景
                  Image.asset(
                    'assets/images/world_map/world_map.png',
                    width: displayWidth,
                    height: displayHeight,
                    fit: BoxFit.fill,
                  ),
                  
                  // 关闭按钮
                  Positioned(
                    top: 10,
                    right: 10,
                    child: PaperButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF4E342E), size: 20),
                      style: PaperButtonStyle.brown,
                      width: 40,
                      height: 40,
                    ),
                  ),

                  // 港口标记点
                  ...availablePorts.map((port) {
                    if (port.mapX == null || port.mapY == null) return const SizedBox.shrink();

                    final double x = port.mapX! * scale;
                    final double y = port.mapY! * scale;
                    final bool isHovered = hoveredPortId == port.id;
                    final bool isSelected = selectedPortId == port.id;
                    final bool isCurrent = port.id == currentPort?.id;

                    // 准备高亮 ID
                    final portKeyId = 'ui.mapPort(\'${port.id}\')';

                    return Positioned(
                      left: x - 50 * scale, // 增加点击区域
                      top: y - 50 * scale,
                      child: MouseRegion(
                        onEnter: (_) => setState(() => hoveredPortId = port.id),
                        onExit: (_) => setState(() => hoveredPortId = null),
                        cursor: SystemMouseCursors.click,
                        child: QuestTarget(
                          id: portKeyId,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: isCurrent ? null : () {
                              setState(() {
                                selectedPortId = port.id;
                                widget.portSystem.gameState.setSelectedMapPortId(port.id);
                              });
                            },
                            child: SizedBox(
                              width: 100 * scale,
                              height: 100 * scale,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 只有在选中时显示红圈
                                  if (isSelected)
                                    Opacity(
                                      opacity: 0.6,
                                      child: Image.asset(
                                        'assets/images/world_map/red_circle.png',
                                        width: 80 * scale,
                                        height: 80 * scale,
                                      ),
                                    ),
                                  
                                  // 港口图标
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        port.isSeaLocation ? Icons.waves : Icons.location_on,
                                        color: isCurrent 
                                            ? Colors.orange 
                                            : (isSelected ? Colors.red : (isHovered ? Colors.red.withValues(alpha: 0.5) : const Color(0xFF5D4037))),
                                        size: 30 * scale,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          port.name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12 * scale,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // 出发按钮 - 右下角
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: QuestTarget(
                      id: 'ui.mapDepartButton',
                      child: PaperButton(
                        onPressed: selectedPortId == null ? null : () async {
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          Future.microtask(() async {
                            try {
                              await widget.portSystem.gameState.startTravelToPort(selectedPortId!);
                            } catch (e) {
                              debugPrint('航行失败: $e');
                            }
                          });
                        },
                        label: '出发',
                        style: PaperButtonStyle.brown,
                        width: 100,
                        height: 48,
                      ),
                    ),
                  ),

                  // 坐标调试信息覆盖层
                  if (widget.portSystem.gameState.showMapCoordinates && mousePosition != null) ...[
                    // 十字准星
                    Positioned(
                      left: mousePosition!.dx - 10,
                      top: mousePosition!.dy,
                      child: Container(width: 20, height: 1, color: Colors.red),
                    ),
                    Positioned(
                      left: mousePosition!.dx,
                      top: mousePosition!.dy - 10,
                      child: Container(width: 1, height: 20, color: Colors.red),
                    ),
                    // 坐标文字
                    Positioned(
                      left: mousePosition!.dx + 10,
                      top: mousePosition!.dy + 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'X: ${(mousePosition!.dx / scale).toStringAsFixed(1)}, Y: ${(mousePosition!.dy / scale).toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
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
                '选择目的地',
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

