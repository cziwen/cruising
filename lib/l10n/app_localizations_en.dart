// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cruising';

  @override
  String get loading => 'Loading...';

  @override
  String get settings => 'Settings';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get load => 'Load';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get ok => 'OK';

  @override
  String get newGame => 'New Game';

  @override
  String get continueGame => 'Continue';

  @override
  String get loadSave => 'Load Save';

  @override
  String get exitGame => 'Exit';

  @override
  String get saveGame => 'Save Game';

  @override
  String get loadGame => 'Load Game';

  @override
  String get soundSettings => 'Audio';

  @override
  String get musicVolume => 'Music Volume';

  @override
  String get sfxVolume => 'SFX Volume';

  @override
  String get displaySettings => 'Display';

  @override
  String get fullscreenMode => 'Fullscreen';

  @override
  String get wallpaperMode => 'Wallpaper Mode';

  @override
  String get windowResolution => 'Resolution';

  @override
  String get languageSettings => 'Language';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => 'Chinese';

  @override
  String get returnMainMenu => 'Return to Main Menu';

  @override
  String get returnMainMenuConfirm =>
      'Unsaved progress will be lost. Return to main menu?';

  @override
  String saveListLoadFailed(Object error) {
    return 'Failed to load save list: $error';
  }

  @override
  String get autoSlotManualBlocked =>
      'Auto-save slot cannot be overwritten manually';

  @override
  String get saveSuccess => 'Save successful';

  @override
  String saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String loadFailed(Object error) {
    return 'Load failed: $error';
  }

  @override
  String get deleteSaveTitle => 'Delete Save';

  @override
  String get deleteSaveConfirm =>
      'Delete this save? This action cannot be undone.';

  @override
  String get slotEmpty => 'This slot is empty';

  @override
  String get emptySlot => 'Empty Slot';

  @override
  String get autoSaveSlot => 'Auto Save';

  @override
  String saveSlotLabel(Object id) {
    return 'Save $id';
  }

  @override
  String locationLabel(Object name) {
    return 'Location: $name';
  }

  @override
  String timeLabel(Object time) {
    return 'Time: $time';
  }

  @override
  String goldDayLabel(Object gold, Object day) {
    return 'Gold: $gold | Day: $day';
  }

  @override
  String get shipUpgrade => 'Ship Upgrade';

  @override
  String get shipUpgradeInDev => 'Upgrade feature is under development...';

  @override
  String crewLeftNoPay(Object names) {
    return 'Crew $names left quietly at port because they were unpaid...';
  }

  @override
  String get market => 'Market';

  @override
  String get hall => 'Hall';

  @override
  String get tavern => 'Tavern';

  @override
  String get shipyard => 'Shipyard';

  @override
  String get manage => 'Manage';

  @override
  String get map => 'Map';

  @override
  String headingTo(Object name) {
    return 'Heading to: $name';
  }

  @override
  String remaining(Object time) {
    return 'Remaining: $time';
  }

  @override
  String daysHours(Object days, Object hours) {
    return '${days}d ${hours}h';
  }

  @override
  String daysOnly(Object days) {
    return '${days}d';
  }

  @override
  String hoursOnly(Object hours) {
    return '${hours}h';
  }

  @override
  String get atSea => 'At Sea';

  @override
  String get unknown => 'Unknown';

  @override
  String get perSecond => '/s';

  @override
  String get shotsPerSecond => 'shots/s';

  @override
  String get knots => 'kt';

  @override
  String get tapAnywhereToContinue => '-- Tap anywhere to continue --';

  @override
  String get spring => 'Spring';

  @override
  String get summer => 'Summer';

  @override
  String get autumn => 'Autumn';

  @override
  String get winter => 'Winter';

  @override
  String seasonDay(Object season, Object day) {
    return '$season Day $day';
  }

  @override
  String get selectDestination => 'Select Destination';

  @override
  String get depart => 'Depart';

  @override
  String get currentPort => 'Current Port';

  @override
  String get tradeDialogNoPort => 'Not at a port and no trade target specified';

  @override
  String marketTitle(Object port) {
    return 'Market - $port';
  }

  @override
  String get merchantInventory => 'Merchant Inventory';

  @override
  String get myInventory => 'My Inventory';

  @override
  String get playerReceives => 'Player Receives';

  @override
  String get playerPays => 'Player Pays';

  @override
  String get tradeIn => 'Receive';

  @override
  String get tradeOut => 'Give';

  @override
  String get balanceOffer => 'Balance Offer';

  @override
  String get confirmTrade => 'Confirm Trade';

  @override
  String get tradeUnfair => 'Unfair Trade';

  @override
  String buyAction(Object name) {
    return 'Buy: $name';
  }

  @override
  String sellAction(Object name) {
    return 'Sell: $name';
  }

  @override
  String holdingAverage(Object price) {
    return 'Holding Avg: $price';
  }

  @override
  String buyAverage(Object price) {
    return 'Buy Avg: $price';
  }

  @override
  String sellAverage(Object price) {
    return 'Sell Avg: $price';
  }

  @override
  String estimatedValue(Object value) {
    return 'Est: $value';
  }

  @override
  String get tradeSuccess => 'Trade successful!';

  @override
  String tradeFailed(Object reason) {
    return 'Trade failed: $reason';
  }

  @override
  String get merchantFavor => '<- Merchant';

  @override
  String get playerFavor => 'Player ->';

  @override
  String get fairTrade => 'Fair Trade';

  @override
  String get seaEventMerchantTrading => 'Trading with a merchant ship...';

  @override
  String shipDamaged(Object value) {
    return 'Ship damaged: durability -$value';
  }

  @override
  String shipRepaired(Object value) {
    return 'Ship repaired: durability +$value';
  }

  @override
  String goldGained(Object value) {
    return 'Gold gained: $value 💰';
  }

  @override
  String goldLost(Object value) {
    return 'Gold lost: $value 💰';
  }

  @override
  String goodsGained(Object name, Object count) {
    return 'Gained: $name x$count';
  }

  @override
  String get cargoFullNoGoods => 'Cargo is full. Cannot obtain goods.';

  @override
  String rerouteToPort(Object port) {
    return 'Route changed. Turning toward $port';
  }

  @override
  String get roleSailor => 'Sailor';

  @override
  String get roleShipwright => 'Shipwright';

  @override
  String get roleGunner => 'Gunner';

  @override
  String get roleUnassigned => 'Unassigned';
}
