import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/goods.dart';
import '../models/port.dart';

/// 游戏配置加载器，用于从 JSON 文件中读取基础配置信息
class GameConfigLoader {
  static final GameConfigLoader _instance = GameConfigLoader._internal();
  factory GameConfigLoader() => _instance;
  GameConfigLoader._internal();

  List<Goods>? _goodsList;
  List<Port>? _portsList;
  Map<String, dynamic>? _crewConfig;
  bool _isLoading = false;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// 获取船员配置
  Map<String, dynamic> get crewConfig {
    if (_crewConfig == null) {
      debugPrint('⚠ Warning: Accessing crewConfig before it is loaded.');
      return {};
    }
    return _crewConfig!;
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

  /// 加载所有配置文件
  Future<void> loadConfig() async {
    if (_isLoading) return;
    if (_isLoaded) return;

    _isLoading = true;
    try {
      await Future.wait([
        _loadGoodsConfig(),
        _loadPortsConfig(),
        _loadCrewConfig(),
      ]);
      _isLoaded = true;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadGoodsConfig() async {
    try {
      final String response = await rootBundle.loadString('assets/config/goods.json');
      final List<dynamic> data = json.decode(response);
      _goodsList = data.map((json) => Goods.fromJson(json)).toList();
    } catch (e) {
      debugPrint('✗ Error loading goods config: $e');
      _goodsList = []; // 发生错误时给一个空列表，防止之后访问抛错
    }
  }

  Future<void> _loadPortsConfig() async {
    try {
      final String response = await rootBundle.loadString('assets/config/ports.json');
      final List<dynamic> data = json.decode(response);
      _portsList = data.map((json) => Port.fromJson(json)).toList();
    } catch (e) {
      debugPrint('✗ Error loading ports config: $e');
      _portsList = []; // 发生错误时给一个空列表
    }
  }

  Future<void> _loadCrewConfig() async {
    try {
      final String response = await rootBundle.loadString('assets/config/crew.json');
      _crewConfig = json.decode(response);
    } catch (e) {
      debugPrint('✗ Error loading crew config: $e');
      _crewConfig = {};
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

