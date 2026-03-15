import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.localeName);

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'appTitle': 'Warehouse Inventory',
      'tabHome': 'Home',
      'tabAccount': 'Account',
      'homeWorkerTitle': 'Putaway Worker',
      'moreTitle': 'More',
      'moreHome': 'Home',
      'moreItemLookup': 'Item Lookup',
      'moreStockAdjustment': 'Stock Adjustment',
      'moreExceptions': 'Exceptions',
      'accountMyAccount': 'My Account',
      'accountDetails': 'Account Details',
      'accountPhone': 'Phone',
      'accountRole': 'Role',
      'accountZone': 'Zone',
      'accountLanguage': 'Language',
      'accountArabic': 'Arabic',
      'accountEnglish': 'English',
      'accountActions': 'Actions',
      'accountChangePassword': 'Change Password',
      'accountSignOut': 'Sign Out',
      'accountComingSoon': 'Coming soon',
      'roleSupervisor': 'SUPERVISOR',
      'roleInbound': 'INBOUND',
      'roleWorker': 'WORKER',
      'zoneWithCode': 'Zone {zone}',
      'receiveTitle': 'Receive Items',
      'receiveScanItemBarcode': 'Scan Item Barcode',
      'receiveScanDestinationLocation': 'Scan Destination Location',
      'receiveUsePhysicalScanner': 'Use physical scanner trigger',
      'receiveConfirmDestinationThenQuantity':
          'Confirm destination then quantity',
      'receiveConfirmReceive': 'Confirm Receive',
      'receiveReceiving': 'Receiving...',
      'receiveAwaitingScan': 'Awaiting scan...',
      'receiveSkuLabel': 'SKU: {barcode}',
      'receiveTotalLabel': 'Total: {quantity}',
      'receiveShelf': 'Shelf',
      'receiveBulk': 'Bulk',
      'receiveDestinationLocationScan': 'Destination Location (scan)',
      'receiveQuantityToReceive': 'Quantity to receive',
      'receiveFullQty': 'Full Qty',
      'moveTitle': 'Move Item',
      'moveScanItemBarcode': 'Scan Item Barcode',
      'moveScanDestinationLocation': 'Scan Destination Location',
      'moveTriggerScannerToCaptureItem': 'Trigger scanner to capture item',
      'moveScanTargetLocationThenConfirm': 'Scan target location then confirm',
      'moveFromLocation': 'FROM LOCATION',
      'moveItemSection': 'ITEM',
      'moveToLocation': 'TO LOCATION',
      'moveQuantitySection': 'QUANTITY',
      'moveDestinationLocationBarcode': 'Destination Location Barcode',
      'moveQtyToMove': 'Qty to move',
      'moveAwaitingScan': 'Awaiting scan...',
      'moveConfirmMove': 'Confirm Move',
      'moveMoving': 'Moving...',
      'moveNoSourceLocations': 'No source locations',
      'moveSkuLabel': 'SKU: {barcode}',
      'moveTotalLabel': 'Total: {quantity}',
      'stockAdjustmentTitle': 'Stock Adjustment',
      'stockScanItemBarcode': 'Scan Item Barcode',
      'stockScanLocationBarcode': 'Scan Location Barcode',
      'stockReadyToSubmit': 'Ready to submit',
      'stockLocationBarcode': 'Location Barcode',
      'stockNewQuantity': 'New Quantity',
      'stockReason': 'Reason',
      'stockSubmitting': 'Submitting...',
      'stockSubmitAdjustment': 'Submit Adjustment',
      'exceptionsTitle': 'Picking Exceptions',
      'exceptionsExpected': 'Expected: {location}',
      'workerRefreshTasks': 'Refresh tasks',
      'workerLookup': 'Lookup',
      'workerAdjust': 'Adjust',
      'workerAvailableTasks': 'Available Tasks',
      'workerMyActiveTasks': 'My Active Tasks',
      'workerNoAvailableTasks': 'No available tasks right now',
      'workerNoActiveTasks': 'No active tasks - claim one above',
      'workerStart': 'Start',
      'workerComplete': 'Complete',
      'workerWelcomeBack': 'Welcome back, {name}',
      'workerTrackQueue': 'Track your queue and close tasks quickly',
      'metricAvailable': 'Available',
      'metricActive': 'Active',
      'metricDone': 'Done',
      'workerDone': 'Done',
      'workerQty': 'Qty {quantity}',
      'workerTaskDetailsTitle': 'Task Details',
      'workerStartTask': 'Start Task',
      'workerItem': 'Item',
      'workerBarcode': 'Barcode',
      'workerNoBarcodeAvailable': 'No barcode available',
      'workerScanOrEnterProductBarcode': 'Scan/Enter product barcode',
      'workerValidateProduct': 'Validate Product',
      'workerProductValidated': 'Product validated',
      'workerProductMismatch': 'Product mismatch',
      'workerMovement': 'Movement',
      'workerFromWithType': 'From ({type})',
      'workerToWithType': 'To ({type})',
      'workerScanOrEnterLocation': 'Scan/Enter location',
      'workerValidateLocation': 'Validate Location',
      'workerLocationValidated': 'Location validated',
      'workerLocationMismatch': 'Location mismatch',
      'workerTaskInfo': 'Task Info',
      'workerTaskType': 'Task type',
      'workerQuantity': 'Quantity',
      'workerStatus': 'Status',
      'supervisorTitle': 'Supervisor',
      'supervisorRefresh': 'Refresh',
      'supervisorCreateTask': 'Create Task',
      'supervisorTaskType': 'Task Type',
      'supervisorItemBarcode': 'Item barcode',
      'supervisorEnterBarcode': 'Enter barcode',
      'supervisorQuantity': 'Quantity',
      'supervisorEnterValidQuantity': 'Enter valid quantity',
      'supervisorFrom': 'From',
      'supervisorTo': 'To',
      'supervisorZone': 'Zone',
      'supervisorOperationsOverview': 'Operations Overview',
      'supervisorPending': 'Pending',
      'supervisorUnassigned': 'Unassigned',
      'supervisorNoTasksForZone': 'No tasks for {zone}',
      'supervisorWorkerNumber': 'Worker #{id}',
      'inboundTitle': 'Inbound Management',
      'inboundRefresh': 'Refresh',
      'inboundPending': 'Pending Inbounds',
      'inboundInProgress': 'In Progress',
      'inboundCompleted': 'Completed Inbounds',
      'inboundNoDocuments': 'No inbound documents',
      'inboundUseCreatePrompt': 'Use Create Inbound to get started',
      'inboundCreateDialogTodo': 'Create Inbound dialog - TODO',
      'inboundReceiveDialogTodo': 'Receive Items dialog - TODO',
      'inboundViewTodo': 'View {documentNumber} - TODO',
      'inboundItemsProgress': '{received}/{total} items',
      'inboundStart': 'Start',
      'inboundReceive': 'Receive',
      'inboundComplete': 'Complete',
      'inboundView': 'View',
      'inboundOverview': 'Inbound Overview',
      'inboundTotal': 'Total',
      'inboundInProgressMetric': 'In Progress',
      'inboundCreateInbound': 'Create Inbound'
      ,
      'inboundDocumentsCount': '{count} documents',
      'inboundDocumentSingular': '{count} document'
    },
    'ar': {
      'appTitle': 'إدارة المخزون',
      'tabHome': 'الرئيسية',
      'tabAccount': 'الحساب',
      'homeWorkerTitle': 'عامل الترصيص',
      'moreTitle': 'المزيد',
      'moreHome': 'الرئيسية',
      'moreItemLookup': 'البحث عن صنف',
      'moreStockAdjustment': 'تعديل المخزون',
      'moreExceptions': 'الاستثناءات',
      'accountMyAccount': 'حسابي',
      'accountDetails': 'تفاصيل الحساب',
      'accountPhone': 'الهاتف',
      'accountRole': 'الدور',
      'accountZone': 'المنطقة',
      'accountLanguage': 'اللغة',
      'accountArabic': 'العربية',
      'accountEnglish': 'الإنجليزية',
      'accountActions': 'الإجراءات',
      'accountChangePassword': 'تغيير كلمة المرور',
      'accountSignOut': 'تسجيل الخروج',
      'accountComingSoon': 'قريبًا',
      'roleSupervisor': 'مشرف',
      'roleInbound': 'استلام',
      'roleWorker': 'عامل',
      'zoneWithCode': 'المنطقة {zone}',
      'receiveTitle': 'استلام الأصناف',
      'receiveScanItemBarcode': 'امسح باركود الصنف',
      'receiveScanDestinationLocation': 'امسح موقع الوجهة',
      'receiveUsePhysicalScanner': 'استخدم زر جهاز المسح',
      'receiveConfirmDestinationThenQuantity': 'أكد الوجهة ثم الكمية',
      'receiveConfirmReceive': 'تأكيد الاستلام',
      'receiveReceiving': 'جارٍ الاستلام...',
      'receiveAwaitingScan': 'بانتظار المسح...',
      'receiveSkuLabel': 'SKU: {barcode}',
      'receiveTotalLabel': 'الإجمالي: {quantity}',
      'receiveShelf': 'رف',
      'receiveBulk': 'تخزين',
      'receiveDestinationLocationScan': 'موقع الوجهة (مسح)',
      'receiveQuantityToReceive': 'الكمية المطلوب استلامها',
      'receiveFullQty': 'الكمية كاملة',
      'moveTitle': 'نقل صنف',
      'moveScanItemBarcode': 'امسح باركود الصنف',
      'moveScanDestinationLocation': 'امسح موقع الوجهة',
      'moveTriggerScannerToCaptureItem': 'استخدم جهاز المسح لالتقاط الصنف',
      'moveScanTargetLocationThenConfirm': 'امسح الموقع الهدف ثم أكد',
      'moveFromLocation': 'من الموقع',
      'moveItemSection': 'الصنف',
      'moveToLocation': 'إلى الموقع',
      'moveQuantitySection': 'الكمية',
      'moveDestinationLocationBarcode': 'باركود موقع الوجهة',
      'moveQtyToMove': 'الكمية للنقل',
      'moveAwaitingScan': 'بانتظار المسح...',
      'moveConfirmMove': 'تأكيد النقل',
      'moveMoving': 'جارٍ النقل...',
      'moveNoSourceLocations': 'لا توجد مواقع مصدر',
      'moveSkuLabel': 'SKU: {barcode}',
      'moveTotalLabel': 'الإجمالي: {quantity}',
      'stockAdjustmentTitle': 'تعديل المخزون',
      'stockScanItemBarcode': 'امسح باركود الصنف',
      'stockScanLocationBarcode': 'امسح باركود الموقع',
      'stockReadyToSubmit': 'جاهز للإرسال',
      'stockLocationBarcode': 'باركود الموقع',
      'stockNewQuantity': 'الكمية الجديدة',
      'stockReason': 'السبب',
      'stockSubmitting': 'جارٍ الإرسال...',
      'stockSubmitAdjustment': 'إرسال التعديل',
      'exceptionsTitle': 'استثناءات الالتقاط',
      'exceptionsExpected': 'المتوقع: {location}',
      'workerRefreshTasks': 'تحديث المهام',
      'workerLookup': 'بحث',
      'workerAdjust': 'تعديل',
      'workerAvailableTasks': 'المهام المتاحة',
      'workerMyActiveTasks': 'مهامي النشطة',
      'workerNoAvailableTasks': 'لا توجد مهام متاحة الآن',
      'workerNoActiveTasks': 'لا توجد مهام نشطة - اختر مهمة أعلاه',
      'workerStart': 'بدء',
      'workerComplete': 'إكمال',
      'workerWelcomeBack': 'مرحبًا بعودتك، {name}',
      'workerTrackQueue': 'تابع قائمة المهام وأنهِها بسرعة',
      'metricAvailable': 'متاح',
      'metricActive': 'نشط',
      'metricDone': 'منجز',
      'workerDone': 'منجز',
      'workerQty': 'الكمية {quantity}',
      'workerTaskDetailsTitle': 'تفاصيل المهمة',
      'workerStartTask': 'بدء المهمة',
      'workerItem': 'الصنف',
      'workerBarcode': 'الباركود',
      'workerNoBarcodeAvailable': 'لا يوجد باركود',
      'workerScanOrEnterProductBarcode': 'امسح/أدخل باركود الصنف',
      'workerValidateProduct': 'التحقق من الصنف',
      'workerProductValidated': 'تم التحقق من الصنف',
      'workerProductMismatch': 'الصنف غير مطابق',
      'workerMovement': 'الحركة',
      'workerFromWithType': 'من ({type})',
      'workerToWithType': 'إلى ({type})',
      'workerScanOrEnterLocation': 'امسح/أدخل الموقع',
      'workerValidateLocation': 'التحقق من الموقع',
      'workerLocationValidated': 'تم التحقق من الموقع',
      'workerLocationMismatch': 'الموقع غير مطابق',
      'workerTaskInfo': 'معلومات المهمة',
      'workerTaskType': 'نوع المهمة',
      'workerQuantity': 'الكمية',
      'workerStatus': 'الحالة',
      'supervisorTitle': 'المشرف',
      'supervisorRefresh': 'تحديث',
      'supervisorCreateTask': 'إنشاء مهمة',
      'supervisorTaskType': 'نوع المهمة',
      'supervisorItemBarcode': 'باركود الصنف',
      'supervisorEnterBarcode': 'أدخل الباركود',
      'supervisorQuantity': 'الكمية',
      'supervisorEnterValidQuantity': 'أدخل كمية صحيحة',
      'supervisorFrom': 'من',
      'supervisorTo': 'إلى',
      'supervisorZone': 'المنطقة',
      'supervisorOperationsOverview': 'نظرة عامة على العمليات',
      'supervisorPending': 'قيد الانتظار',
      'supervisorUnassigned': 'غير مسندة',
      'supervisorNoTasksForZone': 'لا توجد مهام للمنطقة {zone}',
      'supervisorWorkerNumber': 'عامل #{id}',
      'inboundTitle': 'إدارة الوارد',
      'inboundRefresh': 'تحديث',
      'inboundPending': 'وارد قيد الانتظار',
      'inboundInProgress': 'قيد التنفيذ',
      'inboundCompleted': 'مكتمل',
      'inboundNoDocuments': 'لا توجد مستندات وارد',
      'inboundUseCreatePrompt': 'استخدم إنشاء وارد للبدء',
      'inboundCreateDialogTodo': 'نافذة إنشاء وارد - قريبًا',
      'inboundReceiveDialogTodo': 'نافذة استلام الأصناف - قريبًا',
      'inboundViewTodo': 'عرض {documentNumber} - قريبًا',
      'inboundItemsProgress': '{received}/{total} صنف',
      'inboundStart': 'بدء',
      'inboundReceive': 'استلام',
      'inboundComplete': 'إكمال',
      'inboundView': 'عرض',
      'inboundOverview': 'نظرة عامة على الوارد',
      'inboundTotal': 'الإجمالي',
      'inboundInProgressMetric': 'قيد التنفيذ',
      'inboundCreateInbound': 'إنشاء وارد'
      ,
      'inboundDocumentsCount': '{count} مستندات',
      'inboundDocumentSingular': '{count} مستند'
    }
  };

  String _v(String key) {
    return _values[localeName]?[key] ?? _values['en']![key] ?? key;
  }

  String _f(String key, Map<String, String> args) {
    var value = _v(key);
    args.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
  }

  String get appTitle => _v('appTitle');
  String get tabHome => _v('tabHome');
  String get tabAccount => _v('tabAccount');
  String get homeWorkerTitle => _v('homeWorkerTitle');
  String get moreTitle => _v('moreTitle');
  String get moreHome => _v('moreHome');
  String get moreItemLookup => _v('moreItemLookup');
  String get moreStockAdjustment => _v('moreStockAdjustment');
  String get moreExceptions => _v('moreExceptions');
  String get accountMyAccount => _v('accountMyAccount');
  String get accountDetails => _v('accountDetails');
  String get accountPhone => _v('accountPhone');
  String get accountRole => _v('accountRole');
  String get accountZone => _v('accountZone');
  String get accountLanguage => _v('accountLanguage');
  String get accountArabic => _v('accountArabic');
  String get accountEnglish => _v('accountEnglish');
  String get accountActions => _v('accountActions');
  String get accountChangePassword => _v('accountChangePassword');
  String get accountSignOut => _v('accountSignOut');
  String get accountComingSoon => _v('accountComingSoon');
  String get roleSupervisor => _v('roleSupervisor');
  String get roleInbound => _v('roleInbound');
  String get roleWorker => _v('roleWorker');
  String zoneWithCode(String zone) => _f('zoneWithCode', {'zone': zone});
  String get receiveTitle => _v('receiveTitle');
  String get receiveScanItemBarcode => _v('receiveScanItemBarcode');
  String get receiveScanDestinationLocation =>
      _v('receiveScanDestinationLocation');
  String get receiveUsePhysicalScanner => _v('receiveUsePhysicalScanner');
  String get receiveConfirmDestinationThenQuantity =>
      _v('receiveConfirmDestinationThenQuantity');
  String get receiveConfirmReceive => _v('receiveConfirmReceive');
  String get receiveReceiving => _v('receiveReceiving');
  String get receiveAwaitingScan => _v('receiveAwaitingScan');
  String receiveSkuLabel(String barcode) =>
      _f('receiveSkuLabel', {'barcode': barcode});
  String receiveTotalLabel(String quantity) =>
      _f('receiveTotalLabel', {'quantity': quantity});
  String get receiveShelf => _v('receiveShelf');
  String get receiveBulk => _v('receiveBulk');
  String get receiveDestinationLocationScan => _v('receiveDestinationLocationScan');
  String get receiveQuantityToReceive => _v('receiveQuantityToReceive');
  String get receiveFullQty => _v('receiveFullQty');
  String get moveTitle => _v('moveTitle');
  String get moveScanItemBarcode => _v('moveScanItemBarcode');
  String get moveScanDestinationLocation => _v('moveScanDestinationLocation');
  String get moveTriggerScannerToCaptureItem =>
      _v('moveTriggerScannerToCaptureItem');
  String get moveScanTargetLocationThenConfirm =>
      _v('moveScanTargetLocationThenConfirm');
  String get moveFromLocation => _v('moveFromLocation');
  String get moveItemSection => _v('moveItemSection');
  String get moveToLocation => _v('moveToLocation');
  String get moveQuantitySection => _v('moveQuantitySection');
  String get moveDestinationLocationBarcode => _v('moveDestinationLocationBarcode');
  String get moveQtyToMove => _v('moveQtyToMove');
  String get moveAwaitingScan => _v('moveAwaitingScan');
  String get moveConfirmMove => _v('moveConfirmMove');
  String get moveMoving => _v('moveMoving');
  String get moveNoSourceLocations => _v('moveNoSourceLocations');
  String moveSkuLabel(String barcode) => _f('moveSkuLabel', {'barcode': barcode});
  String moveTotalLabel(String quantity) =>
      _f('moveTotalLabel', {'quantity': quantity});
  String get stockAdjustmentTitle => _v('stockAdjustmentTitle');
  String get stockScanItemBarcode => _v('stockScanItemBarcode');
  String get stockScanLocationBarcode => _v('stockScanLocationBarcode');
  String get stockReadyToSubmit => _v('stockReadyToSubmit');
  String get stockLocationBarcode => _v('stockLocationBarcode');
  String get stockNewQuantity => _v('stockNewQuantity');
  String get stockReason => _v('stockReason');
  String get stockSubmitting => _v('stockSubmitting');
  String get stockSubmitAdjustment => _v('stockSubmitAdjustment');
  String get exceptionsTitle => _v('exceptionsTitle');
  String exceptionsExpected(String location) =>
      _f('exceptionsExpected', {'location': location});
  String get workerRefreshTasks => _v('workerRefreshTasks');
  String get workerLookup => _v('workerLookup');
  String get workerAdjust => _v('workerAdjust');
  String get workerAvailableTasks => _v('workerAvailableTasks');
  String get workerMyActiveTasks => _v('workerMyActiveTasks');
  String get workerNoAvailableTasks => _v('workerNoAvailableTasks');
  String get workerNoActiveTasks => _v('workerNoActiveTasks');
  String get workerStart => _v('workerStart');
  String get workerComplete => _v('workerComplete');
  String workerWelcomeBack(String name) => _f('workerWelcomeBack', {'name': name});
  String get workerTrackQueue => _v('workerTrackQueue');
  String get metricAvailable => _v('metricAvailable');
  String get metricActive => _v('metricActive');
  String get metricDone => _v('metricDone');
  String get workerDone => _v('workerDone');
  String workerQty(String quantity) => _f('workerQty', {'quantity': quantity});
  String get workerTaskDetailsTitle => _v('workerTaskDetailsTitle');
  String get workerStartTask => _v('workerStartTask');
  String get workerItem => _v('workerItem');
  String get workerBarcode => _v('workerBarcode');
  String get workerNoBarcodeAvailable => _v('workerNoBarcodeAvailable');
  String get workerScanOrEnterProductBarcode =>
      _v('workerScanOrEnterProductBarcode');
  String get workerValidateProduct => _v('workerValidateProduct');
  String get workerProductValidated => _v('workerProductValidated');
  String get workerProductMismatch => _v('workerProductMismatch');
  String get workerMovement => _v('workerMovement');
  String workerFromWithType(String type) => _f('workerFromWithType', {'type': type});
  String workerToWithType(String type) => _f('workerToWithType', {'type': type});
  String get workerScanOrEnterLocation => _v('workerScanOrEnterLocation');
  String get workerValidateLocation => _v('workerValidateLocation');
  String get workerLocationValidated => _v('workerLocationValidated');
  String get workerLocationMismatch => _v('workerLocationMismatch');
  String get workerTaskInfo => _v('workerTaskInfo');
  String get workerTaskType => _v('workerTaskType');
  String get workerQuantity => _v('workerQuantity');
  String get workerStatus => _v('workerStatus');
  String get supervisorTitle => _v('supervisorTitle');
  String get supervisorRefresh => _v('supervisorRefresh');
  String supervisorNoTasksForZone(String zone) =>
      _f('supervisorNoTasksForZone', {'zone': zone});
  String get supervisorCreateTask => _v('supervisorCreateTask');
  String get supervisorTaskType => _v('supervisorTaskType');
  String get supervisorItemBarcode => _v('supervisorItemBarcode');
  String get supervisorEnterBarcode => _v('supervisorEnterBarcode');
  String get supervisorQuantity => _v('supervisorQuantity');
  String get supervisorEnterValidQuantity => _v('supervisorEnterValidQuantity');
  String get supervisorFrom => _v('supervisorFrom');
  String get supervisorTo => _v('supervisorTo');
  String get supervisorZone => _v('supervisorZone');
  String get supervisorOperationsOverview => _v('supervisorOperationsOverview');
  String get supervisorPending => _v('supervisorPending');
  String get supervisorUnassigned => _v('supervisorUnassigned');
  String supervisorWorkerNumber(String id) =>
      _f('supervisorWorkerNumber', {'id': id});
  String get inboundTitle => _v('inboundTitle');
  String get inboundRefresh => _v('inboundRefresh');
  String get inboundPending => _v('inboundPending');
  String get inboundInProgress => _v('inboundInProgress');
  String get inboundCompleted => _v('inboundCompleted');
  String get inboundNoDocuments => _v('inboundNoDocuments');
  String get inboundUseCreatePrompt => _v('inboundUseCreatePrompt');
  String get inboundCreateDialogTodo => _v('inboundCreateDialogTodo');
  String get inboundReceiveDialogTodo => _v('inboundReceiveDialogTodo');
  String inboundViewTodo(String documentNumber) =>
      _f('inboundViewTodo', {'documentNumber': documentNumber});
  String inboundItemsProgress(String received, String total) =>
      _f('inboundItemsProgress', {'received': received, 'total': total});
  String get inboundStart => _v('inboundStart');
  String get inboundReceive => _v('inboundReceive');
  String get inboundComplete => _v('inboundComplete');
  String get inboundView => _v('inboundView');
  String get inboundOverview => _v('inboundOverview');
  String get inboundTotal => _v('inboundTotal');
  String get inboundInProgressMetric => _v('inboundInProgressMetric');
  String get inboundCreateInbound => _v('inboundCreateInbound');
  String inboundDocumentsCount(String count) =>
      _f('inboundDocumentsCount', {'count': count});
  String inboundDocumentSingular(String count) =>
      _f('inboundDocumentSingular', {'count': count});
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations(locale.languageCode),
    );
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
