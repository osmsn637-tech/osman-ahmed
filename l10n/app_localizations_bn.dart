// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'গুদাম মজুদ';

  @override
  String get tabHome => 'হোম';

  @override
  String get tabAccount => 'অ্যাকাউন্ট';

  @override
  String get homeWorkerTitle => 'পুটঅ্যাওয়ে কর্মী';

  @override
  String get accountMyAccount => 'আমার অ্যাকাউন্ট';

  @override
  String get accountDetails => 'অ্যাকাউন্টের বিবরণ';

  @override
  String get accountPhone => 'ফোন';

  @override
  String get accountRole => 'ভূমিকা';

  @override
  String get accountZone => 'জোন';

  @override
  String get accountLanguage => 'ভাষা';

  @override
  String get accountArabic => 'العربية';

  @override
  String get accountEnglish => 'English';

  @override
  String get accountUrdu => 'বাংলা';

  @override
  String get accountActions => 'কার্যক্রম';

  @override
  String get accountChangePassword => 'পাসওয়ার্ড পরিবর্তন করুন';

  @override
  String get accountSignOut => 'সাইন আউট';

  @override
  String get accountComingSoon => 'শিগগিরই আসছে';

  @override
  String get roleSupervisor => 'সুপারভাইজার';

  @override
  String get roleInbound => 'ইনবাউন্ড';

  @override
  String get roleWorker => 'কর্মী';

  @override
  String zoneWithCode(Object zone) {
    return 'জোন $zone';
  }

  @override
  String get receiveTitle => 'আইটেম গ্রহণ';

  @override
  String get receiveScanItemBarcode => 'আইটেমের বারকোড স্ক্যান করুন';

  @override
  String get receiveScanDestinationLocation => 'গন্তব্য অবস্থান স্ক্যান করুন';

  @override
  String get receiveUsePhysicalScanner =>
      'ফিজিক্যাল স্ক্যানারের ট্রিগার ব্যবহার করুন';

  @override
  String get receiveConfirmDestinationThenQuantity =>
      'আগে গন্তব্য, তারপর পরিমাণ নিশ্চিত করুন';

  @override
  String get receiveConfirmReceive => 'গ্রহণ নিশ্চিত করুন';

  @override
  String get receiveReceiving => 'গ্রহণ করা হচ্ছে...';

  @override
  String get receiveAwaitingScan => 'স্ক্যানের অপেক্ষায়...';

  @override
  String receiveSkuLabel(Object barcode) {
    return 'SKU: $barcode';
  }

  @override
  String receiveTotalLabel(Object quantity) {
    return 'মোট: $quantity';
  }

  @override
  String get receiveShelf => 'শেলফ';

  @override
  String get receiveBulk => 'বাল্ক';

  @override
  String get receiveDestinationLocationScan => 'গন্তব্য অবস্থান (স্ক্যান)';

  @override
  String get receiveQuantityToReceive => 'গ্রহণের পরিমাণ';

  @override
  String get receiveFullQty => 'পূর্ণ পরিমাণ';

  @override
  String get moveTitle => 'আইটেম সরান';

  @override
  String get moveScanItemBarcode => 'আইটেমের বারকোড স্ক্যান করুন';

  @override
  String get moveScanDestinationLocation => 'গন্তব্য অবস্থান স্ক্যান করুন';

  @override
  String get moveTriggerScannerToCaptureItem =>
      'আইটেম ধরতে স্ক্যানার ট্রিগার করুন';

  @override
  String get moveScanTargetLocationThenConfirm =>
      'লক্ষ্য অবস্থান স্ক্যান করে নিশ্চিত করুন';

  @override
  String get moveFromLocation => 'উৎস অবস্থান';

  @override
  String get moveItemSection => 'আইটেম';

  @override
  String get moveToLocation => 'গন্তব্য অবস্থান';

  @override
  String get moveQuantitySection => 'পরিমাণ';

  @override
  String get moveDestinationLocationBarcode => 'গন্তব্য অবস্থানের বারকোড';

  @override
  String get moveQtyToMove => 'সরানোর পরিমাণ';

  @override
  String get moveAwaitingScan => 'স্ক্যানের অপেক্ষায়...';

  @override
  String get moveConfirmMove => 'সরানো নিশ্চিত করুন';

  @override
  String get moveMoving => 'সরানো হচ্ছে...';

  @override
  String get moveNoSourceLocations => 'কোনও উৎস অবস্থান নেই';

  @override
  String moveSkuLabel(Object barcode) {
    return 'SKU: $barcode';
  }

  @override
  String moveTotalLabel(Object quantity) {
    return 'মোট: $quantity';
  }

  @override
  String get stockAdjustmentTitle => 'স্টক সমন্বয়';

  @override
  String get stockScanItemBarcode => 'আইটেমের বারকোড স্ক্যান করুন';

  @override
  String get stockScanLocationBarcode => 'অবস্থানের বারকোড স্ক্যান করুন';

  @override
  String get stockReadyToSubmit => 'জমা দেওয়ার জন্য প্রস্তুত';

  @override
  String get stockLocationBarcode => 'অবস্থানের বারকোড';

  @override
  String get stockNewQuantity => 'নতুন পরিমাণ';

  @override
  String get stockReason => 'কারণ';

  @override
  String get stockSubmitting => 'জমা দেওয়া হচ্ছে...';

  @override
  String get stockSubmitAdjustment => 'সমন্বয় জমা দিন';

  @override
  String get workerRefreshTasks => 'টাস্ক রিফ্রেশ করুন';

  @override
  String get workerLookup => 'অনুসন্ধান';

  @override
  String get workerAdjust => 'সমন্বয়';

  @override
  String get workerAvailableTasks => 'উপলব্ধ টাস্ক';

  @override
  String get workerMyActiveTasks => 'আমার সক্রিয় টাস্ক';

  @override
  String get workerNoAvailableTasks => 'এই মুহূর্তে কোনও টাস্ক উপলব্ধ নেই';

  @override
  String get workerNoActiveTasks =>
      'কোনও সক্রিয় টাস্ক নেই - উপরে থেকে একটি নিন';

  @override
  String get workerStart => 'শুরু করুন';

  @override
  String get workerComplete => 'সম্পূর্ণ করুন';

  @override
  String workerWelcomeBack(Object name) {
    return 'আবার স্বাগতম, $name';
  }

  @override
  String get workerTrackQueue => 'আপনার সারি দেখুন এবং দ্রুত টাস্ক শেষ করুন';

  @override
  String get metricAvailable => 'উপলব্ধ';

  @override
  String get metricActive => 'সক্রিয়';

  @override
  String get metricDone => 'সম্পন্ন';

  @override
  String get workerDone => 'সম্পন্ন';

  @override
  String workerQty(Object quantity) {
    return 'পরিমাণ $quantity';
  }

  @override
  String get workerTaskDetailsTitle => 'টাস্কের বিবরণ';

  @override
  String get workerStartTask => 'টাস্ক শুরু করুন';

  @override
  String get workerItem => 'আইটেম';

  @override
  String get workerBarcode => 'বারকোড';

  @override
  String get workerNoBarcodeAvailable => 'কোনও বারকোড নেই';

  @override
  String get workerScanOrEnterProductBarcode => 'পণ্যের বারকোড স্ক্যান/লিখুন';

  @override
  String get workerValidateProduct => 'পণ্য যাচাই করুন';

  @override
  String get workerProductValidated => 'পণ্য যাচাই হয়েছে';

  @override
  String get workerProductMismatch => 'পণ্য মিলছে না';

  @override
  String get workerMovement => 'মুভমেন্ট';

  @override
  String workerFromWithType(Object type) {
    return 'থেকে ($type)';
  }

  @override
  String workerToWithType(Object type) {
    return 'এ ($type)';
  }

  @override
  String get workerScanOrEnterLocation => 'অবস্থান স্ক্যান/লিখুন';

  @override
  String get workerValidateLocation => 'অবস্থান যাচাই করুন';

  @override
  String get workerLocationValidated => 'অবস্থান যাচাই হয়েছে';

  @override
  String get workerLocationMismatch => 'অবস্থান মিলছে না';

  @override
  String get workerTaskInfo => 'টাস্ক তথ্য';

  @override
  String get workerTaskType => 'টাস্কের ধরন';

  @override
  String get workerQuantity => 'পরিমাণ';

  @override
  String get workerStatus => 'অবস্থা';

  @override
  String get supervisorTitle => 'সুপারভাইজার';

  @override
  String get supervisorRefresh => 'রিফ্রেশ';

  @override
  String supervisorNoTasksForZone(Object zone) {
    return 'জোন $zone-এর জন্য কোনও টাস্ক নেই';
  }

  @override
  String get supervisorCreateTask => 'টাস্ক তৈরি করুন';

  @override
  String get supervisorTaskType => 'টাস্কের ধরন';

  @override
  String get supervisorItemBarcode => 'আইটেমের বারকোড';

  @override
  String get supervisorEnterBarcode => 'বারকোড লিখুন';

  @override
  String get supervisorQuantity => 'পরিমাণ';

  @override
  String get supervisorEnterValidQuantity => 'সঠিক পরিমাণ লিখুন';

  @override
  String get supervisorFrom => 'থেকে';

  @override
  String get supervisorTo => 'এ';

  @override
  String get supervisorZone => 'জোন';

  @override
  String get supervisorOperationsOverview => 'অপারেশনসমূহের সারসংক্ষেপ';

  @override
  String get supervisorPending => 'অপেক্ষমাণ';

  @override
  String get supervisorUnassigned => 'অনির্ধারিত';

  @override
  String supervisorWorkerNumber(Object id) {
    return 'কর্মী #$id';
  }

  @override
  String get inboundTitle => 'ইনবাউন্ড ব্যবস্থাপনা';

  @override
  String get inboundRefresh => 'রিফ্রেশ';

  @override
  String get inboundPending => 'অপেক্ষমাণ ইনবাউন্ড';

  @override
  String get inboundInProgress => 'চলমান';

  @override
  String get inboundCompleted => 'সম্পন্ন ইনবাউন্ড';

  @override
  String get inboundNoDocuments => 'কোনও ইনবাউন্ড নথি নেই';

  @override
  String get inboundReceiveDialogTodo => 'আইটেম গ্রহণ ডায়ালগ - TODO';

  @override
  String inboundViewTodo(Object documentNumber) {
    return '$documentNumber দেখুন - TODO';
  }

  @override
  String inboundItemsProgress(Object received, Object total) {
    return '$received/$total আইটেম';
  }

  @override
  String get inboundStart => 'শুরু করুন';

  @override
  String get inboundReceive => 'গ্রহণ';

  @override
  String get inboundComplete => 'সম্পূর্ণ করুন';

  @override
  String get inboundView => 'দেখুন';

  @override
  String get inboundOverview => 'ইনবাউন্ড সারসংক্ষেপ';

  @override
  String get inboundTotal => 'মোট';

  @override
  String get inboundInProgressMetric => 'চলমান';

  @override
  String inboundDocumentsCount(Object count) {
    return '$countটি নথি';
  }

  @override
  String inboundDocumentSingular(Object count) {
    return '$countটি নথি';
  }
}
