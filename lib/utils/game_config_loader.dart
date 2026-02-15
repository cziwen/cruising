import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/goods.dart';
import '../models/port.dart';
import '../models/quest.dart';
import '../models/sea_event.dart';

/// 游戏配置加载器，用于从 JSON 文件中读取基础配置信息
class GameConfigLoader {
  static final GameConfigLoader _instance = GameConfigLoader._internal();
  factory GameConfigLoader() => _instance;
  GameConfigLoader._internal();

  List<Goods>? _goodsList;
  List<Port>? _portsList;
  List<Quest>? _questsList;
  List<SeaEvent>? _seaEventsList;
  Map<String, dynamic>? _crewConfig;
  Map<String, dynamic>? _musicConfig;
  Map<String, dynamic>? _sfxConfig;
  bool _isLoading = false;
  bool _isLoaded = false;
  String _currentLanguageCode = 'zh';

  bool get isLoaded => _isLoaded;
  String get currentLanguageCode => _currentLanguageCode;

  /// 获取船员配置
  Map<String, dynamic> get crewConfig {
    if (_crewConfig == null) {
      debugPrint('⚠ Warning: Accessing crewConfig before it is loaded.');
      return {};
    }
    return _crewConfig!;
  }

  /// 获取音乐配置
  Map<String, dynamic> get musicConfig {
    if (_musicConfig == null) {
      debugPrint('⚠ Warning: Accessing musicConfig before it is loaded.');
      return {};
    }
    return _musicConfig!;
  }

  /// 获取音效配置
  Map<String, dynamic> get sfxConfig {
    if (_sfxConfig == null) {
      debugPrint('⚠ Warning: Accessing sfxConfig before it is loaded.');
      return {};
    }
    return _sfxConfig!;
  }

  /// 获取所有货物列表
  List<Goods> get goodsList {
    if (_goodsList == null) {
      debugPrint('⚠ Warning: Accessing goodsList before it is loaded.');
      return []; // 返回空列表而不是抛出异常
    }
    return _goodsList!;
  }

  /// 获取所有港口列表
  List<Port> get portsList {
    if (_portsList == null) {
      debugPrint('⚠ Warning: Accessing portsList before it is loaded.');
      return []; // 返回空列表而不是抛出异常
    }
    return _portsList!;
  }

  /// 获取所有任务列表
  List<Quest> get questsList {
    if (_questsList == null) {
      debugPrint('⚠ Warning: Accessing questsList before it is loaded.');
      return [];
    }
    return _questsList!;
  }

  /// 获取所有海上事件列表
  List<SeaEvent> get seaEventsList {
    if (_seaEventsList == null) {
      debugPrint('⚠ Warning: Accessing seaEventsList before it is loaded.');
      return [];
    }
    return _seaEventsList!;
  }

  /// 加载所有配置文件
  Future<void> loadConfig({String? languageCode, bool forceReload = false}) async {
    if (languageCode != null) {
      _currentLanguageCode = _normalizeLanguageCode(languageCode);
    }
    if (_isLoading) return;
    if (_isLoaded && !forceReload) return;

    _isLoading = true;
    _isLoaded = false;
    try {
      await Future.wait([
        _loadGoodsConfig(),
        _loadPortsConfig(),
        _loadQuestsConfig(),
        _loadSeaEventsConfig(),
        _loadCrewConfig(),
        _loadMusicConfig(),
        _loadSfxConfig(),
      ]);
      _isLoaded = true;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> reloadForLocale(String languageCode) async {
    final normalized = _normalizeLanguageCode(languageCode);
    if (_isLoaded && _currentLanguageCode == normalized) return;
    _currentLanguageCode = normalized;
    await loadConfig(forceReload: true);
  }

  Future<void> _loadGoodsConfig() async {
    try {
      final String response = await _loadLocalizedConfigString('goods.json');
      final List<dynamic> data = json.decode(response);
      _goodsList = data.map((json) => Goods.fromJson(json)).toList();
    } catch (e) {
      debugPrint('✗ Error loading goods config: $e');
      _goodsList = []; // 发生错误时给一个空列表，防止之后访问抛错
    }
  }

  Future<void> _loadPortsConfig() async {
    try {
      final String response = await _loadLocalizedConfigString('ports.json');
      final List<dynamic> data = json.decode(response);
      
      // 1. 查找并解析 base 配置
      final baseEntry = data.firstWhere((item) => item['id'] == 'base', orElse: () => null);
      if (baseEntry != null && baseEntry['goodsConfig'] != null) {
        Port.baseGoodsConfig = (baseEntry['goodsConfig'] as Map).map(
          (key, value) => MapEntry(key as String,
              PortGoodsConfig.fromJson(value as Map<String, dynamic>)),
        );
      }

      // 2. 加载普通港口，排除 base 条目
      _portsList = data
          .where((item) => item['id'] != 'base')
          .map((json) => Port.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('✗ Error loading ports config: $e');
      _portsList = []; // 发生错误时给一个空列表
    }
  }

  Future<void> _loadQuestsConfig() async {
    try {
      final String response = await _loadLocalizedConfigString('quests.json');
      final List<dynamic> data = json.decode(response);
      _questsList = data.map((json) => Quest.fromJson(json)).toList();
    } catch (e) {
      debugPrint('✗ Error loading quests config: $e');
      _questsList = [];
    }
  }

  Future<void> _loadCrewConfig() async {
    try {
      final String response = await _loadLocalizedConfigString('crew.json');
      _crewConfig = json.decode(response);
    } catch (e) {
      debugPrint('✗ Error loading crew config: $e');
      _crewConfig = {};
    }
  }

  Future<void> _loadMusicConfig() async {
    try {
      final String response = await rootBundle.loadString('assets/config/music.json');
      _musicConfig = json.decode(response);
    } catch (e) {
      debugPrint('✗ Error loading music config: $e');
      _musicConfig = {};
    }
  }

  Future<void> _loadSfxConfig() async {
    try {
      final String response = await rootBundle.loadString('assets/config/sfx.json');
      _sfxConfig = json.decode(response);
    } catch (e) {
      debugPrint('✗ Error loading sfx config: $e');
      _sfxConfig = {};
    }
  }

  Future<void> _loadSeaEventsConfig() async {
    try {
      final String response = await _loadLocalizedConfigString('sea_events.json');
      final List<dynamic> data = json.decode(response);
      _seaEventsList = data.map((json) => SeaEvent.fromJson(json)).toList();
    } catch (e) {
      debugPrint('✗ Error loading sea events config: $e');
      _seaEventsList = [];
    }
  }

  /// 根据 ID 获取商品信息
  Goods getGoodsById(String goodsId) {
    return goodsList.firstWhere(
      (g) => g.id == goodsId,
      orElse: () => throw Exception('Goods not found in config: $goodsId'),
    );
  }

  String _normalizeLanguageCode(String languageCode) {
    final code = languageCode.toLowerCase();
    return code == 'en' ? 'en' : 'zh';
  }

  Future<String> _loadLocalizedConfigString(String fileName) async {
    final String localizedPath = 'assets/config/i18n/$_currentLanguageCode/$fileName';
    final String zhPath = 'assets/config/i18n/zh/$fileName';
    final String legacyPath = 'assets/config/$fileName';

    try {
      return await rootBundle.loadString(localizedPath);
    } catch (_) {
      try {
        return await rootBundle.loadString(zhPath);
      } catch (_) {
        return await rootBundle.loadString(legacyPath);
      }
    }
  }
}
