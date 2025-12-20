import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../game/game_state.dart';

/// 存档槽位元数据
class SaveSlot {
  final int id; // 0=Auto, 1-3=Manual
  final String timestamp; // ISO 8601 string
  final String portName;
  final int gold;
  final String captainName; // 预留，目前使用固定名字
  final int day; // 游戏内天数

  SaveSlot({
    required this.id,
    required this.timestamp,
    required this.portName,
    required this.gold,
    this.captainName = '船长',
    required this.day,
  });

  String get formattedTime {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  bool get isAutoSave => id == 0;
  String get displayName => isAutoSave ? '自动存档' : '存档 $id';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'portName': portName,
      'gold': gold,
      'captainName': captainName,
      'day': day,
    };
  }

  factory SaveSlot.fromJson(Map<String, dynamic> json) {
    return SaveSlot(
      id: json['id'] as int,
      timestamp: json['timestamp'] as String,
      portName: json['portName'] as String,
      gold: json['gold'] as int,
      captainName: json['captainName'] as String? ?? '船长',
      day: json['day'] as int? ?? 1,
    );
  }
}

/// 存档管理器
class SaveManager {
  static const String _saveFileNamePrefix = 'save_slot_';
  static const String _metaFileName = 'save_meta.json';

  /// 获取文档目录
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// 获取存档文件
  static Future<File> _getSaveFile(int slotId) async {
    final path = await _localPath;
    return File('$path/$_saveFileNamePrefix$slotId.json');
  }

  /// 获取元数据文件
  static Future<File> _getMetaFile() async {
    final path = await _localPath;
    return File('$path/$_metaFileName');
  }

  /// 保存游戏
  static Future<void> saveGame(int slotId, GameState state) async {
    try {
      // 1. 保存游戏数据
      final gameData = state.toJson();
      final file = await _getSaveFile(slotId);
      await file.writeAsString(jsonEncode(gameData));

      // 2. 更新元数据
      final meta = SaveSlot(
        id: slotId,
        timestamp: DateTime.now().toIso8601String(),
        portName: state.currentPort?.name ?? '海上',
        gold: state.gold,
        day: state.dayNightSystem.currentDay,
      );
      await _updateMeta(meta);
      
      print('Game saved to slot $slotId');
    } catch (e) {
      print('Failed to save game: $e');
      rethrow;
    }
  }

  /// 自动存档
  static Future<void> autoSave(GameState state) async {
    await saveGame(0, state);
  }

  /// 读取游戏
  static Future<Map<String, dynamic>> loadGame(int slotId) async {
    try {
      final file = await _getSaveFile(slotId);
      if (!await file.exists()) {
        throw Exception('Save file not found');
      }
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      print('Failed to load game: $e');
      rethrow;
    }
  }

  /// 删除存档
  static Future<void> deleteSave(int slotId) async {
    try {
      final file = await _getSaveFile(slotId);
      if (await file.exists()) {
        await file.delete();
      }
      await _removeMeta(slotId);
    } catch (e) {
      print('Failed to delete save: $e');
    }
  }

  /// 获取所有存档槽位信息
  static Future<List<SaveSlot>> getSaveSlots() async {
    try {
      final file = await _getMetaFile();
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) => SaveSlot.fromJson(json)).toList();
    } catch (e) {
      print('Failed to get save slots: $e');
      return [];
    }
  }

  /// 更新单个槽位的元数据
  static Future<void> _updateMeta(SaveSlot newSlot) async {
    final slots = await getSaveSlots();
    // 移除旧的同ID槽位
    slots.removeWhere((s) => s.id == newSlot.id);
    // 添加新的
    slots.add(newSlot);
    // 排序
    slots.sort((a, b) => a.id.compareTo(b.id));
    
    // 保存回文件
    final file = await _getMetaFile();
    final jsonList = slots.map((s) => s.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// 移除单个槽位的元数据
  static Future<void> _removeMeta(int slotId) async {
    final slots = await getSaveSlots();
    slots.removeWhere((s) => s.id == slotId);
    
    final file = await _getMetaFile();
    final jsonList = slots.map((s) => s.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }
  
  /// 检查是否有存档
  static Future<bool> hasAnySave() async {
    final slots = await getSaveSlots();
    return slots.isNotEmpty;
  }

  /// 删除所有存档
  static Future<void> deleteAllSaves() async {
    try {
      final slots = await getSaveSlots();
      for (final slot in slots) {
        final file = await _getSaveFile(slot.id);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      final metaFile = await _getMetaFile();
      if (await metaFile.exists()) {
        await metaFile.delete();
      }
      print('All saves deleted');
    } catch (e) {
      print('Failed to delete all saves: $e');
    }
  }
}

