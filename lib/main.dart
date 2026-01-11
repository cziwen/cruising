import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/main_menu_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/game_screen.dart';
import 'game/scale_wrapper.dart';
import 'utils/game_config_loader.dart';
import 'systems/window_controller.dart';

void main(List<String> args) async {
  // 检查是否以壁纸模式启动
  final bool isWallpaperMode = args.contains('--wallpaper');

  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 加载基础配置
  await GameConfigLoader().loadConfig();
  
  // 初始化 window_manager（仅在桌面端）
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
      defaultTargetPlatform == TargetPlatform.linux || 
      defaultTargetPlatform == TargetPlatform.macOS)) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = WindowOptions(
      size: const Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: isWallpaperMode,
      title: 'Cruising',
      titleBarStyle: isWallpaperMode ? TitleBarStyle.hidden : TitleBarStyle.normal,
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      if (!isWallpaperMode) {
        await windowManager.focus();
        try {
          await windowManager.setAspectRatio(16 / 9);
        } catch (e) {
          debugPrint('Failed to set aspect ratio: $e');
        }
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        // 如果是 Windows 且开启了壁纸模式，执行嵌入逻辑
        WindowController.embedInDesktop();
      }
    });
  }

  runApp(MainApp(isWallpaperMode: isWallpaperMode));
}

class MainApp extends StatelessWidget {
  final bool isWallpaperMode;
  const MainApp({super.key, this.isWallpaperMode = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cruising',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ScaleWrapper(
          backgroundColor: Colors.black,
          // 在壁纸模式下，不强制保持比例，允许宽度充满
          maintainAspectRatio: !isWallpaperMode,
          child: child!,
        );
      },
      home: LoadingScreen(
        nextScreen: const MainMenuScreen(),
        onLoad: GameScreen.preload,
      ),
    );
  }
}
