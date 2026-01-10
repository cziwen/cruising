import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PixelProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double width;
  final double height;

  const PixelProgressBar({
    super.key,
    required this.value,
    this.width = double.infinity,
    this.height = 32, // Default height for Holder background
  });

  /// 预加载进度条素材
  static Future<void> preload() async {
    await _PixelProgressBarState.preloadImages();
  }

  @override
  State<PixelProgressBar> createState() => _PixelProgressBarState();
}

class _PixelProgressBarState extends State<PixelProgressBar> {
  static const String barBasePath = 'assets/paper_ui/Sprites/Content/3_Progress_Bars/';
  static const String holderBasePath = 'assets/paper_ui/Sprites/Content/5_Holders/';
  
  static Map<String, ui.Image>? _cachedImages;
  static Future<void>? _loadingFuture;
  
  bool _localLoading = true;

  @override
  void initState() {
    super.initState();
    if (_cachedImages != null) {
      _localLoading = false;
    } else {
      _loadImages();
    }
  }

  static Future<void> preloadImages() async {
    if (_cachedImages != null) return;
    if (_loadingFuture != null) return _loadingFuture;

    _loadingFuture = _doLoadImages();
    return _loadingFuture;
  }

  static Future<void> _doLoadImages() async {
    final Map<String, String> assetMap = {
      'bar_10': '${barBasePath}10_clean.png',
      'bar_11': '${barBasePath}11_clean.png',
      'bar_12': '${barBasePath}12_clean.png',
      'bar_13': '${barBasePath}13_clean.png',
      'bar_14': '${barBasePath}14_clean.png',
      'bar_15': '${barBasePath}15_clean.png',
      'holder_9': '${holderBasePath}9.png',
      'holder_10': '${holderBasePath}10.png',
      'holder_11': '${holderBasePath}11.png',
    };

    final Map<String, ui.Image> loadedImages = {};

    try {
      for (final entry in assetMap.entries) {
        final data = await rootBundle.load(entry.value);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        loadedImages[entry.key] = frame.image;
      }
      _cachedImages = loadedImages;
    } catch (e) {
      debugPrint('Error preloading progress bar images: $e');
      rethrow;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<void> _loadImages() async {
    try {
      await preloadImages();
      if (mounted) {
        setState(() {
          _localLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress bar images in widget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localLoading || _cachedImages == null) {
      return SizedBox(
        width: widget.width == double.infinity ? null : widget.width,
        height: widget.height,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = widget.width == double.infinity 
            ? constraints.maxWidth 
            : widget.width;
        
        return CustomPaint(
          size: Size(availableWidth, widget.height),
          painter: _PixelProgressBarPainter(
            value: widget.value,
            images: _cachedImages!,
          ),
        );
      },
    );
  }
}

class _PixelProgressBarPainter extends CustomPainter {
  final double value;
  final Map<String, ui.Image> images;

  // Bar dimensions from _clean assets
  static const double barLeftWidth = 12.0;
  static const double barMidWidth = 15.0;
  static const double barRightWidth = 9.0;

  // Holder dimensions
  static const double holderSideWidth = 16.0;
  static const double holderMidWidth = 16.0;

  _PixelProgressBarPainter({
    required this.value,
    required this.images,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = ui.FilterQuality.none;

    // 1. Draw Holder Background
    _drawHolderBackground(canvas, size, paint);

    // 2. Draw Progress Bar (nested inside Holder)
    _drawProgressBar(canvas, size, paint);
  }

  void _drawHolderBackground(Canvas canvas, Size size, Paint paint) {
    final double remainingWidth = size.width - (holderSideWidth * 2);
    final int midSegments = (remainingWidth / holderMidWidth).floor().clamp(0, 999);
    final double totalHolderWidth = (holderSideWidth * 2) + (midSegments * holderMidWidth);
    
    // 背景板整体水平居中
    double startX = (size.width - totalHolderWidth) / 2;

    // 左侧装饰 (9.png)
    canvas.drawImageRect(
      images['holder_9']!,
      Rect.fromLTWH(0, 0, images['holder_9']!.width.toDouble(), images['holder_9']!.height.toDouble()),
      Rect.fromLTWH(startX, 0, holderSideWidth, size.height),
      paint,
    );
    startX += holderSideWidth;

    // 中间填充 (10.png)
    for (int i = 0; i < midSegments; i++) {
      canvas.drawImageRect(
        images['holder_10']!,
        Rect.fromLTWH(0, 0, images['holder_10']!.width.toDouble(), images['holder_10']!.height.toDouble()),
        Rect.fromLTWH(startX, 0, holderMidWidth, size.height),
        paint,
      );
      startX += holderMidWidth;
    }

    // 右侧装饰 (11.png)
    canvas.drawImageRect(
      images['holder_11']!,
      Rect.fromLTWH(0, 0, images['holder_11']!.width.toDouble(), images['holder_11']!.height.toDouble()),
      Rect.fromLTWH(startX, 0, holderSideWidth, size.height),
      paint,
    );
  }

  void _drawProgressBar(Canvas canvas, Size size, Paint paint) {
    // 进度条在背景板内部垂直居中绘制
    // 背景板高度 32，进度条高度 8，居中即 y=12
    const double barTargetHeight = 8.0; 
    final double barY = (size.height - barTargetHeight) / 2;

    // 计算进度条在 Holder 内部的可用宽度
    // Holder 的左右端各占 16 像素，我们给进度条留出一定的内边距
    const double horizontalPadding = 12.0; 
    final double barAvailableWidth = size.width - (horizontalPadding * 2);
    
    if (barAvailableWidth <= (barLeftWidth + barRightWidth)) return;

    final double remainingBarWidth = barAvailableWidth - barLeftWidth - barRightWidth;
    final int midBarSegments = (remainingBarWidth / barMidWidth).floor().clamp(0, 999);
    final double totalBarWidth = barLeftWidth + barRightWidth + (midBarSegments * barMidWidth);

    // 在水平方向上居中对齐进度条
    double baseStartX = (size.width - totalBarWidth) / 2;

    final int totalBarSegments = midBarSegments + 2;

    // 第一遍绘制：绘制完整的“空”进度条作为背景（设置半透明）
    paint.color = Colors.white.withValues(alpha: 0.5);
    double currentX = baseStartX;
    for (int i = 0; i < totalBarSegments; i++) {
      ui.Image image;
      double currentSegmentWidth;

      if (i == 0) {
        image = images['bar_13']!; // Empty Left
        currentSegmentWidth = barLeftWidth;
      } else if (i == totalBarSegments - 1) {
        image = images['bar_15']!; // Empty Right
        currentSegmentWidth = barRightWidth;
      } else {
        image = images['bar_14']!; // Empty Mid
        currentSegmentWidth = barMidWidth;
      }

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(currentX, barY, currentSegmentWidth, barTargetHeight),
        paint,
      );
      currentX += currentSegmentWidth;
    }

    // 第二遍绘制：根据进度覆盖“满”进度条（恢复完全不透明）
    paint.color = Colors.white;
    currentX = baseStartX;
    final int fullSegments = (value * totalBarSegments).floor();
    
    for (int i = 0; i < fullSegments; i++) {
      ui.Image image;
      double currentSegmentWidth;

      if (i == 0) {
        image = images['bar_10']!; // Full Left
        currentSegmentWidth = barLeftWidth;
      } else if (i == totalBarSegments - 1) {
        image = images['bar_12']!; // Full Right
        currentSegmentWidth = barRightWidth;
      } else {
        image = images['bar_11']!; // Full Mid
        currentSegmentWidth = barMidWidth;
      }

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(currentX, barY, currentSegmentWidth, barTargetHeight),
        paint,
      );
      currentX += currentSegmentWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _PixelProgressBarPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.images != images;
  }
}
