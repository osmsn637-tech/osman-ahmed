import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:wherehouse/flutter_gen/gen_l10n/app_localizations.dart';

import '../core/utils/result.dart';
import '../features/auth/domain/entities/user.dart';
import '../features/auth/presentation/providers/session_provider.dart';
import '../features/move/domain/entities/item_detail.dart';
import '../features/move/domain/entities/item_location_entity.dart';
import '../features/move/domain/entities/item_location_summary_entity.dart';
import '../features/move/domain/entities/location_lookup_summary_entity.dart';
import '../features/move/domain/entities/stock_adjustment_params.dart';
import '../features/move/domain/repositories/item_repository.dart';
import '../features/move/domain/usecases/lookup_item_by_barcode_usecase.dart';
import '../features/move/presentation/controllers/item_adjustment_controller.dart';
import '../features/move/presentation/controllers/item_lookup_controller.dart';
import '../features/move/presentation/pages/item_lookup_result_page.dart';
import '../shared/theme/app_theme.dart';

const _trainingLocaleCode =
    String.fromEnvironment('TRAINING_LOCALE', defaultValue: 'en');

const List<Locale> trainingSupportedLocales = <Locale>[
  Locale('en'),
  Locale('ar'),
  Locale('ur'),
];

Locale resolveTrainingLocale(String code) {
  final normalized = code.trim().toLowerCase();
  if (normalized == 'ar') {
    return const Locale('ar');
  }
  if (normalized == 'ur') {
    return const Locale('ur');
  }
  return const Locale('en');
}

bool trainingIsRtl(Locale locale) {
  final normalized = locale.languageCode.toLowerCase();
  return normalized == 'ar' || normalized == 'ur';
}

String trainingText({
  required Locale locale,
  required String en,
  required String ar,
  String? ur,
}) {
  final normalized = locale.languageCode.toLowerCase();
  if (normalized == 'ar') {
    return ar;
  }
  if (normalized == 'ur') {
    return ur ?? en;
  }
  return en;
}

void main() {
  final session = SessionController()
    ..setUser(
      const User(
        id: 'worker-training',
        name: 'Training Worker',
        role: 'worker',
        phone: '0000000000',
        zone: 'A',
      ),
    );

  runApp(
    ChangeNotifierProvider<SessionController>.value(
      value: session,
      child: const _AdjustTrainingApp(),
    ),
  );
}

class _AdjustTrainingApp extends StatelessWidget {
  const _AdjustTrainingApp();

  @override
  Widget build(BuildContext context) {
    final locale = resolveTrainingLocale(_trainingLocaleCode);
    final repository =
        _TrainingItemRepository(summary: _TrainingScenario.summary);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ItemLookupController>(
          create: (_) => ItemLookupController(
            lookupItemByBarcode: LookupItemByBarcodeUseCase(repository),
          ),
        ),
        ChangeNotifierProvider<ItemAdjustmentController>(
          create: (_) => ItemAdjustmentController(
            adjustStock: repository.adjustStock,
            session: context.read<SessionController>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Adjust Item Training',
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: trainingSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _TrainingAdjustFlowPage(),
      ),
    );
  }
}

class _TrainingHomePage extends StatefulWidget {
  const _TrainingHomePage();

  @override
  State<_TrainingHomePage> createState() => _TrainingHomePageState();
}

class _TrainingHomePageState extends State<_TrainingHomePage> {
  String _bannerText = '';
  bool _started = false;

  Locale get _locale => Localizations.localeOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) {
        return;
      }
      _started = true;
      unawaited(_startTraining());
    });
  }

  Future<void> _startTraining() async {
    _setBanner(_text(
        ar: 'الخطوة 1: امسح باركود الصنف لفتح شاشة التعديل',
        en: 'Step 1: Scan the item barcode to open Adjust',
        ur: 'مرحلہ 1: ایڈجسٹ کھولنے کے لیے آئٹم بارکوڈ اسکین کریں'));
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) {
      return;
    }

    final repository =
        _TrainingItemRepository(summary: _TrainingScenario.summary);
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => MultiProvider(
          providers: [
            ChangeNotifierProvider<ItemLookupController>(
              create: (_) => ItemLookupController(
                lookupItemByBarcode: LookupItemByBarcodeUseCase(repository),
              ),
            ),
            ChangeNotifierProvider<ItemAdjustmentController>(
              create: (_) => ItemAdjustmentController(
                adjustStock: repository.adjustStock,
                session: context.read<SessionController>(),
              ),
            ),
          ],
          child: const _TrainingAdjustFlowPage(),
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _setBanner(String value) {
    if (!mounted) {
      return;
    }
    setState(() => _bannerText = value);
  }

  String _text({required String ar, required String en, String? ur}) {
    return trainingText(locale: _locale, en: en, ar: ar, ur: ur);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            ar: 'تدريب تعديل الصنف',
            en: 'Adjust Item Training',
            ur: 'آئٹم ایڈجسٹمنٹ ٹریننگ',
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6EEF8), AppTheme.surface],
            stops: [0, 0.42],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 38,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _text(
                            ar: 'شاهد خطوات تعديل الصنف باستخدام شاشة التطبيق الحقيقية.',
                            en: 'Watch the real app walkthrough for adjusting an item.',
                            ur: 'آئٹم ایڈجسٹ کرنے کے لیے اصل ایپ کی رہنمائی دیکھیں۔',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _text(
                            ar: 'سيتم فتح شاشة التعديل تلقائيًا خلال لحظات.',
                            en: 'The adjust screen will open automatically.',
                            ur: 'ایڈجسٹ اسکرین خودکار طور پر کھل جائے گی۔',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _TrainingBanner(text: _bannerText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingAdjustFlowPage extends StatefulWidget {
  const _TrainingAdjustFlowPage();

  @override
  State<_TrainingAdjustFlowPage> createState() =>
      _TrainingAdjustFlowPageState();
}

class _TrainingAdjustFlowPageState extends State<_TrainingAdjustFlowPage> {
  VoidCallback? _lookupListener;
  bool _sequenceStarted = false;
  String _bannerText = '';

  Locale get _locale => Localizations.localeOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _setBanner(_text(
          ar: 'الخطوة 1: راجع بيانات الصنف والمواقع',
          en: 'Step 1: Review the item details and locations',
          ur: 'مرحلہ 1: آئٹم کی تفصیلات اور مقامات کا جائزہ لیں'));
      final lookupController = context.read<ItemLookupController>();
      _lookupListener = () {
        final summary = lookupController.state.summary;
        if (summary == null || _sequenceStarted) {
          return;
        }
        _sequenceStarted = true;
        unawaited(_playSequence(summary));
      };
      lookupController.addListener(_lookupListener!);
      _lookupListener!.call();
    });
  }

  @override
  void dispose() {
    final listener = _lookupListener;
    if (listener != null) {
      context.read<ItemLookupController>().removeListener(listener);
    }
    super.dispose();
  }

  Future<void> _playSequence(ItemLocationSummaryEntity summary) async {
    final adjustmentController = context.read<ItemAdjustmentController>();
    final selectedLocation = summary.shelfLocations.first;

    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) {
      return;
    }

    _setBanner(_text(
        ar: 'الخطوة 2: اختر الموقع المراد تعديله',
        en: 'Step 2: Select the location to adjust',
        ur: 'مرحلہ 2: ایڈجسٹ کرنے کے لیے مقام منتخب کریں'));
    adjustmentController.selectLocation(selectedLocation);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) {
      return;
    }

    _setBanner(_text(
        ar: 'الخطوة 3: أدخل الكمية الجديدة',
        en: 'Step 3: Enter the new quantity',
        ur: 'مرحلہ 3: نئی مقدار درج کریں'));
    for (final value in _TrainingScenario.quantitySteps) {
      adjustmentController.setQuantityText(value);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) {
        return;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) {
      return;
    }

    _setBanner(_text(
        ar: 'الخطوة 4: اضغط تأكيد لإرسال التعديل',
        en: 'Step 4: Tap confirm to submit the adjustment',
        ur: 'مرحلہ 4: ایڈجسٹمنٹ جمع کرنے کے لیے تصدیق پر ٹیپ کریں'));
    unawaited(adjustmentController.submitForItem(summary));

    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) {
      return;
    }

    _setBanner(_text(
        ar: 'الخطوة 5: عند ظهور رسالة النجاح تكون العملية اكتملت',
        en: 'Step 5: When the success message appears, the adjustment is complete',
        ur: 'مرحلہ 5: کامیابی کا پیغام ظاہر ہوتے ہی ایڈجسٹمنٹ مکمل ہو جائے گی'));
  }

  void _setBanner(String value) {
    if (!mounted) {
      return;
    }
    setState(() => _bannerText = value);
  }

  String _text({required String ar, required String en, String? ur}) {
    return trainingText(locale: _locale, en: en, ar: ar, ur: ur);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ItemLookupResultPage(
          barcode: _TrainingScenario.barcode,
          mode: ItemLookupPageMode.adjust,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _TrainingBanner(text: _bannerText),
          ),
        ),
      ],
    );
  }
}

class _TrainingBanner extends StatelessWidget {
  const _TrainingBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220F172A),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _TrainingItemRepository implements ItemRepository {
  _TrainingItemRepository({required this.summary});

  final ItemLocationSummaryEntity summary;

  @override
  Future<Result<void>> adjustStock(StockAdjustmentParams params) async {
    await Future<void>.delayed(const Duration(milliseconds: 950));
    return const Success<void>(null);
  }

  @override
  Future<Result<ItemDetail>> fetchItemDetail(String barcode) async {
    return Failure<ItemDetail>(
      StateError('Training repository does not provide item detail'),
    );
  }

  @override
  Future<Result<ItemLocationSummaryEntity>> getItemLocations(
      String barcode) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    return Success<ItemLocationSummaryEntity>(summary);
  }

  @override
  Future<Result<LocationLookupSummaryEntity>> scanLocation(
      String barcode) async {
    return Failure<LocationLookupSummaryEntity>(
      StateError('Training repository does not provide location lookup'),
    );
  }
}

class _TrainingScenario {
  const _TrainingScenario._();

  static const barcode = '6291001001797';
  static const quantitySteps = <String>['1', '12'];

  static const summary = ItemLocationSummaryEntity(
    itemId: 1001,
    itemName: 'Hajer Water 330 ml',
    barcode: barcode,
    itemImageUrl: 'assets/images/hajer_water.jpg',
    totalQuantity: 29,
    locations: [
      ItemLocationEntity(
        locationId: 11,
        zone: 'A',
        type: 'shelf',
        code: 'A10.2',
        quantity: 7,
      ),
      ItemLocationEntity(
        locationId: 12,
        zone: 'A',
        type: 'shelf',
        code: 'A10.4',
        quantity: 5,
      ),
      ItemLocationEntity(
        locationId: 21,
        zone: 'B',
        type: 'bulk',
        code: 'BLK-A1.3',
        quantity: 17,
      ),
    ],
  );
}
