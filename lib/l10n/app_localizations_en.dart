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
  String marketTitle(String portName) {
    return 'Market - $portName';
  }

  @override
  String get confirmTrade => 'Confirm Trade';

  @override
  String get tradeSuccess => 'Trade Successful!';

  @override
  String get tradeUnfair => 'Unfair Trade';

  @override
  String get merchantInventory => 'Merchant Inventory';

  @override
  String get myInventory => 'My Inventory';

  @override
  String get playerGet => 'Player Get';

  @override
  String get playerPay => 'Player Pay';

  @override
  String get receive => 'Receive';

  @override
  String get give => 'Give';

  @override
  String get balanceOffer => 'Balance Offer';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'Sell';

  @override
  String holdAveragePrice(Object price) {
    return 'Avg. Purchase: $price';
  }

  @override
  String batchAveragePrice(Object price, Object type) {
    return '$type Avg: $price';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get favorMerchant => 'Favor Merchant';

  @override
  String get favorPlayer => 'Favor Player';

  @override
  String get fairTrade => 'Fair Trade';

  @override
  String get errorNotAtPort => 'Not at port and no target specified';

  @override
  String get errorMerchantRefuse => 'Merchant refuses (favor player)';

  @override
  String get errorGoldNotEnough => 'Insufficient gold';

  @override
  String errorGoodsNotEnough(Object goodsName) {
    return 'Insufficient $goodsName';
  }

  @override
  String get errorCargoFull => 'Cargo space full';

  @override
  String get errorMerchantGoldNotEnough => 'Merchant insufficient gold';

  @override
  String errorPortStockNotEnough(Object goodsName) {
    return 'Insufficient $goodsName in port';
  }

  @override
  String crewDeparted(Object names) {
    return 'Crew $names left the port quietly because they were not paid...';
  }

  @override
  String get shipUpgrade => 'Ship Upgrade';

  @override
  String get featureInDevelopment => 'Upgrade feature in development...';

  @override
  String get ok => 'OK';

  @override
  String get tavernDefaultDescription => 'An adventurer eager to go to sea.';

  @override
  String crewFull(Object current, Object max) {
    return 'Crew full ($current / $max)';
  }

  @override
  String goldNotEnoughRecruit(Object cost) {
    return 'Not enough gold! Need $cost gold';
  }

  @override
  String get recruitConfirmTitle => 'Recruit this crew member?';

  @override
  String salaryPerDay(Object salary) {
    return 'Salary: $salary Gold / Day';
  }

  @override
  String recruitmentCost(Object cost) {
    return 'Recruitment Cost: $cost Gold';
  }

  @override
  String currentCrewCount(Object current, Object max) {
    return 'Current Crew: $current / $max';
  }

  @override
  String get lookAround => 'Look Around';

  @override
  String get confirmRecruit => 'Confirm Recruit';

  @override
  String recruitSuccess(Object name) {
    return 'Successfully recruited $name!';
  }

  @override
  String get tavern => 'Tavern';

  @override
  String get noAvailableCrew => 'No available crew';

  @override
  String get selectCrewDetail => 'Please select a crew member to view details';

  @override
  String get sailorSkill => 'Sailor Skill';

  @override
  String get shipwrightSkill => 'Shipwright Skill';

  @override
  String get gunnerSkill => 'Gunner Skill';

  @override
  String get recruitHint =>
      'Can assign professions for bonuses after recruitment';

  @override
  String get recruitCrew => 'Recruit';

  @override
  String get upgradeSuccess => 'Upgrade Successful!';

  @override
  String get upgradeOptions => 'Upgrade Options';

  @override
  String get shipyard => 'Shipyard';

  @override
  String get shipAttributes => 'Ship Attributes';

  @override
  String get shipName => 'Ship Name';

  @override
  String get shipLevel => 'Ship Level';

  @override
  String get cargoCapacity => 'Cargo Capacity';

  @override
  String get durability => 'Durability';

  @override
  String get crewCapacity => 'Crew Capacity';

  @override
  String get maxLevelReached => 'Max Level Reached';

  @override
  String upgradeCost(Object cost) {
    return '💰$cost Upgrade';
  }

  @override
  String get maxLevel => 'Max Level';

  @override
  String get newGame => 'New Game';

  @override
  String get continueGame => 'Continue';

  @override
  String get loadGame => 'Load Game';

  @override
  String get exitGame => 'Exit';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get currentLanguage => 'Current Language';

  @override
  String get chinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get soundSettings => 'Sound Settings';

  @override
  String get musicVolume => 'Music Volume';

  @override
  String get sfxVolume => 'SFX Volume';

  @override
  String get displaySettings => 'Display Settings';

  @override
  String get fullScreen => 'Full Screen';

  @override
  String get wallpaperMode => 'Wallpaper Mode';

  @override
  String get windowResolution => 'Resolution';

  @override
  String get saveGame => 'Save Game';

  @override
  String get returnToMainMenu => 'Main Menu';

  @override
  String get close => 'Close';

  @override
  String get returnMainMenuConfirm =>
      'Unsaved progress will be lost. Return to main menu?';

  @override
  String get selectDestination => 'Select Destination';

  @override
  String get depart => 'Depart';

  @override
  String get currentPort => 'Current Port';

  @override
  String get settings => 'Settings';

  @override
  String get market => 'Market';

  @override
  String get hall => 'Main Hall';

  @override
  String get manage => 'Manage';

  @override
  String get map => 'Map';

  @override
  String mainHallTitle(Object level) {
    return 'Main Hall - Lv. $level';
  }

  @override
  String get cityHallUpgrade => 'City Hall Upgrade';

  @override
  String get islandWarehouse => 'Island Warehouse';

  @override
  String get islandFeatureUpgrade => 'Island Feature Upgrade';

  @override
  String get upgradeSyncHint =>
      'Island visual level will increase once all features are upgraded.';

  @override
  String get taxQuota => 'Tax Quota';

  @override
  String get taxQuotaDesc => 'Increase tax collected per hour';

  @override
  String get localEconomy => 'Local Economy';

  @override
  String get localEconomyDesc => 'Lower purchase prices in island shops';

  @override
  String get merchantFunds => 'Merchant Funds';

  @override
  String get merchantFundsDesc => 'Increase merchant\'s maximum gold';

  @override
  String get restockSpeed => 'Restock Speed';

  @override
  String get restockSpeedDesc => 'Increase restock speed and inventory';

  @override
  String get needsOtherUpgrades => 'Need other upgrades first';

  @override
  String get myShip => 'My Ship';

  @override
  String cargoWeight(Object capacity, Object used) {
    return 'Cargo: $used/${capacity}kg';
  }

  @override
  String get emptyStorage => 'Empty';

  @override
  String get depositToWarehouse => 'Deposit to Warehouse';

  @override
  String get withdrawFromWarehouse => 'Withdraw to Ship';

  @override
  String get confirmDeposit => 'Confirm Deposit';

  @override
  String get confirmWithdraw => 'Confirm Withdraw';

  @override
  String get depositSuccess => 'Deposit Successful!';

  @override
  String get withdrawSuccess => 'Withdraw Successful!';

  @override
  String get withdrawFail => 'Withdraw Failed (Insufficient capacity?)';

  @override
  String get crewManagement => 'Crew Management';

  @override
  String get sailingBonus => 'Sailing Bonus';

  @override
  String get autoRepair => 'Auto Repair';

  @override
  String get fireRate => 'Fire Rate';

  @override
  String get noCrewHint => 'No crew members\nPlease recruit at the market';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get dismissCrew => 'Dismiss Crew';

  @override
  String dismissConfirm(Object name) {
    return 'Are you sure you want to dismiss $name?\nThis cannot be undone.';
  }

  @override
  String get atSea => 'At Sea';

  @override
  String get unknownLocation => 'Unknown';

  @override
  String travelingTo(Object destination) {
    return 'Traveling to: $destination';
  }

  @override
  String remainingTime(Object time) {
    return 'Remaining: $time';
  }

  @override
  String days(Object count) {
    return '${count}d';
  }

  @override
  String hours(Object count) {
    return '${count}h';
  }

  @override
  String get knots => 'knots';

  @override
  String get perSecond => '/s';

  @override
  String get shotsPerSecond => 'shots/s';

  @override
  String peopleCount(Object count) {
    return '$count';
  }

  @override
  String get tapAnywhereToContinueHint => '-- Tap anywhere to continue --';

  @override
  String notificationSalaryPaid(Object amount) {
    return 'Paid today\'s crew salary (Total $amount 💰)';
  }

  @override
  String notificationSalaryUnpaid(Object names) {
    return 'Insufficient gold! $names and others did not receive salary, morale decreased';
  }

  @override
  String get notificationEnteredSea => 'Entered the sea';

  @override
  String notificationArrivedAtPort(Object portName) {
    return 'Arrived at $portName';
  }

  @override
  String get notificationEncounterEnemyShip =>
      'Encountered an enemy ship! Prepare for battle';

  @override
  String notificationShipDamaged(Object amount) {
    return 'Ship damaged: Durability decreased by $amount';
  }

  @override
  String notificationShipRepaired(Object amount) {
    return 'Ship repaired: Durability restored by $amount';
  }

  @override
  String notificationGoldGained(Object amount) {
    return 'Gained gold: $amount 💰';
  }

  @override
  String notificationGoldLost(Object amount) {
    return 'Lost gold: $amount 💰';
  }

  @override
  String get notificationMerchantTradeStart =>
      'Trading goods with a merchant ship...';

  @override
  String notificationGoodsGained(Object count, Object goodsName) {
    return 'Gained materials: $goodsName x$count';
  }

  @override
  String get notificationCargoFullCannotGetGoods =>
      'Cargo full, cannot obtain materials';

  @override
  String notificationCourseChangedToNearestPort(Object portName) {
    return 'Course changed, turning to the nearest port: $portName';
  }

  @override
  String get roleSailor => 'Sailor';

  @override
  String get roleShipwright => 'Shipwright';

  @override
  String get roleGunner => 'Gunner';

  @override
  String get roleUnassigned => 'Unassigned';

  @override
  String get weatherCalm => 'Calm';

  @override
  String get weatherLightWind => 'Light Wind';

  @override
  String get weatherStorm => 'Storm';

  @override
  String get seasonSpring => 'Spring';

  @override
  String get seasonSummer => 'Summer';

  @override
  String get seasonAutumn => 'Autumn';

  @override
  String get seasonWinter => 'Winter';

  @override
  String get autoSave => 'Auto Save';

  @override
  String saveSlot(Object id) {
    return 'Save $id';
  }

  @override
  String get emptySlot => 'Empty Slot';
}
