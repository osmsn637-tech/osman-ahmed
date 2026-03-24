import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../shared/l10n/l10n.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/adjustment_task_entities.dart';
import '../../../move/domain/entities/item_location_summary_entity.dart';
import '../../../move/presentation/pages/item_lookup_scan_dialog.dart';
import '../../domain/entities/task_entity.dart';
import '../shared/dashboard_common_widgets.dart';
import '../shared/location_format.dart';
import '../shared/task_report_photo_attachment.dart';
import '../shared/task_visuals.dart';

class WorkerTaskDetailsPage extends StatefulWidget {
  const WorkerTaskDetailsPage({
    super.key,
    required this.task,
    this.onStartTask,
    this.onCompleteTask,
    this.onSaveCycleCountProgress,
    this.onContinueCycleCountLater,
    this.onGetSuggestion,
    this.onScanAdjustmentLocation,
    this.onSubmitAdjustmentCount,
    this.onReportTaskIssue,
    this.onCaptureReportPhoto,
    this.onValidateLocation,
    this.onLookupItem,
  });

  final TaskEntity task;
  final Future<void> Function()? onStartTask;
  final Future<void> Function(
    int taskId, {
    int? quantity,
    String? locationId,
    List<Map<String, Object?>>? cycleCountItems,
  })? onCompleteTask;
  final Future<void> Function(
    int taskId, {
    required Map<String, Object?> progress,
  })? onSaveCycleCountProgress;
  final Future<void> Function(
    int taskId, {
    required Map<String, Object?> progress,
  })? onContinueCycleCountLater;
  final Future<String?> Function()? onGetSuggestion;
  final Future<AdjustmentTaskLocationScan> Function(String barcode)?
      onScanAdjustmentLocation;
  final Future<void> Function({
    required String adjustmentItemId,
    required int quantity,
    String? notes,
  })? onSubmitAdjustmentCount;
  final Future<void> Function({
    required String note,
    String? photoPath,
  })? onReportTaskIssue;
  final Future<TaskReportPhotoAttachment?> Function()? onCaptureReportPhoto;
  final Future<Map<String, dynamic>> Function(String barcode)?
      onValidateLocation;
  final Future<ItemLocationSummaryEntity> Function(String barcode)?
      onLookupItem;

  @override
  State<WorkerTaskDetailsPage> createState() => _WorkerTaskDetailsPageState();
}

class _WorkerTaskDetailsPageState extends State<WorkerTaskDetailsPage>
    with WidgetsBindingObserver {
  static const _scannerFocusRetryDelay = Duration(milliseconds: 250);
  static const _scannerFocusRetryCount = 6;
  late final TextEditingController _productController;
  late final TextEditingController _locationController;
  late final TextEditingController _bulkLocationController;
  late final TextEditingController _quantityController;
  late final TextEditingController _returnToteController;
  late final TextEditingController _returnScanController;
  late final TextEditingController _returnQuantityController;
  late final TextEditingController _cycleCountScanController;
  late final TextEditingController _cycleCountDetailQuantityController;
  late final TextEditingController _cycleCountDetailBarcodeController;
  late final TextEditingController _adjustmentQuantityController;
  late final TextEditingController _unexpectedItemNameController;
  late final TextEditingController _unexpectedItemQuantityController;
  late final FocusNode _productScanFocusNode;
  late final FocusNode _locationScanFocusNode;
  late final FocusNode _returnScanFocusNode;
  late final FocusNode _cycleCountScanFocusNode;
  late final FocusNode _cycleCountDetailBarcodeFocusNode;
  final List<TextEditingController> _cycleCountLineControllers =
      <TextEditingController>[];

  String? _productValidationMessage;
  String? _locationValidationMessage;
  String? _completionMessage;
  String? _startErrorMessage;
  String? _suggestedLocation;
  bool _starting = false;
  bool _completing = false;
  bool _suggesting = false;
  bool _validating = false;
  bool _itemValidated = false;
  bool _locationValidated = false;
  bool _startedLocally = false;
  bool _returnToteValidated = false;
  final bool _showUnexpectedItemFields = false;
  int _receivePage = 0;
  int _refillPage = 0;
  int _returnPage = 0;
  int _cycleCountPage = 0;
  int _refillQuantity = 0;
  bool _refillLookupLoading = false;
  bool _scanningAdjustmentLocation = false;
  bool _submittingAdjustment = false;
  bool _savingCycleCountProgress = false;
  bool _cycleCountDetailOpenedManually = false;
  String? _refillLookupError;
  String? _adjustmentErrorMessage;
  String? _cycleCountScanError;
  String? _selectedAdjustmentItemId;
  String? _selectedCycleCountItemKey;
  ItemLocationSummaryEntity? _refillSummary;
  AdjustmentTaskLocationScan? _adjustmentScan;
  late final List<_CycleCountItemState> _cycleCountItems;
  Timer? _cycleCountScanDebounce;
  Timer? _productValidationDebounce;
  Timer? _locationValidationDebounce;
  Timer? _returnValidationDebounce;
  Timer? _scannerFocusRetryTimer;
  Timer? _productFailureClearTimer;
  Timer? _locationFailureClearTimer;
  Timer? _cycleCountDetailBarcodeClearTimer;
  final List<bool> _returnItemValidated = <bool>[];

  String _tr(String english, String arabic) =>
      context.isArabicLocale ? arabic : english;

  String get _manualTypeLabel => _tr('Manual Type', 'إدخال يدوي');

  String get _cancelLabel => _tr('Cancel', 'إلغاء');

  String get _locationValidatedLabel =>
      _tr('Location validated', 'تم التحقق من الموقع');

  String get _pendingTaskRightProductMessage =>
      _tr('right product', 'الصنف الصحيح');
  final List<bool> _returnItemLocationValidated = <bool>[];
  final List<TextEditingController> _returnItemLocationControllers =
      <TextEditingController>[];
  final List<TextEditingController> _returnItemQuantityControllers =
      <TextEditingController>[];
  String? _lastAutoValidatedProduct;
  String? _lastAutoValidatedLocation;
  String? _locationValidationInFlightValue;
  bool _cycleCountDetailBarcodeValidated = false;

  String _messageForError(
    Object error, {
    required String fallbackEnglish,
    required String fallbackArabic,
  }) {
    return switch (error) {
      AppException(message: final message) when message.trim().isNotEmpty =>
        message,
      _ => _tr(fallbackEnglish, fallbackArabic),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final task = widget.task;
    _productController = TextEditingController();
    _locationController = TextEditingController(
      text: task.type == TaskType.receive || task.type == TaskType.cycleCount
          ? ''
          : task.toLocation ?? '',
    );
    _bulkLocationController =
        TextEditingController(text: task.fromLocation ?? '');
    _quantityController = TextEditingController(text: task.quantity.toString());
    _returnToteController = TextEditingController();
    _returnScanController = TextEditingController();
    _returnQuantityController = TextEditingController();
    _cycleCountScanController = TextEditingController();
    _cycleCountDetailQuantityController = TextEditingController();
    _cycleCountDetailBarcodeController = TextEditingController();
    _adjustmentQuantityController = TextEditingController();
    _unexpectedItemNameController = TextEditingController();
    _unexpectedItemQuantityController = TextEditingController();
    _productScanFocusNode = FocusNode(debugLabel: 'task-product-scan');
    _locationScanFocusNode = FocusNode(debugLabel: 'task-location-scan');
    _returnScanFocusNode = FocusNode(debugLabel: 'return-scan');
    _cycleCountScanFocusNode = FocusNode(debugLabel: 'cycle-count-scan');
    _cycleCountDetailBarcodeFocusNode =
        FocusNode(debugLabel: 'cycle-count-detail-barcode');
    _refillQuantity = task.quantity;
    _quantityController.addListener(_updateRefillQuantity);
    _cycleCountItems = _buildInitialCycleCountItems(task);
    _restoreCycleCountProgress(task);
    for (final _ in task.cycleCountExpectedLines) {
      _cycleCountLineControllers.add(TextEditingController());
    }
    for (final _ in task.returnItems) {
      _returnItemValidated.add(false);
      _returnItemLocationValidated.add(false);
      _returnItemLocationControllers.add(TextEditingController());
      _returnItemQuantityControllers.add(TextEditingController());
    }
    if (task.type == TaskType.refill) {
      _refillLookupLoading = true;
      _bulkLocationController.text = '';
      _locationController.text = '';
      _quantityController.text = '';
      _refillQuantity = 0;
      Future<void>.microtask(_loadRefillLookup);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreActiveValidationFocus();
      _restoreCycleCountScannerFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _productController.dispose();
    _locationController.dispose();
    _bulkLocationController.dispose();
    _quantityController.removeListener(_updateRefillQuantity);
    _quantityController.dispose();
    _returnToteController.dispose();
    _returnValidationDebounce?.cancel();
    _scannerFocusRetryTimer?.cancel();
    _productFailureClearTimer?.cancel();
    _locationFailureClearTimer?.cancel();
    _cycleCountDetailBarcodeClearTimer?.cancel();
    _returnScanController.dispose();
    _returnQuantityController.dispose();
    _cycleCountScanDebounce?.cancel();
    _productValidationDebounce?.cancel();
    _locationValidationDebounce?.cancel();
    _cycleCountScanController.dispose();
    _cycleCountDetailQuantityController.dispose();
    _cycleCountDetailBarcodeController.dispose();
    _adjustmentQuantityController.dispose();
    _unexpectedItemNameController.dispose();
    _unexpectedItemQuantityController.dispose();
    _productScanFocusNode.dispose();
    _locationScanFocusNode.dispose();
    _returnScanFocusNode.dispose();
    _cycleCountScanFocusNode.dispose();
    _cycleCountDetailBarcodeFocusNode.dispose();
    for (final controller in _cycleCountLineControllers) {
      controller.dispose();
    }
    for (final controller in _returnItemLocationControllers) {
      controller.dispose();
    }
    for (final controller in _returnItemQuantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _restoreActiveValidationFocus();
      _restoreCycleCountScannerFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final task = _effectiveTask;
    final fromType = detectLocationType(task.fromLocation);
    final toType = detectLocationType(task.toLocation);
    final barcode = task.itemBarcode?.trim();
    final imageUrl = task.type == TaskType.refill
        ? _resolvedRefillImageUrl(task)
        : task.itemImageUrl?.trim();
    final hasBarcode = barcode != null && barcode.isNotEmpty;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final canStartFromDetails =
        task.status == TaskStatus.pending && task.assignedTo == null;
    final canCompleteFromDetails = task.status == TaskStatus.inProgress;
    final showStartAction = canStartFromDetails && widget.onStartTask != null;
    final showCompleteAction =
        canCompleteFromDetails && widget.onCompleteTask != null;
    final typeColor = taskTypeColor(task.type);
    final statusColor = taskStatusColor(task.status);
    final refillReady = _isRefillFlowComplete();
    final receiveReady = _isReceiveFlowComplete();
    final returnValidationReady = _isReturnValidationComplete();
    final returnReady = _isReturnFlowComplete();
    final adjustmentReady = _isAdjustmentFlowComplete();
    final cycleCountReady = _isCycleCountFlowComplete();
    final refillQuantityDisplay =
        '${task.formatQuantity(_refillQuantity)} / ${task.formatQuantity(task.quantity)}';
    final showReturnAdvanceAction = showCompleteAction &&
        task.type == TaskType.returnTask &&
        _returnPage == 0;
    final showReturnCompleteAction = showCompleteAction &&
        task.type == TaskType.returnTask &&
        _returnPage == 1;
    final showsBottomActionBar = showStartAction ||
        showReturnAdvanceAction ||
        showReturnCompleteAction ||
        (showCompleteAction &&
            task.type != TaskType.receive &&
            task.type != TaskType.refill &&
            task.type != TaskType.returnTask);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workerTaskDetailsTitle),
        actions: [
          if (widget.onReportTaskIssue != null)
            IconButton(
              key: const Key('report-task-button'),
              onPressed: _openReportTaskDialog,
              icon: const Icon(Icons.report_problem_outlined),
              tooltip: _tr('Report Problem', 'الإبلاغ عن مشكلة'),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                task.status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: showsBottomActionBar
          ? SafeArea(
              minimum: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  key: showStartAction
                      ? const Key('start-task-button')
                      : showReturnAdvanceAction
                          ? const Key('return-page-next-button')
                          : const Key('complete-task-button'),
                  onPressed: showStartAction
                      ? (_starting ? null : _startTask)
                      : showReturnAdvanceAction
                          ? (returnValidationReady ? _advanceReturnPage : null)
                          : (task.type == TaskType.receive && _receivePage != 1)
                              ? null
                              : (_completing ||
                                      (task.type == TaskType.refill &&
                                          !refillReady) ||
                                      (task.type == TaskType.receive &&
                                          !receiveReady) ||
                                      (task.type == TaskType.returnTask &&
                                          !returnReady) ||
                                      (task.type == TaskType.adjustment &&
                                          !adjustmentReady) ||
                                      (task.type == TaskType.cycleCount &&
                                          !cycleCountReady))
                                  ? null
                                  : _completeTask,
                  icon: (showStartAction ? _starting : _completing)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(showStartAction
                          ? Icons.play_arrow_rounded
                          : showReturnAdvanceAction
                              ? Icons.keyboard_double_arrow_right_rounded
                              : Icons.check_rounded),
                  label: Text(
                    showStartAction
                        ? l10n.workerStartTask
                        : showReturnAdvanceAction
                            ? _tr('Return', 'إرجاع')
                            : l10n.workerComplete,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showStartAction || showReturnAdvanceAction
                        ? AppTheme.primary
                        : AppTheme.success,
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                ),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8EEFA), AppTheme.surface],
            stops: [0, 0.4],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            showsBottomActionBar ? 112 : 16,
          ),
          children: [
            if (_startErrorMessage != null) ...[
              _ValidationMessage(
                message: _startErrorMessage!,
                isPositive: false,
              ),
              const SizedBox(height: 12),
            ],
            if (task.type == TaskType.receive) ...[
              _SectionCard(
                title: '',
                icon: _receivePage == 0
                    ? Icons.looks_one_rounded
                    : Icons.looks_two_rounded,
                accentColor: typeColor,
                showHeader: false,
                child: _receivePage == 0
                    ? _buildReceivePageOne(
                        context,
                        task,
                        hasImage: hasImage,
                        imageUrl: imageUrl,
                        hasBarcode: hasBarcode,
                        barcode: barcode,
                      )
                    : _buildReceivePageTwo(context, task),
              ),
            ] else if (task.type == TaskType.refill) ...[
              _SectionCard(
                title: '',
                icon: _refillPage == 0
                    ? Icons.looks_one_rounded
                    : Icons.looks_two_rounded,
                accentColor: typeColor,
                showHeader: false,
                child: _refillLookupLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _refillLookupError != null
                        ? _buildRefillLookupError(context)
                        : _refillPage == 0
                            ? _buildRefillPageOne(
                                context,
                                task,
                                hasImage: hasImage,
                                imageUrl: imageUrl,
                                hasBarcode: hasBarcode,
                                barcode: barcode,
                              )
                            : _buildRefillPageTwo(context, task),
              ),
            ] else if (task.type == TaskType.returnTask) ...[
              _SectionCard(
                title: '',
                icon: Icons.undo_rounded,
                accentColor: typeColor,
                showHeader: false,
                child: _buildReturnTaskFlow(
                  context,
                  task,
                  hasImage: hasImage,
                  imageUrl: imageUrl,
                  hasBarcode: hasBarcode,
                  barcode: barcode,
                ),
              ),
            ] else if (task.type == TaskType.cycleCount) ...[
              _SectionCard(
                title: '',
                icon: Icons.fact_check_rounded,
                accentColor: typeColor,
                showHeader: false,
                child: _buildCycleCountFlow(
                  context,
                  task,
                  hasImage: hasImage,
                  imageUrl: imageUrl,
                  hasBarcode: hasBarcode,
                  barcode: barcode,
                ),
              ),
            ] else if (task.type == TaskType.adjustment) ...[
              _SectionCard(
                title: '',
                icon: Icons.tune_rounded,
                accentColor: typeColor,
                showHeader: false,
                child: _buildAdjustmentTaskFlow(context, task),
              ),
            ] else ...[
              _TaskHeroCard(
                task: task,
                typeColor: typeColor,
                statusColor: statusColor,
                fromType: fromType.label,
                toType: toType.label,
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: l10n.workerItem,
                icon: Icons.inventory_2_rounded,
                accentColor: typeColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.itemName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _ImagePanel(hasImage: hasImage, imageUrl: imageUrl),
                    const SizedBox(height: 12),
                    Text(
                      l10n.workerBarcode,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasBarcode ? barcode : l10n.workerNoBarcodeAvailable,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildHiddenBarcodeCaptureField(),
                    _buildScanCaptureSummary(
                      emptyText: l10n.workerScanOrEnterProductBarcode,
                      currentValue: _productController.text,
                      manualButtonText: _manualTypeLabel,
                      manualButtonKey: const Key('manual-type-barcode-button'),
                      onManualType: _openManualBarcodeDialog,
                    ),
                    if (_productValidationMessage != null) ...[
                      const SizedBox(height: 10),
                      _buildProductValidationAlert(context),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: l10n.workerMovement,
                icon: Icons.swap_horiz_rounded,
                accentColor: AppTheme.accent,
                child: _buildMovementSection(
                    context, task, fromType.label, toType.label),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: l10n.workerTaskInfo,
                icon: Icons.assignment_rounded,
                accentColor: statusColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DashboardTypeBadge(
                          task.type,
                          isPutaway: task.isPutawayTask,
                        ),
                        const SizedBox(width: 8),
                        DashboardStatusBadge(task.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: l10n.workerTaskType,
                      value: taskTypeLabel(
                        task.type,
                        isPutaway: task.isPutawayTask,
                      ),
                    ),
                    _InfoRow(
                      label: l10n.workerQuantity,
                      value: task.type == TaskType.refill
                          ? refillQuantityDisplay
                          : task.formatQuantity(task.quantity),
                    ),
                    _InfoRow(
                      label: l10n.workerStatus,
                      value: task.status.name.toUpperCase(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRefillLookupError(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _refillLookupError ??
              _tr(
                'Could not load refill locations.',
                'تعذر تحميل مواقع إعادة التعبئة.',
              ),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('refill-retry-button'),
          onPressed: _loadRefillLookup,
          child: Text(_tr('Retry', 'إعادة المحاولة')),
        ),
      ],
    );
  }

  Widget _buildRefillPageOne(
    BuildContext context,
    TaskEntity task, {
    required bool hasImage,
    required String? imageUrl,
    required bool hasBarcode,
    required String? barcode,
  }) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.itemName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        _ImagePanel(
          key: const Key('refill-item-image'),
          hasImage: hasImage,
          imageUrl: imageUrl,
          height: 116,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          label: l10n.workerBarcode,
          value: hasBarcode ? barcode! : l10n.workerNoBarcodeAvailable,
        ),
        _InfoRow(
          label: l10n.workerQuantity,
          value: task.formatQuantity(task.quantity),
        ),
        const SizedBox(height: 12),
        _LocationRow(
          label: _tr('From Bulk Location', 'من موقع التخزين'),
          value: _refillBulkLocation,
          icon: Icons.north_west_rounded,
        ),
        const SizedBox(height: 16),
        _buildHiddenBarcodeCaptureField(),
        _buildScanCaptureSummary(
          emptyText: _tr('Scan product barcode', 'امسح باركود الصنف'),
          currentValue: _productController.text,
          manualButtonText: _manualTypeLabel,
          manualButtonKey: const Key('manual-type-barcode-button'),
          onManualType: _openManualBarcodeDialog,
        ),
        if (_productValidationMessage != null) ...[
          const SizedBox(height: 10),
          _buildProductValidationAlert(context),
        ],
      ],
    );
  }

  Widget _buildRefillPageTwo(BuildContext context, TaskEntity task) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_productValidationMessage != null) ...[
          const SizedBox(height: 10),
          _buildProductValidationAlert(context),
          const SizedBox(height: 12),
        ],
        Text(
          _tr('Shelf Location', 'موقع الرف'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        _LocationRow(
          label: _tr('To Shelf Location', 'إلى موقع الرف'),
          value: _refillShelfLocation,
          icon: Icons.south_east_rounded,
        ),
        const SizedBox(height: 16),
        _buildHiddenLocationCaptureField(),
        _buildScanCaptureSummary(
          emptyText: _refillShelfLocation == null
              ? _tr('Scan shelf location', 'امسح موقع الرف')
              : _tr(
                  'Scan ${_refillShelfLocation!}',
                  'امسح ${_refillShelfLocation!}',
                ),
          currentValue: _locationController.text,
          manualButtonText: _manualTypeLabel,
          manualButtonKey: const Key('manual-type-location-button'),
          onManualType: _openManualLocationDialog,
          icon: Icons.location_on_outlined,
        ),
        if (_locationValidationMessage != null) ...[
          const SizedBox(height: 10),
          _buildLocationValidationAlert(context),
        ],
        const SizedBox(height: 12),
        TextField(
          key: const Key('refill-quantity-field'),
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _tr('Enter quantity', 'أدخل الكمية'),
            hintText: _tr('Quantity to move', 'الكمية المطلوب نقلها'),
            suffixText: _tr(
              'max ${task.formatQuantity(task.quantity)}',
              'الحد الأقصى ${task.formatQuantity(task.quantity)}',
            ),
            prefixIcon: const Icon(Icons.format_list_numbered_rounded),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        if (_completionMessage != null) ...[
          const SizedBox(height: 10),
          _ValidationMessage(message: _completionMessage!, isPositive: false),
        ],
        const SizedBox(height: 12),
        if (widget.onCompleteTask != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('complete-task-button'),
              onPressed: _completing || !_isRefillFlowComplete()
                  ? null
                  : _completeTask,
              icon: _completing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(l10n.workerComplete),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReceivePageOne(
    BuildContext context,
    TaskEntity task, {
    required bool hasImage,
    required String? imageUrl,
    required bool hasBarcode,
    required String? barcode,
  }) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReceiveHeroCard(
          itemName: task.itemName,
          barcode: hasBarcode ? barcode! : l10n.workerNoBarcodeAvailable,
          itemImageUrl: imageUrl,
          quantityLabel: task.formatQuantity(task.quantity),
        ),
        const SizedBox(height: 12),
        _LocationRow(
          label: _tr('From Inbound', 'من الوارد'),
          value: _tr('Inbound', 'الوارد'),
          icon: Icons.north_west_rounded,
        ),
        const SizedBox(height: 16),
        _buildHiddenBarcodeCaptureField(),
        _buildScanCaptureSummary(
          emptyText: _tr('Scan product barcode', 'امسح باركود الصنف'),
          currentValue: _productController.text,
          manualButtonText: _manualTypeLabel,
          manualButtonKey: const Key('manual-type-barcode-button'),
          onManualType: _openManualBarcodeDialog,
        ),
        if (_productValidationMessage != null) ...[
          const SizedBox(height: 10),
          _buildProductValidationAlert(context),
        ],
      ],
    );
  }

  Widget _buildReceivePageTwo(BuildContext context, TaskEntity task) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_productValidationMessage != null) ...[
          const SizedBox(height: 10),
          _buildProductValidationAlert(context),
          const SizedBox(height: 12),
        ],
        Text(
          _tr('Bulk Location', 'موقع التخزين'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        _LocationRow(
          label: _tr('To Bulk Location', 'إلى موقع التخزين'),
          value: task.toLocation,
          icon: Icons.south_east_rounded,
        ),
        const SizedBox(height: 16),
        _buildHiddenLocationCaptureField(),
        _buildScanCaptureSummary(
          emptyText: widget.task.toLocation == null
              ? _tr('Scan bulk location', 'امسح موقع التخزين')
              : _tr(
                  'Scan ${widget.task.toLocation!}',
                  'امسح ${widget.task.toLocation!}',
                ),
          currentValue: _locationController.text,
          manualButtonText: _manualTypeLabel,
          manualButtonKey: const Key('manual-type-location-button'),
          onManualType: _openManualLocationDialog,
          icon: Icons.location_on_outlined,
        ),
        if (_locationValidationMessage != null) ...[
          const SizedBox(height: 10),
          _buildLocationValidationAlert(context),
        ],
        const SizedBox(height: 12),
        if (widget.onCompleteTask != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('complete-task-button'),
              onPressed: _completing || !_isReceiveFlowComplete()
                  ? null
                  : _completeTask,
              icon: _completing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(l10n.workerComplete),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReturnTaskFlow(
    BuildContext context,
    TaskEntity task, {
    required bool hasImage,
    required String? imageUrl,
    required bool hasBarcode,
    required String? barcode,
  }) {
    return _returnPage == 0
        ? _buildReturnValidationPage(context, task)
        : _buildReturnExecutionPage(context, task);
  }

  Widget _buildReturnValidationPage(BuildContext context, TaskEntity task) {
    final items = task.returnItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.itemName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        _LocationRow(
          label: _tr('Return Tote', 'حاوية المرتجع'),
          value: task.returnContainerId,
          icon: Icons.inventory_rounded,
        ),
        const SizedBox(height: 16),
        _buildHiddenReturnCaptureField(),
        _buildScanCaptureSummary(
          emptyText: _tr('Scan return item barcode', 'امسح باركود صنف المرتجع'),
          currentValue: _returnScanController.text,
          manualButtonText: _manualTypeLabel,
          manualButtonKey: const Key('manual-type-return-barcode-button'),
          onManualType: _openReturnManualBarcodeDialog,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < items.length; index++) ...[
          _buildReturnValidationLine(
            context,
            item: items[index],
            index: index,
          ),
          const SizedBox(height: 10),
        ],
        if (_completionMessage != null) ...[
          const SizedBox(height: 8),
          _ValidationMessage(message: _completionMessage!, isPositive: false),
        ],
      ],
    );
  }

  Widget _buildReturnExecutionPage(BuildContext context, TaskEntity task) {
    final items = task.returnItems;
    final typeColor = taskTypeColor(task.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Return Items', 'أصناف المرتجع'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < items.length; index++) ...[
          _buildReturnExecutionLine(
            context,
            item: items[index],
            index: index,
            typeColor: typeColor,
          ),
          const SizedBox(height: 12),
        ],
        if (_completionMessage != null) ...[
          const SizedBox(height: 8),
          _ValidationMessage(message: _completionMessage!, isPositive: false),
        ],
      ],
    );
  }

  Widget _buildReturnValidationLine(
    BuildContext context, {
    required ReturnTaskItem item,
    required int index,
  }) {
    final validated =
        index < _returnItemValidated.length && _returnItemValidated[index];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: validated
              ? AppTheme.success.withValues(alpha: 0.45)
              : AppTheme.surfaceAlt,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            key: Key('return-validate-line-$index-button'),
            onPressed: () => _scanReturnItem(index),
            icon: Icon(
              validated
                  ? Icons.check_circle_rounded
                  : Icons.qr_code_scanner_rounded,
              color: validated ? AppTheme.success : AppTheme.primary,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              item.formatQuantity(item.quantity),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (item.barcode != null && item.barcode!.isNotEmpty)
                  Text(
                    item.barcode!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ReturnItemThumb(imageUrl: item.imageUrl),
        ],
      ),
    );
  }

  Widget _buildReturnExecutionLine(
    BuildContext context, {
    required ReturnTaskItem item,
    required int index,
    required Color typeColor,
  }) {
    final validated = index < _returnItemLocationValidated.length &&
        _returnItemLocationValidated[index];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceAlt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (item.barcode != null && item.barcode!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.barcode!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      item.location ?? '-',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              _ReturnItemThumb(imageUrl: item.imageUrl),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: validated
                          ? AppTheme.success.withValues(alpha: 0.35)
                          : AppTheme.surfaceAlt,
                    ),
                  ),
                  child: Text(
                    _returnItemLocationControllers[index].text.trim().isEmpty
                        ? _tr('Scan return location', 'امسح موقع المرتجع')
                        : _returnItemLocationControllers[index].text.trim(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _returnItemLocationControllers[index]
                                  .text
                                  .trim()
                                  .isEmpty
                              ? AppTheme.textMuted
                              : AppTheme.textPrimary,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: Key('return-line-$index-scan-location-button'),
                onPressed: () => _scanReturnItemLocation(index),
                style: IconButton.styleFrom(
                  backgroundColor: typeColor.withValues(alpha: 0.10),
                  side: BorderSide(color: typeColor.withValues(alpha: 0.25)),
                ),
                icon: Icon(
                  validated
                      ? Icons.check_circle_rounded
                      : Icons.qr_code_scanner_rounded,
                  color: validated ? AppTheme.success : typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: Key('return-line-$index-quantity-field'),
            controller: _returnItemQuantityControllers[index],
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _tr('Returned Quantity', 'الكمية المرتجعة'),
              suffixText: _tr(
                'max ${item.formatQuantity(item.quantity)}',
                'الحد الأقصى ${item.formatQuantity(item.quantity)}',
              ),
              prefixIcon: const Icon(Icons.format_list_numbered_rounded),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (validated)
            _ValidationMessage(
              message: _locationValidatedLabel,
              isPositive: true,
            ),
        ],
      ),
    );
  }

  Widget _buildCycleCountFlow(
    BuildContext context,
    TaskEntity task, {
    required bool hasImage,
    required String? imageUrl,
    required bool hasBarcode,
    required String? barcode,
  }) {
    return _cycleCountPage == 1 && _selectedCycleCountItem != null
        ? _buildCycleCountDetailPage(context, task, _selectedCycleCountItem!)
        : _buildCycleCountListPage(context, task);
  }

  Widget _buildAdjustmentTaskFlow(BuildContext context, TaskEntity task) {
    final scan = _adjustmentScan;
    final selected = _selectedAdjustmentProduct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Adjustment', 'تعديل المخزون'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                key: const Key('adjustment-location-code'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surfaceAlt),
                ),
                child: Text(
                  scan?.locationCode.isNotEmpty == true
                      ? scan!.locationCode
                      : _tr(
                          'Scan a location to load products',
                          'امسح موقعًا لتحميل المنتجات',
                        ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scan == null
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const Key('adjustment-scan-location-button'),
              onPressed:
                  _scanningAdjustmentLocation ? null : _scanAdjustmentLocation,
              style: IconButton.styleFrom(
                backgroundColor:
                    taskTypeColor(task.type).withValues(alpha: 0.10),
                side: BorderSide(
                  color: taskTypeColor(task.type).withValues(alpha: 0.25),
                ),
              ),
              icon: _scanningAdjustmentLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_scanner_rounded),
            ),
          ],
        ),
        if (_adjustmentErrorMessage != null) ...[
          const SizedBox(height: 10),
          _ValidationMessage(
            message: _adjustmentErrorMessage!,
            isPositive: false,
          ),
        ],
        if (scan != null) ...[
          const SizedBox(height: 16),
          Text(
            _tr(
              'Products at ${scan.locationCode}',
              'المنتجات في ${scan.locationCode}',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          for (final product in scan.products) ...[
            _buildAdjustmentProductCard(
              context,
              product: product,
              selected: product.adjustmentItemId == _selectedAdjustmentItemId,
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (selected != null) ...[
          const SizedBox(height: 6),
          _buildAdjustmentEditor(context, selected),
        ],
      ],
    );
  }

  Widget _buildAdjustmentProductCard(
    BuildContext context, {
    required AdjustmentTaskProduct product,
    required bool selected,
  }) {
    final previewQuantity =
        selected ? (_adjustmentEnteredQuantity ?? product.systemQuantity) : product.systemQuantity;
    final previewActive = selected && previewQuantity != product.systemQuantity;

    return InkWell(
      key: Key('adjustment-product-${product.adjustmentItemId}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => _selectAdjustmentProduct(product),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.surfaceAlt,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.productName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.counted
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.surfaceAlt.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    product.counted
                        ? _tr('Counted', 'تم العد')
                        : _tr('Pending', 'قيد الانتظار'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: product.counted
                          ? AppTheme.success
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _tr(
                'Current: ${widget.task.formatQuantity(product.systemQuantity)}',
                'الحالي: ${widget.task.formatQuantity(product.systemQuantity)}',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (previewActive) ...[
              const SizedBox(height: 4),
              Text(
                _tr(
                  'New quantity: ${widget.task.formatQuantity(previewQuantity)}',
                  'الكمية الجديدة: ${widget.task.formatQuantity(previewQuantity)}',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentEditor(
    BuildContext context,
    AdjustmentTaskProduct product,
  ) {
    final previewQuantity = _adjustmentEnteredQuantity ?? product.systemQuantity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceAlt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr(
              'Adjust ${product.productName}',
              'تعديل ${product.productName}',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _tr(
              'Current: ${widget.task.formatQuantity(product.systemQuantity)}',
              'الحالي: ${widget.task.formatQuantity(product.systemQuantity)}',
            ),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _tr(
              'New: ${widget.task.formatQuantity(previewQuantity)}',
              'الجديد: ${widget.task.formatQuantity(previewQuantity)}',
            ),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('adjustment-quantity-field'),
            controller: _adjustmentQuantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _tr('New quantity', 'الكمية الجديدة'),
              hintText: _tr('Enter counted quantity', 'أدخل الكمية المعدودة'),
            ),
            onChanged: (_) {
              setState(() => _adjustmentErrorMessage = null);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('adjustment-submit-button'),
              onPressed: _submittingAdjustment || _adjustmentEnteredQuantity == null
                  ? null
                  : _submitAdjustmentChange,
              child: Text(
                _submittingAdjustment
                    ? _tr('Submitting...', 'جارٍ الإرسال...')
                    : _tr('Submit Adjustment', 'إرسال التعديل'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleCountHiddenScanField() {
    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0,
        child: TextField(
          key: const Key('cycle-count-hidden-scan-field'),
          controller: _cycleCountScanController,
          focusNode: _cycleCountScanFocusNode,
          autofocus: true,
          keyboardType: TextInputType.none,
          showCursor: false,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _handleCycleCountScanChanged,
          onSubmitted: (_) => _submitCycleCountScan(
            _normalizeCycleCountBarcode(_cycleCountScanController.text),
          ),
        ),
      ),
    );
  }

  Widget _buildHiddenValidationField({
    required Key fieldKey,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    bool autofocus = true,
  }) {
    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0,
        child: TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: TextInputType.none,
          showCursor: false,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHiddenBarcodeCaptureField() {
    return _buildHiddenValidationField(
      fieldKey: const Key('product-validate-field'),
      controller: _productController,
      focusNode: _productScanFocusNode,
      onChanged: _handleProductInputChanged,
    );
  }

  Widget _buildHiddenLocationCaptureField() {
    return _buildHiddenValidationField(
      fieldKey: const Key('location-validate-field'),
      controller: _locationController,
      focusNode: _locationScanFocusNode,
      onChanged: _handleLocationInputChanged,
    );
  }

  Widget _buildHiddenReturnCaptureField() {
    return _buildHiddenValidationField(
      fieldKey: const Key('return-validate-field'),
      controller: _returnScanController,
      focusNode: _returnScanFocusNode,
      onChanged: _handleReturnBarcodeInputChanged,
    );
  }

  Widget _buildScanCaptureSummary({
    required String emptyText,
    required String currentValue,
    required String manualButtonText,
    required Key manualButtonKey,
    required VoidCallback onManualType,
    IconData icon = Icons.qr_code_scanner_rounded,
  }) {
    final value = currentValue.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceAlt),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value.isEmpty ? emptyText : value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: value.isEmpty
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: manualButtonKey,
          onPressed: onManualType,
          icon: const Icon(Icons.keyboard_rounded),
          label: Text(manualButtonText),
        ),
      ],
    );
  }

  Widget _buildProductValidationAlert(BuildContext context) {
    final message = _productValidationMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final isPendingReadyMessage = message == _pendingTaskRightProductMessage;
    final isPositive =
        isPendingReadyMessage || message == l10n.workerProductValidated;
    final supportingText = isPendingReadyMessage
        ? _tr(
            'Start the task to unlock the next step.',
            'ابدأ المهمة لفتح الخطوة التالية.',
          )
        : isPositive
            ? _tr(
                'Correct barcode captured. Continue to the next step.',
                'تم التقاط الباركود الصحيح. تابع إلى الخطوة التالية.',
              )
            : _tr(
                'This barcode does not match the task item. Scan the correct product to continue.',
                'هذا الباركود لا يطابق صنف المهمة. امسح الصنف الصحيح للمتابعة.',
              );

    return _ValidationMessage(
      key: const Key('product-validation-alert'),
      message: message,
      supportingText: supportingText,
      isPositive: isPositive,
    );
  }

  Widget _buildLocationValidationAlert(BuildContext context) {
    final message = _locationValidationMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final isPositive = message == l10n.workerLocationValidated;
    final supportingText = isPositive
        ? _tr(
            'Location confirmed. You can keep moving through the task.',
            'تم تأكيد الموقع. يمكنك متابعة خطوات المهمة.',
          )
        : _tr(
            'The scanned location does not match this step. Scan the expected location and try again.',
            'الموقع الممسوح لا يطابق هذه الخطوة. امسح الموقع المتوقع ثم حاول مرة أخرى.',
          );

    return _ValidationMessage(
      key: const Key('location-validation-alert'),
      message: message,
      supportingText: supportingText,
      isPositive: isPositive,
    );
  }

  Widget _buildCycleCountListPage(BuildContext context, TaskEntity task) {
    final typeColor = taskTypeColor(task.type);
    final counted = _cycleCountItems.where((item) => item.completed).length;
    final total = _cycleCountItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Cycle Count', 'الجرد الدوري'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        _LocationRow(
          label: _tr('Count Location', 'موقع الجرد'),
          value: task.toLocation,
          icon: Icons.grid_view_rounded,
        ),
        _buildCycleCountHiddenScanField(),
        const SizedBox(height: 12),
        _buildHiddenLocationCaptureField(),
        _buildScanCaptureSummary(
          emptyText: _tr('Scan count location', 'امسح موقع الجرد'),
          currentValue: _locationController.text,
          manualButtonText: _manualTypeLabel,
          manualButtonKey: const Key('manual-type-location-button'),
          onManualType: _openManualLocationDialog,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                _tr('Counted Items', 'الأصناف المعدودة'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Text(
              _tr(
                '$counted of $total counted',
                '$counted من $total تم عدها',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('cycle-count-continue-later-button'),
                onPressed:
                    _savingCycleCountProgress ? null : _continueCycleCountLater,
                child: _savingCycleCountProgress
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_tr('Continue later', 'متابعة لاحقًا')),
              ),
            ),
          ],
        ),
        if (_cycleCountScanError != null) ...[
          const SizedBox(height: 8),
          _ValidationMessage(message: _cycleCountScanError!, isPositive: false),
        ],
        if (_locationValidationMessage != null) ...[
          const SizedBox(height: 8),
          _ValidationMessage(
            message: _locationValidationMessage!,
            isPositive: _locationValidated,
          ),
        ],
        const SizedBox(height: 12),
        for (final item in _cycleCountItems) ...[
          _buildCycleCountListItem(context, item),
          const SizedBox(height: 10),
        ],
        if (_completionMessage != null) ...[
          const SizedBox(height: 8),
          _ValidationMessage(message: _completionMessage!, isPositive: false),
        ],
      ],
    );
  }

  Widget _buildCycleCountListItem(
    BuildContext context,
    _CycleCountItemState item,
  ) {
    final statusColor = item.completed ? AppTheme.success : AppTheme.textMuted;
    return InkWell(
      onTap: () => _openCycleCountItem(item.key, openedManually: true),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.completed
                ? AppTheme.success.withValues(alpha: 0.35)
                : AppTheme.surfaceAlt,
          ),
        ),
        child: Row(
          children: [
            _ReturnItemThumb(imageUrl: item.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (item.barcode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.barcode,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  item.completed
                      ? Icons.check_circle_rounded
                      : Icons.pending_outlined,
                  color: statusColor,
                ),
                const SizedBox(height: 4),
                Text(
                  item.completed
                      ? _tr(
                          '${item.formatQuantity(item.countedQuantity)} counted',
                          '${item.formatQuantity(item.countedQuantity)} تم عدها',
                        )
                      : _tr('Pending', 'قيد الانتظار'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleCountDetailPage(
    BuildContext context,
    TaskEntity task,
    _CycleCountItemState item,
  ) {
    final quantityEnabled = _isCycleCountDetailQuantityEnabled(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _returnToCycleCountList,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                _tr('Count Item', 'عد الصنف'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _LocationRow(
          label: _tr('Shelf Location', 'موقع الرف'),
          value: task.toLocation,
          icon: Icons.grid_view_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReturnItemThumb(imageUrl: item.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (item.barcode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.barcode,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_cycleCountDetailOpenedManually) ...[
          _buildHiddenValidationField(
            fieldKey: const Key('cycle-count-detail-barcode-field'),
            controller: _cycleCountDetailBarcodeController,
            focusNode: _cycleCountDetailBarcodeFocusNode,
            onChanged: _handleCycleCountDetailBarcodeChanged,
          ),
          _buildScanCaptureSummary(
            emptyText: _tr('Scan or type barcode', 'امسح أو اكتب الباركود'),
            currentValue: _cycleCountDetailBarcodeController.text,
            manualButtonText: _manualTypeLabel,
            manualButtonKey: const Key('cycle-count-detail-manual-type-button'),
            onManualType: _openCycleCountManualBarcodeDialog,
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: const Key('cycle-count-detail-quantity-field'),
          controller: _cycleCountDetailQuantityController,
          enabled: quantityEnabled,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _tr('Shelf Quantity', 'كمية الرف'),
            prefixIcon: const Icon(Icons.fact_check_outlined),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('cycle-count-detail-confirm-button'),
            onPressed:
                _savingCycleCountProgress ? null : _confirmCycleCountItem,
            child: _savingCycleCountProgress
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_tr('Confirm quantity', 'تأكيد الكمية')),
          ),
        ),
        if (_completionMessage != null) ...[
          const SizedBox(height: 8),
          _ValidationMessage(message: _completionMessage!, isPositive: false),
        ],
      ],
    );
  }

  Future<void> _startTask() async {
    if (widget.onStartTask == null) return;
    setState(() {
      _starting = true;
      _startErrorMessage = null;
    });
    try {
      await widget.onStartTask!();
      if (mounted) {
        setState(() {
          _startedLocally = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _startErrorMessage = _tr(
            'Failed to start task. Please try again.',
            'فشل بدء المهمة. حاول مرة أخرى.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  TaskEntity get _effectiveTask {
    if (!_startedLocally || widget.task.status != TaskStatus.pending) {
      return widget.task;
    }

    return TaskEntity(
      id: widget.task.id,
      remoteTaskId: widget.task.remoteTaskId,
      apiTaskType: widget.task.apiTaskType,
      type: widget.task.type,
      itemId: widget.task.itemId,
      itemName: widget.task.itemName,
      itemBarcode: widget.task.itemBarcode,
      itemImageUrl: widget.task.itemImageUrl,
      fromLocation: widget.task.fromLocation,
      toLocation: widget.task.toLocation,
      toLocationId: widget.task.toLocationId,
      quantity: widget.task.quantity,
      assignedTo: widget.task.assignedTo ?? '__local_worker__',
      status: TaskStatus.inProgress,
      createdBy: widget.task.createdBy,
      zone: widget.task.zone,
      createdAt: widget.task.createdAt,
      source: widget.task.source,
      priority: widget.task.priority,
      sourceEventId: widget.task.sourceEventId,
      workflowData: widget.task.workflowData,
    );
  }

  List<_CycleCountItemState> _buildInitialCycleCountItems(TaskEntity task) {
    return task.cycleCountItems
        .map(
          (item) => _CycleCountItemState(
            key: item.key,
            itemName: item.itemName,
            barcode: item.barcode,
            expectedQuantity: item.expectedQuantity,
            imageUrl: item.imageUrl,
            unit: item.quantityUnit,
          ),
        )
        .toList(growable: false);
  }

  void _restoreCycleCountProgress(TaskEntity task) {
    if (task.type != TaskType.cycleCount) return;
    final progressByKey = task.cycleCountProgressByKey;
    if (progressByKey.isNotEmpty) {
      for (var index = 0; index < _cycleCountItems.length; index++) {
        final saved = progressByKey[_cycleCountItems[index].key];
        if (saved == null) continue;
        _cycleCountItems[index] = _cycleCountItems[index].copyWith(
          countedQuantity: saved.countedQuantity,
          completed: saved.completed,
        );
      }
    }

    final raw = task.workflowData['cycleCountProgress'];
    if (raw is! Map) return;
    final savedLocation = raw['location']?.toString().trim();
    if (savedLocation != null && savedLocation.isNotEmpty) {
      _locationController.text = savedLocation;
    }
    if (raw['locationValidated'] == true) {
      _locationValidated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _locationValidationMessage = _locationValidatedLabel;
        });
      });
    }
  }

  void _restoreCycleCountScannerFocus() {
    if (!mounted ||
        widget.task.type != TaskType.cycleCount ||
        !_locationValidated ||
        _cycleCountPage != 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_locationValidated ||
          _cycleCountPage != 0 ||
          _cycleCountScanFocusNode.hasFocus) {
        return;
      }
      _requestScannerFocus(_cycleCountScanFocusNode);
    });
  }

  _CycleCountItemState? get _selectedCycleCountItem {
    final key = _selectedCycleCountItemKey;
    if (key == null) return null;
    for (final item in _cycleCountItems) {
      if (item.key == key) return item;
    }
    return null;
  }

  void _openCycleCountItem(String key, {bool openedManually = false}) {
    _CycleCountItemState? item;
    for (final entry in _cycleCountItems) {
      if (entry.key == key) {
        item = entry;
        break;
      }
    }
    if (item == null) return;
    final selectedItem = item;
    _cycleCountDetailQuantityController.text = selectedItem.countedQuantity > 0
        ? selectedItem.countedQuantity.toString()
        : '';
    _cycleCountDetailBarcodeClearTimer?.cancel();
    _cycleCountDetailBarcodeController.clear();
    _cycleCountScanDebounce?.cancel();
    _cycleCountScanController.clear();
    setState(() {
      _selectedCycleCountItemKey = selectedItem.key;
      _cycleCountPage = 1;
      _cycleCountDetailOpenedManually = openedManually;
      _cycleCountDetailBarcodeValidated = false;
      _cycleCountScanError = null;
      _completionMessage = null;
    });
    if (openedManually) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _cycleCountPage != 1 ||
            !_cycleCountDetailOpenedManually) {
          return;
        }
        _cycleCountDetailBarcodeFocusNode.requestFocus();
      });
    }
  }

  void _returnToCycleCountList() {
    _cycleCountDetailBarcodeClearTimer?.cancel();
    setState(() {
      _cycleCountPage = 0;
      _selectedCycleCountItemKey = null;
      _cycleCountDetailOpenedManually = false;
      _cycleCountDetailBarcodeValidated = false;
      _cycleCountDetailBarcodeController.clear();
      _completionMessage = null;
    });
    _restoreCycleCountScannerFocus();
  }

  void _handleCycleCountScanChanged(String value) {
    if (!_locationValidated || _cycleCountPage != 0) return;
    final normalized = _normalizeCycleCountBarcode(value);
    if (normalized.isEmpty) return;

    _cycleCountScanDebounce?.cancel();
    if (value.contains('\n') || value.contains('\r')) {
      _submitCycleCountScan(normalized);
      return;
    }

    _cycleCountScanDebounce = Timer(
      const Duration(milliseconds: 160),
      () => _submitCycleCountScan(
        _normalizeCycleCountBarcode(_cycleCountScanController.text),
      ),
    );
  }

  String _normalizeCycleCountBarcode(String value) {
    return value.replaceAll(RegExp(r'[\r\n]+'), '').trim().toUpperCase();
  }

  void _handleCycleCountDetailBarcodeChanged(String value) {
    _cycleCountDetailBarcodeClearTimer?.cancel();
    final item = _selectedCycleCountItem;
    final normalized = _normalizeCycleCountBarcode(value);
    final expected =
        item == null ? '' : _normalizeCycleCountBarcode(item.barcode);
    setState(() {
      _cycleCountDetailBarcodeValidated =
          expected.isEmpty || (normalized.isNotEmpty && normalized == expected);
      if (_completionMessage != null) {
        _completionMessage = null;
      }
    });
    if (normalized.isEmpty) return;
    _cycleCountDetailBarcodeClearTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_normalizeCycleCountBarcode(
              _cycleCountDetailBarcodeController.text) !=
          normalized) {
        return;
      }
      setState(() {
        _cycleCountDetailBarcodeController.clear();
      });
      _restoreActiveValidationFocus();
    });
  }

  bool _isCycleCountDetailQuantityEnabled(_CycleCountItemState item) {
    if (!_cycleCountDetailOpenedManually) {
      return true;
    }
    final expectedBarcode = _normalizeCycleCountBarcode(item.barcode);
    if (expectedBarcode.isEmpty) {
      return true;
    }
    return _cycleCountDetailBarcodeValidated;
  }

  Future<void> _submitCycleCountScan(String normalized) async {
    if (!mounted) return;
    _cycleCountScanDebounce?.cancel();
    _cycleCountScanController.clear();
    if (!_locationValidated || normalized.isEmpty || _cycleCountPage != 0) {
      return;
    }

    for (final item in _cycleCountItems) {
      if (item.barcode.trim().toUpperCase() == normalized) {
        setState(() => _cycleCountScanError = null);
        _openCycleCountItem(item.key);
        return;
      }
    }

    setState(() {
      _cycleCountScanError = _tr(
        'Scanned item is not in this cycle count list.',
        'الصنف الممسوح غير موجود في قائمة الجرد هذه.',
      );
    });
    _restoreCycleCountScannerFocus();
  }

  void _showCycleCountScanError() {
    setState(() {
      _cycleCountScanError = _tr(
        'Scanned item is not in this cycle count list.',
        'الصنف الممسوح غير موجود في قائمة الجرد هذه.',
      );
    });
    _restoreCycleCountScannerFocus();
  }

  Map<String, Object?> _buildCycleCountProgressPayload() {
    return <String, Object?>{
      'items': _cycleCountItems
          .map(
            (item) => <String, Object?>{
              'key': item.key,
              'itemName': item.itemName,
              'barcode': item.barcode,
              'countedQuantity': item.countedQuantity,
              'completed': item.completed,
            },
          )
          .toList(growable: false),
      'location': _locationController.text.trim(),
      'locationValidated': _locationValidated,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  List<Map<String, Object?>> _cycleCountSubmissionItems() {
    return _cycleCountItems
        .map(
          (item) => <String, Object?>{
            'itemName': item.itemName,
            'barcode': item.barcode,
            'countedQuantity': item.countedQuantity,
          },
        )
        .toList(growable: false);
  }

  Future<void> _saveCycleCountProgress() async {
    if (widget.onSaveCycleCountProgress == null ||
        widget.task.type != TaskType.cycleCount) {
      return;
    }
    await widget.onSaveCycleCountProgress!(
      widget.task.id,
      progress: _buildCycleCountProgressPayload(),
    );
  }

  Future<void> _confirmCycleCountItem() async {
    final item = _selectedCycleCountItem;
    if (item == null) return;
    if (!_isCycleCountDetailQuantityEnabled(item)) {
      setState(() {
        _completionMessage = _tr(
          'Validate the item barcode before entering quantity.',
          'تحقق من باركود الصنف قبل إدخال الكمية.',
        );
      });
      return;
    }
    final manualBarcode = _normalizeCycleCountBarcode(
      _cycleCountDetailBarcodeController.text,
    );
    final expectedBarcode = _normalizeCycleCountBarcode(item.barcode);
    if (manualBarcode.isNotEmpty &&
        expectedBarcode.isNotEmpty &&
        manualBarcode != expectedBarcode) {
      setState(() {
        _completionMessage = _tr(
          'Typed barcode does not match this item.',
          'الباركود المُدخل لا يطابق هذا الصنف.',
        );
      });
      return;
    }
    final quantity =
        _parsePositiveInt(_cycleCountDetailQuantityController.text);
    if (quantity == null) {
      setState(() {
        _completionMessage = _tr(
          'Enter a valid counted quantity.',
          'أدخل كمية معدودة صحيحة.',
        );
      });
      return;
    }

    setState(() {
      _savingCycleCountProgress = true;
      _completionMessage = null;
    });
    try {
      final index =
          _cycleCountItems.indexWhere((entry) => entry.key == item.key);
      if (index == -1) return;
      _cycleCountItems[index] = _cycleCountItems[index].copyWith(
        countedQuantity: quantity,
        completed: true,
      );
      await _saveCycleCountProgress();
      if (!mounted) return;
      _cycleCountDetailBarcodeClearTimer?.cancel();
      setState(() {
        _cycleCountPage = 0;
        _selectedCycleCountItemKey = null;
        _cycleCountDetailOpenedManually = false;
        _cycleCountDetailBarcodeValidated = false;
        _cycleCountDetailBarcodeController.clear();
      });
      _restoreCycleCountScannerFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _completionMessage = _tr(
          'Failed to save cycle count progress.',
          'فشل حفظ تقدم الجرد.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingCycleCountProgress = false;
        });
      }
    }
  }

  Future<void> _continueCycleCountLater() async {
    setState(() {
      _savingCycleCountProgress = true;
      _completionMessage = null;
    });
    try {
      final continueLater = widget.onContinueCycleCountLater;
      if (continueLater != null) {
        await continueLater(
          widget.task.id,
          progress: _buildCycleCountProgressPayload(),
        );
      } else {
        await _saveCycleCountProgress();
      }
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _completionMessage = _tr(
          'Failed to save cycle count progress.',
          'فشل حفظ تقدم الجرد.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingCycleCountProgress = false;
        });
      }
    }
  }

  Future<void> _scanAdjustmentLocation() async {
    final scanner = widget.onScanAdjustmentLocation;
    if (scanner == null || _scanningAdjustmentLocation) return;

    final scanned = await showItemLookupScanDialog(
      context,
      title: _tr('Scan adjustment location', 'امسح موقع التعديل'),
      hintText: _tr(
        'Scan or enter location barcode',
        'امسح أو أدخل باركود الموقع',
      ),
      showKeyboard: false,
    );
    if (!mounted || scanned == null) return;

    setState(() {
      _scanningAdjustmentLocation = true;
      _adjustmentErrorMessage = null;
    });
    try {
      final result = await scanner(scanned.trim());
      if (!mounted) return;
      setState(() {
        _adjustmentScan = result;
        _selectedAdjustmentItemId = null;
        _adjustmentQuantityController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _adjustmentErrorMessage = _tr(
          'Could not load adjustment products for this location.',
          'تعذر تحميل منتجات التعديل لهذا الموقع.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _scanningAdjustmentLocation = false);
      }
    }
  }

  void _selectAdjustmentProduct(AdjustmentTaskProduct product) {
    setState(() {
      _selectedAdjustmentItemId = product.adjustmentItemId;
      _adjustmentQuantityController.text = '${product.systemQuantity}';
      _adjustmentErrorMessage = null;
    });
  }

  Future<void> _submitAdjustmentChange() async {
    final submitter = widget.onSubmitAdjustmentCount;
    final selected = _selectedAdjustmentProduct;
    if (submitter == null || selected == null || _submittingAdjustment) return;

    final quantity = _adjustmentEnteredQuantity;
    if (quantity == null) {
      setState(() {
        _adjustmentErrorMessage = _tr(
          'Enter an adjustment quantity.',
          'أدخل كمية التعديل.',
        );
      });
      return;
    }

    setState(() {
      _submittingAdjustment = true;
      _adjustmentErrorMessage = null;
    });

    try {
      await submitter(
        adjustmentItemId: selected.adjustmentItemId,
        quantity: quantity,
      );
      if (!mounted) return;
      final scan = _adjustmentScan;
      if (scan == null) return;
      final updatedProducts = scan.products
          .map(
            (product) => product.adjustmentItemId == selected.adjustmentItemId
                ? product.copyWith(
                    counted: true,
                    systemQuantity: quantity,
                  )
                : product,
          )
          .toList(growable: false);
      setState(() {
        _adjustmentScan = AdjustmentTaskLocationScan(
          locationId: scan.locationId,
          locationCode: scan.locationCode,
          products: updatedProducts,
        );
        _adjustmentQuantityController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _adjustmentErrorMessage = _tr(
          'Failed to submit adjustment. Please try again.',
          'فشل إرسال التعديل. حاول مرة أخرى.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _submittingAdjustment = false);
      }
    }
  }

  Future<void> _completeTask() async {
    if (_completing) return;
    setState(() => _completionMessage = null);
    if (widget.onCompleteTask == null) return;
    setState(() => _completing = true);
    try {
      final task = widget.task;
      if (task.type == TaskType.refill) {
        final shelfLocation = _locationController.text.trim();
        if (_refillQuantity <= 0 ||
            shelfLocation.isEmpty ||
            !_locationValidated) {
          setState(() => _completionMessage = _tr(
                'Enter quantity to move and confirm the shelf location before completing.',
                'أدخل الكمية المراد نقلها وأكد موقع الرف قبل الإكمال.',
              ));
          return;
        }
        await widget.onCompleteTask!(
          task.id,
          quantity: _refillQuantity,
          locationId: shelfLocation,
        );
      } else if (task.type == TaskType.returnTask) {
        if (!_isReturnFlowComplete()) {
          setState(() => _completionMessage = _tr(
                'Process every return item before completing.',
                'عالج كل أصناف المرتجع قبل الإكمال.',
              ));
          return;
        }
        await widget.onCompleteTask!(
          task.id,
          quantity: _returnProcessedQuantity,
          locationId: _lastReturnLocation,
        );
      } else if (task.type == TaskType.cycleCount) {
        final location = _locationController.text.trim();
        if (!_isCycleCountFlowComplete()) {
          setState(() => _completionMessage = _tr(
                'Finish the cycle count inputs before completing.',
                'أكمل مدخلات الجرد قبل الإكمال.',
              ));
          return;
        }
        await widget.onCompleteTask!(
          task.id,
          quantity: _cycleCountTotalCountedQuantity,
          locationId: location,
          cycleCountItems: _cycleCountSubmissionItems(),
        );
      } else if (task.type == TaskType.receive) {
        final receiveLocationId = task.isPutawayTask
            ? task.toLocationId?.trim()
            : _locationController.text.trim();
        await widget.onCompleteTask!(
          task.id,
          quantity: task.quantity,
          locationId: receiveLocationId,
        );
      } else {
        await widget.onCompleteTask!(task.id);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      setState(() {
        _completionMessage = switch (error) {
          AppException(message: final message) when message.trim().isNotEmpty =>
            message,
          _ => _tr(
              'Failed to complete task. Please try again.',
              'فشل إكمال المهمة. حاول مرة أخرى.',
            ),
        };
      });
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Widget _buildMovementSection(
    BuildContext context,
    TaskEntity task,
    String fromTypeLabel,
    String toTypeLabel,
  ) {
    final l10n = context.l10n;
    if (task.type == TaskType.refill) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('bulk-location-field'),
            controller: _bulkLocationController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _tr('Step 1: Bulk location', 'الخطوة 1: موقع التخزين'),
              hintText: 'BULK-01-01',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('refill-quantity-field'),
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _tr(
                'Step 2: Select quantity (max ${task.formatQuantity(task.quantity)})',
                'الخطوة 2: اختر الكمية (الحد الأقصى ${task.formatQuantity(task.quantity)})',
              ),
              hintText: _tr('Enter quantity', 'أدخل الكمية'),
              suffixText: _tr(
                'max ${task.formatQuantity(task.quantity)}',
                'الحد الأقصى ${task.formatQuantity(task.quantity)}',
              ),
              prefixIcon: const Icon(Icons.format_list_numbered_rounded),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _LocationRow(
            label: l10n.workerFromWithType(fromTypeLabel),
            value: task.fromLocation,
            icon: Icons.north_west_rounded,
          ),
          const SizedBox(height: 8),
          _LocationRow(
            label: _tr(
              'Task destination (for reference)',
              'وجهة المهمة (للمرجع)',
            ),
            value: task.toLocation,
            icon: Icons.south_east_rounded,
          ),
          const SizedBox(height: 12),
          _buildHiddenLocationCaptureField(),
          _buildScanCaptureSummary(
            emptyText:
                _tr('Step 3: Scan shelf location', 'الخطوة 3: امسح موقع الرف'),
            currentValue: _locationController.text,
            manualButtonText: _manualTypeLabel,
            manualButtonKey: const Key('manual-type-location-button'),
            onManualType: _openManualLocationDialog,
            icon: Icons.location_on_outlined,
          ),
          if (_completionMessage != null) ...[
            const SizedBox(height: 10),
            _ValidationMessage(message: _completionMessage!, isPositive: false),
          ],
        ],
      );
    }

    return Column(
      children: [
        _LocationRow(
          label: l10n.workerFromWithType(fromTypeLabel),
          value: task.fromLocation,
          icon: Icons.north_west_rounded,
        ),
        const SizedBox(height: 10),
        const Icon(
          Icons.arrow_downward_rounded,
          color: AppTheme.textMuted,
          size: 18,
        ),
        const SizedBox(height: 10),
        _LocationRow(
          label: l10n.workerToWithType(toTypeLabel),
          value: task.toLocation,
          icon: Icons.south_east_rounded,
        ),
        const SizedBox(height: 12),
        _buildHiddenLocationCaptureField(),
        _buildScanCaptureSummary(
          emptyText: l10n.workerScanOrEnterLocation,
          currentValue: _locationController.text,
          manualButtonText: _manualTypeLabel,
          manualButtonKey: const Key('manual-type-location-button'),
          onManualType: _openManualLocationDialog,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 8),
        if (widget.onGetSuggestion != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: const Key('suggest-location-button'),
              onPressed: _suggesting ? null : _loadSuggestion,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
              ),
              child: _suggesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _tr(
                        'Use suggested location',
                        'استخدم الموقع المقترح',
                      ),
                    ),
            ),
          ),
        ],
        if (_suggestedLocation != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _locationController.text = _suggestedLocation!;
              _handleLocationInputChanged(_suggestedLocation!);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.accent.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Text(
                    _tr(
                      'Suggested: $_suggestedLocation',
                      'المقترح: $_suggestedLocation',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_locationValidationMessage != null) ...[
          const SizedBox(height: 10),
          _buildLocationValidationAlert(context),
        ],
      ],
    );
  }

  bool _isRefillFlowComplete() {
    if (widget.task.type != TaskType.refill) return true;
    final shelf = _locationController.text.trim();
    return _refillPage == 1 &&
        !_refillLookupLoading &&
        _refillLookupError == null &&
        _itemValidated &&
        _locationValidated &&
        shelf.isNotEmpty &&
        _refillQuantity > 0 &&
        _refillQuantity <= widget.task.quantity;
  }

  bool _isReceiveFlowComplete() {
    if (widget.task.type != TaskType.receive) return true;
    return _receivePage == 1 && _itemValidated && _locationValidated;
  }

  bool _isReturnValidationComplete() {
    if (widget.task.type != TaskType.returnTask) return true;
    return _returnItemValidated.isNotEmpty &&
        _returnItemValidated.every((validated) => validated);
  }

  bool _isReturnFlowComplete() {
    if (widget.task.type != TaskType.returnTask) return true;
    if (_returnPage != 1) return false;
    if (_returnItemLocationValidated.any((validated) => !validated)) {
      return false;
    }
    for (var index = 0; index < widget.task.returnItems.length; index++) {
      final expected = widget.task.returnItems[index].quantity;
      final quantity =
          _parsePositiveInt(_returnItemQuantityControllers[index].text);
      if (quantity == null || quantity > expected) return false;
    }
    return true;
  }

  bool _isAdjustmentFlowComplete() {
    if (widget.task.type != TaskType.adjustment) return true;
    final scan = _adjustmentScan;
    if (scan == null || scan.products.isEmpty) return false;
    return scan.products.every((product) => product.counted);
  }

  AdjustmentTaskProduct? get _selectedAdjustmentProduct {
    final selectedId = _selectedAdjustmentItemId;
    final products = _adjustmentScan?.products;
    if (selectedId == null || products == null) return null;
    for (final product in products) {
      if (product.adjustmentItemId == selectedId) return product;
    }
    return null;
  }

  int? get _adjustmentEnteredQuantity =>
      _parseNonNegativeInt(_adjustmentQuantityController.text);

  bool _isCycleCountFlowComplete() {
    final task = widget.task;
    if (task.type != TaskType.cycleCount) return true;
    if (!_locationValidated) return false;
    if (_cycleCountPage != 0) return false;
    if (_cycleCountItems.isEmpty) return false;
    return _cycleCountItems
        .every((item) => item.completed && item.countedQuantity > 0);
  }

  int get _returnProcessedQuantity {
    var total = 0;
    for (final controller in _returnItemQuantityControllers) {
      total += _parsePositiveInt(controller.text) ?? 0;
    }
    return total;
  }

  String? get _lastReturnLocation {
    if (_returnItemLocationControllers.isEmpty) return null;
    return _returnItemLocationControllers.last.text.trim();
  }

  int get _fullShelfCountedQuantity {
    var total = 0;
    for (final controller in _cycleCountLineControllers) {
      total += _parsePositiveInt(controller.text) ?? 0;
    }
    total += _parsePositiveInt(_unexpectedItemQuantityController.text) ?? 0;
    return total;
  }

  int get _cycleCountTotalCountedQuantity {
    var total = 0;
    for (final item in _cycleCountItems) {
      total += item.countedQuantity;
    }
    return total;
  }

  int? _parsePositiveInt(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  int? _parseNonNegativeInt(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  void _updateRefillQuantity() {
    final parsed = int.tryParse(_quantityController.text.trim());
    final next = parsed == null || parsed <= 0 ? 0 : parsed;
    if (_refillQuantity != next) {
      setState(() => _refillQuantity = next);
    }
  }

  _ActiveValidationTarget get _activeValidationTarget {
    final task = widget.task;
    if (task.type == TaskType.cycleCount) {
      if (!_locationValidated) return _ActiveValidationTarget.location;
      if (_cycleCountPage == 1 && _cycleCountDetailOpenedManually) {
        return _ActiveValidationTarget.cycleCountDetailBarcode;
      }
      return _ActiveValidationTarget.none;
    }
    if (task.type == TaskType.receive) {
      return _itemValidated
          ? _ActiveValidationTarget.location
          : _ActiveValidationTarget.barcode;
    }
    if (task.type == TaskType.refill) {
      return _itemValidated
          ? _ActiveValidationTarget.location
          : _ActiveValidationTarget.barcode;
    }
    if (task.type == TaskType.returnTask) {
      return _returnPage == 0
          ? _ActiveValidationTarget.returnBarcode
          : _ActiveValidationTarget.none;
    }
    if (task.type == TaskType.adjustment) {
      return _ActiveValidationTarget.none;
    }
    final hasBarcode = (task.itemBarcode?.trim().isNotEmpty ?? false);
    if (!_itemValidated && hasBarcode) {
      return _ActiveValidationTarget.barcode;
    }
    return _ActiveValidationTarget.location;
  }

  String _normalizeProductBarcode(String value) {
    return value.replaceAll(RegExp(r'\D+'), '');
  }

  void _handleProductInputChanged(String value) {
    _productFailureClearTimer?.cancel();
    final normalized = _normalizeProductBarcode(value);
    if (normalized != value) {
      _productController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
      return;
    }
    if (_lastAutoValidatedProduct == normalized &&
        normalized.isNotEmpty &&
        _productValidationMessage != null) {
      return;
    }
    setState(() {
      if (_itemValidated ||
          _locationValidated ||
          _productValidationMessage != null ||
          _locationValidationMessage != null ||
          _receivePage != 0 ||
          _refillPage != 0) {
        _itemValidated = false;
        _locationValidated = false;
        _productValidationMessage = null;
        _locationValidationMessage = null;
        _completionMessage = null;
        if (widget.task.type == TaskType.receive) {
          _receivePage = 0;
        }
        if (widget.task.type == TaskType.refill) {
          _refillPage = 0;
          _locationController.clear();
        }
      }
    });
    if (normalized.isEmpty) {
      _lastAutoValidatedProduct = null;
      _productValidationDebounce?.cancel();
      return;
    }
    _scheduleProductFailureClear(normalized);
    _productValidationDebounce?.cancel();
    _productValidationDebounce = Timer(
      const Duration(milliseconds: 150),
      () {
        if (!mounted) return;
        if (_normalizeProductBarcode(_productController.text) != normalized) {
          return;
        }
        _validateProduct();
      },
    );
  }

  void _handleLocationInputChanged(String value) {
    _locationFailureClearTimer?.cancel();
    final normalized = value.trim().toUpperCase();
    final isRepeatedValidatedValue = _lastAutoValidatedLocation == normalized &&
        _locationValidationMessage != null;
    if (isRepeatedValidatedValue ||
        _locationValidationInFlightValue == normalized) {
      return;
    }
    setState(() {
      if (_locationValidated || _locationValidationMessage != null) {
        _locationValidated = false;
        _locationValidationMessage = null;
      }
    });
    if (normalized.isEmpty) {
      _lastAutoValidatedLocation = null;
      _locationValidationDebounce?.cancel();
      _locationValidationInFlightValue = null;
      return;
    }
    _scheduleLocationFailureClear(normalized);
    if (!_canAutoValidateLocation()) return;
    _locationValidationDebounce?.cancel();
    _locationValidationDebounce = Timer(
      const Duration(milliseconds: 150),
      () {
        if (!mounted) return;
        if (_locationController.text.trim().toUpperCase() != normalized) return;
        if (!_canAutoValidateLocation()) return;
        _validateLocation();
      },
    );
  }

  bool _canAutoValidateLocation() {
    if (_validating) return false;
    if ((widget.task.type == TaskType.receive ||
            widget.task.type == TaskType.refill) &&
        !_itemValidated) {
      return false;
    }
    return true;
  }

  String _normalizeReturnBarcode(String value) {
    return value.replaceAll(RegExp(r'[\r\n]+'), '').trim().toUpperCase();
  }

  void _handleReturnBarcodeInputChanged(String value) {
    if (_returnPage != 0) return;
    final normalized = _normalizeReturnBarcode(value);
    if (normalized.isEmpty) {
      _returnValidationDebounce?.cancel();
      return;
    }

    _returnValidationDebounce?.cancel();
    if (value.contains('\n') || value.contains('\r')) {
      _submitReturnBarcodeScan(normalized);
      return;
    }

    _returnValidationDebounce = Timer(
      const Duration(milliseconds: 150),
      () => _submitReturnBarcodeScan(
        _normalizeReturnBarcode(_returnScanController.text),
      ),
    );
  }

  void _submitReturnBarcodeScan(String normalized) {
    if (!mounted) return;
    _returnValidationDebounce?.cancel();
    _returnScanController.clear();
    if (widget.task.type != TaskType.returnTask ||
        _returnPage != 0 ||
        normalized.isEmpty) {
      return;
    }

    for (var index = 0; index < widget.task.returnItems.length; index++) {
      if (_returnItemValidated[index]) continue;
      final expected = _normalizeReturnBarcode(
        widget.task.returnItems[index].barcode ?? '',
      );
      if (expected != normalized) continue;
      setState(() {
        _returnItemValidated[index] = true;
        _completionMessage = null;
      });
      _playScanFeedback(isSuccess: true);
      _restoreActiveValidationFocus();
      return;
    }

    setState(() {
      _completionMessage = _tr(
        'Scanned item is not in this return list.',
        'الصنف الممسوح غير موجود في قائمة المرتجعات هذه.',
      );
    });
    _playScanFeedback(isSuccess: false);
    _restoreActiveValidationFocus();
  }

  void _restoreActiveValidationFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (_activeValidationTarget) {
        case _ActiveValidationTarget.barcode:
          _ensureScannerFocus(_productScanFocusNode);
          break;
        case _ActiveValidationTarget.location:
          _ensureScannerFocus(_locationScanFocusNode);
          break;
        case _ActiveValidationTarget.returnBarcode:
          _ensureScannerFocus(_returnScanFocusNode);
          break;
        case _ActiveValidationTarget.cycleCountDetailBarcode:
          _ensureScannerFocus(_cycleCountDetailBarcodeFocusNode);
          break;
        case _ActiveValidationTarget.none:
          break;
      }
    });
  }

  void _requestScannerFocus(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
    focusNode.requestFocus();
    focusNode.consumeKeyboardToken();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _ensureScannerFocus(FocusNode focusNode) {
    _scannerFocusRetryTimer?.cancel();
    var retriesLeft = focusNode.hasFocus ? 0 : _scannerFocusRetryCount;
    _requestScannerFocus(focusNode);
    _scannerFocusRetryTimer =
        Timer.periodic(_scannerFocusRetryDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (focusNode.hasFocus || retriesLeft <= 0) {
        timer.cancel();
        return;
      }
      retriesLeft -= 1;
      _requestScannerFocus(focusNode);
    });
  }

  Future<void> _openManualBarcodeDialog() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _ManualBarcodeKeypadDialog(
        initialValue: _productController.text,
      ),
    );
    if (!mounted || value == null) {
      _restoreActiveValidationFocus();
      return;
    }
    _productController.text = value;
    _handleProductInputChanged(value);
    _restoreActiveValidationFocus();
  }

  Future<void> _openReportTaskDialog() async {
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => _TaskReportDialog(
        onSubmit: ({
          required note,
          String? photoPath,
        }) =>
            widget.onReportTaskIssue!(
          note: note,
          photoPath: photoPath,
        ),
        onCapturePhoto: widget.onCaptureReportPhoto,
      ),
    );
    if (!mounted || submitted != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tr(
            'Problem report sent successfully.',
            'تم إرسال البلاغ بنجاح.',
          ),
        ),
      ),
    );
  }

  Future<void> _openReturnManualBarcodeDialog() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _ManualBarcodeKeypadDialog(
        initialValue: _returnScanController.text,
      ),
    );
    if (!mounted || value == null) {
      _restoreActiveValidationFocus();
      return;
    }
    _returnScanController.text = value;
    _handleReturnBarcodeInputChanged(value);
    _restoreActiveValidationFocus();
  }

  Future<void> _openManualLocationDialog() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _ManualLocationEntryDialog(
        initialValue: _locationController.text,
      ),
    );
    if (!mounted || value == null) {
      _restoreActiveValidationFocus();
      return;
    }
    _locationController.text = value;
    _handleLocationInputChanged(value);
    _restoreActiveValidationFocus();
  }

  Future<void> _openCycleCountManualBarcodeDialog() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _ManualBarcodeKeypadDialog(
        initialValue: _cycleCountDetailBarcodeController.text,
      ),
    );
    if (!mounted || value == null) {
      _restoreActiveValidationFocus();
      return;
    }
    _cycleCountDetailBarcodeController.text = value;
    _handleCycleCountDetailBarcodeChanged(value);
    _restoreActiveValidationFocus();
  }

  void _validateProduct() {
    final l10n = context.l10n;
    final effectiveTask = _effectiveTask;
    final expected = _normalizeProductBarcode(widget.task.itemBarcode ?? '');
    final scanned = _normalizeProductBarcode(_productController.text);
    final isValid = scanned == expected;
    final canAdvanceProductFlow = effectiveTask.status == TaskStatus.inProgress;
    final usePendingRightProductMessage = isValid &&
        !canAdvanceProductFlow &&
        (widget.task.type == TaskType.receive ||
            widget.task.type == TaskType.refill);
    setState(() {
      _productValidationMessage = usePendingRightProductMessage
          ? _pendingTaskRightProductMessage
          : isValid
              ? l10n.workerProductValidated
              : l10n.workerProductMismatch;
      _lastAutoValidatedProduct = scanned.isEmpty ? null : scanned;
      if (widget.task.type == TaskType.receive) {
        _itemValidated = isValid;
        _locationValidated = false;
        _locationValidationMessage = null;
        _receivePage = isValid && canAdvanceProductFlow ? 1 : 0;
      } else if (widget.task.type == TaskType.refill) {
        _itemValidated = isValid;
        _locationValidated = false;
        _locationValidationMessage = null;
        _completionMessage = null;
        _locationController.clear();
        _refillPage = isValid && canAdvanceProductFlow ? 1 : 0;
      } else if (widget.task.type == TaskType.returnTask ||
          widget.task.isSingleItemCycleCount) {
        _itemValidated = isValid;
      }
    });
    _playScanFeedback(isSuccess: isValid);
    if (!isValid && scanned.isNotEmpty) {
      _scheduleProductFailureClear(scanned);
    }
    _restoreActiveValidationFocus();
  }

  void _validateReturnTote() {
    final expected = widget.task.returnContainerId?.trim().toUpperCase() ?? '';
    final scanned = _returnToteController.text.trim().toUpperCase();
    setState(() {
      _returnToteValidated = scanned.isNotEmpty && scanned == expected;
      _completionMessage = _returnToteValidated ? null : _completionMessage;
    });
  }

  Future<void> _scanReturnItem(int index) async {
    if (index < 0 || index >= _returnItemValidated.length) return;
    final expected =
        widget.task.returnItems[index].barcode?.trim().toUpperCase() ?? '';
    final scanned = await showItemLookupScanDialog(
      context,
      title: _tr('Scan item barcode', 'امسح باركود الصنف'),
      hintText: _tr(
        'Scan or enter item barcode',
        'امسح أو أدخل باركود الصنف',
      ),
      showKeyboard: false,
    );
    if (!mounted || scanned == null) return;
    setState(() {
      _returnItemValidated[index] = scanned.trim().toUpperCase() == expected;
    });
  }

  void _advanceReturnPage() {
    if (!_isReturnValidationComplete()) return;
    setState(() {
      _returnPage = 1;
      _completionMessage = null;
    });
  }

  Future<void> _scanReturnItemLocation(int index) async {
    if (index < 0 || index >= widget.task.returnItems.length) return;
    final scanned = await showItemLookupScanDialog(
      context,
      title: _tr('Scan return location', 'امسح موقع المرتجع'),
      hintText: _tr(
        'Scan or enter return location',
        'امسح أو أدخل موقع المرتجع',
      ),
      showKeyboard: false,
    );
    if (!mounted || scanned == null) return;
    final expected =
        (widget.task.returnItems[index].location ?? '').trim().toUpperCase();
    setState(() {
      _returnItemLocationControllers[index].text = scanned.trim();
      _returnItemLocationValidated[index] =
          scanned.trim().isNotEmpty && scanned.trim().toUpperCase() == expected;
    });
  }

  Future<void> _loadSuggestion() async {
    final fetcher = widget.onGetSuggestion;
    if (fetcher == null) return;
    final l10n = context.l10n;
    setState(() {
      _suggesting = true;
      _locationValidationMessage = null;
    });
    try {
      final suggestion = await fetcher();
      if (!mounted) return;
      setState(() {
        _suggestedLocation = suggestion;
        if (suggestion == null) {
          _locationValidationMessage = l10n.workerLocationMismatch;
        }
      });
      if (suggestion != null) {
        _locationController.text = suggestion;
        _handleLocationInputChanged(suggestion);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestedLocation = null;
          _locationValidationMessage = l10n.workerLocationMismatch;
        });
      }
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  Future<void> _validateLocation() async {
    final l10n = context.l10n;
    if (widget.task.type == TaskType.receive && !_itemValidated) return;
    if (widget.task.type == TaskType.refill && !_itemValidated) return;
    final scanned = _locationController.text.trim().toUpperCase();
    if (scanned.isEmpty) return;
    final expected = ((widget.task.type == TaskType.refill
                ? _refillShelfLocation
                : widget.task.toLocation ?? widget.task.fromLocation) ??
            '')
        .trim()
        .toUpperCase();
    if (widget.task.type == TaskType.refill) {
      final isValid = scanned == expected;
      _applyLocationValidationResult(l10n, scanned: scanned, isValid: isValid);
      if (isValid) {
        _restoreCycleCountScannerFocus();
      }
      _restoreActiveValidationFocus();
      return;
    }
    if (widget.task.isPutawayTask) {
      final isValid = scanned == expected;
      _applyLocationValidationResult(l10n, scanned: scanned, isValid: isValid);
      if (isValid) {
        _restoreCycleCountScannerFocus();
      }
      _restoreActiveValidationFocus();
      return;
    }
    if (widget.onValidateLocation == null) {
      final isValid = scanned == expected;
      _applyLocationValidationResult(l10n, scanned: scanned, isValid: isValid);
      if (isValid) {
        _restoreCycleCountScannerFocus();
      }
      _restoreActiveValidationFocus();
      return;
    }

    _locationValidationInFlightValue = scanned;
    setState(() => _validating = true);
    try {
      final response = await widget.onValidateLocation!(scanned);
      if (!mounted) return;
      final valid = _extractValidationResult(response);
      final isValid = valid ?? (scanned == expected);
      _applyLocationValidationResult(l10n, scanned: scanned, isValid: isValid);
      if (isValid) {
        _restoreCycleCountScannerFocus();
      }
    } catch (_) {
      if (!mounted) return;
      final isValid = scanned == expected;
      _applyLocationValidationResult(l10n, scanned: scanned, isValid: isValid);
      if (isValid) {
        _restoreCycleCountScannerFocus();
      }
    } finally {
      _locationValidationInFlightValue = null;
      if (mounted) setState(() => _validating = false);
      if (mounted && _locationController.text.trim().toUpperCase() != scanned) {
        _handleLocationInputChanged(_locationController.text);
      }
      _restoreActiveValidationFocus();
    }
  }

  void _applyLocationValidationResult(
    AppLocalizations l10n, {
    required String scanned,
    required bool isValid,
  }) {
    setState(() {
      _locationValidationMessage =
          isValid ? l10n.workerLocationValidated : l10n.workerLocationMismatch;
      if (widget.task.type == TaskType.receive ||
          widget.task.type == TaskType.refill ||
          widget.task.type == TaskType.returnTask ||
          widget.task.type == TaskType.cycleCount) {
        _locationValidated = isValid;
      }
      _lastAutoValidatedLocation = scanned;
    });
    _playScanFeedback(isSuccess: isValid);
    if (!isValid && scanned.isNotEmpty) {
      _scheduleLocationFailureClear(scanned);
    }
  }

  void _playScanFeedback({required bool isSuccess}) {
    if (isSuccess) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
      return;
    }
    HapticFeedback.vibrate();
    SystemSound.play(SystemSoundType.alert);
  }

  void _scheduleProductFailureClear(String scanned) {
    _productFailureClearTimer?.cancel();
    _productFailureClearTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_normalizeProductBarcode(_productController.text) != scanned) return;
      setState(() {
        _productController.clear();
        _lastAutoValidatedProduct = null;
      });
      _restoreActiveValidationFocus();
    });
  }

  void _scheduleLocationFailureClear(String scanned) {
    _locationFailureClearTimer?.cancel();
    _locationFailureClearTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_locationController.text.trim().toUpperCase() != scanned) return;
      setState(() {
        _locationController.clear();
        _lastAutoValidatedLocation = null;
      });
      _restoreActiveValidationFocus();
    });
  }

  bool? _extractValidationResult(Map<String, dynamic> response) {
    final value = response['valid'] ??
        response['isValid'] ??
        response['is_valid'] ??
        response['validLocation'];
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() != 0;
    if (value is String) {
      final lowered = value.toLowerCase();
      if (lowered == 'true' || lowered == 'yes' || lowered == '1') return true;
      if (lowered == 'false' || lowered == 'no' || lowered == '0') return false;
    }
    return null;
  }

  Future<void> _loadRefillLookup() async {
    final lookup = widget.onLookupItem;
    final barcode = widget.task.itemBarcode?.trim() ?? '';
    if (lookup == null || barcode.isEmpty) {
      _finishRefillLookupWithFallback();
      return;
    }

    setState(() {
      _refillLookupLoading = true;
      _refillLookupError = null;
      _refillSummary = null;
      _itemValidated = false;
      _locationValidated = false;
      _productValidationMessage = null;
      _locationValidationMessage = null;
      _completionMessage = null;
      _refillPage = 0;
      _bulkLocationController.clear();
      _locationController.clear();
      _quantityController.clear();
      _refillQuantity = 0;
    });

    try {
      final summary = await lookup(barcode);
      final bulk = _firstBulkLocation(summary);
      final shelf = _firstShelfLocation(summary);
      if (bulk == null || shelf == null) {
        _finishRefillLookupWithFallback(summary: summary);
        return;
      }
      setState(() {
        _refillLookupLoading = false;
        _refillSummary = summary;
        _bulkLocationController.text = bulk;
      });
    } catch (_) {
      _finishRefillLookupWithFallback();
    }
  }

  void _finishRefillLookupWithFallback({ItemLocationSummaryEntity? summary}) {
    final fallbackBulk = widget.task.fromLocation?.trim();
    final fallbackShelf = widget.task.toLocation?.trim();
    final hasFallbackBulk = fallbackBulk != null && fallbackBulk.isNotEmpty;
    final hasFallbackShelf = fallbackShelf != null && fallbackShelf.isNotEmpty;

    setState(() {
      _refillLookupLoading = false;
      _refillSummary = summary;
      if (hasFallbackBulk) {
        _bulkLocationController.text = fallbackBulk;
      }
      _refillLookupError = hasFallbackBulk && hasFallbackShelf
          ? null
          : _tr(
              'Could not load refill locations.',
              'تعذر تحميل مواقع إعادة التعبئة.',
            );
    });
  }

  String? _resolvedRefillImageUrl(TaskEntity task) {
    final lookupImage = _refillSummary?.itemImageUrl?.trim();
    if (lookupImage != null && lookupImage.isNotEmpty) {
      return lookupImage;
    }
    final taskImage = task.itemImageUrl?.trim();
    if (taskImage != null && taskImage.isNotEmpty) {
      return taskImage;
    }
    return null;
  }

  String? get _refillBulkLocation => _firstBulkLocation(_refillSummary);

  String? get _refillShelfLocation => _firstShelfLocation(_refillSummary);

  String? _firstBulkLocation(ItemLocationSummaryEntity? summary) {
    if (summary != null && summary.bulkLocations.isNotEmpty) {
      return summary.bulkLocations.first.code;
    }
    final fallback = widget.task.fromLocation?.trim();
    if (fallback == null || fallback.isEmpty) return null;
    return fallback;
  }

  String? _firstShelfLocation(ItemLocationSummaryEntity? summary) {
    if (summary != null && summary.shelfLocations.isNotEmpty) {
      return summary.shelfLocations.first.code;
    }
    final fallback = widget.task.toLocation?.trim();
    if (fallback == null || fallback.isEmpty) return null;
    return fallback;
  }

}

class _TaskHeroCard extends StatelessWidget {
  const _TaskHeroCard({
    required this.task,
    required this.typeColor,
    required this.statusColor,
    required this.fromType,
    required this.toType,
  });

  final TaskEntity task;
  final Color typeColor;
  final Color statusColor;
  final String fromType;
  final String toType;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: typeColor.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(
                icon: Icons.category_outlined,
                label: taskTypeLabelForContext(
                  context,
                  task.type,
                  isPutaway: task.isPutawayTask,
                ),
                color: typeColor,
              ),
              _MiniBadge(
                icon: Icons.timer_outlined,
                label: taskStatusLabelForContext(context, task.status),
                color: statusColor,
              ),
              _MiniBadge(
                icon: Icons.move_up_rounded,
                label: '$fromType → $toType',
                color: AppTheme.accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                key: const Key('task-hero-quantity-summary'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.surfaceAlt.withValues(alpha: 0.95),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.numbers_rounded,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.workerQuantity,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          task.formatQuantity(task.quantity),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                task.itemBarcode?.isEmpty == true ? '' : '#${task.id}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiveHeroCard extends StatelessWidget {
  const _ReceiveHeroCard({
    required this.itemName,
    required this.barcode,
    required this.itemImageUrl,
    required this.quantityLabel,
  });

  final String itemName;
  final String barcode;
  final String? itemImageUrl;
  final String quantityLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = context.isArabicLocale;

    return Card(
      key: const Key('receive-hero-card'),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.10),
                theme.colorScheme.secondary.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _ImagePanel(
                key: const Key('receive-item-image'),
                hasImage:
                    itemImageUrl != null && itemImageUrl!.trim().isNotEmpty,
                imageUrl: itemImageUrl,
                height: 116,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              Text(
                itemName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                key: const Key('receive-barcode-pill'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  barcode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                key: const Key('receive-quantity-card'),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'إجمالي الكمية' : 'Total Quantity',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quantityLabel,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.accentColor,
    this.showHeader = true,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color accentColor;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceAlt),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: accentColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    super.key,
    required this.hasImage,
    required this.imageUrl,
    this.height = 184,
    this.fit = BoxFit.cover,
  });

  final bool hasImage;
  final String? imageUrl;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.surfaceAlt.withValues(alpha: 0.45),
        border: Border.all(color: AppTheme.surfaceAlt),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 36,
          color: AppTheme.textMuted,
        ),
      ),
    );

    if (!hasImage) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl!,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, _, __) => placeholder,
      ),
    );
  }
}

class _CycleCountItemState {
  const _CycleCountItemState({
    required this.key,
    required this.itemName,
    required this.barcode,
    required this.expectedQuantity,
    this.countedQuantity = 0,
    this.completed = false,
    this.imageUrl,
    this.unit,
  });

  final String key;
  final String itemName;
  final String barcode;
  final int expectedQuantity;
  final int countedQuantity;
  final bool completed;
  final String? imageUrl;
  final String? unit;

  String get quantityUnit => unit?.trim().isNotEmpty == true ? unit!.trim() : 'pc';
  String formatQuantity(int value) => '$value $quantityUnit';

  _CycleCountItemState copyWith({
    int? countedQuantity,
    bool? completed,
  }) {
    return _CycleCountItemState(
      key: key,
      itemName: itemName,
      barcode: barcode,
      expectedQuantity: expectedQuantity,
      countedQuantity: countedQuantity ?? this.countedQuantity,
      completed: completed ?? this.completed,
      imageUrl: imageUrl,
      unit: unit,
    );
  }
}

class _ReturnItemThumb extends StatelessWidget {
  const _ReturnItemThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceAlt),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 20,
        color: AppTheme.textMuted,
      ),
    );

    final trimmed = imageUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        trimmed,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String? value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  (value == null || value!.isEmpty) ? '-' : value!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ActiveValidationTarget {
  none,
  barcode,
  location,
  returnBarcode,
  cycleCountDetailBarcode,
}

class _TaskReportDialog extends StatefulWidget {
  const _TaskReportDialog({
    required this.onSubmit,
    this.onCapturePhoto,
  });

  final Future<void> Function({
    required String note,
    String? photoPath,
  }) onSubmit;
  final Future<TaskReportPhotoAttachment?> Function()? onCapturePhoto;

  @override
  State<_TaskReportDialog> createState() => _TaskReportDialogState();
}

class _TaskReportDialogState extends State<_TaskReportDialog> {
  late final TextEditingController _noteController;
  TaskReportPhotoAttachment? _photo;
  String? _errorMessage;
  bool _capturingPhoto = false;
  bool _submitting = false;

  bool get _canSubmit => !_submitting && _noteController.text.trim().isNotEmpty;

  String _tr(String english, String arabic) =>
      context.isArabicLocale ? arabic : english;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController()..addListener(_handleNoteChanged);
  }

  @override
  void dispose() {
    _noteController
      ..removeListener(_handleNoteChanged)
      ..dispose();
    super.dispose();
  }

  void _handleNoteChanged() {
    setState(() {});
  }

  String _messageForError(Object error) {
    return switch (error) {
      AppException(message: final message) when message.trim().isNotEmpty =>
        message,
      _ => _tr(
          'Failed to send the problem report. Please try again.',
          'فشل إرسال البلاغ. حاول مرة أخرى.',
        ),
    };
  }

  Future<void> _capturePhoto() async {
    if (widget.onCapturePhoto == null || _capturingPhoto || _submitting) {
      return;
    }

    setState(() {
      _capturingPhoto = true;
      _errorMessage = null;
    });
    try {
      final photo = await widget.onCapturePhoto!.call();
      if (!mounted || photo == null) {
        return;
      }
      setState(() => _photo = photo);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageForError(error));
    } finally {
      if (mounted) {
        setState(() => _capturingPhoto = false);
      }
    }
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (note.isEmpty || _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await widget.onSubmit(
        note: note,
        photoPath: _photo?.path,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageForError(error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = context.isArabicLocale;

    return AlertDialog(
      key: const Key('report-task-dialog'),
      title: Text(_tr('Report Problem', 'الإبلاغ عن مشكلة')),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr(
                  'Describe the issue so the team can review this task.',
                  'صف المشكلة حتى يتمكن الفريق من مراجعة هذه المهمة.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('report-task-note-field'),
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: _tr('Note', 'ملاحظة'),
                  hintText: _tr(
                    'Write what went wrong',
                    'اكتب ما حدث',
                  ),
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.edit_note_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('report-task-photo-button'),
                  onPressed: widget.onCapturePhoto == null ||
                          _capturingPhoto ||
                          _submitting
                      ? null
                      : _capturePhoto,
                  icon: _capturingPhoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _photo == null
                              ? Icons.photo_camera_outlined
                              : Icons.cameraswitch_outlined,
                        ),
                  label: Text(
                    _capturingPhoto
                        ? _tr('Opening camera...', 'جارٍ فتح الكاميرا...')
                        : _photo == null
                            ? _tr('Take Photo', 'التقاط صورة')
                            : _tr('Retake Photo', 'إعادة التقاط الصورة'),
                  ),
                ),
              ),
              if (_photo != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image(
                    key: const Key('report-task-photo-preview'),
                    image: MemoryImage(_photo!.bytes),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    key: const Key('report-task-remove-photo-button'),
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _photo = null),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(_tr('Remove Photo', 'إزالة الصورة')),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                _ValidationMessage(
                  key: const Key('report-task-error-message'),
                  message: _errorMessage!,
                  isPositive: false,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(false),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          key: const Key('report-task-submit-button'),
          onPressed: _canSubmit ? _submit : null,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_tr('Submit Report', 'إرسال البلاغ')),
        ),
      ],
    );
  }
}

class _ManualBarcodeKeypadDialog extends StatefulWidget {
  const _ManualBarcodeKeypadDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_ManualBarcodeKeypadDialog> createState() =>
      _ManualBarcodeKeypadDialogState();
}

class _ManualBarcodeKeypadDialogState
    extends State<_ManualBarcodeKeypadDialog> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.replaceAll(RegExp(r'\D+'), '');
  }

  void _appendDigit(String digit) {
    setState(() => _value = '$_value$digit');
  }

  void _deleteDigit() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabicLocale;
    const digits = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('manual-barcode-dialog'),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      title: Text(isArabic ? 'إدخال يدوي' : 'Manual Type'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.08),
                      AppTheme.accent.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.surfaceAlt),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'الباركود' : 'Barcode',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _value.isEmpty
                          ? (isArabic
                              ? 'أدخل أرقام الباركود'
                              : 'Enter barcode digits')
                          : _value,
                      textAlign: TextAlign.left,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isArabic
                    ? 'أدخل أرقام الباركود يدويًا إذا لم يستجب الماسح.'
                    : 'Type the barcode digits manually if the scanner does not respond.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                key: const Key('manual-barcode-grid'),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.28,
                children: [
                  for (final digit in digits)
                    _BarcodeKeyButton(
                      key: Key('manual-barcode-digit-$digit'),
                      label: digit,
                      onPressed: () => _appendDigit(digit),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _BarcodeKeyButton(
                      key: const Key('manual-barcode-delete'),
                      label: isArabic ? 'حذف' : 'Del',
                      onPressed: _deleteDigit,
                      backgroundColor: AppTheme.surfaceAlt,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BarcodeKeyButton(
                      key: const Key('manual-barcode-digit-0'),
                      label: '0',
                      onPressed: () => _appendDigit('0'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        key: const Key('manual-barcode-submit'),
                        onPressed: _value.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(_value),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isArabic ? 'استخدام' : 'Use',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
      ],
    );
  }
}

class _ManualLocationEntryDialog extends StatefulWidget {
  const _ManualLocationEntryDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_ManualLocationEntryDialog> createState() =>
      _ManualLocationEntryDialogState();
}

class _ManualLocationEntryDialogState
    extends State<_ManualLocationEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabicLocale;
    return AlertDialog(
      key: const Key('manual-location-dialog'),
      title: Text(isArabic ? 'إدخال يدوي' : 'Manual Type'),
      content: TextField(
        key: const Key('manual-location-dialog-field'),
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: isArabic ? 'الموقع' : 'Location',
          prefixIcon: const Icon(Icons.location_on_outlined),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          key: const Key('manual-location-submit'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(isArabic ? 'استخدام الموقع' : 'Use Location'),
        ),
      ],
    );
  }
}

class _BarcodeKeyButton extends StatelessWidget {
  const _BarcodeKeyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: foregroundColor ?? AppTheme.primary,
          elevation: 0,
          side: BorderSide(
            color: (backgroundColor ?? Colors.white) == Colors.white
                ? AppTheme.primary.withValues(alpha: 0.18)
                : AppTheme.surfaceAlt,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ValidationMessage extends StatelessWidget {
  const _ValidationMessage({
    super.key,
    required this.message,
    required this.isPositive,
    this.supportingText,
  });

  final String message;
  final bool isPositive;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isPositive ? AppTheme.success : AppTheme.error;
    final backgroundColor = color.withValues(alpha: 0.08);
    final borderColor = color.withValues(alpha: 0.18);
    final iconBackgroundColor = color.withValues(alpha: 0.14);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPositive ? Icons.check_circle_rounded : Icons.error_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  if (supportingText != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      supportingText!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
