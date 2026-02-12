import 'package:flutter/material.dart';
import '../models/sea_event.dart';
import '../systems/sea_event_system.dart';
import 'paper_dialog.dart';

/// 海上随机事件对话框
class SeaEventDialog extends StatelessWidget {
  final SeaEvent event;

  const SeaEventDialog({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return PaperDialog(
      assetPath: 'assets/paper_ui/Sprites/Paper_UI_Pack/Plain/8_Shop/1.png',
      width: 600,
      height: 550, // Slightly taller to accommodate content
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/paper_ui/Sprites/Paper_UI_Pack/Plain/2_Headers/4.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Center(
              child: Text(
                event.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 中间内容区 (带滚动)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 图片 (占位符)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4E342E).withOpacity(0.3), width: 1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 描述
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.4,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),

          // 选项区 (固定在底部，如果太多也会滚动)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: event.choices.where((choice) {
                  if (choice.condition == 'combat_unlocked') {
                    return SeaEventSystem.instance.gameState?.isCombatUnlocked ?? false;
                  }
                  return true;
                }).map((choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        SeaEventSystem.instance.executeChoice(choice);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/paper_ui/Sprites/Paper_UI_Pack/Plain/3_Item_Holder/1.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            choice.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4E342E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 静态方法用于显示对话框
  static Future<void> show(BuildContext context, SeaEvent event) {
    return showDialog(
      context: context,
      barrierDismissible: false, // 强制选择
      builder: (context) => SeaEventDialog(event: event),
    );
  }
}
