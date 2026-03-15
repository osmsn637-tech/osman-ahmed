import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/l10n/l10n.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/adjustment_task_entities.dart';
import '../../../move/domain/entities/item_location_summary_entity.dart';
import '../../../move/presentation/pages/item_lookup_scan_dialog.dart';
import '../../domain/entities/task_entity.dart';
import '../shared/dashboard_common_widgets.dart';
import '../shared/location_format.dart';
import '../shared/task_visuals.dart';

class WorkerTaskDetailsPage extends StatefulWidget {
  const WorkerTaskDetailsPage({
    super.key,
    required this.task,
    this.onStartTask,
    this.onCompleteTask,
    this.onSaveCycleCountProgress,
    this.onGetSuggestion,
    this.onScanAdjustmentLocation,
    this.onSubmitAdjustmentCount,
    this.onValidateLocation,
    this.onLookupItem,
  });

  final TaskEntity task;
  final Future<void> Function()? onStartTask;
  final Future<void> Function(
    int taskId, {
    int? quantity,
    String? locationId,
  })? onCompleteTask;
  final Future<void> Function(
    int taskId, {
    required Map<String, Object?> progress,
  })? onSaveCycleCountProgress;
  final Future<String?> Function()? onGetSuggestion;
  final Future<AdjustmentTaskLocationScan> Function(String barcode)?
      onScanAdjustmentLocation;
  final Future<void> Function({
    required String adjustmentItemId,
    required int actualQuantity,
    String? notes,
  })? onSubmitAdjustmentCount;
  final Future<Map<String, dynamic>> Function(String barcode)?
      onValidateLocation;
  final Future<ItemLocationSummaryEntity> Function(String barcode)?
      onLookupItem;

  @override
  State<WorkerTaskDetailsPage> createState() => _WorkerTaskDetailsPageState();
}

class _WorkerTaskDetailsPageState extends State<WorkerTaskDetailsPage> {
  late final TextEditingController _productController;
  late final TextEditingController _locationController;
  late final TextEditingController _bulkLocationController;
  late final TextEditingController _quantityController;
  late final TextEditingController _returnToteController;
  late final TextEditingController _returnQuantityController;
  late final TextEditingController _cycleCountScanController;
  late final TextEditingController _cycleCountDetailQuantityController;
  late final TextEditingController _cycleCountDetailBarcodeController;
  late final TextEditingController _adjustmentNoteController;
  late final TextEditingController _unexpectedItemNameController;
  late final TextEditingController _unexpectedItemQuantityController;
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
  int _adjustmentDelta = 0;
  String? _refillLookupError;
  String? _adjustmentErrorMessage;
  String? _cycleCountScanError;
  String? _selectedAdjustmentItemId;
  String? _selectedCycleCountItemKey;
  ItemLocationSummaryEntity? _refillSummary;
  AdjustmentTaskLocationScan? _adjustmentScan;
  _AdjustmentMode _adjustmentMode = _AdjustmentMode.decrease;
  late final List<_CycleCountItemState> _cycleCountItems;
  Timer? _cycleCountScanDebounce;
  final List<bool> _returnItemValidated = <bool>[];
  final List<bool> _returnItemLocationValidated = <bool>[];
  final List<TextEditingController> _returnItemLocationControllers =
      <TextEditingController>[];
  final List<TextEditingController> _returnItemQuantityControllers =
      <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _productController = TextEditingController();
    _locationController = TextEditingController(
      text: task.type == TaskType.receive ? '' : task.toLocation ?? '',
    );
    _bulkLocationController =
        TextEditingController(text: task.fromLocation ?? '');
    _quantityController = TextEditingController(text: task.quantity.toString());
    _returnToteController = TextEditingController();
    _returnQuantityController = TextEditingController();
    _cycleCountScanController = TextEditingController();
    _cycleCountDetailQuantityController = TextEditingController();
    _cycleCountDetailBarcodeController = TextEditingController();
    _adjustmentNoteController = TextEditingController();
    _unexpectedItemNameController = TextEditingController();
    _unexpectedItemQuantityController = TextEditingController();
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
      _restoreCycleCountScannerFocus();
    });
  }

  @override
  void dispose() {
    _productController.dispose();
    _locationController.dispose();
    _bulkLocationController.dispose();
    _quantityController.removeListener(_updateRefillQuantity);
    _quantityController.dispose();
    _returnToteController.dispose();
    _returnQuantityController.dispose();
    _cycleCountScanDebounce?.cancel();
    _cycleCountScanController.dispose();
    _cycleCountDetailQuantityController.dispose();
    _cycleCountDetailBarcodeController.dispose();
    _adjustmentNoteController.dispose();
    _unexpectedItemNameController.dispose();
    _unexpectedItemQuantityController.dispose();
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
    final refillQuantityDisplay = '$_refillQuantity/${task.quantity}';
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
                            ? 'Return'
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
                    TextField(
                      key: const Key('product-validate-field'),
                      controller: _productController,
                      decoration: InputDecoration(
                        labelText: l10n.workerScanOrEnterProductBarcode,
                        prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        key: const Key('validate-product-button'),
                        onPressed: hasBarcode ? _validateProduct : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: typeColor,
                          side: BorderSide(color: typeColor),
                        ),
                        child: Text(l10n.workerValidateProduct),
                      ),
                    ),
                    if (_productValidationMessage != null) ...[
                      const SizedBox(height: 10),
                      _ValidationMessage(
                        message: _productValidationMessage!,
                        isPositive: _productValidationMessage ==
                            l10n.workerProductValidated,
                      ),
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
                        DashboardTypeBadge(task.type),
                        const SizedBox(width: 8),
                        DashboardStatusBadge(task.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: l10n.workerTaskType,
                      value: taskTypeLabel(task.type),
                    ),
                    _InfoRow(
                      label: l10n.workerQuantity,
                      value: task.type == TaskType.refill
                          ? refillQuantityDisplay
                          : task.quantity.toString(),
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
          _refillLookupError ?? 'Could not load refill locations.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('refill-retry-button'),
          onPressed: _loadRefillLookup,
          child: const Text('Retry'),
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
          value: task.quantity.toString(),
        ),
        const SizedBox(height: 12),
        _LocationRow(
          label: 'From Bulk Location',
          value: _refillBulkLocation,
          icon: Icons.north_west_rounded,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('product-validate-field'),
          controller: _productController,
          onChanged: (_) {
            if (_itemValidated ||
                _locationValidated ||
                _productValidationMessage != null ||
                _locationValidationMessage != null ||
                _refillPage != 0) {
              setState(() {
                _itemValidated = false;
                _locationValidated = false;
                _productValidationMessage = null;
                _locationValidationMessage = null;
                _refillPage = 0;
              });
            }
          },
          decoration: const InputDecoration(
            labelText: 'Validate barcode',
            prefixIcon: Icon(Icons.qr_code_scanner_rounded),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('validate-product-button'),
            onPressed: hasBarcode ? _validateProduct : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: taskTypeColor(widget.task.type),
              side: BorderSide(color: taskTypeColor(widget.task.type)),
            ),
            child: Text(l10n.workerValidateProduct),
          ),
        ),
        if (_productValidationMessage != null) ...[
          const SizedBox(height: 10),
          _ValidationMessage(
            message: _productValidationMessage!,
            isPositive:
                _productValidationMessage == l10n.workerProductValidated,
          ),
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
          _ValidationMessage(
            message: _productValidationMessage!,
            isPositive:
                _productValidationMessage == l10n.workerProductValidated,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'Shelf Location',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        _LocationRow(
          label: 'To Shelf Location',
          value: _refillShelfLocation,
          icon: Icons.south_east_rounded,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('location-validate-field'),
          controller: _locationController,
          onChanged: (_) {
            if (_locationValidated || _locationValidationMessage != null) {
              setState(() {
                _locationValidated = false;
                _locationValidationMessage = null;
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'Validate shelf location',
            helperText:
                'Scan ${_refillShelfLocation ?? 'the shelf location'} to continue.',
            prefixIcon: const Icon(Icons.location_on_outlined),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('validate-location-button'),
            onPressed:
                (!_itemValidated || _validating) ? null : _validateLocation,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: const BorderSide(color: AppTheme.accent),
            ),
            child: _validating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.workerValidateLocation),
          ),
        ),
        if (_locationValidationMessage != null) ...[
          const SizedBox(height: 10),
          _ValidationMessage(
            message: _locationValidationMessage!,
            isPositive:
                _locationValidationMessage == l10n.workerLocationValidated,
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          key: const Key('refill-quantity-field'),
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Enter quantity',
            hintText: 'Quantity to move',
            suffixText: 'max ${task.quantity}',
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
          quantity: task.quantity,
        ),
        const SizedBox(height: 12),
        const _LocationRow(
          label: 'From Inbound',
          value: 'Inbound',
          icon: Icons.north_west_rounded,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('product-validate-field'),
          controller: _productController,
          onChanged: (_) {
            if (_itemValidated ||
                _locationValidated ||
                _productValidationMessage != null ||
                _locationValidationMessage != null ||
                _receivePage != 0) {
              setState(() {
                _itemValidated = false;
                _locationValidated = false;
                _productValidationMessage = null;
                _locationValidationMessage = null;
                _receivePage = 0;
              });
            }
          },
          decoration: const InputDecoration(
            labelText: 'Validate barcode',
            prefixIcon: Icon(Icons.qr_code_scanner_rounded),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('validate-product-button'),
            onPressed: hasBarcode ? _validateProduct : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: taskTypeColor(widget.task.type),
              side: BorderSide(color: taskTypeColor(widget.task.type)),
            ),
            child: Text(l10n.workerValidateProduct),
          ),
        ),
        if (_productValidationMessage != null) ...[
          const SizedBox(height: 10),
          _ValidationMessage(
            message: _productValidationMessage!,
            isPositive:
                _productValidationMessage == l10n.workerProductValidated,
          ),
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
          _ValidationMessage(
            message: _productValidationMessage!,
            isPositive:
                _productValidationMessage == l10n.workerProductValidated,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'Bulk Location',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        _LocationRow(
          label: 'To Bulk Location',
          value: task.toLocation,
          icon: Icons.south_east_rounded,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('location-validate-field'),
          controller: _locationController,
          onChanged: (_) {
            if (_locationValidated || _locationValidationMessage != null) {
              setState(() {
                _locationValidated = false;
                _locationValidationMessage = null;
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'Validate bulk location',
            helperText:
                'Scan ${widget.task.toLocation ?? 'the bulk location'} to complete.',
            prefixIcon: const Icon(Icons.location_on_outlined),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('validate-location-button'),
            onPressed:
                (!_itemValidated || _validating) ? null : _validateLocation,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: const BorderSide(color: AppTheme.accent),
            ),
            child: _validating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.workerValidateLocation),
          ),
        ),
        if (_locationValidationMessage != null) ...[
          const SizedBox(height: 10),
          _ValidationMessage(
            message: _locationValidationMessage!,
            isPositive:
                _locationValidationMessage == l10n.workerLocationValidated,
          ),
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
          label: 'Return Tote',
          value: task.returnContainerId,
          icon: Icons.inventory_rounded,
        ),
        const SizedBox(height: 16),
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
          'Return Items',
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
            width: 36,
            child: Text(
              '${item.quantity}',
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
                        ? 'Scan return location'
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
              labelText: 'Returned Quantity',
              suffixText: 'max ${item.quantity}',
              prefixIcon: const Icon(Icons.format_list_numbered_rounded),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (validated)
            const _ValidationMessage(
              message: 'Location validated',
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
          'Adjustment',
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
                      : 'Scan a location to load products',
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
            'Products at ${scan.locationCode}',
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
    final previewActive = selected && _adjustmentDelta > 0;
    final previewQuantity =
        previewActive ? _adjustmentPreviewQuantity : product.systemQuantity;
    final modeLabel =
        _adjustmentMode == _AdjustmentMode.decrease ? 'Decrease' : 'Increase';

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
                    product.counted ? 'Counted' : 'Pending',
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
              'Current: ${product.systemQuantity}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (previewActive) ...[
              const SizedBox(height: 4),
              Text(
                '$modeLabel by $_adjustmentDelta -> $previewQuantity',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _adjustmentMode == _AdjustmentMode.decrease
                          ? AppTheme.warning
                          : AppTheme.success,
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
    final previewQuantity = _adjustmentPreviewQuantity;
    final canIncreaseDelta = _adjustmentMode == _AdjustmentMode.increase ||
        _adjustmentDelta < product.systemQuantity;

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
            'Adjust ${product.productName}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                key: const Key('adjustment-mode-decrease'),
                label: const Text('Decrease'),
                selected: _adjustmentMode == _AdjustmentMode.decrease,
                onSelected: (_) => _setAdjustmentMode(_AdjustmentMode.decrease),
              ),
              ChoiceChip(
                key: const Key('adjustment-mode-increase'),
                label: const Text('Increase'),
                selected: _adjustmentMode == _AdjustmentMode.increase,
                onSelected: (_) => _setAdjustmentMode(_AdjustmentMode.increase),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                key: const Key('adjustment-delta-decrement'),
                onPressed:
                    _adjustmentDelta > 0 ? _decrementAdjustmentDelta : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_adjustmentDelta',
                    key: const Key('adjustment-delta-value'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('adjustment-delta-increment'),
                onPressed: canIncreaseDelta ? _incrementAdjustmentDelta : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current: ${product.systemQuantity}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Change: ${_adjustmentMode == _AdjustmentMode.decrease ? '-' : '+'}$_adjustmentDelta',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'New: $previewQuantity',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('adjustment-note-field'),
            controller: _adjustmentNoteController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Add note for this adjustment',
            ),
            onChanged: (_) {
              if (_adjustmentErrorMessage != null) {
                setState(() => _adjustmentErrorMessage = null);
              }
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('adjustment-submit-button'),
              onPressed: _submittingAdjustment || _adjustmentDelta <= 0
                  ? null
                  : _submitAdjustmentChange,
              child: Text(
                _submittingAdjustment ? 'Submitting...' : 'Submit Adjustment',
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

  Widget _buildCycleCountListPage(BuildContext context, TaskEntity task) {
    final typeColor = taskTypeColor(task.type);
    final counted = _cycleCountItems.where((item) => item.completed).length;
    final total = _cycleCountItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cycle Count',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        _LocationRow(
          label: 'Count Location',
          value: task.toLocation,
          icon: Icons.grid_view_rounded,
        ),
        _buildCycleCountHiddenScanField(),
        const SizedBox(height: 12),
        TextField(
          key: const Key('location-validate-field'),
          controller: _locationController,
          onChanged: (_) {
            if (_locationValidated || _locationValidationMessage != null) {
              setState(() {
                _locationValidated = false;
                _locationValidationMessage = null;
              });
            }
          },
          decoration: const InputDecoration(
            labelText: 'Scan count location',
            prefixIcon: Icon(Icons.location_on_outlined),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('validate-location-button'),
            onPressed: _validating ? null : _validateLocation,
            style: OutlinedButton.styleFrom(
              foregroundColor: typeColor,
              side: BorderSide(color: typeColor),
            ),
            child: const Text('Validate Location'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Counted Items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Text(
              '$counted of $total counted',
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
                    : const Text('Continue later'),
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
                      ? '${item.countedQuantity} counted'
                      : 'Pending',
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
                'Count Item',
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
          label: 'Shelf Location',
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
          TextField(
            key: const Key('cycle-count-detail-barcode-field'),
            controller: _cycleCountDetailBarcodeController,
            focusNode: _cycleCountDetailBarcodeFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Type barcode manually',
              prefixIcon: Icon(Icons.qr_code_rounded),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: const Key('cycle-count-detail-quantity-field'),
          controller: _cycleCountDetailQuantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Shelf Quantity',
            prefixIcon: Icon(Icons.fact_check_outlined),
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
                : const Text('Confirm quantity'),
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
          _startErrorMessage = 'Failed to start task. Please try again.';
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
      _locationValidationMessage = 'Location validated';
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
      _cycleCountScanFocusNode.requestFocus();
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
    _cycleCountDetailBarcodeController.clear();
    _cycleCountScanDebounce?.cancel();
    _cycleCountScanController.clear();
    setState(() {
      _selectedCycleCountItemKey = selectedItem.key;
      _cycleCountPage = 1;
      _cycleCountDetailOpenedManually = openedManually;
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
    setState(() {
      _cycleCountPage = 0;
      _selectedCycleCountItemKey = null;
      _cycleCountDetailOpenedManually = false;
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

  void _submitCycleCountScan(String normalized) {
    if (!mounted) return;
    _cycleCountScanDebounce?.cancel();
    _cycleCountScanController.clear();
    if (!_locationValidated || normalized.isEmpty || _cycleCountPage != 0) {
      return;
    }

    for (final item in _cycleCountItems) {
      if (item.barcode.trim().toUpperCase() == normalized) {
        _openCycleCountItem(item.key);
        return;
      }
    }

    setState(() {
      _cycleCountScanError = 'Scanned item is not in this cycle count list.';
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
    final manualBarcode = _normalizeCycleCountBarcode(
      _cycleCountDetailBarcodeController.text,
    );
    final expectedBarcode = _normalizeCycleCountBarcode(item.barcode);
    if (manualBarcode.isNotEmpty &&
        expectedBarcode.isNotEmpty &&
        manualBarcode != expectedBarcode) {
      setState(() {
        _completionMessage = 'Typed barcode does not match this item.';
      });
      return;
    }
    final quantity =
        _parsePositiveInt(_cycleCountDetailQuantityController.text);
    if (quantity == null) {
      setState(() {
        _completionMessage = 'Enter a valid counted quantity.';
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
      setState(() {
        _cycleCountPage = 0;
        _selectedCycleCountItemKey = null;
        _cycleCountDetailOpenedManually = false;
        _cycleCountDetailBarcodeController.clear();
      });
      _restoreCycleCountScannerFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _completionMessage = 'Failed to save cycle count progress.';
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
      await _saveCycleCountProgress();
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _completionMessage = 'Failed to save cycle count progress.';
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
      title: 'Scan adjustment location',
      hintText: 'Scan or enter location barcode',
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
        _adjustmentDelta = 0;
        _adjustmentMode = _AdjustmentMode.decrease;
        _adjustmentNoteController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _adjustmentErrorMessage =
            'Could not load adjustment products for this location.';
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
      _adjustmentDelta = 0;
      _adjustmentMode = _AdjustmentMode.decrease;
      _adjustmentNoteController.clear();
      _adjustmentErrorMessage = null;
    });
  }

  void _setAdjustmentMode(_AdjustmentMode mode) {
    final selected = _selectedAdjustmentProduct;
    setState(() {
      _adjustmentMode = mode;
      if (selected != null &&
          _adjustmentMode == _AdjustmentMode.decrease &&
          _adjustmentDelta > selected.systemQuantity) {
        _adjustmentDelta = selected.systemQuantity;
      }
      _adjustmentErrorMessage = null;
    });
  }

  void _incrementAdjustmentDelta() {
    final selected = _selectedAdjustmentProduct;
    if (selected == null) return;
    if (_adjustmentMode == _AdjustmentMode.decrease &&
        _adjustmentDelta >= selected.systemQuantity) {
      return;
    }
    setState(() {
      _adjustmentDelta += 1;
      _adjustmentErrorMessage = null;
    });
  }

  void _decrementAdjustmentDelta() {
    if (_adjustmentDelta <= 0) return;
    setState(() {
      _adjustmentDelta -= 1;
      _adjustmentErrorMessage = null;
    });
  }

  Future<void> _submitAdjustmentChange() async {
    final submitter = widget.onSubmitAdjustmentCount;
    final selected = _selectedAdjustmentProduct;
    if (submitter == null || selected == null || _submittingAdjustment) return;

    if (_adjustmentDelta <= 0) {
      setState(() {
        _adjustmentErrorMessage = 'Enter an adjustment quantity.';
      });
      return;
    }

    final actualQuantity = _adjustmentPreviewQuantity;
    if (actualQuantity < 0) {
      setState(() {
        _adjustmentErrorMessage =
            'Decrease amount cannot make quantity negative.';
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
        actualQuantity: actualQuantity,
        notes: _adjustmentNoteController.text.trim().isEmpty
            ? null
            : _adjustmentNoteController.text.trim(),
      );
      if (!mounted) return;
      final scan = _adjustmentScan;
      if (scan == null) return;
      final updatedProducts = scan.products
          .map(
            (product) => product.adjustmentItemId == selected.adjustmentItemId
                ? product.copyWith(
                    counted: true,
                    systemQuantity: actualQuantity,
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
        _adjustmentDelta = 0;
        _adjustmentNoteController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _adjustmentErrorMessage =
            'Failed to submit adjustment. Please try again.';
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
          setState(() => _completionMessage =
              'Enter quantity to move and confirm the shelf location before completing.');
          return;
        }
        await widget.onCompleteTask!(
          task.id,
          quantity: _refillQuantity,
          locationId: shelfLocation,
        );
      } else if (task.type == TaskType.returnTask) {
        if (!_isReturnFlowComplete()) {
          setState(() => _completionMessage =
              'Process every return item before completing.');
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
          setState(() => _completionMessage =
              'Finish the cycle count inputs before completing.');
          return;
        }
        await widget.onCompleteTask!(
          task.id,
          quantity: _cycleCountTotalCountedQuantity,
          locationId: location,
        );
      } else {
        await widget.onCompleteTask!(task.id);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _completionMessage = 'Failed to complete task. Please try again.';
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
            decoration: const InputDecoration(
              labelText: 'Step 1: Bulk location',
              hintText: 'BULK-01-01',
              prefixIcon: Icon(Icons.inventory_2_outlined),
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
              labelText: 'Step 2: Select quantity (max ${task.quantity})',
              hintText: 'Enter quantity',
              suffixText: 'max ${task.quantity}',
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
            label: 'Task destination (for reference)',
            value: task.toLocation,
            icon: Icons.south_east_rounded,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('location-validate-field'),
            controller: _locationController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Step 3: Scan or enter shelf location',
              prefixIcon: Icon(Icons.location_on_outlined),
              filled: true,
              fillColor: Colors.white,
            ),
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
        TextField(
          key: const Key('location-validate-field'),
          controller: _locationController,
          decoration: InputDecoration(
            labelText: l10n.workerScanOrEnterLocation,
            prefixIcon: const Icon(Icons.location_on_outlined),
            filled: true,
            fillColor: Colors.white,
          ),
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
                  : const Text('Use suggested location'),
            ),
          ),
        ],
        if (_suggestedLocation != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _locationController.text = _suggestedLocation!;
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
                    'Suggested: $_suggestedLocation',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('validate-location-button'),
            onPressed: _validating ? null : _validateLocation,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: const BorderSide(color: AppTheme.accent),
            ),
            child: _validating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.workerValidateLocation),
          ),
        ),
        if (_locationValidationMessage != null) ...[
          const SizedBox(height: 10),
          _ValidationMessage(
            message: _locationValidationMessage!,
            isPositive:
                _locationValidationMessage == l10n.workerLocationValidated,
          ),
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

  int get _adjustmentPreviewQuantity {
    final product = _selectedAdjustmentProduct;
    if (product == null) return 0;
    if (_adjustmentMode == _AdjustmentMode.increase) {
      return product.systemQuantity + _adjustmentDelta;
    }
    return product.systemQuantity - _adjustmentDelta;
  }

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

  void _updateRefillQuantity() {
    final parsed = int.tryParse(_quantityController.text.trim());
    final next = parsed == null || parsed <= 0 ? 0 : parsed;
    if (_refillQuantity != next) {
      setState(() => _refillQuantity = next);
    }
  }

  void _validateProduct() {
    final l10n = context.l10n;
    final expected = widget.task.itemBarcode?.trim().toUpperCase() ?? '';
    final scanned = _productController.text.trim().toUpperCase();
    final isValid = scanned == expected;
    setState(() {
      _productValidationMessage =
          isValid ? l10n.workerProductValidated : l10n.workerProductMismatch;
      if (widget.task.type == TaskType.receive) {
        _itemValidated = isValid;
        _locationValidated = false;
        _locationValidationMessage = null;
        _receivePage = isValid ? 1 : 0;
      } else if (widget.task.type == TaskType.refill) {
        _itemValidated = isValid;
        _locationValidated = false;
        _locationValidationMessage = null;
        _completionMessage = null;
        _locationController.clear();
        _refillPage = isValid ? 1 : 0;
      } else if (widget.task.type == TaskType.returnTask ||
          widget.task.isSingleItemCycleCount) {
        _itemValidated = isValid;
      }
    });
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
      title: 'Scan item barcode',
      hintText: 'Scan or enter item barcode',
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
      title: 'Scan return location',
      hintText: 'Scan or enter return location',
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
        } else {
          _locationController.text = suggestion;
          _locationValidationMessage = l10n.workerLocationValidated;
        }
      });
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
    final expected = ((widget.task.type == TaskType.refill
                ? _refillShelfLocation
                : widget.task.toLocation ?? widget.task.fromLocation) ??
            '')
        .trim()
        .toUpperCase();
    if (widget.task.type == TaskType.refill) {
      final isValid = scanned == expected;
      setState(() {
        _locationValidated = isValid;
        _locationValidationMessage = isValid
            ? l10n.workerLocationValidated
            : l10n.workerLocationMismatch;
      });
      if (isValid) {
        _restoreCycleCountScannerFocus();
      }
      return;
    }
    if (widget.onValidateLocation == null) {
      final isValid = scanned == expected;
      setState(() {
        _locationValidationMessage = isValid
            ? l10n.workerLocationValidated
            : l10n.workerLocationMismatch;
        if (widget.task.type == TaskType.receive ||
            widget.task.type == TaskType.refill ||
            widget.task.type == TaskType.returnTask ||
            widget.task.type == TaskType.cycleCount) {
          _locationValidated = isValid;
        }
      });
      if (isValid) {
        _restoreCycleCountScannerFocus();
      }
      return;
    }

    setState(() => _validating = true);
    try {
      final response = await widget.onValidateLocation!(scanned);
      if (!mounted) return;
      final valid = _extractValidationResult(response);
      final isValid = valid ?? (scanned == expected);
      setState(() {
        _locationValidationMessage = isValid
            ? l10n.workerLocationValidated
            : l10n.workerLocationMismatch;
        if (widget.task.type == TaskType.receive ||
            widget.task.type == TaskType.refill ||
            widget.task.type == TaskType.returnTask ||
            widget.task.type == TaskType.cycleCount) {
          _locationValidated = isValid;
        }
      });
      if (isValid) {
        _restoreCycleCountScannerFocus();
      }
    } catch (_) {
      if (!mounted) return;
      final isValid = scanned == expected;
      setState(() {
        _locationValidationMessage = isValid
            ? l10n.workerLocationValidated
            : l10n.workerLocationMismatch;
        if (widget.task.type == TaskType.receive ||
            widget.task.type == TaskType.refill ||
            widget.task.type == TaskType.returnTask ||
            widget.task.type == TaskType.cycleCount) {
          _locationValidated = isValid;
        }
      });
      if (isValid) {
        _restoreCycleCountScannerFocus();
      }
    } finally {
      if (mounted) setState(() => _validating = false);
    }
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
          : 'Could not load refill locations.';
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
                label: taskTypeLabel(task.type),
                color: typeColor,
              ),
              _MiniBadge(
                icon: Icons.timer_outlined,
                label: task.status.name.toUpperCase(),
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
                          task.quantity.toString(),
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
    required this.quantity,
  });

  final String itemName;
  final String barcode;
  final String? itemImageUrl;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    const Text(
                      'Total Quantity',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$quantity',
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
  });

  final String key;
  final String itemName;
  final String barcode;
  final int expectedQuantity;
  final int countedQuantity;
  final bool completed;
  final String? imageUrl;

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
    );
  }
}

enum _AdjustmentMode { decrease, increase }

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
    required this.message,
    required this.isPositive,
  });

  final String message;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppTheme.success : AppTheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(
            message,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
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
