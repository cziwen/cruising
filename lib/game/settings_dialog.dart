import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'scale_wrapper.dart';
import 'game_state.dart';
import '../screens/save_load_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/main_menu_screen.dart';

/// 设置对话框
class SettingsDialog extends StatefulWidget {
  final GameState? gameState; // 如果提供，则显示游戏内选项（保存/读取/返回主菜单）

  const SettingsDialog({
    super.key,
    this.gameState,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  // 分辨率设置
  final List<Size> _resolutions = const [
    Size(1280, 720),
    Size(1920, 1080),
    Size(2560, 1440),
  ];
  Size _currentResolution = const Size(1280, 720);
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    // 仅在桌面端初始化状态
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.macOS)) {
      _checkFullScreenState();
    }
  }

  Future<void> _checkFullScreenState() async {
    final isFullScreen = await windowManager.isFullScreen();
    final size = await windowManager.getSize();
    if (mounted) {
      setState(() {
        _isFullScreen = isFullScreen;
        // 尝试匹配当前分辨率
        try {
          _currentResolution = _resolutions.firstWhere(
            (r) => r.width == size.width && r.height == size.height,
            orElse: () => _resolutions[0],
          );
        } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isInGame = widget.gameState != null;

    return ScaleWrapper(
      child: Dialog(
        backgroundColor: Colors.transparent, // 背景透明，由 Container 控制
        child: Container(
          width: 500, // 设计尺寸
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '设置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              
              // 内容区域
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('音乐'),
                        value: true,
                        onChanged: (value) {},
                      ),
                      SwitchListTile(
                        title: const Text('音效'),
                        value: true,
                        onChanged: (value) {},
                      ),
                      // 仅在桌面端显示分辨率和全屏设置
                      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                          defaultTargetPlatform == TargetPlatform.linux || 
                          defaultTargetPlatform == TargetPlatform.macOS)) ...[
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text('显示设置', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        SwitchListTile(
                          title: const Text('全屏模式'),
                          value: _isFullScreen,
                          onChanged: (value) async {
                            await windowManager.setFullScreen(value);
                            setState(() {
                              _isFullScreen = value;
                            });
                          },
                        ),
                        // 只有非全屏模式下才显示分辨率选择
                        if (!_isFullScreen)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('窗口分辨率'),
                                DropdownButton<Size>(
                                  value: _currentResolution,
                                  items: _resolutions.map((size) {
                                    return DropdownMenuItem<Size>(
                                      value: size,
                                      child: Text('${size.width.toInt()} x ${size.height.toInt()}'),
                                    );
                                  }).toList(),
                                  onChanged: (Size? newSize) async {
                                    if (newSize != null) {
                                      setState(() {
                                        _currentResolution = newSize;
                                      });
                                      await windowManager.setSize(newSize);
                                      await windowManager.center();
                                      // 强制设置纵横比（如果需要保持16:9）
                                      try {
                                        await windowManager.setAspectRatio(16 / 9);
                                      } catch (_) {}
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                      
                      // 游戏内选项
                      if (isInGame) ...[
                        const Divider(),
                        // 游戏控制选项
                        ListTile(
                          leading: const Icon(Icons.save),
                          title: const Text('保存游戏'),
                          onTap: () {
                            // 关闭设置对话框后打开保存页面
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SaveLoadScreen(
                                  mode: SaveLoadMode.save,
                                  gameState: widget.gameState!,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.file_upload),
                          title: const Text('读取游戏'),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SaveLoadScreen(
                                  mode: SaveLoadMode.load,
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.home),
                          title: const Text('返回主菜单'),
                          onTap: () {
                            Navigator.of(context).pop(); // 关闭设置对话框
                            // 显示确认对话框
                            showDialog(
                              context: context,
                              builder: (context) => ScaleWrapper(
                                child: AlertDialog(
                                  title: const Text('返回主菜单'),
                                  content: const Text('未保存的进度将会丢失，确定要返回主菜单吗？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // 关闭确认对话框
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) => const LoadingScreen(
                                              nextScreen: MainMenuScreen(),
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('确定'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const Divider(height: 1),
              // 底部按钮
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('关闭'),
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
}



