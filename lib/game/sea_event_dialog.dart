import 'package:flutter/material.dart';
import '../models/sea_event.dart';
import '../models/port.dart';
import '../systems/sea_event_system.dart';
import '../systems/trade_system.dart';
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
      width: 900,
      height: 825, // Slightly taller to accommodate content
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Center(
        child: SizedBox(
          width: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 96),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/paper_ui/Sprites/Paper_UI_Pack/Plain/2_Headers/4.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: Text(
                      event.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 中间内容区 (带滚动)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 图片显示区
                      Transform.scale(
                        scale: 0.8,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF4E342E).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: event.assetPath != null
                                ? Image.asset(
                                    event.assetPath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 48,
                                          color: Color(0xFF4E342E),
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 48,
                                      color: Color(0xFF4E342E),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // 描述
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.4,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 4),

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
                    }).map((choice) => Align(
                      heightFactor: 0.75,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final result = SeaEventSystem.instance.executeChoice(choice);
                            Navigator.of(context).pop();
                            
                            // 如果返回了港口对象，说明需要打开交易界面
                            if (result is Port) {
                              final gameState = SeaEventSystem.instance.gameState;
                              if (gameState != null) {
                                TradeSystem.showTradeDialog(
                                  context, 
                                  TradeSystem(gameState),
                                  portId: result.id,
                                );
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
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
              const SizedBox(height: 80),
            ],
          ),
        ),
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
