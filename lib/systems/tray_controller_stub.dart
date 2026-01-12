import 'package:tray_manager/tray_manager.dart';

class TrayController extends TrayListener {
  static final TrayController _instance = TrayController._internal();
  factory TrayController() => _instance;
  TrayController._internal();

  Future<void> initialize() async {
    // Web 平台不做任何事
  }

  Future<void> updateTrayMenu() async {
    // Web 平台不做任何事
  }
}
