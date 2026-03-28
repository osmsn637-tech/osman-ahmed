// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'گودام انوینٹری';

  @override
  String get tabHome => 'ہوم';

  @override
  String get tabAccount => 'اکاؤنٹ';

  @override
  String get homeWorkerTitle => 'پٹ اوے کارکن';

  @override
  String get moreTitle => 'مزید';

  @override
  String get moreHome => 'ہوم';

  @override
  String get moreItemLookup => 'آئٹم تلاش';

  @override
  String get moreStockAdjustment => 'اسٹاک ایڈجسٹمنٹ';

  @override
  String get moreExceptions => 'استثنات';

  @override
  String get accountMyAccount => 'میرا اکاؤنٹ';

  @override
  String get accountDetails => 'اکاؤنٹ کی تفصیلات';

  @override
  String get accountPhone => 'فون';

  @override
  String get accountRole => 'رول';

  @override
  String get accountZone => 'زون';

  @override
  String get accountLanguage => 'زبان';

  @override
  String get accountArabic => 'العربية';

  @override
  String get accountEnglish => 'English';

  @override
  String get accountUrdu => 'اردو';

  @override
  String get accountActions => 'کارروائیاں';

  @override
  String get accountChangePassword => 'پاس ورڈ تبدیل کریں';

  @override
  String get accountSignOut => 'سائن آؤٹ';

  @override
  String get accountComingSoon => 'جلد آرہا ہے';

  @override
  String get roleSupervisor => 'سپروائزر';

  @override
  String get roleInbound => 'ان باؤنڈ';

  @override
  String get roleWorker => 'ورکر';

  @override
  String zoneWithCode(Object zone) {
    return 'زون $zone';
  }

  @override
  String get receiveTitle => 'آئٹمز وصول کریں';

  @override
  String get receiveScanItemBarcode => 'آئٹم بارکوڈ اسکین کریں';

  @override
  String get receiveScanDestinationLocation => 'منزل کا مقام اسکین کریں';

  @override
  String get receiveUsePhysicalScanner => 'فزیکل اسکینر ٹرگر استعمال کریں';

  @override
  String get receiveConfirmDestinationThenQuantity =>
      'پہلے منزل پھر مقدار کی تصدیق کریں';

  @override
  String get receiveConfirmReceive => 'وصولی کی تصدیق کریں';

  @override
  String get receiveReceiving => 'وصول کیا جا رہا ہے...';

  @override
  String get receiveAwaitingScan => 'اسکین کا انتظار ہے...';

  @override
  String receiveSkuLabel(Object barcode) {
    return 'SKU: $barcode';
  }

  @override
  String receiveTotalLabel(Object quantity) {
    return 'کل: $quantity';
  }

  @override
  String get receiveShelf => 'شیلف';

  @override
  String get receiveBulk => 'بلک';

  @override
  String get receiveDestinationLocationScan => 'منزل کا مقام (اسکین)';

  @override
  String get receiveQuantityToReceive => 'وصول کرنے کی مقدار';

  @override
  String get receiveFullQty => 'مکمل مقدار';

  @override
  String get moveTitle => 'آئٹم منتقل کریں';

  @override
  String get moveScanItemBarcode => 'آئٹم بارکوڈ اسکین کریں';

  @override
  String get moveScanDestinationLocation => 'منزل کا مقام اسکین کریں';

  @override
  String get moveTriggerScannerToCaptureItem =>
      'آئٹم پکڑنے کے لیے اسکینر ٹرگر کریں';

  @override
  String get moveScanTargetLocationThenConfirm =>
      'ہدف مقام اسکین کریں پھر تصدیق کریں';

  @override
  String get moveFromLocation => 'مقام سے';

  @override
  String get moveItemSection => 'آئٹم';

  @override
  String get moveToLocation => 'مقام تک';

  @override
  String get moveQuantitySection => 'مقدار';

  @override
  String get moveDestinationLocationBarcode => 'منزل مقام کا بارکوڈ';

  @override
  String get moveQtyToMove => 'منتقل کرنے کی مقدار';

  @override
  String get moveAwaitingScan => 'اسکین کا انتظار ہے...';

  @override
  String get moveConfirmMove => 'منتقلی کی تصدیق کریں';

  @override
  String get moveMoving => 'منتقل کیا جا رہا ہے...';

  @override
  String get moveNoSourceLocations => 'کوئی ماخذ مقام نہیں';

  @override
  String moveSkuLabel(Object barcode) {
    return 'SKU: $barcode';
  }

  @override
  String moveTotalLabel(Object quantity) {
    return 'کل: $quantity';
  }

  @override
  String get stockAdjustmentTitle => 'اسٹاک ایڈجسٹمنٹ';

  @override
  String get stockScanItemBarcode => 'آئٹم بارکوڈ اسکین کریں';

  @override
  String get stockScanLocationBarcode => 'مقام بارکوڈ اسکین کریں';

  @override
  String get stockReadyToSubmit => 'جمع کرانے کے لیے تیار';

  @override
  String get stockLocationBarcode => 'مقام بارکوڈ';

  @override
  String get stockNewQuantity => 'نئی مقدار';

  @override
  String get stockReason => 'وجہ';

  @override
  String get stockSubmitting => 'جمع کیا جا رہا ہے...';

  @override
  String get stockSubmitAdjustment => 'ایڈجسٹمنٹ جمع کریں';

  @override
  String get exceptionsTitle => 'پکنگ استثنات';

  @override
  String exceptionsExpected(Object location) {
    return 'متوقع: $location';
  }

  @override
  String get workerRefreshTasks => 'ٹاسک تازہ کریں';

  @override
  String get workerLookup => 'تلاش';

  @override
  String get workerAdjust => 'ایڈجسٹ';

  @override
  String get workerAvailableTasks => 'دستیاب ٹاسکس';

  @override
  String get workerMyActiveTasks => 'میرے فعال ٹاسکس';

  @override
  String get workerNoAvailableTasks => 'اس وقت کوئی دستیاب ٹاسک نہیں';

  @override
  String get workerNoActiveTasks =>
      'کوئی فعال ٹاسک نہیں - اوپر سے ایک منتخب کریں';

  @override
  String get workerStart => 'شروع کریں';

  @override
  String get workerComplete => 'مکمل کریں';

  @override
  String workerWelcomeBack(Object name) {
    return 'واپسی پر خوش آمدید، $name';
  }

  @override
  String get workerTrackQueue =>
      'اپنی قطار پر نظر رکھیں اور ٹاسکس جلد مکمل کریں';

  @override
  String get metricAvailable => 'دستیاب';

  @override
  String get metricActive => 'فعال';

  @override
  String get metricDone => 'مکمل';

  @override
  String get workerDone => 'مکمل';

  @override
  String workerQty(Object quantity) {
    return 'مقدار $quantity';
  }

  @override
  String get workerTaskDetailsTitle => 'ٹاسک کی تفصیلات';

  @override
  String get workerStartTask => 'ٹاسک شروع کریں';

  @override
  String get workerItem => 'آئٹم';

  @override
  String get workerBarcode => 'بارکوڈ';

  @override
  String get workerNoBarcodeAvailable => 'کوئی بارکوڈ دستیاب نہیں';

  @override
  String get workerScanOrEnterProductBarcode => 'پروڈکٹ بارکوڈ اسکین/درج کریں';

  @override
  String get workerValidateProduct => 'پروڈکٹ کی تصدیق کریں';

  @override
  String get workerProductValidated => 'پروڈکٹ کی تصدیق ہوگئی';

  @override
  String get workerProductMismatch => 'پروڈکٹ میل نہیں کھاتی';

  @override
  String get workerMovement => 'حرکت';

  @override
  String workerFromWithType(Object type) {
    return '$type سے';
  }

  @override
  String workerToWithType(Object type) {
    return '$type تک';
  }

  @override
  String get workerScanOrEnterLocation => 'مقام اسکین/درج کریں';

  @override
  String get workerValidateLocation => 'مقام کی تصدیق کریں';

  @override
  String get workerLocationValidated => 'مقام کی تصدیق ہوگئی';

  @override
  String get workerLocationMismatch => 'مقام میل نہیں کھاتا';

  @override
  String get workerTaskInfo => 'ٹاسک معلومات';

  @override
  String get workerTaskType => 'ٹاسک کی قسم';

  @override
  String get workerQuantity => 'مقدار';

  @override
  String get workerStatus => 'حالت';

  @override
  String get supervisorTitle => 'سپروائزر';

  @override
  String get supervisorRefresh => 'تازہ کریں';

  @override
  String supervisorNoTasksForZone(Object zone) {
    return 'زون $zone کے لیے کوئی ٹاسک نہیں';
  }

  @override
  String get supervisorCreateTask => 'ٹاسک بنائیں';

  @override
  String get supervisorTaskType => 'ٹاسک کی قسم';

  @override
  String get supervisorItemBarcode => 'آئٹم بارکوڈ';

  @override
  String get supervisorEnterBarcode => 'بارکوڈ درج کریں';

  @override
  String get supervisorQuantity => 'مقدار';

  @override
  String get supervisorEnterValidQuantity => 'درست مقدار درج کریں';

  @override
  String get supervisorFrom => 'سے';

  @override
  String get supervisorTo => 'تک';

  @override
  String get supervisorZone => 'زون';

  @override
  String get supervisorOperationsOverview => 'آپریشنز کا جائزہ';

  @override
  String get supervisorPending => 'زیر التوا';

  @override
  String get supervisorUnassigned => 'غیر تفویض شدہ';

  @override
  String supervisorWorkerNumber(Object id) {
    return 'ورکر #$id';
  }

  @override
  String get inboundTitle => 'ان باؤنڈ مینجمنٹ';

  @override
  String get inboundRefresh => 'تازہ کریں';

  @override
  String get inboundPending => 'زیر التوا ان باؤنڈز';

  @override
  String get inboundInProgress => 'جاری';

  @override
  String get inboundCompleted => 'مکمل ان باؤنڈز';

  @override
  String get inboundNoDocuments => 'کوئی ان باؤنڈ دستاویز نہیں';

  @override
  String get inboundUseCreatePrompt =>
      'شروع کرنے کے لیے Create Inbound استعمال کریں';

  @override
  String get inboundCreateDialogTodo => 'Create Inbound ڈائیلاگ - TODO';

  @override
  String get inboundReceiveDialogTodo => 'Receive Items ڈائیلاگ - TODO';

  @override
  String inboundViewTodo(Object documentNumber) {
    return '$documentNumber دیکھیں - TODO';
  }

  @override
  String inboundItemsProgress(Object received, Object total) {
    return '$received/$total آئٹمز';
  }

  @override
  String get inboundStart => 'شروع کریں';

  @override
  String get inboundReceive => 'وصول کریں';

  @override
  String get inboundComplete => 'مکمل کریں';

  @override
  String get inboundView => 'دیکھیں';

  @override
  String get inboundOverview => 'ان باؤنڈ جائزہ';

  @override
  String get inboundTotal => 'کل';

  @override
  String get inboundInProgressMetric => 'جاری';

  @override
  String get inboundCreateInbound => 'ان باؤنڈ بنائیں';

  @override
  String inboundDocumentsCount(Object count) {
    return '$count دستاویزات';
  }

  @override
  String inboundDocumentSingular(Object count) {
    return '$count دستاویز';
  }
}
