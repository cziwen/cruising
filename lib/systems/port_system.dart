import 'package:flutter/material.dart';
import '../models/port.dart';
import '../game/game_state.dart';

/// 港口系统 - 管理港口列表和切换
class PortSystem {
  final GameState gameState;

  PortSystem(this.gameState);

  /// 获取可访问的港口列表
  List<Port> getAvailablePorts() {
    return gameState.ports.where((port) => port.unlocked).toList();
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
class _PortSelectDialog extends StatelessWidget {
  final PortSystem portSystem;

  const _PortSelectDialog({required this.portSystem});

  @override
  Widget build(BuildContext context) {
    final availablePorts = portSystem.getAvailablePorts();
    final currentPort = portSystem.gameState.currentPort;

    return Dialog(
      child: Container(
        width: 500,
        height: 400,
        padding: const EdgeInsets.all(16),
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
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            
            // 港口列表
            Expanded(
              child: ListView.builder(
                itemCount: availablePorts.length,
                itemBuilder: (context, index) {
                  final port = availablePorts[index];
                  final isCurrentPort = port.id == currentPort?.id;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCurrentPort ? Colors.blue.withValues(alpha: 0.2) : null,
                    child: ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(port.name),
                      subtitle: Text(port.description),
                      trailing: isCurrentPort
                          ? const Text(
                              '当前港口',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () async {
                                // 在异步操作前保存必要的引用
                                final navigator = Navigator.of(context);
                                
                                // 关闭对话框
                                navigator.pop();
                                
                                // 使用 Future.microtask 确保在下一个事件循环中执行
                                // 这样可以避免在 widget 销毁时访问 context
                                Future.microtask(() async {
                                  try {
                                    await portSystem.gameState.startTravelToPort(port.id);
                                    // 成功消息不再显示，因为对话框已关闭
                                  } catch (e) {
                                    // 错误处理：由于 context 可能已失效，我们不在异步操作后显示错误
                                    // 错误会通过 GameState 的异常传播，可以在上层处理
                                    debugPrint('航行失败: $e');
                                  }
                                });
                              },
                              child: const Text('出发'),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

