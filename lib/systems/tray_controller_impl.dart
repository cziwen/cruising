import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'window_controller.dart';

class TrayController extends TrayListener {
  static final TrayController _instance = TrayController._internal();
  factory TrayController() => _instance;
  TrayController._internal();

  Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 在 Windows 上使用 .ico 文件更稳定，其他平台使用 .png
      String iconPath = Platform.isWindows 
        ? 'assets/images/icon/app_icon.ico' 
        : 'assets/images/icon/Icon.png';

      await trayManager.setIcon(iconPath);
      
      // 监听窗口模式变化并更新托盘菜单
      WindowController.isWallpaperModeProvider.addListener(() {
        updateTrayMenu();
      });

      await updateTrayMenu();
      trayManager.addListener(this);
    }
  }

  Future<void> updateTrayMenu() async {
    final bool isWallpaper = WindowController.isWallpaperMode;
    
    final Menu menu = Menu(
      items: [
        MenuItem(
          key: 'toggle_mode',
          label: isWallpaper ? '恢复窗口化 (Restore Windowed)' : '无边框窗口化 (Borderless Mode)',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_game',
          label: '退出游戏 (Exit)',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() {
  }

  @override
  void onTrayIconMouseUp() {
    // 左键点击切换模式
    _toggleMode();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'toggle_mode') {
      _toggleMode();
    } else if (menuItem.key == 'exit_game') {
      exit(0);
    }
  }

  void _toggleMode() {
    if (WindowController.isWallpaperMode) {
      WindowController.restoreWindow();
    } else {
      WindowController.embedInDesktop();
    }
  }
}
