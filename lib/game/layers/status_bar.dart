import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../game_state.dart';

/// 状态栏组件
/// 显示游戏核心资源和运营状态信息，采用分块单行布局
class StatusBar extends StatelessWidget {
  final GameState gameState;

  const StatusBar({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth / 25).clamp(14.0, 18.0);
    final iconSize = (screenWidth / 35).clamp(18.0, 22.0);

    return Center(
      child: Container(
        width: 814,
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ui/HUD_bot_bg_s.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min, // 包裹内容
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 分块 1：金币 + 位置
              _buildSection([
                _buildStatItem(
                  icon: Icons.monetization_on,
                  label: '${gameState.gold}',
                  iconSize: iconSize,
                  fontSize: fontSize,
                  valueColor: Colors.amber[900]!, // 加深一点颜色
                ),
                const SizedBox(width: 10),
                _buildLocationItem(
                  fontSize: fontSize,
                  iconSize: iconSize,
                  l10n: l10n,
                ),
              ]),
              const SizedBox(width: 4),

              // 分块 2：载货量 + 船员
              _buildSection([
                _buildStatItem(
                  icon: Icons.inventory_2,
                  label: '${gameState.usedCargoWeight.toStringAsFixed(0)}/${gameState.ship.cargoCapacity}',
                  iconSize: iconSize,
                  fontSize: fontSize,
                  valueColor: Colors.blue[900]!,
                ),
                const SizedBox(width: 10),
                _buildStatItem(
                  icon: Icons.people,
                  label: '${gameState.crewCount}/${gameState.maxCrewCount}',
                  iconSize: iconSize,
                  fontSize: fontSize,
                  valueColor: Colors.green[900]!,
                ),
              ]),
              const SizedBox(width: 4),

              // 分块 3：耐久 + 修复速度
              _buildSection([
                _buildStatItem(
                  icon: Icons.build,
                  label: '${gameState.ship.durability.toInt()}/${gameState.ship.maxDurability.toInt()}',
                  iconSize: iconSize,
                  fontSize: fontSize,
                  valueColor: Colors.orange[900]!,
                ),
                const SizedBox(width: 10),
                _buildStatItem(
                  icon: Icons.build_circle,
                  label: '${gameState.autoRepairPerSecond.toStringAsFixed(1)}/s',
                  iconSize: iconSize,
                  fontSize: fontSize,
                  valueColor: Colors.orangeAccent[700]!,
                ),
              ]),
              const SizedBox(width: 4),

              // 分块 4：炮火攻击力
              _buildSection([
                _buildStatItem(
                  icon: Icons.gps_fixed,
                  label: gameState.fireRatePerSecond.toStringAsFixed(1),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  valueColor: Colors.red[900]!,
                ),
              ]),
              const SizedBox(width: 4),

              // 分块 5：航速
              _buildSection([
                _buildStatItem(
                  icon: Icons.sailing,
                  label: gameState.currentSpeed.toStringAsFixed(1),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  valueColor: Colors.cyan[900]!,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建分块容器
  Widget _buildSection(List<Widget> children) {
    return PaperHolder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  /// 构建统计项（图标 + 文本）
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required double iconSize,
    required double fontSize,
    required Color valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: const Color(0xFF4E342E), // 深褐色图标
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: valueColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建位置显示项
  Widget _buildLocationItem({
    required double fontSize,
    required double iconSize,
    required AppLocalizations l10n,
  }) {
    String locationText;
    if (gameState.isAtSea) {
      locationText = l10n.atSea;
    } else if (gameState.currentPort != null) {
      locationText = gameState.currentPort!.name;
    } else {
      locationText = l10n.unknownLocation;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          size: iconSize,
          color: const Color(0xFF4E342E), // 深褐色图标
        ),
        const SizedBox(width: 3),
        Text(
          locationText,
          style: TextStyle(
            color: const Color(0xFF4E342E), // 深褐色文字
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// 纸质风格容器组件
/// 使用 9.png, 10.png, 11.png 构建可平铺的背景
class PaperHolder extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const PaperHolder({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: Stack(
        children: [
          // 背景层
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 统一拉伸到容器高度
              children: [
                // 左侧 (9.png)
                Image.asset(
                  'assets/paper_ui/Sprites/Content/5_Holders/9.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
                // 中间平铺 (10.png)
                Expanded(
                  child: Image.asset(
                    'assets/paper_ui/Sprites/Content/5_Holders/10.png',
                    repeat: ImageRepeat.repeatX,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  ),
                ),
                // 右侧 (11.png)
                Image.asset(
                  'assets/paper_ui/Sprites/Content/5_Holders/11.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
              ],
            ),
          ),
          // 内容层
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Center(
              widthFactor: width != null ? null : 1.0,
              heightFactor: height != null ? null : 1.0,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
