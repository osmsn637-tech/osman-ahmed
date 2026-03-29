// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'إدارة المخزون';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabAccount => 'الحساب';

  @override
  String get homeWorkerTitle => 'عامل الترصيص';

  @override
  String get accountMyAccount => 'حسابي';

  @override
  String get accountDetails => 'تفاصيل الحساب';

  @override
  String get accountPhone => 'الهاتف';

  @override
  String get accountRole => 'الدور';

  @override
  String get accountZone => 'المنطقة';

  @override
  String get accountLanguage => 'اللغة';

  @override
  String get accountArabic => 'العربية';

  @override
  String get accountEnglish => 'الإنجليزية';

  @override
  String get accountUrdu => 'الأردية';

  @override
  String get accountActions => 'الإجراءات';

  @override
  String get accountChangePassword => 'تغيير كلمة المرور';

  @override
  String get accountSignOut => 'تسجيل الخروج';

  @override
  String get accountComingSoon => 'قريبًا';

  @override
  String get roleSupervisor => 'مشرف';

  @override
  String get roleInbound => 'استلام';

  @override
  String get roleWorker => 'عامل';

  @override
  String zoneWithCode(Object zone) {
    return 'المنطقة $zone';
  }

  @override
  String get receiveTitle => 'استلام الأصناف';

  @override
  String get receiveScanItemBarcode => 'امسح باركود الصنف';

  @override
  String get receiveScanDestinationLocation => 'امسح موقع الوجهة';

  @override
  String get receiveUsePhysicalScanner => 'استخدم زر جهاز المسح';

  @override
  String get receiveConfirmDestinationThenQuantity => 'أكد الوجهة ثم الكمية';

  @override
  String get receiveConfirmReceive => 'تأكيد الاستلام';

  @override
  String get receiveReceiving => 'جارٍ الاستلام...';

  @override
  String get receiveAwaitingScan => 'بانتظار المسح...';

  @override
  String receiveSkuLabel(Object barcode) {
    return 'SKU: $barcode';
  }

  @override
  String receiveTotalLabel(Object quantity) {
    return 'الإجمالي: $quantity';
  }

  @override
  String get receiveShelf => 'رف';

  @override
  String get receiveBulk => 'تخزين';

  @override
  String get receiveDestinationLocationScan => 'موقع الوجهة (مسح)';

  @override
  String get receiveQuantityToReceive => 'الكمية المطلوب استلامها';

  @override
  String get receiveFullQty => 'الكمية كاملة';

  @override
  String get moveTitle => 'نقل صنف';

  @override
  String get moveScanItemBarcode => 'امسح باركود الصنف';

  @override
  String get moveScanDestinationLocation => 'امسح موقع الوجهة';

  @override
  String get moveTriggerScannerToCaptureItem =>
      'استخدم جهاز المسح لالتقاط الصنف';

  @override
  String get moveScanTargetLocationThenConfirm => 'امسح الموقع الهدف ثم أكد';

  @override
  String get moveFromLocation => 'من الموقع';

  @override
  String get moveItemSection => 'الصنف';

  @override
  String get moveToLocation => 'إلى الموقع';

  @override
  String get moveQuantitySection => 'الكمية';

  @override
  String get moveDestinationLocationBarcode => 'باركود موقع الوجهة';

  @override
  String get moveQtyToMove => 'الكمية للنقل';

  @override
  String get moveAwaitingScan => 'بانتظار المسح...';

  @override
  String get moveConfirmMove => 'تأكيد النقل';

  @override
  String get moveMoving => 'جارٍ النقل...';

  @override
  String get moveNoSourceLocations => 'لا توجد مواقع مصدر';

  @override
  String moveSkuLabel(Object barcode) {
    return 'SKU: $barcode';
  }

  @override
  String moveTotalLabel(Object quantity) {
    return 'الإجمالي: $quantity';
  }

  @override
  String get stockAdjustmentTitle => 'تعديل المخزون';

  @override
  String get stockScanItemBarcode => 'امسح باركود الصنف';

  @override
  String get stockScanLocationBarcode => 'امسح باركود الموقع';

  @override
  String get stockReadyToSubmit => 'جاهز للإرسال';

  @override
  String get stockLocationBarcode => 'باركود الموقع';

  @override
  String get stockNewQuantity => 'الكمية الجديدة';

  @override
  String get stockReason => 'السبب';

  @override
  String get stockSubmitting => 'جارٍ الإرسال...';

  @override
  String get stockSubmitAdjustment => 'إرسال التعديل';

  @override
  String get workerRefreshTasks => 'تحديث المهام';

  @override
  String get workerLookup => 'بحث';

  @override
  String get workerAdjust => 'تعديل';

  @override
  String get workerAvailableTasks => 'المهام المتاحة';

  @override
  String get workerMyActiveTasks => 'مهامي النشطة';

  @override
  String get workerNoAvailableTasks => 'لا توجد مهام متاحة الآن';

  @override
  String get workerNoActiveTasks => 'لا توجد مهام نشطة - اختر مهمة أعلاه';

  @override
  String get workerStart => 'بدء';

  @override
  String get workerComplete => 'إكمال';

  @override
  String workerWelcomeBack(Object name) {
    return 'مرحبًا بعودتك، $name';
  }

  @override
  String get workerTrackQueue => 'تابع قائمة المهام وأنهِها بسرعة';

  @override
  String get metricAvailable => 'متاح';

  @override
  String get metricActive => 'نشط';

  @override
  String get metricDone => 'منجز';

  @override
  String get workerDone => 'منجز';

  @override
  String workerQty(Object quantity) {
    return 'الكمية $quantity';
  }

  @override
  String get workerTaskDetailsTitle => 'تفاصيل المهمة';

  @override
  String get workerStartTask => 'بدء المهمة';

  @override
  String get workerItem => 'الصنف';

  @override
  String get workerBarcode => 'الباركود';

  @override
  String get workerNoBarcodeAvailable => 'لا يوجد باركود';

  @override
  String get workerScanOrEnterProductBarcode => 'امسح/أدخل باركود الصنف';

  @override
  String get workerValidateProduct => 'التحقق من الصنف';

  @override
  String get workerProductValidated => 'تم التحقق من الصنف';

  @override
  String get workerProductMismatch => 'الصنف غير مطابق';

  @override
  String get workerMovement => 'الحركة';

  @override
  String workerFromWithType(Object type) {
    return 'من ($type)';
  }

  @override
  String workerToWithType(Object type) {
    return 'إلى ($type)';
  }

  @override
  String get workerScanOrEnterLocation => 'امسح/أدخل الموقع';

  @override
  String get workerValidateLocation => 'التحقق من الموقع';

  @override
  String get workerLocationValidated => 'تم التحقق من الموقع';

  @override
  String get workerLocationMismatch => 'الموقع غير مطابق';

  @override
  String get workerTaskInfo => 'معلومات المهمة';

  @override
  String get workerTaskType => 'نوع المهمة';

  @override
  String get workerQuantity => 'الكمية';

  @override
  String get workerStatus => 'الحالة';

  @override
  String get supervisorTitle => 'المشرف';

  @override
  String get supervisorRefresh => 'تحديث';

  @override
  String supervisorNoTasksForZone(Object zone) {
    return 'لا توجد مهام للمنطقة $zone';
  }

  @override
  String get supervisorCreateTask => 'إنشاء مهمة';

  @override
  String get supervisorTaskType => 'نوع المهمة';

  @override
  String get supervisorItemBarcode => 'باركود الصنف';

  @override
  String get supervisorEnterBarcode => 'أدخل الباركود';

  @override
  String get supervisorQuantity => 'الكمية';

  @override
  String get supervisorEnterValidQuantity => 'أدخل كمية صحيحة';

  @override
  String get supervisorFrom => 'من';

  @override
  String get supervisorTo => 'إلى';

  @override
  String get supervisorZone => 'المنطقة';

  @override
  String get supervisorOperationsOverview => 'نظرة عامة على العمليات';

  @override
  String get supervisorPending => 'قيد الانتظار';

  @override
  String get supervisorUnassigned => 'غير مسندة';

  @override
  String supervisorWorkerNumber(Object id) {
    return 'عامل #$id';
  }

  @override
  String get inboundTitle => 'إدارة الوارد';

  @override
  String get inboundRefresh => 'تحديث';

  @override
  String get inboundPending => 'وارد قيد الانتظار';

  @override
  String get inboundInProgress => 'قيد التنفيذ';

  @override
  String get inboundCompleted => 'مكتمل';

  @override
  String get inboundNoDocuments => 'لا توجد مستندات وارد';

  @override
  String get inboundReceiveDialogTodo => 'نافذة استلام الأصناف - قريبًا';

  @override
  String inboundViewTodo(Object documentNumber) {
    return 'عرض $documentNumber - قريبًا';
  }

  @override
  String inboundItemsProgress(Object received, Object total) {
    return '$received/$total صنف';
  }

  @override
  String get inboundStart => 'بدء';

  @override
  String get inboundReceive => 'استلام';

  @override
  String get inboundComplete => 'إكمال';

  @override
  String get inboundView => 'عرض';

  @override
  String get inboundOverview => 'نظرة عامة على الوارد';

  @override
  String get inboundTotal => 'الإجمالي';

  @override
  String get inboundInProgressMetric => 'قيد التنفيذ';

  @override
  String inboundDocumentsCount(Object count) {
    return '$count مستندات';
  }

  @override
  String inboundDocumentSingular(Object count) {
    return '$count مستند';
  }
}
