import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/foundation.dart';

class WindowController {
  static const int WM_SPAWN_WORKER = 0x052C;

  /// 将游戏窗口嵌入到 Windows 桌面底层 (WorkerW)
  static void embedInDesktop() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;

    // 1. 找到游戏主窗口句柄
    // 注意：标题必须与 main.dart 中的 title 一致
    final windowName = 'Cruising'.toNativeUtf16();
    final hwnd = FindWindow(null, windowName);
    free(windowName);

    if (hwnd == 0) {
      debugPrint('Failed to find game window');
      return;
    }

    // 2. 找到 Progman 窗口
    final progman = FindWindow('Progman'.toNativeUtf16(), nullptr);
    if (progman == 0) return;

    // 3. 发送消息触发 WorkerW 创建
    SendMessage(progman, WM_SPAWN_WORKER, 0, 0);

    // 4. 找到那个 WorkerW 窗口
    // 它通常是 Progman 的后继窗口中，类名为 WorkerW 且包含 SHELLDLL_DefView 的
    int workerW = 0;
    
    // 枚举窗口的回调函数
    int enumWindowProc(int hwnd, int lParam) {
      final shellDll = FindWindowEx(hwnd, 0, 'SHELLDLL_DefView'.toNativeUtf16(), nullptr);
      if (shellDll != 0) {
        // 找到了包含 SHELLDLL_DefView 的 WorkerW 的 *下一个* 窗口
        workerW = FindWindowEx(0, hwnd, 'WorkerW'.toNativeUtf16(), nullptr);
      }
      return 1; // 继续枚举
    }

    // 遍历顶级窗口查找 WorkerW
    final pEnumProc = NativeCallable<EnumWindowsProc>.isolateLocal(enumWindowProc);
    EnumWindows(pEnumProc.nativeFunction, 0);
    pEnumProc.close();

    if (workerW != 0) {
      // 5. 设置父窗口
      SetParent(hwnd, workerW);
      debugPrint('Successfully embedded in WorkerW');
    } else {
      // 如果没找到对应的 WorkerW，尝试直接挂载到 Progman (较旧版本 Windows)
      SetParent(hwnd, progman);
      debugPrint('Fallback: embedded in Progman');
    }

    // 6. 移除边框和标题栏
    final style = GetWindowLongPtr(hwnd, GWL_STYLE);
    SetWindowLongPtr(hwnd, GWL_STYLE, style & ~WS_CAPTION & ~WS_THICKFRAME);
    
    // 7. 全屏化
    final screenWidth = GetSystemMetrics(SM_CXSCREEN);
    final screenHeight = GetSystemMetrics(SM_CYSCREEN);
    SetWindowPos(hwnd, 0, 0, 0, screenWidth, screenHeight, SWP_SHOWWINDOW);
  }

  /// 恢复普通窗口模式
  static void restoreWindow() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;

    final windowName = 'Cruising'.toNativeUtf16();
    final hwnd = FindWindow(nullptr, windowName);
    free(windowName);

    if (hwnd == 0) return;

    // 恢复父窗口为桌面
    SetParent(hwnd, 0);

    // 恢复样式
    final style = GetWindowLongPtr(hwnd, GWL_STYLE);
    SetWindowLongPtr(hwnd, GWL_STYLE, style | WS_CAPTION | WS_THICKFRAME);

    // 恢复位置（这里可以根据需要设置初始大小）
    SetWindowPos(hwnd, HWND_TOP, 100, 100, 1280, 720, SWP_SHOWWINDOW);
  }
}
