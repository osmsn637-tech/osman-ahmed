// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Warehouse Inventory';

  @override
  String get tabHome => 'Home';

  @override
  String get tabAccount => 'Account';

  @override
  String get homeWorkerTitle => 'Putaway Worker';

  @override
  String get moreTitle => 'More';

  @override
  String get moreHome => 'Home';

  @override
  String get moreItemLookup => 'Item Lookup';

  @override
  String get moreStockAdjustment => 'Stock Adjustment';

  @override
  String get moreExceptions => 'Exceptions';

  @override
  String get accountMyAccount => 'My Account';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get accountPhone => 'Phone';

  @override
  String get accountRole => 'Role';

  @override
  String get accountZone => 'Zone';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountArabic => 'Arabic';

  @override
  String get accountEnglish => 'English';

  @override
  String get accountUrdu => 'اردو';

  @override
  String get accountActions => 'Actions';

  @override
  String get accountChangePassword => 'Change Password';

  @override
  String get accountSignOut => 'Sign Out';

  @override
  String get accountComingSoon => 'Coming soon';

  @override
  String get roleSupervisor => 'SUPERVISOR';

  @override
  String get roleInbound => 'INBOUND';

  @override
  String get roleWorker => 'WORKER';

  @override
  String zoneWithCode(Object zone) {
    return 'Zone $zone';
  }

  @override
  String get receiveTitle => 'Receive Items';

  @override
  String get receiveScanItemBarcode => 'Scan Item Barcode';

  @override
  String get receiveScanDestinationLocation => 'Scan Destination Location';

  @override
  String get receiveUsePhysicalScanner => 'Use physical scanner trigger';

  @override
  String get receiveConfirmDestinationThenQuantity =>
      'Confirm destination then quantity';

  @override
  String get receiveConfirmReceive => 'Confirm Receive';

  @override
  String get receiveReceiving => 'Receiving...';

  @override
  String get receiveAwaitingScan => 'Awaiting scan...';

  @override
  String receiveSkuLabel(Object barcode) {
    return 'SKU: $barcode';
  }

  @override
  String receiveTotalLabel(Object quantity) {
    return 'Total: $quantity';
  }

  @override
  String get receiveShelf => 'Shelf';

  @override
  String get receiveBulk => 'Bulk';

  @override
  String get receiveDestinationLocationScan => 'Destination Location (scan)';

  @override
  String get receiveQuantityToReceive => 'Quantity to receive';

  @override
  String get receiveFullQty => 'Full Qty';

  @override
  String get moveTitle => 'Move Item';

  @override
  String get moveScanItemBarcode => 'Scan Item Barcode';

  @override
  String get moveScanDestinationLocation => 'Scan Destination Location';

  @override
  String get moveTriggerScannerToCaptureItem =>
      'Trigger scanner to capture item';

  @override
  String get moveScanTargetLocationThenConfirm =>
      'Scan target location then confirm';

  @override
  String get moveFromLocation => 'FROM LOCATION';

  @override
  String get moveItemSection => 'ITEM';

  @override
  String get moveToLocation => 'TO LOCATION';

  @override
  String get moveQuantitySection => 'QUANTITY';

  @override
  String get moveDestinationLocationBarcode => 'Destination Location Barcode';

  @override
  String get moveQtyToMove => 'Qty to move';

  @override
  String get moveAwaitingScan => 'Awaiting scan...';

  @override
  String get moveConfirmMove => 'Confirm Move';

  @override
  String get moveMoving => 'Moving...';

  @override
  String get moveNoSourceLocations => 'No source locations';

  @override
  String moveSkuLabel(Object barcode) {
    return 'SKU: $barcode';
  }

  @override
  String moveTotalLabel(Object quantity) {
    return 'Total: $quantity';
  }

  @override
  String get stockAdjustmentTitle => 'Stock Adjustment';

  @override
  String get stockScanItemBarcode => 'Scan Item Barcode';

  @override
  String get stockScanLocationBarcode => 'Scan Location Barcode';

  @override
  String get stockReadyToSubmit => 'Ready to submit';

  @override
  String get stockLocationBarcode => 'Location Barcode';

  @override
  String get stockNewQuantity => 'New Quantity';

  @override
  String get stockReason => 'Reason';

  @override
  String get stockSubmitting => 'Submitting...';

  @override
  String get stockSubmitAdjustment => 'Submit Adjustment';

  @override
  String get exceptionsTitle => 'Picking Exceptions';

  @override
  String exceptionsExpected(Object location) {
    return 'Expected: $location';
  }

  @override
  String get workerRefreshTasks => 'Refresh tasks';

  @override
  String get workerLookup => 'Lookup';

  @override
  String get workerAdjust => 'Adjust';

  @override
  String get workerAvailableTasks => 'Available Tasks';

  @override
  String get workerMyActiveTasks => 'My Active Tasks';

  @override
  String get workerNoAvailableTasks => 'No available tasks right now';

  @override
  String get workerNoActiveTasks => 'No active tasks - claim one above';

  @override
  String get workerStart => 'Start';

  @override
  String get workerComplete => 'Complete';

  @override
  String workerWelcomeBack(Object name) {
    return 'Welcome back, $name';
  }

  @override
  String get workerTrackQueue => 'Track your queue and close tasks quickly';

  @override
  String get metricAvailable => 'Available';

  @override
  String get metricActive => 'Active';

  @override
  String get metricDone => 'Done';

  @override
  String get workerDone => 'Done';

  @override
  String workerQty(Object quantity) {
    return 'Qty $quantity';
  }

  @override
  String get workerTaskDetailsTitle => 'Task Details';

  @override
  String get workerStartTask => 'Start Task';

  @override
  String get workerItem => 'Item';

  @override
  String get workerBarcode => 'Barcode';

  @override
  String get workerNoBarcodeAvailable => 'No barcode available';

  @override
  String get workerScanOrEnterProductBarcode => 'Scan/Enter product barcode';

  @override
  String get workerValidateProduct => 'Validate Product';

  @override
  String get workerProductValidated => 'Product validated';

  @override
  String get workerProductMismatch => 'Product mismatch';

  @override
  String get workerMovement => 'Movement';

  @override
  String workerFromWithType(Object type) {
    return 'From ($type)';
  }

  @override
  String workerToWithType(Object type) {
    return 'To ($type)';
  }

  @override
  String get workerScanOrEnterLocation => 'Scan/Enter location';

  @override
  String get workerValidateLocation => 'Validate Location';

  @override
  String get workerLocationValidated => 'Location validated';

  @override
  String get workerLocationMismatch => 'Location mismatch';

  @override
  String get workerTaskInfo => 'Task Info';

  @override
  String get workerTaskType => 'Task type';

  @override
  String get workerQuantity => 'Quantity';

  @override
  String get workerStatus => 'Status';

  @override
  String get supervisorTitle => 'Supervisor';

  @override
  String get supervisorRefresh => 'Refresh';

  @override
  String supervisorNoTasksForZone(Object zone) {
    return 'No tasks for $zone';
  }

  @override
  String get supervisorCreateTask => 'Create Task';

  @override
  String get supervisorTaskType => 'Task Type';

  @override
  String get supervisorItemBarcode => 'Item barcode';

  @override
  String get supervisorEnterBarcode => 'Enter barcode';

  @override
  String get supervisorQuantity => 'Quantity';

  @override
  String get supervisorEnterValidQuantity => 'Enter valid quantity';

  @override
  String get supervisorFrom => 'From';

  @override
  String get supervisorTo => 'To';

  @override
  String get supervisorZone => 'Zone';

  @override
  String get supervisorOperationsOverview => 'Operations Overview';

  @override
  String get supervisorPending => 'Pending';

  @override
  String get supervisorUnassigned => 'Unassigned';

  @override
  String supervisorWorkerNumber(Object id) {
    return 'Worker #$id';
  }

  @override
  String get inboundTitle => 'Inbound Management';

  @override
  String get inboundRefresh => 'Refresh';

  @override
  String get inboundPending => 'Pending Inbounds';

  @override
  String get inboundInProgress => 'In Progress';

  @override
  String get inboundCompleted => 'Completed Inbounds';

  @override
  String get inboundNoDocuments => 'No inbound documents';

  @override
  String get inboundUseCreatePrompt => 'Use Create Inbound to get started';

  @override
  String get inboundCreateDialogTodo => 'Create Inbound dialog - TODO';

  @override
  String get inboundReceiveDialogTodo => 'Receive Items dialog - TODO';

  @override
  String inboundViewTodo(Object documentNumber) {
    return 'View $documentNumber - TODO';
  }

  @override
  String inboundItemsProgress(Object received, Object total) {
    return '$received/$total items';
  }

  @override
  String get inboundStart => 'Start';

  @override
  String get inboundReceive => 'Receive';

  @override
  String get inboundComplete => 'Complete';

  @override
  String get inboundView => 'View';

  @override
  String get inboundOverview => 'Inbound Overview';

  @override
  String get inboundTotal => 'Total';

  @override
  String get inboundInProgressMetric => 'In Progress';

  @override
  String get inboundCreateInbound => 'Create Inbound';

  @override
  String inboundDocumentsCount(Object count) {
    return '$count documents';
  }

  @override
  String inboundDocumentSingular(Object count) {
    return '$count document';
  }
}
