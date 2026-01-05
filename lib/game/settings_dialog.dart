import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'game_state.dart';
import '../screens/save_load_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/main_menu_screen.dart';
import 'paper_dialog.dart';

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

    return PaperDialog(
      assetPath: 'assets/paper_ui/Sprites/Book Desk/4.png',
      width: 500,
      height: 600,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '设置 Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E342E),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF4E342E)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF8D6E63), height: 1),
          
          // 内容区域
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSwitchTile('音乐', true, (v) {}),
                  _buildSwitchTile('音效', true, (v) {}),
                  
                  // 仅在桌面端显示分辨率和全屏设置
                  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                      defaultTargetPlatform == TargetPlatform.linux || 
                      defaultTargetPlatform == TargetPlatform.macOS)) ...[
                    const Divider(color: Color(0xFF8D6E63)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        '显示设置',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                    ),
                    _buildSwitchTile('全屏模式', _isFullScreen, (value) async {
                      await windowManager.setFullScreen(value);
                      setState(() {
                        _isFullScreen = value;
                      });
                    }),
                    // 只有非全屏模式下才显示分辨率选择
                    if (!_isFullScreen)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '窗口分辨率',
                              style: TextStyle(color: Color(0xFF5D4037)),
                            ),
                            DropdownButton<Size>(
                              value: _currentResolution,
                              dropdownColor: const Color(0xFFEFEBE9),
                              style: const TextStyle(color: Color(0xFF4E342E)),
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
                    const Divider(color: Color(0xFF8D6E63)),
                    // 游戏控制选项
                    _buildActionTile(Icons.save, '保存游戏', () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SaveLoadScreen(
                            mode: SaveLoadMode.save,
                            gameState: widget.gameState!,
                          ),
                        ),
                      );
                    }),
                    _buildActionTile(Icons.file_upload, '读取游戏', () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SaveLoadScreen(
                            mode: SaveLoadMode.load,
                          ),
                        ),
                      );
                    }),
                    _buildActionTile(Icons.home, '返回主菜单', () {
                      Navigator.of(context).pop();
                      _showExitConfirmation(context);
                    }),
                  ],
                ],
              ),
            ),
          ),
          
          const Divider(color: Color(0xFF8D6E63), height: 1),
          // 底部按钮
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '关闭',
                    style: TextStyle(color: Color(0xFF8D6E63), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Color(0xFF4E342E))),
      value: value,
      activeColor: const Color(0xFF5D4037),
      activeTrackColor: const Color(0xFFD7CCC8),
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5D4037)),
      title: Text(title, style: const TextStyle(color: Color(0xFF4E342E))),
      onTap: onTap,
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEFEBE9),
        title: const Text('返回主菜单', style: TextStyle(color: Color(0xFF4E342E), fontWeight: FontWeight.bold)),
        content: const Text('未保存的进度将会丢失，确定要返回主菜单吗？', style: TextStyle(color: Color(0xFF5D4037))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消', style: TextStyle(color: Color(0xFF8D6E63))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoadingScreen(
                    nextScreen: MainMenuScreen(),
                  ),
                ),
              );
            },
            child: const Text('确定', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
