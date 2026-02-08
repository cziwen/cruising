import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../utils/game_config_loader.dart';

/// 环境音效控制器，负责在特定状态下间歇性播放音效
class AmbientSFXController {
  final String category;
  final List<String> tracks;
  final int minDelay;
  final int maxDelay;
  final List<String> activeStates;
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  double _volume = 0.5;

  AmbientSFXController({
    required this.category,
    required this.tracks,
    required this.minDelay,
    required this.maxDelay,
    required this.activeStates,
  });

  void setVolume(double volume) {
    _volume = volume;
    _player.setVolume(volume);
  }

  void updateState(String stateName) {
    if (activeStates.contains(stateName)) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    if (_timer != null) return;
    _scheduleNext();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _player.stop();
  }

  void _scheduleNext() {
    _timer?.cancel();
    final delay = minDelay + Random().nextInt(maxDelay - minDelay + 1);
    _timer = Timer(Duration(seconds: delay), () {
      _playRandom();
      _scheduleNext();
    });
  }

  Future<void> _playRandom() async {
    if (tracks.isEmpty || _volume <= 0) return;
    final track = tracks[Random().nextInt(tracks.length)];
    try {
      await _player.setVolume(_volume);
      await _player.play(AssetSource(track));
    } catch (e) {
      debugPrint('AmbientSFX Error ($category): $e');
    }
  }

  void dispose() {
    _stop();
    _player.dispose();
  }
}

/// 音频系统，负责背景音乐和音效的切换、管理
class MusicSystem {
  static final MusicSystem _instance = MusicSystem._internal();
  factory MusicSystem() => _instance;

  MusicSystem._internal() {
    _playerA = AudioPlayer();
    _playerB = AudioPlayer();
    _currentPlayer = _playerA;

    // 初始化 SFX 播放器池
    for (int i = 0; i < _sfxPoolSize; i++) {
      _sfxPool.add(AudioPlayer());
    }
  }

  late AudioPlayer _playerA;
  late AudioPlayer _playerB;
  late AudioPlayer _currentPlayer;

  // SFX 相关
  final int _sfxPoolSize = 5;
  final List<AudioPlayer> _sfxPool = [];
  int _nextSfxIndex = 0;
  final Map<String, AmbientSFXController> _ambientControllers = {};

  String? _currentState;
  String? _currentTrack;
  double _musicVolume = 0.3;
  double _sfxVolume = 0.1;
  Timer? _fadeTimer;
  bool _isInitialized = false;

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  /// 初始化音频系统
  void initialize() {
    _isInitialized = true;
    
    // 加载环境音配置
    final sfxConfig = GameConfigLoader().sfxConfig;
    if (sfxConfig.containsKey('ambient')) {
      final ambientConfig = sfxConfig['ambient'] as Map<String, dynamic>;
      ambientConfig.forEach((key, value) {
        final config = value as Map<String, dynamic>;
        _ambientControllers[key] = AmbientSFXController(
          category: key,
          tracks: List<String>.from(config['tracks']),
          minDelay: config['min_delay'],
          maxDelay: config['max_delay'],
          activeStates: List<String>.from(config['states']),
        )..setVolume(_sfxVolume);
      });
    }

    if (_currentState != null) {
      debugPrint('MusicSystem: Initialized with pending state: $_currentState');
      _updateAmbientControllers(_currentState!);
      
      if (_currentTrack != null) {
        _crossFadeTo(_currentTrack!);
      }
    }
  }

  /// 设置全局音乐音量 (0.0 到 1.0)
  void setMusicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
    // 如果没有正在进行的淡入淡出，直接更新当前播放器音量
    if (_fadeTimer == null || !_fadeTimer!.isActive) {
      _currentPlayer.setVolume(_musicVolume);
      if (_musicVolume <= 0) {
        _currentPlayer.stop();
      }
    }
  }

  /// 设置全局音效音量 (0.0 到 1.0)
  void setSfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
    for (var controller in _ambientControllers.values) {
      controller.setVolume(_sfxVolume);
      if (_sfxVolume <= 0) {
        controller._stop();
      }
    }
    for (var player in _sfxPool) {
      player.setVolume(_sfxVolume);
      if (_sfxVolume <= 0) {
        player.stop();
      }
    }
  }

  /// 播放指定状态对应的背景音乐和环境音
  Future<void> playState(String stateName) async {
    // 即使 BGM 没变，也要更新环境音状态
    _updateAmbientControllers(stateName);

    // 检查是否有状态触发的单次音效
    final sfxConfig = GameConfigLoader().sfxConfig;
    if (sfxConfig.containsKey('one_shot')) {
      final oneShotConfig = sfxConfig['one_shot'] as Map<String, dynamic>;
      if (oneShotConfig.containsKey(stateName)) {
        playSFX(stateName);
      }
    }

    _currentState = stateName;
    final musicConfig = GameConfigLoader().musicConfig;

    if (!musicConfig.containsKey(stateName)) {
      debugPrint('MusicSystem: State "$stateName" not found in music config. Stopping BGM.');
      _currentTrack = null;
      await _fadeOutAndStop();
      return;
    }

    final List<dynamic> tracks = musicConfig[stateName];
    if (tracks.isEmpty) {
      debugPrint('MusicSystem: State "$stateName" has no tracks. Stopping BGM.');
      _currentTrack = null;
      await _fadeOutAndStop();
      return;
    }

    final random = Random();
    final String trackPath = tracks[random.nextInt(tracks.length)];

    if (_currentTrack == trackPath && 
        (_currentPlayer.state == PlayerState.playing || _musicVolume <= 0)) {
      return;
    }

    debugPrint('MusicSystem: Switching BGM to state "$stateName", track: $trackPath');
    _currentTrack = trackPath;

    if (!_isInitialized) {
      debugPrint('MusicSystem: Not initialized yet. Delaying BGM playback.');
      return;
    }

    if (_musicVolume <= 0) {
      debugPrint('MusicSystem: Volume is 0, skipping playback but updating state.');
      await _fadeOutAndStop();
      return;
    }

    try {
      await _crossFadeTo(trackPath);
    } catch (e) {
      debugPrint('MusicSystem Error: Failed to play music: $e');
    }
  }

  /// 播放单次音效
  Future<void> playSFX(String sfxId) async {
    if (_sfxVolume <= 0) return;
    final sfxConfig = GameConfigLoader().sfxConfig;
    if (!sfxConfig.containsKey('one_shot')) return;

    final oneShotConfig = sfxConfig['one_shot'] as Map<String, dynamic>;
    if (!oneShotConfig.containsKey(sfxId)) {
      // debugPrint('MusicSystem: SFX "$sfxId" not found in config.');
      return;
    }

    final String assetPath = oneShotConfig[sfxId];
    
    // 从池中获取播放器
    final player = _sfxPool[_nextSfxIndex];
    _nextSfxIndex = (_nextSfxIndex + 1) % _sfxPoolSize;

    try {
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('MusicSystem SFX Error: Failed to play SFX "$sfxId": $e');
    }
  }

  void _updateAmbientControllers(String stateName) {
    for (var controller in _ambientControllers.values) {
      controller.updateState(stateName);
    }
  }

  /// 交叉淡入淡出到新音轨
  Future<void> _crossFadeTo(String assetPath) async {
    _fadeTimer?.cancel();

    if (_musicVolume <= 0) {
      await _currentPlayer.stop();
      _currentTrack = assetPath;
      return;
    }

    final nextPlayer = (_currentPlayer == _playerA) ? _playerB : _playerA;
    
    try {
      await nextPlayer.setSource(AssetSource(assetPath));
      await nextPlayer.setReleaseMode(ReleaseMode.loop);
      await nextPlayer.setVolume(0);
      
      try {
        await nextPlayer.resume();
      } catch (e) {
        debugPrint('MusicSystem Warning: Could not auto-resume next player (expected on Web): $e');
      }
    } catch (e) {
      debugPrint('MusicSystem Error: Error preparing next player: $e');
      return;
    }

    const steps = 20; // 增加步数使淡入淡出更平滑
    const duration = Duration(milliseconds: 2000);
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    int currentStep = 0;

    _fadeTimer = Timer.periodic(stepDuration, (timer) async {
      currentStep++;
      final double progress = currentStep / steps;

      try {
        // 使用当前最新的 _musicVolume
        await _currentPlayer.setVolume(((1 - progress) * _musicVolume).clamp(0.0, 1.0));
        await nextPlayer.setVolume((progress * _musicVolume).clamp(0.0, 1.0));
      } catch (e) {
        debugPrint('MusicSystem Warning: Error setting volume during fade: $e');
      }

      if (currentStep >= steps) {
        timer.cancel();
        try {
          await _currentPlayer.stop();
          _currentPlayer = nextPlayer;
          debugPrint('MusicSystem: Current track finalized: $assetPath');
        } catch (e) {
          debugPrint('MusicSystem Error: Error stopping old player: $e');
        }
      }
    });
  }

  /// 淡出并停止当前音乐
  Future<void> _fadeOutAndStop() async {
    _fadeTimer?.cancel();
    
    if (_musicVolume <= 0 || _currentPlayer.state != PlayerState.playing) {
      await _currentPlayer.stop();
      return;
    }

    const steps = 20;
    const duration = Duration(milliseconds: 1000);
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    int currentStep = 0;

    _fadeTimer = Timer.periodic(stepDuration, (timer) async {
      currentStep++;
      final double progress = currentStep / steps;
      // 动态使用当前音量进行淡出
      final double newVolume = ((1 - progress) * _musicVolume).clamp(0.0, 1.0);

      try {
        await _currentPlayer.setVolume(newVolume);
      } catch (e) {
        debugPrint('MusicSystem Warning: Error setting volume during fade out: $e');
      }

      if (currentStep >= steps || _musicVolume <= 0) {
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

  /// 尝试恢复播放当前音乐 (常用于 Web 端用户交互后)
  Future<void> resumeMusic() async {
    if (!_isInitialized || _musicVolume <= 0) return;

    if (_currentPlayer.state != PlayerState.playing && _currentTrack != null) {
      try {
        await _crossFadeTo(_currentTrack!);
      } catch (e) {
        debugPrint('MusicSystem Error: Failed to resume music: $e');
      }
    }
  }

  /// 停止所有音频（包括环境音）
  void stopAll() {
    _fadeOutAndStop();
    for (var controller in _ambientControllers.values) {
      controller._stop();
    }
  }

  void dispose() {
    _playerA.dispose();
    _playerB.dispose();
    for (var player in _sfxPool) {
      player.dispose();
    }
    for (var controller in _ambientControllers.values) {
      controller.dispose();
    }
  }
}
