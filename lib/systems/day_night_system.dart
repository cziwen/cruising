import 'dart:math';
import 'package:flutter/material.dart';

/// 季节枚举
enum Season {
  spring('春'),
  summer('夏'),
  autumn('秋'),
  winter('冬');

  final String displayName;
  const Season(this.displayName);
}

/// 昼夜系统管理器
class DayNightSystem {
  // 游戏时间（分钟，从0开始，一天1440分钟）
  int _gameMinutes = 720; // 默认从12:00开始（正午）
  
  // 允许外部设置（用于初始化）
  set gameMinutes(int value) => _gameMinutes = value;
  
  // 一天的总分钟数
  static const int minutesPerDay = 1440; // 24小时 × 60分钟
  
  // 日期跟踪
  int _currentDay = 1; // 当前日期（1-120，一年120天）
  static const int daysPerSeason = 30; // 每个季节30天
  static const int daysPerYear = 120; // 一年120天（4个季节 × 30天）
  
  // 白天持续时间（分钟）
  static const int dayDurationMinutes = 720; // 12小时
  
  // 夜晚持续时间（分钟）
  static const int nightDurationMinutes = 720; // 12小时
  
  // 时间流逝速度：游戏内1小时 = 现实1秒
  static const double timeScale = 60.0; // 1现实秒 = 60游戏分钟 = 1游戏小时
  
  // 时间流逝倍数（用于调试，默认1.0）
  double _timeMultiplier = 1.0;
  
  // 是否暂停时间流逝
  bool _isPaused = false;
  
  // 累积的游戏内时间（分钟，用于 dt 增量更新）
  double _accumulatedGameMinutes = 0.0;
  
  int get gameMinutes => _gameMinutes;
  bool get isPaused => _isPaused;
  int get currentDay => _currentDay;
  double get timeMultiplier => _timeMultiplier;
  
  /// 设置游戏时间（用于初始化）
  void setGameMinutes(int value) {
    _gameMinutes = value;
    _accumulatedGameMinutes = value.toDouble();
  }
  
  /// 获取当前时间（小时:00）
  /// 只显示小时，分钟固定为 00
  /// 基于累积的游戏内时间计算，确保精确显示
  String get currentTime {
    // 使用累积的游戏内时间，只计算小时
    final totalMinutes = _accumulatedGameMinutes;
    final hours = (totalMinutes ~/ 60).floor() % 24;
    // 分钟固定为 00
    return '${hours.toString().padLeft(2, '0')}:00';
  }
  
  /// 获取当前小时（基于累积时间）
  int get currentHour => (_accumulatedGameMinutes ~/ 60).floor() % 24;
  
  /// 获取当前分钟（基于累积时间）
  int get currentMinute => _accumulatedGameMinutes.floor() % 60;
  
  /// 判断是否为白天
  /// 白天：6:00-18:00（360-1080分钟）
  /// 基于累积时间计算，确保精确
  bool get isDaytime {
    final dayCyclePosition = _accumulatedGameMinutes % minutesPerDay;
    // 6:00（360分钟）到18:00（1080分钟）为白天
    return dayCyclePosition >= 360 && dayCyclePosition < 1080;
  }
  
  /// 判断是否为夜晚
  bool get isNighttime => !isDaytime;

  /// 获取当前季节
  Season get currentSeason {
    final seasonIndex = (_currentDay - 1) ~/ daysPerSeason;
    switch (seasonIndex) {
      case 0:
        return Season.spring;
      case 1:
        return Season.summer;
      case 2:
        return Season.autumn;
      case 3:
        return Season.winter;
      default:
        // 如果超过120天，循环回到春季
        return Season.values[seasonIndex % 4];
    }
  }

  /// 获取当前季节的第几天（1-30）
  int get currentDayOfSeason {
    return ((_currentDay - 1) % daysPerSeason) + 1;
  }

  /// 获取格式化的季节日期字符串（如"春 15日"）
  String get seasonDateString {
    return '${currentSeason.displayName} $currentDayOfSeason日';
  }
  
  /// 获取当前昼夜周期进度（0.0-1.0）
  /// 0.0 = 日出（6:00），0.5 = 日落（18:00），1.0 = 下一个日出
  /// 将6:00（360分钟）映射到0.0，18:00（1080分钟）映射到0.5
  /// 基于累积时间计算，确保精确
  double get dayCycleProgress {
    final dayCyclePosition = _accumulatedGameMinutes % minutesPerDay;
    // 将6:00（360分钟）作为起点（0.0）
    // 如果当前时间小于6:00，则属于前一天的夜晚部分
    final adjustedMinutes = (dayCyclePosition - 360 + minutesPerDay) % minutesPerDay;
    return adjustedMinutes / minutesPerDay;
  }
  
  /// 暂停时间流逝
  void pause() {
    _isPaused = true;
  }
  
  /// 恢复时间流逝
  void resume() {
    _isPaused = false;
  }
  
  /// 设置时间流逝倍数（用于调试）
  /// [multiplier] 时间倍数，1.0为正常速度，2.0为2倍速，0.5为0.5倍速
  void setTimeMultiplier(double multiplier) {
    _timeMultiplier = multiplier.clamp(0.1, 10.0); // 限制在0.1到10倍之间
  }
  
  /// 使用 dt 增量更新游戏时间（每帧调用）
  /// [dtRealSeconds] 实际经过的秒数（从上一帧到当前帧）
  /// 返回是否跨越了00:00（用于工资结算）
  bool updateWithDeltaTime(double dtRealSeconds) {
    if (_isPaused) return false;
    
    // 记录更新前的状态
    final double previousAccumulated = _accumulatedGameMinutes;
    
    // 将实际时间增量转换为游戏内时间增量
    // 1现实秒 = 1游戏小时 = 60游戏分钟
    // 应用时间倍数
    final dtGameMinutes = dtRealSeconds * timeScale * _timeMultiplier;
    
    // 累积游戏内时间
    _accumulatedGameMinutes += dtGameMinutes;
    
    // 更新整数分钟数（用于显示和序列化）
    _gameMinutes = _accumulatedGameMinutes.round();
    
    // 检查是否跨越了 00:00 (1440分钟)
    // 使用 floor 计算经过的总天数，如果总天数增加，说明跨越了午夜
    final int previousTotalDays = (previousAccumulated / minutesPerDay).floor();
    final int currentTotalDays = (_accumulatedGameMinutes / minutesPerDay).floor();
    
    if (currentTotalDays > previousTotalDays) {
      // 跨越 00:00 时，增加日期
      // 即使跳过了很多天（比如调试倍数极高），也能正确处理
      _currentDay += (currentTotalDays - previousTotalDays);
      
      // 处理跨年情况
      while (_currentDay > daysPerYear) {
        _currentDay -= daysPerYear;
      }
      
      return true;
    }
    
    return false;
  }
  
  /// 更新时间（已废弃，保留用于兼容）
  /// 现在应该使用 updateWithDeltaTime() 方法
  @Deprecated('使用 updateWithDeltaTime() 方法')
  void update() {
    // 为了向后兼容，保留此方法但不执行任何操作
    // 实际更新应该通过 updateWithDeltaTime() 进行
  }
  
  /// 重置时间
  void reset() {
    _gameMinutes = 720; // 重置为12:00
    _accumulatedGameMinutes = 720.0;
    _isPaused = false;
    _currentDay = 1; // 重置为第1天（春季第1天）
    _timeMultiplier = 1.0; // 重置时间倍数为1.0
  }
  
  /// 检查是否跨越了00:00（用于工资结算）
  bool checkMidnightCrossing(int previousMinutes) {
    final int previousDay = previousMinutes ~/ minutesPerDay;
    final int currentDay = _gameMinutes ~/ minutesPerDay;
    return currentDay > previousDay;
  }

  Map<String, dynamic> toJson() {
    return {
      'gameMinutes': _gameMinutes,
      'currentDay': _currentDay,
      'accumulatedGameMinutes': _accumulatedGameMinutes,
      'isPaused': _isPaused,
      'timeMultiplier': _timeMultiplier,
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    _gameMinutes = json['gameMinutes'] as int;
    _currentDay = json['currentDay'] as int;
    _accumulatedGameMinutes = (json['accumulatedGameMinutes'] as num).toDouble();
    _isPaused = json['isPaused'] as bool;
    _timeMultiplier = (json['timeMultiplier'] as num).toDouble();
  }
}

/// 太阳/月亮位置计算器
class CelestialBodyPosition {
  /// 计算太阳/月亮在屏幕上的位置（弧形轨迹）
  /// 
  /// [progress] 昼夜周期进度（0.0-1.0，0.0=日出，0.5=日落，1.0=下一个日出）
  /// [screenWidth] 屏幕宽度
  /// [screenHeight] 屏幕高度
  /// [isDaytime] 是否为白天（true=太阳，false=月亮）
  /// 
  /// 返回 (x, y) 坐标
  static Offset calculatePosition(
    double progress,
    double screenWidth,
    double screenHeight,
    bool isDaytime,
  ) {
    // 弧形轨迹参数
    final arcHeight = screenHeight * 0.25; // 弧形高度（屏幕高度的25%）
    final startX = screenWidth + 50; // 起始X（屏幕右侧外）
    final endX = -50; // 结束X（屏幕左侧外）
    final centerY = screenHeight * 0.15 - 50; // 弧形中心Y（调高50像素）
    
    // 将昼夜周期进度转换为天体移动进度
    // 太阳：progress 0.0-0.5 映射到移动进度 0.0-1.0
    // 月亮：progress 0.5-1.0 映射到移动进度 0.0-1.0
    double movementProgress;
    if (isDaytime) {
      // 太阳：从0.0到0.5，映射到0.0到1.0
      movementProgress = (progress / 0.5).clamp(0.0, 1.0);
    } else {
      // 月亮：从0.5到1.0，映射到0.0到1.0
      movementProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
    }
    
    // X坐标：从右到左线性移动
    final x = startX + (endX - startX) * movementProgress;
    
    // Y坐标：弧形轨迹（使用正弦函数，关于x轴镜像）
    // movementProgress 0.0-1.0 映射到 0-π
    // 使用 1 - sin(angle) 实现镜像，让轨迹从高到低再到高
    final angle = movementProgress * pi;
    final y = centerY + arcHeight * (1.0 - sin(angle));
    
    return Offset(x, y);
  }
  
  /// 获取太阳/月亮的透明度（用于过渡效果）
  /// 
  /// [progress] 昼夜周期进度（0.0-1.0）
  /// [isDaytime] 是否为白天
  /// 
  /// 返回透明度（0.0-1.0）
  static double getOpacity(double progress, bool isDaytime) {
    if (isDaytime) {
      // 太阳：在白天（0.0-0.5）显示，夜晚（0.5-1.0）隐藏
      if (progress < 0.5) {
        // 日出和日落时的淡入淡出
        if (progress < 0.1) {
          return progress / 0.1; // 日出淡入
        } else if (progress > 0.4) {
          return (0.5 - progress) / 0.1; // 日落淡出
        } else {
          return 1.0; // 正午完全显示
        }
      } else {
        return 0.0; // 夜晚完全隐藏
      }
    } else {
      // 月亮：在夜晚（0.5-1.0）显示，白天（0.0-0.5）隐藏
      if (progress >= 0.5) {
        final nightProgress = (progress - 0.5) / 0.5; // 0.0-1.0
        // 月出和月落时的淡入淡出
        if (nightProgress < 0.1) {
          return nightProgress / 0.1; // 月出淡入
        } else if (nightProgress > 0.9) {
          return (1.0 - nightProgress) / 0.1; // 月落淡出
        } else {
          return 1.0; // 午夜完全显示
        }
      } else {
        return 0.0; // 白天完全隐藏
      }
    }
  }
}




