// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Cruising';

  @override
  String get loading => '加载中...';

  @override
  String get settings => '设置';

  @override
  String get close => '关闭';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

  @override
  String get load => '读取';

  @override
  String get overwrite => '覆盖';

  @override
  String get ok => '确定';

  @override
  String get newGame => '新游戏';

  @override
  String get continueGame => '继续游戏';

  @override
  String get loadSave => '读取存档';

  @override
  String get exitGame => '退出';

  @override
  String get saveGame => '保存游戏';

  @override
  String get loadGame => '读取游戏';

  @override
  String get soundSettings => '声音设置';

  @override
  String get musicVolume => '音乐音量';

  @override
  String get sfxVolume => '音效音量';

  @override
  String get displaySettings => '显示设置';

  @override
  String get fullscreenMode => '全屏模式';

  @override
  String get wallpaperMode => '动态壁纸模式';

  @override
  String get windowResolution => '窗口分辨率';

  @override
  String get languageSettings => '语言设置';

  @override
  String get language => '语言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get returnMainMenu => '返回主菜单';

  @override
  String get returnMainMenuConfirm => '未保存的进度将会丢失，确定要返回主菜单吗？';

  @override
  String saveListLoadFailed(Object error) {
    return '加载存档列表失败: $error';
  }

  @override
  String get autoSlotManualBlocked => '自动存档位无法手动覆盖';

  @override
  String get saveSuccess => '保存成功';

  @override
  String saveFailed(Object error) {
    return '保存失败: $error';
  }

  @override
  String loadFailed(Object error) {
    return '读取失败: $error';
  }

  @override
  String get deleteSaveTitle => '删除存档';

  @override
  String get deleteSaveConfirm => '确定要删除这个存档吗？此操作无法撤销。';

  @override
  String get slotEmpty => '该槽位为空';

  @override
  String get emptySlot => '空槽位';

  @override
  String get autoSaveSlot => '自动存档';

  @override
  String saveSlotLabel(Object id) {
    return '存档 $id';
  }

  @override
  String locationLabel(Object name) {
    return '位置: $name';
  }

  @override
  String timeLabel(Object time) {
    return '时间: $time';
  }

  @override
  String goldDayLabel(Object gold, Object day) {
    return '金币: $gold | 天数: $day';
  }

  @override
  String get shipUpgrade => '船只升级';

  @override
  String get shipUpgradeInDev => '升级功能开发中...';

  @override
  String crewLeftNoPay(Object names) {
    return '船员 $names 因为得不到报酬，已经在港口悄悄离开了...';
  }

  @override
  String get market => '市场';

  @override
  String get hall => '大厅';

  @override
  String get tavern => '酒馆';

  @override
  String get shipyard => '船厂';

  @override
  String get manage => '管理';

  @override
  String get map => '地图';

  @override
  String headingTo(Object name) {
    return '前往: $name';
  }

  @override
  String remaining(Object time) {
    return '剩余: $time';
  }

  @override
  String daysHours(Object days, Object hours) {
    return '$days天$hours小时';
  }

  @override
  String daysOnly(Object days) {
    return '$days天';
  }

  @override
  String hoursOnly(Object hours) {
    return '$hours小时';
  }

  @override
  String get atSea => '海上';

  @override
  String get unknown => '未知';

  @override
  String get perSecond => '/秒';

  @override
  String get shotsPerSecond => '炮/秒';

  @override
  String get knots => '节';

  @override
  String get tapAnywhereToContinue => '-- 点击任意处继续 --';

  @override
  String get spring => '春';

  @override
  String get summer => '夏';

  @override
  String get autumn => '秋';

  @override
  String get winter => '冬';

  @override
  String seasonDay(Object season, Object day) {
    return '$season $day日';
  }

  @override
  String get selectDestination => '选择目的地';

  @override
  String get depart => '出发';

  @override
  String get currentPort => '当前港口';

  @override
  String get tradeDialogNoPort => '当前不在港口且未指定交易对象';

  @override
  String marketTitle(Object port) {
    return '市场 - $port';
  }

  @override
  String get merchantInventory => '商人库存';

  @override
  String get myInventory => '我的库存';

  @override
  String get playerReceives => '玩家获得';

  @override
  String get playerPays => '玩家支付';

  @override
  String get tradeIn => '换入';

  @override
  String get tradeOut => '换出';

  @override
  String get balanceOffer => '平衡报价';

  @override
  String get confirmTrade => '确认交易';

  @override
  String get tradeUnfair => '交易不公平';

  @override
  String buyAction(Object name) {
    return '购买: $name';
  }

  @override
  String sellAction(Object name) {
    return '出售: $name';
  }

  @override
  String holdingAverage(Object price) {
    return '持有均价: $price';
  }

  @override
  String buyAverage(Object price) {
    return '买入均价: $price';
  }

  @override
  String sellAverage(Object price) {
    return '售出均价: $price';
  }

  @override
  String estimatedValue(Object value) {
    return '估值: $value';
  }

  @override
  String get tradeSuccess => '交易成功！';

  @override
  String tradeFailed(Object reason) {
    return '交易失败: $reason';
  }

  @override
  String get merchantFavor => '← 偏向商人';

  @override
  String get playerFavor => '偏向玩家 →';

  @override
  String get fairTrade => '公平交易';

  @override
  String get seaEventMerchantTrading => '正在与商船进行物资交换...';

  @override
  String shipDamaged(Object value) {
    return '船只受损：耐久度下降了 $value';
  }

  @override
  String shipRepaired(Object value) {
    return '船只修复：耐久度恢复了 $value';
  }

  @override
  String goldGained(Object value) {
    return '获得金币：$value 💰';
  }

  @override
  String goldLost(Object value) {
    return '损失金币：$value 💰';
  }

  @override
  String goodsGained(Object name, Object count) {
    return '获得物资：$name x$count';
  }

  @override
  String get cargoFullNoGoods => '货舱已满，无法获取物资';

  @override
  String rerouteToPort(Object port) {
    return '航道改变，正转向 $port';
  }

  @override
  String get roleSailor => '水手';

  @override
  String get roleShipwright => '船工';

  @override
  String get roleGunner => '炮手';

  @override
  String get roleUnassigned => '未分配';
}
