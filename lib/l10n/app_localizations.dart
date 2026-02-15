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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Cruising'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @loadSave.
  ///
  /// In en, this message translates to:
  /// **'Load Save'**
  String get loadSave;

  /// No description provided for @exitGame.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitGame;

  /// No description provided for @saveGame.
  ///
  /// In en, this message translates to:
  /// **'Save Game'**
  String get saveGame;

  /// No description provided for @loadGame.
  ///
  /// In en, this message translates to:
  /// **'Load Game'**
  String get loadGame;

  /// No description provided for @soundSettings.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get soundSettings;

  /// No description provided for @musicVolume.
  ///
  /// In en, this message translates to:
  /// **'Music Volume'**
  String get musicVolume;

  /// No description provided for @sfxVolume.
  ///
  /// In en, this message translates to:
  /// **'SFX Volume'**
  String get sfxVolume;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySettings;

  /// No description provided for @fullscreenMode.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreenMode;

  /// No description provided for @wallpaperMode.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper Mode'**
  String get wallpaperMode;

  /// No description provided for @windowResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get windowResolution;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;

  /// No description provided for @returnMainMenu.
  ///
  /// In en, this message translates to:
  /// **'Return to Main Menu'**
  String get returnMainMenu;

  /// No description provided for @returnMainMenuConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unsaved progress will be lost. Return to main menu?'**
  String get returnMainMenuConfirm;

  /// No description provided for @saveListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load save list: {error}'**
  String saveListLoadFailed(Object error);

  /// No description provided for @autoSlotManualBlocked.
  ///
  /// In en, this message translates to:
  /// **'Auto-save slot cannot be overwritten manually'**
  String get autoSlotManualBlocked;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Save successful'**
  String get saveSuccess;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String loadFailed(Object error);

  /// No description provided for @deleteSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Save'**
  String get deleteSaveTitle;

  /// No description provided for @deleteSaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this save? This action cannot be undone.'**
  String get deleteSaveConfirm;

  /// No description provided for @slotEmpty.
  ///
  /// In en, this message translates to:
  /// **'This slot is empty'**
  String get slotEmpty;

  /// No description provided for @emptySlot.
  ///
  /// In en, this message translates to:
  /// **'Empty Slot'**
  String get emptySlot;

  /// No description provided for @autoSaveSlot.
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get autoSaveSlot;

  /// No description provided for @saveSlotLabel.
  ///
  /// In en, this message translates to:
  /// **'Save {id}'**
  String saveSlotLabel(Object id);

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location: {name}'**
  String locationLabel(Object name);

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String timeLabel(Object time);

  /// No description provided for @goldDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Gold: {gold} | Day: {day}'**
  String goldDayLabel(Object gold, Object day);

  /// No description provided for @shipUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Ship Upgrade'**
  String get shipUpgrade;

  /// No description provided for @shipUpgradeInDev.
  ///
  /// In en, this message translates to:
  /// **'Upgrade feature is under development...'**
  String get shipUpgradeInDev;

  /// No description provided for @crewLeftNoPay.
  ///
  /// In en, this message translates to:
  /// **'Crew {names} left quietly at port because they were unpaid...'**
  String crewLeftNoPay(Object names);

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @hall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get hall;

  /// No description provided for @tavern.
  ///
  /// In en, this message translates to:
  /// **'Tavern'**
  String get tavern;

  /// No description provided for @shipyard.
  ///
  /// In en, this message translates to:
  /// **'Shipyard'**
  String get shipyard;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @headingTo.
  ///
  /// In en, this message translates to:
  /// **'Heading to: {name}'**
  String headingTo(Object name);

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {time}'**
  String remaining(Object time);

  /// No description provided for @daysHours.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h'**
  String daysHours(Object days, Object hours);

  /// No description provided for @daysOnly.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String daysOnly(Object days);

  /// No description provided for @hoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String hoursOnly(Object hours);

  /// No description provided for @atSea.
  ///
  /// In en, this message translates to:
  /// **'At Sea'**
  String get atSea;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @perSecond.
  ///
  /// In en, this message translates to:
  /// **'/s'**
  String get perSecond;

  /// No description provided for @shotsPerSecond.
  ///
  /// In en, this message translates to:
  /// **'shots/s'**
  String get shotsPerSecond;

  /// No description provided for @knots.
  ///
  /// In en, this message translates to:
  /// **'kt'**
  String get knots;

  /// No description provided for @tapAnywhereToContinue.
  ///
  /// In en, this message translates to:
  /// **'-- Tap anywhere to continue --'**
  String get tapAnywhereToContinue;

  /// No description provided for @spring.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get spring;

  /// No description provided for @summer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get summer;

  /// No description provided for @autumn.
  ///
  /// In en, this message translates to:
  /// **'Autumn'**
  String get autumn;

  /// No description provided for @winter.
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get winter;

  /// No description provided for @seasonDay.
  ///
  /// In en, this message translates to:
  /// **'{season} Day {day}'**
  String seasonDay(Object season, Object day);

  /// No description provided for @selectDestination.
  ///
  /// In en, this message translates to:
  /// **'Select Destination'**
  String get selectDestination;

  /// No description provided for @depart.
  ///
  /// In en, this message translates to:
  /// **'Depart'**
  String get depart;

  /// No description provided for @currentPort.
  ///
  /// In en, this message translates to:
  /// **'Current Port'**
  String get currentPort;

  /// No description provided for @tradeDialogNoPort.
  ///
  /// In en, this message translates to:
  /// **'Not at a port and no trade target specified'**
  String get tradeDialogNoPort;

  /// No description provided for @marketTitle.
  ///
  /// In en, this message translates to:
  /// **'Market - {port}'**
  String marketTitle(Object port);

  /// No description provided for @merchantInventory.
  ///
  /// In en, this message translates to:
  /// **'Merchant Inventory'**
  String get merchantInventory;

  /// No description provided for @myInventory.
  ///
  /// In en, this message translates to:
  /// **'My Inventory'**
  String get myInventory;

  /// No description provided for @playerReceives.
  ///
  /// In en, this message translates to:
  /// **'Player Receives'**
  String get playerReceives;

  /// No description provided for @playerPays.
  ///
  /// In en, this message translates to:
  /// **'Player Pays'**
  String get playerPays;

  /// No description provided for @tradeIn.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get tradeIn;

  /// No description provided for @tradeOut.
  ///
  /// In en, this message translates to:
  /// **'Give'**
  String get tradeOut;

  /// No description provided for @balanceOffer.
  ///
  /// In en, this message translates to:
  /// **'Balance Offer'**
  String get balanceOffer;

  /// No description provided for @confirmTrade.
  ///
  /// In en, this message translates to:
  /// **'Confirm Trade'**
  String get confirmTrade;

  /// No description provided for @tradeUnfair.
  ///
  /// In en, this message translates to:
  /// **'Unfair Trade'**
  String get tradeUnfair;

  /// No description provided for @buyAction.
  ///
  /// In en, this message translates to:
  /// **'Buy: {name}'**
  String buyAction(Object name);

  /// No description provided for @sellAction.
  ///
  /// In en, this message translates to:
  /// **'Sell: {name}'**
  String sellAction(Object name);

  /// No description provided for @holdingAverage.
  ///
  /// In en, this message translates to:
  /// **'Holding Avg: {price}'**
  String holdingAverage(Object price);

  /// No description provided for @buyAverage.
  ///
  /// In en, this message translates to:
  /// **'Buy Avg: {price}'**
  String buyAverage(Object price);

  /// No description provided for @sellAverage.
  ///
  /// In en, this message translates to:
  /// **'Sell Avg: {price}'**
  String sellAverage(Object price);

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Est: {value}'**
  String estimatedValue(Object value);

  /// No description provided for @tradeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trade successful!'**
  String get tradeSuccess;

  /// No description provided for @tradeFailed.
  ///
  /// In en, this message translates to:
  /// **'Trade failed: {reason}'**
  String tradeFailed(Object reason);

  /// No description provided for @merchantFavor.
  ///
  /// In en, this message translates to:
  /// **'<- Merchant'**
  String get merchantFavor;

  /// No description provided for @playerFavor.
  ///
  /// In en, this message translates to:
  /// **'Player ->'**
  String get playerFavor;

  /// No description provided for @fairTrade.
  ///
  /// In en, this message translates to:
  /// **'Fair Trade'**
  String get fairTrade;

  /// No description provided for @seaEventMerchantTrading.
  ///
  /// In en, this message translates to:
  /// **'Trading with a merchant ship...'**
  String get seaEventMerchantTrading;

  /// No description provided for @shipDamaged.
  ///
  /// In en, this message translates to:
  /// **'Ship damaged: durability -{value}'**
  String shipDamaged(Object value);

  /// No description provided for @shipRepaired.
  ///
  /// In en, this message translates to:
  /// **'Ship repaired: durability +{value}'**
  String shipRepaired(Object value);

  /// No description provided for @goldGained.
  ///
  /// In en, this message translates to:
  /// **'Gold gained: {value} 💰'**
  String goldGained(Object value);

  /// No description provided for @goldLost.
  ///
  /// In en, this message translates to:
  /// **'Gold lost: {value} 💰'**
  String goldLost(Object value);

  /// No description provided for @goodsGained.
  ///
  /// In en, this message translates to:
  /// **'Gained: {name} x{count}'**
  String goodsGained(Object name, Object count);

  /// No description provided for @cargoFullNoGoods.
  ///
  /// In en, this message translates to:
  /// **'Cargo is full. Cannot obtain goods.'**
  String get cargoFullNoGoods;

  /// No description provided for @rerouteToPort.
  ///
  /// In en, this message translates to:
  /// **'Route changed. Turning toward {port}'**
  String rerouteToPort(Object port);

  /// No description provided for @roleSailor.
  ///
  /// In en, this message translates to:
  /// **'Sailor'**
  String get roleSailor;

  /// No description provided for @roleShipwright.
  ///
  /// In en, this message translates to:
  /// **'Shipwright'**
  String get roleShipwright;

  /// No description provided for @roleGunner.
  ///
  /// In en, this message translates to:
  /// **'Gunner'**
  String get roleGunner;

  /// No description provided for @roleUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get roleUnassigned;
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
