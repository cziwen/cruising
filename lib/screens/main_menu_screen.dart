import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show exit;
import 'package:window_manager/window_manager.dart';
import '../game/debug_panel.dart';
import '../game/settings_dialog.dart';
import 'game_screen.dart';
import 'loading_screen.dart';
import 'save_load_screen.dart';
import '../systems/save_system.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  // 分辨率选项
  final List<Size> _resolutions = const [
    Size(1280, 720),
    Size(1920, 1080),
    Size(2560, 1440),
  ];
  
  // 当前选择的分辨率
  final Size _currentResolution = const Size(1280, 720);
  
  // 全屏状态
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
    if (mounted) {
      setState(() {
        _isFullScreen = isFullScreen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景层
          Positioned.fill(
            child: Image.asset(
              'assets/images/oceanbackground.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 内容层
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 标题
                const Text(
                  'Cruising',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(5.0, 5.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                
                // 菜单按钮
                _buildMenuButton(
                  context,
                  label: '新游戏',
                  onPressed: () => _startNewGame(context),
                ),
                const SizedBox(height: 20),
                
                _buildMenuButton(
                  context,
                  label: '继续游戏',
                  onPressed: () => _continueGame(context),
                  isSecondary: true,
                ),
                const SizedBox(height: 20),
                
                _buildMenuButton(
                  context,
                  label: '读取存档',
                  onPressed: () => _loadGame(context),
                  isSecondary: true,
                ),
                const SizedBox(height: 20),
                
                _buildMenuButton(
                  context,
                  label: '设置',
                  onPressed: () => _showSettings(context),
                ),
                const SizedBox(height: 20),
                
                // 仅在非 Web 平台显示退出按钮
                if (!kIsWeb) 
                  _buildMenuButton(
                    context,
                    label: '退出',
                    onPressed: () => _exitGame(),
                  ),
              ],
            ),
          ),
          
          // 调试面板
          const DebugPanel(),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white.withOpacity(0.8) : Colors.white,
          foregroundColor: Colors.blue[900],
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _startNewGame(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoadingScreen(
          nextScreen: const GameScreen(),
          onLoad: GameScreen.preload,
        ),
      ),
    );
  }

  Future<void> _continueGame(BuildContext context) async {
    try {
      final slots = await SaveManager.getSaveSlots();
      if (slots.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('暂无存档')),
          );
        }
        return;
      }

      // Sort by timestamp descending
      slots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestSlot = slots.first;

      final gameData = await SaveManager.loadGame(latestSlot.id);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoadingScreen(
              nextScreen: GameScreen(initialSaveData: gameData),
              onLoad: GameScreen.preload,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取存档失败: $e')),
        );
      }
    }
  }

  void _loadGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SaveLoadScreen(mode: SaveLoadMode.load),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  void _exitGame() {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux)) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }
}
