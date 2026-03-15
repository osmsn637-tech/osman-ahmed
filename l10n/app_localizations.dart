import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Inventory'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @homeWorkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Putaway Worker'**
  String get homeWorkerTitle;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @moreHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get moreHome;

  /// No description provided for @moreItemLookup.
  ///
  /// In en, this message translates to:
  /// **'Item Lookup'**
  String get moreItemLookup;

  /// No description provided for @moreStockAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Stock Adjustment'**
  String get moreStockAdjustment;

  /// No description provided for @moreExceptions.
  ///
  /// In en, this message translates to:
  /// **'Exceptions'**
  String get moreExceptions;

  /// No description provided for @accountMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get accountMyAccount;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @accountPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get accountPhone;

  /// No description provided for @accountRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get accountRole;

  /// No description provided for @accountZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get accountZone;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @accountArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get accountArabic;

  /// No description provided for @accountEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get accountEnglish;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get accountActions;

  /// No description provided for @accountChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get accountChangePassword;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get accountSignOut;

  /// No description provided for @accountComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get accountComingSoon;

  /// No description provided for @roleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'SUPERVISOR'**
  String get roleSupervisor;

  /// No description provided for @roleInbound.
  ///
  /// In en, this message translates to:
  /// **'INBOUND'**
  String get roleInbound;

  /// No description provided for @roleWorker.
  ///
  /// In en, this message translates to:
  /// **'WORKER'**
  String get roleWorker;

  /// No description provided for @zoneWithCode.
  ///
  /// In en, this message translates to:
  /// **'Zone {zone}'**
  String zoneWithCode(Object zone);

  /// No description provided for @receiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive Items'**
  String get receiveTitle;

  /// No description provided for @receiveScanItemBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Item Barcode'**
  String get receiveScanItemBarcode;

  /// No description provided for @receiveScanDestinationLocation.
  ///
  /// In en, this message translates to:
  /// **'Scan Destination Location'**
  String get receiveScanDestinationLocation;

  /// No description provided for @receiveUsePhysicalScanner.
  ///
  /// In en, this message translates to:
  /// **'Use physical scanner trigger'**
  String get receiveUsePhysicalScanner;

  /// No description provided for @receiveConfirmDestinationThenQuantity.
  ///
  /// In en, this message translates to:
  /// **'Confirm destination then quantity'**
  String get receiveConfirmDestinationThenQuantity;

  /// No description provided for @receiveConfirmReceive.
  ///
  /// In en, this message translates to:
  /// **'Confirm Receive'**
  String get receiveConfirmReceive;

  /// No description provided for @receiveReceiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving...'**
  String get receiveReceiving;

  /// No description provided for @receiveAwaitingScan.
  ///
  /// In en, this message translates to:
  /// **'Awaiting scan...'**
  String get receiveAwaitingScan;

  /// No description provided for @receiveSkuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU: {barcode}'**
  String receiveSkuLabel(Object barcode);

  /// No description provided for @receiveTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {quantity}'**
  String receiveTotalLabel(Object quantity);

  /// No description provided for @receiveShelf.
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get receiveShelf;

  /// No description provided for @receiveBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk'**
  String get receiveBulk;

  /// No description provided for @receiveDestinationLocationScan.
  ///
  /// In en, this message translates to:
  /// **'Destination Location (scan)'**
  String get receiveDestinationLocationScan;

  /// No description provided for @receiveQuantityToReceive.
  ///
  /// In en, this message translates to:
  /// **'Quantity to receive'**
  String get receiveQuantityToReceive;

  /// No description provided for @receiveFullQty.
  ///
  /// In en, this message translates to:
  /// **'Full Qty'**
  String get receiveFullQty;

  /// No description provided for @moveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move Item'**
  String get moveTitle;

  /// No description provided for @moveScanItemBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Item Barcode'**
  String get moveScanItemBarcode;

  /// No description provided for @moveScanDestinationLocation.
  ///
  /// In en, this message translates to:
  /// **'Scan Destination Location'**
  String get moveScanDestinationLocation;

  /// No description provided for @moveTriggerScannerToCaptureItem.
  ///
  /// In en, this message translates to:
  /// **'Trigger scanner to capture item'**
  String get moveTriggerScannerToCaptureItem;

  /// No description provided for @moveScanTargetLocationThenConfirm.
  ///
  /// In en, this message translates to:
  /// **'Scan target location then confirm'**
  String get moveScanTargetLocationThenConfirm;

  /// No description provided for @moveFromLocation.
  ///
  /// In en, this message translates to:
  /// **'FROM LOCATION'**
  String get moveFromLocation;

  /// No description provided for @moveItemSection.
  ///
  /// In en, this message translates to:
  /// **'ITEM'**
  String get moveItemSection;

  /// No description provided for @moveToLocation.
  ///
  /// In en, this message translates to:
  /// **'TO LOCATION'**
  String get moveToLocation;

  /// No description provided for @moveQuantitySection.
  ///
  /// In en, this message translates to:
  /// **'QUANTITY'**
  String get moveQuantitySection;

  /// No description provided for @moveDestinationLocationBarcode.
  ///
  /// In en, this message translates to:
  /// **'Destination Location Barcode'**
  String get moveDestinationLocationBarcode;

  /// No description provided for @moveQtyToMove.
  ///
  /// In en, this message translates to:
  /// **'Qty to move'**
  String get moveQtyToMove;

  /// No description provided for @moveAwaitingScan.
  ///
  /// In en, this message translates to:
  /// **'Awaiting scan...'**
  String get moveAwaitingScan;

  /// No description provided for @moveConfirmMove.
  ///
  /// In en, this message translates to:
  /// **'Confirm Move'**
  String get moveConfirmMove;

  /// No description provided for @moveMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving...'**
  String get moveMoving;

  /// No description provided for @moveNoSourceLocations.
  ///
  /// In en, this message translates to:
  /// **'No source locations'**
  String get moveNoSourceLocations;

  /// No description provided for @moveSkuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU: {barcode}'**
  String moveSkuLabel(Object barcode);

  /// No description provided for @moveTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {quantity}'**
  String moveTotalLabel(Object quantity);

  /// No description provided for @stockAdjustmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock Adjustment'**
  String get stockAdjustmentTitle;

  /// No description provided for @stockScanItemBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Item Barcode'**
  String get stockScanItemBarcode;

  /// No description provided for @stockScanLocationBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Location Barcode'**
  String get stockScanLocationBarcode;

  /// No description provided for @stockReadyToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Ready to submit'**
  String get stockReadyToSubmit;

  /// No description provided for @stockLocationBarcode.
  ///
  /// In en, this message translates to:
  /// **'Location Barcode'**
  String get stockLocationBarcode;

  /// No description provided for @stockNewQuantity.
  ///
  /// In en, this message translates to:
  /// **'New Quantity'**
  String get stockNewQuantity;

  /// No description provided for @stockReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get stockReason;

  /// No description provided for @stockSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get stockSubmitting;

  /// No description provided for @stockSubmitAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Submit Adjustment'**
  String get stockSubmitAdjustment;

  /// No description provided for @exceptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Picking Exceptions'**
  String get exceptionsTitle;

  /// No description provided for @exceptionsExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected: {location}'**
  String exceptionsExpected(Object location);

  /// No description provided for @workerRefreshTasks.
  ///
  /// In en, this message translates to:
  /// **'Refresh tasks'**
  String get workerRefreshTasks;

  /// No description provided for @workerLookup.
  ///
  /// In en, this message translates to:
  /// **'Lookup'**
  String get workerLookup;

  /// No description provided for @workerAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get workerAdjust;

  /// No description provided for @workerAvailableTasks.
  ///
  /// In en, this message translates to:
  /// **'Available Tasks'**
  String get workerAvailableTasks;

  /// No description provided for @workerMyActiveTasks.
  ///
  /// In en, this message translates to:
  /// **'My Active Tasks'**
  String get workerMyActiveTasks;

  /// No description provided for @workerNoAvailableTasks.
  ///
  /// In en, this message translates to:
  /// **'No available tasks right now'**
  String get workerNoAvailableTasks;

  /// No description provided for @workerNoActiveTasks.
  ///
  /// In en, this message translates to:
  /// **'No active tasks - claim one above'**
  String get workerNoActiveTasks;

  /// No description provided for @workerStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get workerStart;

  /// No description provided for @workerComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get workerComplete;

  /// No description provided for @workerWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String workerWelcomeBack(Object name);

  /// No description provided for @workerTrackQueue.
  ///
  /// In en, this message translates to:
  /// **'Track your queue and close tasks quickly'**
  String get workerTrackQueue;

  /// No description provided for @metricAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get metricAvailable;

  /// No description provided for @metricActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get metricActive;

  /// No description provided for @metricDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get metricDone;

  /// No description provided for @workerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get workerDone;

  /// No description provided for @workerQty.
  ///
  /// In en, this message translates to:
  /// **'Qty {quantity}'**
  String workerQty(Object quantity);

  /// No description provided for @workerTaskDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get workerTaskDetailsTitle;

  /// No description provided for @workerStartTask.
  ///
  /// In en, this message translates to:
  /// **'Start Task'**
  String get workerStartTask;

  /// No description provided for @workerItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get workerItem;

  /// No description provided for @workerBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get workerBarcode;

  /// No description provided for @workerNoBarcodeAvailable.
  ///
  /// In en, this message translates to:
  /// **'No barcode available'**
  String get workerNoBarcodeAvailable;

  /// No description provided for @workerScanOrEnterProductBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan/Enter product barcode'**
  String get workerScanOrEnterProductBarcode;

  /// No description provided for @workerValidateProduct.
  ///
  /// In en, this message translates to:
  /// **'Validate Product'**
  String get workerValidateProduct;

  /// No description provided for @workerProductValidated.
  ///
  /// In en, this message translates to:
  /// **'Product validated'**
  String get workerProductValidated;

  /// No description provided for @workerProductMismatch.
  ///
  /// In en, this message translates to:
  /// **'Product mismatch'**
  String get workerProductMismatch;

  /// No description provided for @workerMovement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get workerMovement;

  /// No description provided for @workerFromWithType.
  ///
  /// In en, this message translates to:
  /// **'From ({type})'**
  String workerFromWithType(Object type);

  /// No description provided for @workerToWithType.
  ///
  /// In en, this message translates to:
  /// **'To ({type})'**
  String workerToWithType(Object type);

  /// No description provided for @workerScanOrEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Scan/Enter location'**
  String get workerScanOrEnterLocation;

  /// No description provided for @workerValidateLocation.
  ///
  /// In en, this message translates to:
  /// **'Validate Location'**
  String get workerValidateLocation;

  /// No description provided for @workerLocationValidated.
  ///
  /// In en, this message translates to:
  /// **'Location validated'**
  String get workerLocationValidated;

  /// No description provided for @workerLocationMismatch.
  ///
  /// In en, this message translates to:
  /// **'Location mismatch'**
  String get workerLocationMismatch;

  /// No description provided for @workerTaskInfo.
  ///
  /// In en, this message translates to:
  /// **'Task Info'**
  String get workerTaskInfo;

  /// No description provided for @workerTaskType.
  ///
  /// In en, this message translates to:
  /// **'Task type'**
  String get workerTaskType;

  /// No description provided for @workerQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get workerQuantity;

  /// No description provided for @workerStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get workerStatus;

  /// No description provided for @supervisorTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get supervisorTitle;

  /// No description provided for @supervisorRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get supervisorRefresh;

  /// No description provided for @supervisorNoTasksForZone.
  ///
  /// In en, this message translates to:
  /// **'No tasks for {zone}'**
  String supervisorNoTasksForZone(Object zone);

  /// No description provided for @supervisorCreateTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get supervisorCreateTask;

  /// No description provided for @supervisorTaskType.
  ///
  /// In en, this message translates to:
  /// **'Task Type'**
  String get supervisorTaskType;

  /// No description provided for @supervisorItemBarcode.
  ///
  /// In en, this message translates to:
  /// **'Item barcode'**
  String get supervisorItemBarcode;

  /// No description provided for @supervisorEnterBarcode.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode'**
  String get supervisorEnterBarcode;

  /// No description provided for @supervisorQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get supervisorQuantity;

  /// No description provided for @supervisorEnterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter valid quantity'**
  String get supervisorEnterValidQuantity;

  /// No description provided for @supervisorFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get supervisorFrom;

  /// No description provided for @supervisorTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get supervisorTo;

  /// No description provided for @supervisorZone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get supervisorZone;

  /// No description provided for @supervisorOperationsOverview.
  ///
  /// In en, this message translates to:
  /// **'Operations Overview'**
  String get supervisorOperationsOverview;

  /// No description provided for @supervisorPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get supervisorPending;

  /// No description provided for @supervisorUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get supervisorUnassigned;

  /// No description provided for @supervisorWorkerNumber.
  ///
  /// In en, this message translates to:
  /// **'Worker #{id}'**
  String supervisorWorkerNumber(Object id);

  /// No description provided for @inboundTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbound Management'**
  String get inboundTitle;

  /// No description provided for @inboundRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get inboundRefresh;

  /// No description provided for @inboundPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Inbounds'**
  String get inboundPending;

  /// No description provided for @inboundInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inboundInProgress;

  /// No description provided for @inboundCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed Inbounds'**
  String get inboundCompleted;

  /// No description provided for @inboundNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'No inbound documents'**
  String get inboundNoDocuments;

  /// No description provided for @inboundUseCreatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Use Create Inbound to get started'**
  String get inboundUseCreatePrompt;

  /// No description provided for @inboundCreateDialogTodo.
  ///
  /// In en, this message translates to:
  /// **'Create Inbound dialog - TODO'**
  String get inboundCreateDialogTodo;

  /// No description provided for @inboundReceiveDialogTodo.
  ///
  /// In en, this message translates to:
  /// **'Receive Items dialog - TODO'**
  String get inboundReceiveDialogTodo;

  /// No description provided for @inboundViewTodo.
  ///
  /// In en, this message translates to:
  /// **'View {documentNumber} - TODO'**
  String inboundViewTodo(Object documentNumber);

  /// No description provided for @inboundItemsProgress.
  ///
  /// In en, this message translates to:
  /// **'{received}/{total} items'**
  String inboundItemsProgress(Object received, Object total);

  /// No description provided for @inboundStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get inboundStart;

  /// No description provided for @inboundReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get inboundReceive;

  /// No description provided for @inboundComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get inboundComplete;

  /// No description provided for @inboundView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get inboundView;

  /// No description provided for @inboundOverview.
  ///
  /// In en, this message translates to:
  /// **'Inbound Overview'**
  String get inboundOverview;

  /// No description provided for @inboundTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get inboundTotal;

  /// No description provided for @inboundInProgressMetric.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inboundInProgressMetric;

  /// No description provided for @inboundCreateInbound.
  ///
  /// In en, this message translates to:
  /// **'Create Inbound'**
  String get inboundCreateInbound;

  /// No description provided for @inboundDocumentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} documents'**
  String inboundDocumentsCount(Object count);

  /// No description provided for @inboundDocumentSingular.
  ///
  /// In en, this message translates to:
  /// **'{count} document'**
  String inboundDocumentSingular(Object count);
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
