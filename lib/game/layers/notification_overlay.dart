import 'package:flutter/material.dart';
import '../../systems/guidance_system.dart';
import 'notification_item.dart';

/// 提示系统覆盖层容器
/// 监听 GuidanceSystem 并展示所有活跃提示
class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GuidanceSystem.instance,
      builder: (context, child) {
        final hints = GuidanceSystem.instance.activeHints;
        
        return Stack(
          children: [
            for (int i = 0; i < hints.length; i++)
              NotificationItem(
                key: ValueKey(hints[i].id),
                hint: hints[i],
                index: i,
                onDismissed: () {
                  GuidanceSystem.instance.removeHint(hints[i].id);
                },
              ),
          ],
        );
      },
    );
  }
}
