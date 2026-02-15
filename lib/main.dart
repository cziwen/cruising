import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'screens/loading_screen.dart';
import 'screens/game_screen.dart';
import 'game/scale_wrapper.dart';
import 'game/layers/quest_overlay.dart';
import 'l10n/app_localizations.dart';
import 'utils/game_config_loader.dart';
import 'systems/window_controller.dart';
import 'systems/tray_controller.dart';
import 'systems/quest_system.dart';
import 'systems/app_settings_controller.dart';

void main(List<String> args) async {
  // 检查是否通过命令行参数以壁纸模式启动
  final bool isWallpaperMode = args.contains('--wallpaper');

  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化系统托盘
  await TrayController().initialize();

  final appSettings = AppSettingsController();
  await appSettings.load();
  
  // 加载基础配置
  await GameConfigLoader().loadConfig(
    languageCode: appSettings.locale.languageCode,
  );
  
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
          // 仅在非壁纸模式下尝试限制比例
          await windowManager.setAspectRatio(16 / 9);
        } catch (e) {
          debugPrint('Failed to set aspect ratio: $e');
        }
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        // 如果是通过命令行开启了壁纸模式，执行嵌入逻辑
        WindowController.embedInDesktop();
      }
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: QuestSystem.instance),
        ChangeNotifierProvider.value(value: appSettings),
      ],
      child: MainApp(
        isWallpaperMode: isWallpaperMode,
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  final bool isWallpaperMode;
  const MainApp({super.key, this.isWallpaperMode = false});

  @override
  Widget build(BuildContext context) {
    // 如果是通过命令行指定的，初始化状态
    if (isWallpaperMode) {
      WindowController.isWallpaperModeProvider.value = true;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: WindowController.isWallpaperModeProvider,
      builder: (context, isWallpaper, child) {
        final appSettings = context.watch<AppSettingsController>();
        return MaterialApp(
          locale: appSettings.locale,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          builder: (context, child) {
            return ScaleWrapper(
              // 关键：沉浸模式下背景必须透明，否则黑色底色会遮挡 ShaderMask 的渐变透明效果
              backgroundColor: isWallpaper ? Colors.transparent : Colors.black,
              // 始终保持比例，修复无边框模式下的布局溢出
              maintainAspectRatio: true,
              child: Stack(
                children: [
                  child!,
                  const QuestOverlay(),
                ],
              ),
            );
          },
          home: LoadingScreen(
            nextScreen: const GameScreen(showMainMenuInitially: true),
            onLoad: GameScreen.preload,
          ),
        );
      },
    );
  }
}
