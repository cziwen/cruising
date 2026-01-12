import 'dart:ffi';
import 'dart:ui' as ui;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

class WindowController {
  /// 全局沉浸模式状态
  static final ValueNotifier<bool> isWallpaperModeProvider = ValueNotifier<bool>(false);

  static bool get isWallpaperMode => isWallpaperModeProvider.value;

  /// 进入无边框沉浸模式
  static void embedInDesktop() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;

    // 1. 先将窗口透明度设为 0，防止切换样式时的原生白边闪烁
    await windowManager.setOpacity(0.0);

    // 2. 设置状态
    isWallpaperModeProvider.value = true;

    // 3. 获取句柄
    final windowName = 'Cruising'.toNativeUtf16();
    int hwnd = FindWindow(nullptr, windowName);
    free(windowName);
    if (hwnd == 0) hwnd = GetForegroundWindow();
    if (hwnd == 0) return;

    // 4. 同步 window_manager 状态
    // 先处理插件状态，防止其后续覆盖原生设置
    await windowManager.setAspectRatio(0); // 彻底禁用比例限制，防止沉浸模式下因比例不符导致的白边
    await windowManager.setSkipTaskbar(true);
    await windowManager.setHasShadow(false);

    // 5. 彻底移除窗口装饰与边框 (WS_POPUP)
    int style = GetWindowLongPtr(hwnd, GWL_STYLE);
    // 显式剥离所有边框、标题栏、对话框边框和调整大小相关的标志
    style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU | WS_DLGFRAME | WS_BORDER);
    style |= WS_POPUP | WS_VISIBLE;
    SetWindowLongPtr(hwnd, GWL_STYLE, style);

    // 6. 开启扩展透明样式 (WS_EX_LAYERED)
    int exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    // 移除窗口边缘样式并添加层叠样式
    exStyle &= ~(WS_EX_WINDOWEDGE | WS_EX_DLGMODALFRAME);
    SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle | WS_EX_LAYERED);

    // 7. 彻底消除 DWM 绘制的边框 (Margins 设置为 0)
    final margins = calloc<MARGINS>();
    margins.ref.cxLeftWidth = 0;
    margins.ref.cxRightWidth = 0;
    margins.ref.cyTopHeight = 0;
    margins.ref.cyBottomHeight = 0;
    DwmExtendFrameIntoClientArea(hwnd, margins);
    free(margins);

    // 8. 禁用窗口圆角 (防止 Windows 11 自动圆角导致的边缘留白)
    final cornerPreference = calloc<Int32>();
    cornerPreference.value = 1; // DWMWCP_DONOTROUND
    DwmSetWindowAttribute(hwnd, 33, cornerPreference, sizeOf<Int32>()); // 33 为 DWMWA_WINDOW_CORNER_PREFERENCE
    free(cornerPreference);

    // 9. 强制刷新窗口框架与样式
    SetWindowPos(hwnd, 0, 0, 0, 0, 0, 
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED | SWP_DRAWFRAME | SWP_NOACTIVATE | SWP_SHOWWINDOW);

    // 10. 强制 DWM 刷新：通过微调窗口大小（抖动）来强行重置渲染
    final rect = calloc<RECT>();
    GetWindowRect(hwnd, rect);
    final width = rect.ref.right - rect.ref.left;
    final height = rect.ref.bottom - rect.ref.top;
    
    // 增加 1 像素并立即恢复，触发系统重新计算所有像素对齐
    SetWindowPos(hwnd, 0, 0, 0, width + 1, height + 1, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    SetWindowPos(hwnd, 0, 0, 0, width, height, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    free(rect);

    // 11. 等待一小段时间（约 100ms），让 Flutter 引擎完成无边框模式下的首帧渲染
    await Future.delayed(const Duration(milliseconds: 100));
    await windowManager.setOpacity(1.0);
    
    debugPrint('Borderless immersion mode activated successfully.');
  }

  /// 恢复普通窗口模式
  static void restoreWindow() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;

    // 1. 获取句柄
    final windowName = 'Cruising'.toNativeUtf16();
    int hwnd = FindWindow(nullptr, windowName);
    free(windowName);
    if (hwnd == 0) hwnd = GetForegroundWindow();
    if (hwnd == 0) return;

    // 2. 核心：不仅设置不透明度，还要显式隐藏窗口，确保样式切换在不可见状态下完成
    await windowManager.setOpacity(0.0);
    ShowWindow(hwnd, SW_HIDE); // 原生隐藏，防止任何残留重绘
    
    isWallpaperModeProvider.value = false;

    // 3. 恢复普通窗口样式 (WS_OVERLAPPEDWINDOW)
    int style = GetWindowLongPtr(hwnd, GWL_STYLE);
    style = (style & ~WS_POPUP) | WS_OVERLAPPEDWINDOW;
    SetWindowLongPtr(hwnd, GWL_STYLE, style);

    // 恢复扩展样式（移除 WS_EX_LAYERED）
    int exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle & ~WS_EX_LAYERED);

    // 恢复 DWM 默认边框渲染
    final margins = calloc<MARGINS>();
    margins.ref.cxLeftWidth = 0;
    margins.ref.cxRightWidth = 0;
    margins.ref.cyTopHeight = 0;
    margins.ref.cyBottomHeight = 0;
    DwmExtendFrameIntoClientArea(hwnd, margins);
    free(margins);

    // 恢复默认圆角
    final cornerPreference = calloc<Int32>();
    cornerPreference.value = 0; // DWMWCP_DEFAULT
    DwmSetWindowAttribute(hwnd, 33, cornerPreference, sizeOf<Int32>());
    free(cornerPreference);

    // 4. 强制刷新框架，并通知插件同步状态
    SetWindowPos(hwnd, 0, 0, 0, 0, 0, 
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED | SWP_DRAWFRAME);

    await windowManager.setAspectRatio(16 / 9);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setHasShadow(true);
    await windowManager.setFullScreen(false);
    
    // 5. 【核心修复】微调尺寸强制触发布局刷新，并在不可见状态下居中
    await windowManager.setSize(const ui.Size(1280.1, 720.1));
    await windowManager.center();
    
    // 等待足够时间（150ms），让 Windows 和 Flutter 消化样式和尺寸变化
    await Future.delayed(const Duration(milliseconds: 150));
    
    // 6. 恢复标准尺寸并显示
    await windowManager.setSize(const ui.Size(1280, 720));
    ShowWindow(hwnd, SW_SHOW); // 原生显示
    await windowManager.show();
    await windowManager.focus();
    
    // 7. 最后恢复不透明度并强制位置刷新
    await windowManager.setOpacity(1.0);
    SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
    SetForegroundWindow(hwnd);
  }
}
