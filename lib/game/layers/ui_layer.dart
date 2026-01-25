import 'dart:async';
import 'package:flutter/material.dart';
import '../game_state.dart';
import '../crew_management_dialog.dart';
import '../main_hall_dialog.dart';
import '../paper_button.dart';
import '../pixel_progress_bar.dart';
import '../../systems/music_system.dart';
import '../../systems/quest_system.dart';
import 'status_bar.dart';

/// UI层 - 界面元素（按钮、菜单、信息显示等）
class UILayer extends StatefulWidget {
  final GameState gameState;
  final VoidCallback? onTradePressed;
  final VoidCallback? onPortSelectPressed;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onMarketPressed;
  final VoidCallback? onCrewMarketPressed;
  final VoidCallback? onShipyardPressed;
  final VoidCallback? onSettingsPressed;

  const UILayer({
    super.key,
    required this.gameState,
    this.onTradePressed,
    this.onPortSelectPressed,
    this.onUpgradePressed,
    this.onMarketPressed,
    this.onCrewMarketPressed,
    this.onShipyardPressed,
    this.onSettingsPressed,
  });

  @override
  State<UILayer> createState() => _UILayerState();
}

class _FloatingText {
  final String text;
  final Offset position;
  final DateTime startTime;
  static const duration = Duration(milliseconds: 1500);

  _FloatingText(this.text, this.position) : startTime = DateTime.now();

  double get opacity {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed >= duration) return 0.0;
    return 1.0 - (elapsed.inMilliseconds / duration.inMilliseconds);
  }

  double get yOffset {
    final elapsed = DateTime.now().difference(startTime);
    // 向上飘动 100 像素
    return -100.0 * (elapsed.inMilliseconds / duration.inMilliseconds);
  }

  bool get isExpired => DateTime.now().difference(startTime) >= duration;
}

class _UILayerState extends State<UILayer> {
  final List<_FloatingText> _floatingTexts = [];
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _addFloatingText(String text, Offset position) {
    setState(() {
      _floatingTexts.add(_FloatingText(text, position));
    });

    // 如果还没有计时器，则启动一个
    if (_animationTimer == null || !_animationTimer!.isActive) {
      _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        setState(() {
          _floatingTexts.removeWhere((item) => item.isExpired);
          if (_floatingTexts.isEmpty) {
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    // 岛屿中心位置调整：向左偏移 100px，向上偏移 10px
    final islandCenterX = centerX - 100;
    final islandCenterY = centerY - 10;
    
    return Stack(
      children: [
        // 顶部航行进度条（仅在海上航行时显示）
        if (widget.gameState.isAtSea)
          Positioned(
            top: 0,
            left: 180,  // 左侧留出更多空间，避免与左上角时间显示冲突
            right: 16,  // 右侧留出边距
            child: QuestTarget(
              id: 'ui.travelProgressBar',
              child: _buildTravelProgressBar(),
            ),
          ),
        
        // 底部状态栏（新设计）
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: StatusBar(gameState: widget.gameState),
        ),
        
        // 岛屿周围的交互按钮
        ..._buildIslandButtons(islandCenterX, islandCenterY),
        
        // 选择目的地按钮 - 右下角
        _buildDestinationButtonAnimated(),
        
        // 漂浮动画层
        ..._floatingTexts.map((ft) => Positioned(
              left: ft.position.dx,
              top: ft.position.dy + ft.yOffset,
              child: Opacity(
                opacity: ft.opacity,
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    ft.text,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),

        // 调试面板 (已移动到 GameScreen 顶层 Stack)
      ],
    );
  }

  /// 构建带动画的岛屿交互按钮
  List<Widget> _buildIslandButtons(double islandCenterX, double islandCenterY) {
    final showButtons = !widget.gameState.isTransitioning && 
                        !widget.gameState.isAtSea && 
                        widget.gameState.currentPort != null;
    
    return [
      // 使用 AnimatedOpacity 包裹所有岛屿按钮
      IgnorePointer(
        ignoring: !showButtons,
        child: AnimatedOpacity(
          opacity: showButtons ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Stack(
            children: [
              // 税收提示 - 岛屿正上方 (仅限主岛)
              if (widget.gameState.currentPort?.id == 'home_island' && widget.gameState.homeIsland.accumulatedTax > 0)
                Positioned(
                  left: islandCenterX - 60,
                  top: islandCenterY - 230,
                  child: QuestTarget(
                    id: 'ui.collectTaxButton',
                    child: _buildTaxButton(islandCenterX - 60, islandCenterY - 230),
                  ),
                ),

              // 市场按钮 - 岛屿左侧
              Positioned(
                left: islandCenterX - 250,
                top: islandCenterY - 50,
                child: QuestTarget(
                  id: 'ui.marketButton',
                  child: _buildIslandButton(
                    '市场',
                    widget.onMarketPressed ?? widget.onTradePressed,
                    Colors.blue,
                  ),
                ),
              ),
              
              // 大厅按钮 (仅限主岛)
              if (widget.gameState.currentPort?.id == 'home_island')
                Positioned(
                  left: islandCenterX - 250,
                  top: islandCenterY + 80,
                  child: _buildIslandButton(
                    '大厅',
                    () => _showMainHall(context, 0),
                    Colors.indigo,
                  ),
                ),

              // 港口酒馆按钮 - 岛屿左上方
              Positioned(
                left: islandCenterX - 220,
                top: islandCenterY - 150,
                child: _buildIslandButton(
                  '港口酒馆',
                  widget.onCrewMarketPressed,
                  Colors.purple,
                ),
              ),
              // 设置按钮 - 岛屿右上方 (与酒馆对称)
              Positioned(
                left: islandCenterX + 220,
                top: islandCenterY - 150,
                child: _buildIslandButton(
                  '设置',
                  widget.onSettingsPressed,
                  Colors.blueGrey,
                ),
              ),
              // 船厂按钮 - 岛屿右侧（代替升级）
              Positioned(
                left: islandCenterX + 150,
                top: islandCenterY - 50,
                child: QuestTarget(
                  id: 'ui.shipUpgradeButton',
                  child: _buildIslandButton(
                    '船厂',
                    widget.onShipyardPressed ?? widget.onUpgradePressed,
                    Colors.orange,
                  ),
                ),
              ),
              // 船员管理按钮 - 岛屿右下方（船只旁边）
              Positioned(
                left: islandCenterX + 120,
                top: islandCenterY + 80,
                child: _buildIslandButton(
                  '船员管理',
                  () => _showCrewManagement(context),
                  Colors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  /// 构建带动画的选择目的地按钮
  Widget _buildDestinationButtonAnimated() {
    final showButton = !widget.gameState.isTransitioning && !widget.gameState.isAtSea;
    
    return Positioned(
      bottom: 80,
      right: 16,
      child: IgnorePointer(
        ignoring: !showButton,
        child: AnimatedOpacity(
          opacity: showButton ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: _buildDestinationButton(),
        ),
      ),
    );
  }

  /// 构建岛屿周围的按钮
  Widget _buildIslandButton(String text, VoidCallback? onPressed, Color color) {
    PaperButtonStyle style = PaperButtonStyle.brown;
    if (color == Colors.blue) style = PaperButtonStyle.blue;
    if (color == Colors.green) style = PaperButtonStyle.green;
    if (color == Colors.purple) style = PaperButtonStyle.gold; // Using gold for purple as a highlight
    if (color == Colors.orange) style = PaperButtonStyle.gold;
    if (color == Colors.teal) style = PaperButtonStyle.blue;
    if (color == Colors.blueGrey) style = PaperButtonStyle.brown;

    return PaperButton(
      label: text,
      onPressed: onPressed,
      style: style,
      width: 100,
      height: 40,
    );
  }

  /// 构建选择目的地按钮
  Widget _buildDestinationButton() {
    return QuestTarget(
      id: 'ui.portListButton',
      child: PaperButton(
        label: '选择目的地',
        icon: const Icon(Icons.map, color: Color(0xFF4E342E), size: 20),
        onPressed: widget.onPortSelectPressed,
        style: PaperButtonStyle.green,
        width: 120,
        height: 48,
      ),
    );
  }

  /// 显示船员管理对话框
  void _showCrewManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CrewManagementDialog(
        gameState: widget.gameState,
      ),
    );
  }

  /// 显示大厅对话框
  void _showMainHall(BuildContext context, int initialTab) {
    showDialog(
      context: context,
      builder: (context) => MainHallDialog(
        gameState: widget.gameState,
        initialTab: initialTab,
      ),
    );
  }

  /// 构建税收提示按钮
  Widget _buildTaxButton(double x, double y) {
    return GestureDetector(
      onTap: () {
        final amount = widget.gameState.homeIsland.accumulatedTax;
        if (amount > 0) {
          MusicSystem().playSFX('button_press');
          _addFloatingText('+$amount 💰', Offset(x + 20, y));
          widget.gameState.collectTax();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💰', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              '${widget.gameState.homeIsland.accumulatedTax}',
              style: const TextStyle(
                color: Colors.brown,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建航行进度条
  Widget _buildTravelProgressBar() {
    final remainingHours = widget.gameState.remainingTravelHours;
    final destinationName = widget.gameState.destinationPort?.name ?? '目的地';
    
    // 将小时数转换为"X天Y小时"格式
    final days = remainingHours ~/ 24;
    final hours = remainingHours % 24;
    String remainingTimeText;
    if (days > 0 && hours > 0) {
      remainingTimeText = '$days天$hours小时';
    } else if (days > 0) {
      remainingTimeText = '$days天';
    } else {
      remainingTimeText = '$hours小时';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 目的地和剩余时间
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '前往: $destinationName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '剩余: $remainingTimeText',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 进度条
          PixelProgressBar(
            value: widget.gameState.travelProgress,
            width: double.infinity,
            height: 32, // 背景板高度
          ),
        ],
      ),
    );
  }
}
