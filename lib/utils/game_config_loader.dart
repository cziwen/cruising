import 'dart:convert';
import 'dart:ui';
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

  bool get isLoaded => _isLoaded;

  /// 加载指定语言的配置文件，如果 locale 为 null 则加载默认配置 (默认为 English 'en')
  Future<void> _loadLocalizedConfig(Locale? locale) async {
    final String langCode = locale?.languageCode ?? 'en';
    
    // 如果是默认语言 zh，直接加载原文件即可，或者尝试加载 _zh 文件
    // 这里我们约定：原文件是中文，翻译文件是 _en.json 等
    // 尽管原文件是中文，但系统启动默认会加载 _en.json 以提供英文体验。
    
    await Future.wait([
      _loadGoodsConfig(langCode),
      _loadPortsConfig(langCode),
      _loadQuestsConfig(langCode),
      _loadSeaEventsConfig(langCode),
      _loadCrewConfig(langCode),
      _loadMusicConfig(), // 音乐配置暂不本地化
      _loadSfxConfig(),   // 音效配置暂不本地化
    ]);
  }

  Future<String> _loadJsonString(String basePath, String langCode) async {
    // 优先尝试加载 {basePath}_{langCode}.json
    // 如果 langCode 是 zh，优先加载原路径，因为原路径就是中文
    if (langCode == 'zh') {
      try {
        return await rootBundle.loadString(basePath);
      } catch (_) {
        // fallback
      }
    }

    final String localizedPath = basePath.replaceFirst('.json', '_$langCode.json');
    try {
      return await rootBundle.loadString(localizedPath);
    } catch (e) {
      // 如果本地化文件不存在，回退到默认文件
      return await rootBundle.loadString(basePath);
    }
  }

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
  Future<void> loadConfig({Locale? locale}) async {
    if (_isLoading) return;
    // 如果已经加载过了，且 locale 没变，可以跳过。但这里简单起见，如果传入 locale 就重新加载
    // 实际项目中可以记录当前的 _currentLocale

    _isLoading = true;
    try {
      await _loadLocalizedConfig(locale);
      _isLoaded = true;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadGoodsConfig(String langCode) async {
    try {
      final String response = await _loadJsonString('assets/config/goods.json', langCode);
      final List<dynamic> data = json.decode(response);
      _goodsList = data.map((json) => Goods.fromJson(json)).toList();
    } catch (e) {
      debugPrint('✗ Error loading goods config: $e');
      _goodsList = [];
    }
  }

  Future<void> _loadPortsConfig(String langCode) async {
    try {
      final String response = await _loadJsonString('assets/config/ports.json', langCode);
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
      _portsList = [];
    }
  }

  Future<void> _loadQuestsConfig(String langCode) async {
    try {
      final String response = await _loadJsonString('assets/config/quests.json', langCode);
      final List<dynamic> data = json.decode(response);
      _questsList = data.map((json) => Quest.fromJson(json)).toList();
    } catch (e) {
      debugPrint('✗ Error loading quests config: $e');
      _questsList = [];
    }
  }

  Future<void> _loadCrewConfig(String langCode) async {
    try {
      final String response = await _loadJsonString('assets/config/crew.json', langCode);
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

  Future<void> _loadSeaEventsConfig(String langCode) async {
    try {
      final String response = await _loadJsonString('assets/config/sea_events.json', langCode);
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
}

