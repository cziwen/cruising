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

  /// 获取所有货物列表
  List<Goods> get goodsList {
    if (_goodsList == null) {
      throw Exception('GameConfigLoader: goodsList not loaded. Call loadConfig() first.');
    }
    return _goodsList!;
  }

  /// 获取所有港口列表
  List<Port> get portsList {
    if (_portsList == null) {
      throw Exception('GameConfigLoader: portsList not loaded. Call loadConfig() first.');
    }
    return _portsList!;
  }

  /// 加载所有配置文件
  Future<void> loadConfig() async {
    await Future.wait([
      _loadGoodsConfig(),
      _loadPortsConfig(),
    ]);
  }

  Future<void> _loadGoodsConfig() async {
    try {
      final String response = await rootBundle.loadString('assets/config/goods.json');
      final List<dynamic> data = json.decode(response);
      _goodsList = data.map((json) => Goods.fromJson(json)).toList();
      debugPrint('✓ Loaded ${_goodsList?.length} goods from config');
    } catch (e) {
      debugPrint('✗ Error loading goods config: $e');
      rethrow;
    }
  }

  Future<void> _loadPortsConfig() async {
    try {
      final String response = await rootBundle.loadString('assets/config/ports.json');
      final List<dynamic> data = json.decode(response);
      _portsList = data.map((json) => Port.fromJson(json)).toList();
      debugPrint('✓ Loaded ${_portsList?.length} ports from config');
    } catch (e) {
      debugPrint('✗ Error loading ports config: $e');
      rethrow;
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

