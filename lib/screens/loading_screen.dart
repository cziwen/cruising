import 'package:flutter/material.dart';

/// 加载回调函数类型，接收 BuildContext 并返回 Future
typedef LoadCallback = Future<void> Function(BuildContext context);

class LoadingScreen extends StatefulWidget {
  final Widget nextScreen;
  final Duration duration;
  final List<Future<dynamic>>? waitFor;
  final LoadCallback? onLoad;

  const LoadingScreen({
    super.key,
    required this.nextScreen,
    this.duration = const Duration(seconds: 1),
    this.waitFor,
    this.onLoad,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _loadingStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在 didChangeDependencies 中启动加载，确保 context 可用
    if (!_loadingStarted) {
      _loadingStarted = true;
      _startLoading();
    }
  }

  Future<void> _startLoading() async {
    // 基础等待时间
    final minWait = Future.delayed(widget.duration);
    
    // 收集所有等待任务
    final tasks = <Future<dynamic>>[minWait];
    
    // 外部等待任务列表
    if (widget.waitFor != null) {
      tasks.addAll(widget.waitFor!);
    }
    
    // onLoad 回调（需要 context）
    if (widget.onLoad != null) {
      tasks.add(widget.onLoad!(context));
    }
    
    // 等待所有任务完成（至少等待 duration 时间）
    await Future.wait(tasks);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景层
          Positioned.fill(
            child: Image.asset(
              'assets/images/painting/Cover_0.png', // 使用有效的封面图片作为加载背景
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // 如果备用图片也失败，使用渐变背景
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF87CEEB),
                        const Color(0xFF4682B4),
                        const Color(0xFF1E90FF),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 内容层
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 6,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

