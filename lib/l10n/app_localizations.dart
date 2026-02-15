import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 应用程序的标题
  ///
  /// In zh, this message translates to:
  /// **'航行'**
  String get appTitle;

  /// No description provided for @marketTitle.
  ///
  /// In zh, this message translates to:
  /// **'市场 - {portName}'**
  String marketTitle(String portName);

  /// No description provided for @confirmTrade.
  ///
  /// In zh, this message translates to:
  /// **'确认交易'**
  String get confirmTrade;

  /// No description provided for @tradeSuccess.
  ///
  /// In zh, this message translates to:
  /// **'交易成功！'**
  String get tradeSuccess;

  /// No description provided for @tradeUnfair.
  ///
  /// In zh, this message translates to:
  /// **'交易不公平'**
  String get tradeUnfair;

  /// No description provided for @merchantInventory.
  ///
  /// In zh, this message translates to:
  /// **'商人库存'**
  String get merchantInventory;

  /// No description provided for @myInventory.
  ///
  /// In zh, this message translates to:
  /// **'我的库存'**
  String get myInventory;

  /// No description provided for @playerGet.
  ///
  /// In zh, this message translates to:
  /// **'玩家获得'**
  String get playerGet;

  /// No description provided for @playerPay.
  ///
  /// In zh, this message translates to:
  /// **'玩家支付'**
  String get playerPay;

  /// No description provided for @receive.
  ///
  /// In zh, this message translates to:
  /// **'换入'**
  String get receive;

  /// No description provided for @give.
  ///
  /// In zh, this message translates to:
  /// **'换出'**
  String get give;

  /// No description provided for @balanceOffer.
  ///
  /// In zh, this message translates to:
  /// **'平衡报价'**
  String get balanceOffer;

  /// No description provided for @buy.
  ///
  /// In zh, this message translates to:
  /// **'购买'**
  String get buy;

  /// No description provided for @sell.
  ///
  /// In zh, this message translates to:
  /// **'出售'**
  String get sell;

  /// No description provided for @holdAveragePrice.
  ///
  /// In zh, this message translates to:
  /// **'持有均价: {price}'**
  String holdAveragePrice(Object price);

  /// No description provided for @batchAveragePrice.
  ///
  /// In zh, this message translates to:
  /// **'{type}均价: {price}'**
  String batchAveragePrice(Object price, Object type);

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @favorMerchant.
  ///
  /// In zh, this message translates to:
  /// **'偏向商人'**
  String get favorMerchant;

  /// No description provided for @favorPlayer.
  ///
  /// In zh, this message translates to:
  /// **'偏向玩家'**
  String get favorPlayer;

  /// No description provided for @fairTrade.
  ///
  /// In zh, this message translates to:
  /// **'公平交易'**
  String get fairTrade;

  /// No description provided for @errorNotAtPort.
  ///
  /// In zh, this message translates to:
  /// **'当前不在港口且未指定交易对象'**
  String get errorNotAtPort;

  /// No description provided for @errorMerchantRefuse.
  ///
  /// In zh, this message translates to:
  /// **'商人拒绝此交易（交易偏向玩家）'**
  String get errorMerchantRefuse;

  /// No description provided for @errorGoldNotEnough.
  ///
  /// In zh, this message translates to:
  /// **'金币不足'**
  String get errorGoldNotEnough;

  /// No description provided for @errorGoodsNotEnough.
  ///
  /// In zh, this message translates to:
  /// **'{goodsName} 库存不足'**
  String errorGoodsNotEnough(Object goodsName);

  /// No description provided for @errorCargoFull.
  ///
  /// In zh, this message translates to:
  /// **'载货空间不足'**
  String get errorCargoFull;

  /// No description provided for @errorMerchantGoldNotEnough.
  ///
  /// In zh, this message translates to:
  /// **'商人金币不足'**
  String get errorMerchantGoldNotEnough;

  /// No description provided for @errorPortStockNotEnough.
  ///
  /// In zh, this message translates to:
  /// **'{goodsName} 港口库存不足'**
  String errorPortStockNotEnough(Object goodsName);

  /// No description provided for @crewDeparted.
  ///
  /// In zh, this message translates to:
  /// **'船员 {names} 因为得不到报酬，已经在港口悄悄离开了...'**
  String crewDeparted(Object names);

  /// No description provided for @shipUpgrade.
  ///
  /// In zh, this message translates to:
  /// **'船只升级'**
  String get shipUpgrade;

  /// No description provided for @featureInDevelopment.
  ///
  /// In zh, this message translates to:
  /// **'升级功能开发中...'**
  String get featureInDevelopment;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get ok;

  /// No description provided for @tavernDefaultDescription.
  ///
  /// In zh, this message translates to:
  /// **'一位渴望出海的冒险者。'**
  String get tavernDefaultDescription;

  /// No description provided for @crewFull.
  ///
  /// In zh, this message translates to:
  /// **'船员已满（{current} / {max}）'**
  String crewFull(Object current, Object max);

  /// No description provided for @goldNotEnoughRecruit.
  ///
  /// In zh, this message translates to:
  /// **'金币不足！需要 {cost} 金币'**
  String goldNotEnoughRecruit(Object cost);

  /// No description provided for @recruitConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'招募该船员？'**
  String get recruitConfirmTitle;

  /// No description provided for @salaryPerDay.
  ///
  /// In zh, this message translates to:
  /// **'工资：{salary} 金币 / 天'**
  String salaryPerDay(Object salary);

  /// No description provided for @recruitmentCost.
  ///
  /// In zh, this message translates to:
  /// **'招募费用：{cost} 金币'**
  String recruitmentCost(Object cost);

  /// No description provided for @currentCrewCount.
  ///
  /// In zh, this message translates to:
  /// **'当前船员数：{current} / {max}'**
  String currentCrewCount(Object current, Object max);

  /// No description provided for @lookAround.
  ///
  /// In zh, this message translates to:
  /// **'再看看'**
  String get lookAround;

  /// No description provided for @confirmRecruit.
  ///
  /// In zh, this message translates to:
  /// **'确认招募'**
  String get confirmRecruit;

  /// No description provided for @recruitSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功招募 {name}！'**
  String recruitSuccess(Object name);

  /// No description provided for @tavern.
  ///
  /// In zh, this message translates to:
  /// **'酒馆'**
  String get tavern;

  /// No description provided for @noAvailableCrew.
  ///
  /// In zh, this message translates to:
  /// **'暂无可招募船员'**
  String get noAvailableCrew;

  /// No description provided for @selectCrewDetail.
  ///
  /// In zh, this message translates to:
  /// **'请选择一名船员查看详情'**
  String get selectCrewDetail;

  /// No description provided for @sailorSkill.
  ///
  /// In zh, this message translates to:
  /// **'水手技能'**
  String get sailorSkill;

  /// No description provided for @shipwrightSkill.
  ///
  /// In zh, this message translates to:
  /// **'船工技能'**
  String get shipwrightSkill;

  /// No description provided for @gunnerSkill.
  ///
  /// In zh, this message translates to:
  /// **'炮手技能'**
  String get gunnerSkill;

  /// No description provided for @recruitHint.
  ///
  /// In zh, this message translates to:
  /// **'招募后可分配职业以提供加成（在船员管理界面）'**
  String get recruitHint;

  /// No description provided for @recruitCrew.
  ///
  /// In zh, this message translates to:
  /// **'招募'**
  String get recruitCrew;

  /// No description provided for @upgradeSuccess.
  ///
  /// In zh, this message translates to:
  /// **'升级成功！'**
  String get upgradeSuccess;

  /// No description provided for @upgradeOptions.
  ///
  /// In zh, this message translates to:
  /// **'升级选项'**
  String get upgradeOptions;

  /// No description provided for @shipyard.
  ///
  /// In zh, this message translates to:
  /// **'船厂'**
  String get shipyard;

  /// No description provided for @shipAttributes.
  ///
  /// In zh, this message translates to:
  /// **'船只属性'**
  String get shipAttributes;

  /// No description provided for @shipName.
  ///
  /// In zh, this message translates to:
  /// **'船名'**
  String get shipName;

  /// No description provided for @shipLevel.
  ///
  /// In zh, this message translates to:
  /// **'船只等级'**
  String get shipLevel;

  /// No description provided for @cargoCapacity.
  ///
  /// In zh, this message translates to:
  /// **'载货量'**
  String get cargoCapacity;

  /// No description provided for @durability.
  ///
  /// In zh, this message translates to:
  /// **'耐久度'**
  String get durability;

  /// No description provided for @crewCapacity.
  ///
  /// In zh, this message translates to:
  /// **'船员容量'**
  String get crewCapacity;

  /// No description provided for @maxLevelReached.
  ///
  /// In zh, this message translates to:
  /// **'已达最高等级'**
  String get maxLevelReached;

  /// No description provided for @upgradeCost.
  ///
  /// In zh, this message translates to:
  /// **'💰{cost} 升级'**
  String upgradeCost(Object cost);

  /// No description provided for @maxLevel.
  ///
  /// In zh, this message translates to:
  /// **'已满级'**
  String get maxLevel;

  /// No description provided for @newGame.
  ///
  /// In zh, this message translates to:
  /// **'新游戏'**
  String get newGame;

  /// No description provided for @continueGame.
  ///
  /// In zh, this message translates to:
  /// **'继续游戏'**
  String get continueGame;

  /// No description provided for @loadGame.
  ///
  /// In zh, this message translates to:
  /// **'读取存档'**
  String get loadGame;

  /// No description provided for @exitGame.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get exitGame;

  /// No description provided for @languageSettings.
  ///
  /// In zh, this message translates to:
  /// **'语言设置'**
  String get languageSettings;

  /// No description provided for @currentLanguage.
  ///
  /// In zh, this message translates to:
  /// **'当前语言'**
  String get currentLanguage;

  /// No description provided for @chinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @soundSettings.
  ///
  /// In zh, this message translates to:
  /// **'声音设置'**
  String get soundSettings;

  /// No description provided for @musicVolume.
  ///
  /// In zh, this message translates to:
  /// **'音乐音量'**
  String get musicVolume;

  /// No description provided for @sfxVolume.
  ///
  /// In zh, this message translates to:
  /// **'音效音量'**
  String get sfxVolume;

  /// No description provided for @displaySettings.
  ///
  /// In zh, this message translates to:
  /// **'显示设置'**
  String get displaySettings;

  /// No description provided for @fullScreen.
  ///
  /// In zh, this message translates to:
  /// **'全屏模式'**
  String get fullScreen;

  /// No description provided for @wallpaperMode.
  ///
  /// In zh, this message translates to:
  /// **'动态壁纸模式'**
  String get wallpaperMode;

  /// No description provided for @windowResolution.
  ///
  /// In zh, this message translates to:
  /// **'窗口分辨率'**
  String get windowResolution;

  /// No description provided for @saveGame.
  ///
  /// In zh, this message translates to:
  /// **'保存游戏'**
  String get saveGame;

  /// No description provided for @returnToMainMenu.
  ///
  /// In zh, this message translates to:
  /// **'返回主菜单'**
  String get returnToMainMenu;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @returnMainMenuConfirm.
  ///
  /// In zh, this message translates to:
  /// **'未保存的进度将会丢失，确定要返回主菜单吗？'**
  String get returnMainMenuConfirm;

  /// No description provided for @selectDestination.
  ///
  /// In zh, this message translates to:
  /// **'选择目的地'**
  String get selectDestination;

  /// No description provided for @depart.
  ///
  /// In zh, this message translates to:
  /// **'出发'**
  String get depart;

  /// No description provided for @currentPort.
  ///
  /// In zh, this message translates to:
  /// **'当前港口'**
  String get currentPort;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @market.
  ///
  /// In zh, this message translates to:
  /// **'市场'**
  String get market;

  /// No description provided for @hall.
  ///
  /// In zh, this message translates to:
  /// **'大厅'**
  String get hall;

  /// No description provided for @manage.
  ///
  /// In zh, this message translates to:
  /// **'管理'**
  String get manage;

  /// No description provided for @map.
  ///
  /// In zh, this message translates to:
  /// **'地图'**
  String get map;

  /// No description provided for @mainHallTitle.
  ///
  /// In zh, this message translates to:
  /// **'大厅 - 等级 {level}'**
  String mainHallTitle(Object level);

  /// No description provided for @cityHallUpgrade.
  ///
  /// In zh, this message translates to:
  /// **'市政厅升级'**
  String get cityHallUpgrade;

  /// No description provided for @islandWarehouse.
  ///
  /// In zh, this message translates to:
  /// **'岛屿仓库'**
  String get islandWarehouse;

  /// No description provided for @islandFeatureUpgrade.
  ///
  /// In zh, this message translates to:
  /// **'岛屿功能升级'**
  String get islandFeatureUpgrade;

  /// No description provided for @upgradeSyncHint.
  ///
  /// In zh, this message translates to:
  /// **'当所有功能均升级后，岛屿视觉等级将自动提升。'**
  String get upgradeSyncHint;

  /// No description provided for @taxQuota.
  ///
  /// In zh, this message translates to:
  /// **'税收额度'**
  String get taxQuota;

  /// No description provided for @taxQuotaDesc.
  ///
  /// In zh, this message translates to:
  /// **'提升每小时产生的税收金额'**
  String get taxQuotaDesc;

  /// No description provided for @localEconomy.
  ///
  /// In zh, this message translates to:
  /// **'本地经济'**
  String get localEconomy;

  /// No description provided for @localEconomyDesc.
  ///
  /// In zh, this message translates to:
  /// **'降低岛屿商店买入价格'**
  String get localEconomyDesc;

  /// No description provided for @merchantFunds.
  ///
  /// In zh, this message translates to:
  /// **'商人资金'**
  String get merchantFunds;

  /// No description provided for @merchantFundsDesc.
  ///
  /// In zh, this message translates to:
  /// **'提升本地商人最大默认金额'**
  String get merchantFundsDesc;

  /// No description provided for @restockSpeed.
  ///
  /// In zh, this message translates to:
  /// **'补货速度'**
  String get restockSpeed;

  /// No description provided for @restockSpeedDesc.
  ///
  /// In zh, this message translates to:
  /// **'提升本地商人货物刷新速度与库存'**
  String get restockSpeedDesc;

  /// No description provided for @needsOtherUpgrades.
  ///
  /// In zh, this message translates to:
  /// **'需先升级其他项'**
  String get needsOtherUpgrades;

  /// No description provided for @myShip.
  ///
  /// In zh, this message translates to:
  /// **'我的船只'**
  String get myShip;

  /// No description provided for @cargoWeight.
  ///
  /// In zh, this message translates to:
  /// **'载重: {used}/{capacity}kg'**
  String cargoWeight(Object capacity, Object used);

  /// No description provided for @emptyStorage.
  ///
  /// In zh, this message translates to:
  /// **'空空如也'**
  String get emptyStorage;

  /// No description provided for @depositToWarehouse.
  ///
  /// In zh, this message translates to:
  /// **'存入仓库'**
  String get depositToWarehouse;

  /// No description provided for @withdrawFromWarehouse.
  ///
  /// In zh, this message translates to:
  /// **'取出到船'**
  String get withdrawFromWarehouse;

  /// No description provided for @confirmDeposit.
  ///
  /// In zh, this message translates to:
  /// **'确认存入'**
  String get confirmDeposit;

  /// No description provided for @confirmWithdraw.
  ///
  /// In zh, this message translates to:
  /// **'确认取出'**
  String get confirmWithdraw;

  /// No description provided for @depositSuccess.
  ///
  /// In zh, this message translates to:
  /// **'存入成功！'**
  String get depositSuccess;

  /// No description provided for @withdrawSuccess.
  ///
  /// In zh, this message translates to:
  /// **'取出成功！'**
  String get withdrawSuccess;

  /// No description provided for @withdrawFail.
  ///
  /// In zh, this message translates to:
  /// **'取出失败（可能载重不足）'**
  String get withdrawFail;

  /// No description provided for @crewManagement.
  ///
  /// In zh, this message translates to:
  /// **'船员管理'**
  String get crewManagement;

  /// No description provided for @sailingBonus.
  ///
  /// In zh, this message translates to:
  /// **'航速加成'**
  String get sailingBonus;

  /// No description provided for @autoRepair.
  ///
  /// In zh, this message translates to:
  /// **'自动修理'**
  String get autoRepair;

  /// No description provided for @fireRate.
  ///
  /// In zh, this message translates to:
  /// **'开炮速度'**
  String get fireRate;

  /// No description provided for @noCrewHint.
  ///
  /// In zh, this message translates to:
  /// **'暂无船员\n请在人才市场招募'**
  String get noCrewHint;

  /// No description provided for @unpaid.
  ///
  /// In zh, this message translates to:
  /// **'欠薪中'**
  String get unpaid;

  /// No description provided for @dismissCrew.
  ///
  /// In zh, this message translates to:
  /// **'解雇船员'**
  String get dismissCrew;

  /// No description provided for @dismissConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要解雇 {name} 吗？\n解雇后无法撤销。'**
  String dismissConfirm(Object name);

  /// No description provided for @atSea.
  ///
  /// In zh, this message translates to:
  /// **'海上'**
  String get atSea;

  /// No description provided for @unknownLocation.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get unknownLocation;

  /// No description provided for @travelingTo.
  ///
  /// In zh, this message translates to:
  /// **'前往: {destination}'**
  String travelingTo(Object destination);

  /// No description provided for @remainingTime.
  ///
  /// In zh, this message translates to:
  /// **'剩余: {time}'**
  String remainingTime(Object time);

  /// No description provided for @days.
  ///
  /// In zh, this message translates to:
  /// **'{count}天'**
  String days(Object count);

  /// No description provided for @hours.
  ///
  /// In zh, this message translates to:
  /// **'{count}小时'**
  String hours(Object count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
