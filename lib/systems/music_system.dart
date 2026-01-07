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

    await _crossFadeTo(trackPath);
  }

  /// 交叉淡入淡出到新音轨
  Future<void> _crossFadeTo(String assetPath) async {
    _fadeTimer?.cancel();

    final nextPlayer = (_currentPlayer == _playerA) ? _playerB : _playerA;
    
    // 准备下一个播放器
    await nextPlayer.setSource(AssetSource(assetPath));
    await nextPlayer.setReleaseMode(ReleaseMode.loop);
    await nextPlayer.setVolume(0);
    await nextPlayer.resume();

    // 开始淡入淡出过程
    const steps = 20;
    const duration = Duration(milliseconds: 1500);
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    int currentStep = 0;

    _fadeTimer = Timer.periodic(stepDuration, (timer) async {
      currentStep++;
      final double progress = currentStep / steps;

      // 淡出当前播放器
      await _currentPlayer.setVolume((1 - progress) * _volume);
      // 淡入下一个播放器
      await nextPlayer.setVolume(progress * _volume);

      if (currentStep >= steps) {
        timer.cancel();
        await _currentPlayer.stop();
        _currentPlayer = nextPlayer;
      }
    });
  }

  /// 淡出并停止当前音乐
  Future<void> _fadeOutAndStop() async {
    _fadeTimer?.cancel();
    
    const steps = 20;
    const duration = Duration(milliseconds: 1000);
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    int currentStep = 0;

    final initialVolume = _volume;

    _fadeTimer = Timer.periodic(stepDuration, (timer) async {
      currentStep++;
      final double progress = currentStep / steps;
      final double newVolume = (1 - progress) * initialVolume;

      await _currentPlayer.setVolume(newVolume);

      if (currentStep >= steps) {
        timer.cancel();
        await _currentPlayer.stop();
      }
    });
  }
}

