import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'game_state.dart';
import '../screens/save_load_screen.dart';
import '../screens/game_screen.dart';
import 'paper_dialog.dart';
import 'paper_button.dart';
import '../systems/music_system.dart';
import '../systems/window_controller.dart';
import '../systems/quest_system.dart';

/// 设置对话框
class SettingsDialog extends StatefulWidget {
  final GameState? gameState; // 如果提供，则显示游戏内选项（保存/读取/返回主菜单）
  final VoidCallback? onReturnToMainMenu;

  const SettingsDialog({
    super.key,
    this.gameState,
    this.onReturnToMainMenu,
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
  bool _isWallpaperMode = false;

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
    // 这里简单通过 skipTaskbar 来判断是否是壁纸模式
    final skipTaskbar = await windowManager.isSkipTaskbar();

    if (mounted) {
      setState(() {
        _isFullScreen = isFullScreen;
        _isWallpaperMode = skipTaskbar;
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
                // 移除右上角的 IconButton
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      '声音设置',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E342E),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text('音乐音量', style: TextStyle(color: Color(0xFF4E342E))),
                        Expanded(
                          child: Slider(
                            value: MusicSystem().musicVolume,
                            activeColor: const Color(0xFF5D4037),
                            inactiveColor: const Color(0xFFD7CCC8),
                            onChanged: (v) {
                              setState(() {
                                MusicSystem().setMusicVolume(v);
                              });
                            },
                          ),
                        ),
                        Text('${(MusicSystem().musicVolume * 100).toInt()}%', style: const TextStyle(color: Color(0xFF4E342E))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text('音效音量', style: TextStyle(color: Color(0xFF4E342E))),
                        Expanded(
                          child: Slider(
                            value: MusicSystem().sfxVolume,
                            activeColor: const Color(0xFF5D4037),
                            inactiveColor: const Color(0xFFD7CCC8),
                            onChanged: (v) {
                              setState(() {
                                MusicSystem().setSfxVolume(v);
                              });
                            },
                          ),
                        ),
                        Text('${(MusicSystem().sfxVolume * 100).toInt()}%', style: const TextStyle(color: Color(0xFF4E342E))),
                      ],
                    ),
                  ),
                  
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
                    if (defaultTargetPlatform == TargetPlatform.windows)
                      _buildSwitchTile('动态壁纸模式', _isWallpaperMode, (value) async {
                        if (value) {
                          WindowController.embedInDesktop();
                          await windowManager.setSkipTaskbar(true);
                        } else {
                          WindowController.restoreWindow();
                          await windowManager.setSkipTaskbar(false);
                        }
                        setState(() {
                          _isWallpaperMode = value;
                        });
                      }),
                    // 只有非全屏模式下才显示分辨率选择
                    if (!_isFullScreen && !_isWallpaperMode)
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
                PaperButton(
                  label: '关闭',
                  onPressed: () => Navigator.of(context).pop(),
                  style: PaperButtonStyle.brown,
                  width: 80,
                  height: 32,
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
      builder: (context) => PaperDialog(
        assetPath: 'assets/paper_ui/Sprites/Book Desk/4.png',
        width: 400,
        height: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('返回主菜单', style: TextStyle(color: Color(0xFF4E342E), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('未保存的进度将会丢失，确定要返回主菜单吗？', style: TextStyle(color: Color(0xFF5D4037)), textAlign: TextAlign.center),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PaperButton(
                  label: '取消',
                  onPressed: () => Navigator.of(context).pop(),
                  style: PaperButtonStyle.brown,
                  width: 80,
                  height: 32,
                ),
                PaperButton(
                  label: '确定',
                  onPressed: () {
                    if (widget.onReturnToMainMenu != null) {
                      widget.onReturnToMainMenu!();
                    } else {
                      QuestSystem.instance.reset();
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const GameScreen(
                            showMainMenuInitially: true,
                          ),
                        ),
                      );
                    }
                  },
                  style: PaperButtonStyle.red,
                  width: 80,
                  height: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
