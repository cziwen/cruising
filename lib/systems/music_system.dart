import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../utils/game_config_loader.dart';

/// 音乐系统，负责背景音乐的切换、淡入淡出和音量管理
class MusicSystem {
  static final MusicSystem _instance = MusicSystem._internal();
  factory MusicSystem() => _instance;

  MusicSystem._internal() {
    _playerA = AudioPlayer();
    _playerB = AudioPlayer();
    _currentPlayer = _playerA;
  }

  late AudioPlayer _playerA;
  late AudioPlayer _playerB;
  late AudioPlayer _currentPlayer;

  String? _currentState;
  String? _currentTrack;
  double _volume = 0.5;
  Timer? _fadeTimer;

  double get volume => _volume;

  /// 设置全局音乐音量 (0.0 到 1.0)
  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    _currentPlayer.setVolume(_volume);
  }

  /// 播放指定状态对应的音乐
  /// 如果状态匹配成功，随机从该状态的音乐列表中选择一首播放
  /// 如果状态匹配失败或状态名改变，平滑淡出当前音乐
  Future<void> playState(String stateName) async {
    if (_currentState == stateName) return;

    final config = GameConfigLoader().musicConfig;
    if (!config.containsKey(stateName)) {
      debugPrint('MusicSystem: State "$stateName" not found in config. Stopping music.');
      _currentState = stateName;
      _currentTrack = null;
      await _fadeOutAndStop();
      return;
    }

    final List<dynamic> tracks = config[stateName];
    if (tracks.isEmpty) {
      debugPrint('MusicSystem: State "$stateName" has no tracks. Stopping music.');
      _currentState = stateName;
      _currentTrack = null;
      await _fadeOutAndStop();
      return;
    }

    // 随机选择一首歌
    final random = Random();
    final String trackPath = tracks[random.nextInt(tracks.length)];

    if (_currentTrack == trackPath) {
      _currentState = stateName;
      return;
    }

    debugPrint('MusicSystem: Switching to state "$stateName", track: $trackPath');
    _currentState = stateName;
    _currentTrack = trackPath;

    try {
      await _crossFadeTo(trackPath);
    } catch (e) {
      debugPrint('MusicSystem Error: Failed to play music: $e');
    }
  }

  /// 交叉淡入淡出到新音轨
  Future<void> _crossFadeTo(String assetPath) async {
    _fadeTimer?.cancel();

    final nextPlayer = (_currentPlayer == _playerA) ? _playerB : _playerA;
    
    debugPrint('MusicSystem: Preparing next player with $assetPath');
    
    // 准备下一个播放器
    try {
      await nextPlayer.setSource(AssetSource(assetPath));
      await nextPlayer.setReleaseMode(ReleaseMode.loop);
      await nextPlayer.setVolume(0);
      
      // 在播放前确保状态正确
      await nextPlayer.resume();
      debugPrint('MusicSystem: Next player resumed (initially silent)');
    } catch (e) {
      debugPrint('MusicSystem Error: Error preparing next player: $e');
      return;
    }

    // 开始淡入淡出过程
    // 减少步数，增加步长，以减少对 Windows 消息队列的压力
    const steps = 15;
    const duration = Duration(milliseconds: 2000);
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    int currentStep = 0;

    _fadeTimer = Timer.periodic(stepDuration, (timer) async {
      currentStep++;
      final double progress = currentStep / steps;

      try {
        // 淡出当前播放器
        await _currentPlayer.setVolume(((1 - progress) * _volume).clamp(0.0, 1.0));
        // 淡入下一个播放器
        await nextPlayer.setVolume((progress * _volume).clamp(0.0, 1.0));
      } catch (e) {
        debugPrint('MusicSystem Warning: Error setting volume during fade: $e');
      }

      if (currentStep >= steps) {
        timer.cancel();
        try {
          await _currentPlayer.stop();
          _currentPlayer = nextPlayer;
          debugPrint('MusicSystem: Fade completed. Current track: $assetPath');
        } catch (e) {
          debugPrint('MusicSystem Error: Error stopping old player: $e');
        }
      }
    });
  }

  /// 淡出并停止当前音乐
  Future<void> _fadeOutAndStop() async {
    _fadeTimer?.cancel();
    
    // 如果已经在音量为0，直接停止
    if (_volume <= 0) {
      await _currentPlayer.stop();
      return;
    }

    const steps = 15;
    const duration = Duration(milliseconds: 1000);
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    int currentStep = 0;

    final initialVolume = _volume;

    _fadeTimer = Timer.periodic(stepDuration, (timer) async {
      currentStep++;
      final double progress = currentStep / steps;
      final double newVolume = ((1 - progress) * initialVolume).clamp(0.0, 1.0);

      try {
        await _currentPlayer.setVolume(newVolume);
      } catch (e) {
        debugPrint('MusicSystem Warning: Error setting volume during fade out: $e');
      }

      if (currentStep >= steps) {
        timer.cancel();
        try {
          await _currentPlayer.stop();
          debugPrint('MusicSystem: Music stopped.');
        } catch (e) {
          debugPrint('MusicSystem Error: Error stopping player: $e');
        }
      }
    });
  }
}

