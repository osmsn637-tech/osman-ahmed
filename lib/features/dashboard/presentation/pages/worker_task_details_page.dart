import 'package:flutter/material.dart';

import '../../../../shared/l10n/l10n.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../move/domain/entities/item_location_summary_entity.dart';
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
    this.onGetSuggestion,
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
  final Future<String?> Function()? onGetSuggestion;
  final Future<Map<String, dynamic>> Function(String barcode)?
      onValidateLocation;
  final Future<ItemLocationSummaryEntity> Function(String barcode)? onLookupItem;

  @override
  State<WorkerTaskDetailsPage> createState() => _WorkerTaskDetailsPageState();
}

class _WorkerTaskDetailsPageState extends State<WorkerTaskDetailsPage> {
  late final TextEditingController _productController;
  late final TextEditingController _locationController;
  late final TextEditingController _bulkLocationController;
  late final TextEditingController _quantityController;

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
  int _receivePage = 0;
  int _refillPage = 0;
  int _refillQuantity = 0;
  bool _refillLookupLoading = false;
  String? _refillLookupError;
  ItemLocationSummaryEntity? _refillSummary;

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
    _refillQuantity = task.quantity;
    _quantityController.addListener(_updateRefillQuantity);
    if (task.type == TaskType.refill) {
      _refillLookupLoading = true;
      _bulkLocationController.text = '';
      _locationController.text = '';
      _quantityController.text = '';
      _refillQuantity = 0;
      Future<void>.microtask(_loadRefillLookup);
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    _locationController.dispose();
    _bulkLocationController.dispose();
    _quantityController.removeListener(_updateRefillQuantity);
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final task = widget.task;
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
    final refillQuantityDisplay = '$_refillQuantity/${task.quantity}';

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
      bottomNavigationBar:
          showStartAction ||
                  (showCompleteAction &&
                      task.type != TaskType.receive &&
                      task.type != TaskType.refill)
          ? SafeArea(
              minimum: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  key: showStartAction
                      ? const Key('start-task-button')
                      : const Key('complete-task-button'),
                  onPressed: showStartAction
                      ? (_starting ? null : _startTask)
                      : (task.type == TaskType.receive && _receivePage != 1)
                          ? null
                      : (_completing ||
                              (task.type == TaskType.refill && !refillReady) ||
                              (task.type == TaskType.receive && !receiveReady))
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
                          : Icons.check_rounded),
                  label: Text(showStartAction ? l10n.workerStartTask : l10n.workerComplete),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        showStartAction ? AppTheme.primary : AppTheme.success,
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
          padding: const EdgeInsets.all(16),
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
                        isPositive:
                            _productValidationMessage == l10n.workerProductValidated,
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
                      value: task.type.name.toUpperCase(),
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
          decoration: InputDecoration(
            labelText: 'Validate barcode',
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
              onPressed: _completing || !_isReceiveFlowComplete() ? null : _completeTask,
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

  Future<void> _startTask() async {
    if (widget.onStartTask == null) return;
    setState(() {
      _starting = true;
      _startErrorMessage = null;
    });
    try {
      await widget.onStartTask!();
      if (mounted) Navigator.of(context).pop();
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
      }
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
      setState(() {
        final isValid = scanned == expected;
        _locationValidated = isValid;
        _locationValidationMessage = isValid
            ? l10n.workerLocationValidated
            : l10n.workerLocationMismatch;
      });
      return;
    }
    if (widget.onValidateLocation == null) {
      setState(() {
        final isValid = scanned == expected;
        _locationValidationMessage = isValid
            ? l10n.workerLocationValidated
            : l10n.workerLocationMismatch;
        if (widget.task.type == TaskType.receive ||
            widget.task.type == TaskType.refill) {
          _locationValidated = isValid;
        }
      });
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
            widget.task.type == TaskType.refill) {
          _locationValidated = isValid;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final isValid = scanned == expected;
        _locationValidationMessage = isValid
            ? l10n.workerLocationValidated
            : l10n.workerLocationMismatch;
        if (widget.task.type == TaskType.receive ||
            widget.task.type == TaskType.refill) {
          _locationValidated = isValid;
        }
      });
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
      setState(() {
        _refillLookupLoading = false;
        _refillLookupError = 'Could not load refill locations.';
      });
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
        setState(() {
          _refillLookupLoading = false;
          _refillLookupError = 'Could not load refill locations.';
        });
        return;
      }
      setState(() {
        _refillLookupLoading = false;
        _refillSummary = summary;
        _bulkLocationController.text = bulk;
      });
    } catch (_) {
      setState(() {
        _refillLookupLoading = false;
        _refillLookupError = 'Could not load refill locations.';
      });
    }
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
    if (summary == null || summary.bulkLocations.isEmpty) return null;
    return summary.bulkLocations.first.code;
  }

  String? _firstShelfLocation(ItemLocationSummaryEntity? summary) {
    if (summary == null || summary.shelfLocations.isEmpty) return null;
    return summary.shelfLocations.first.code;
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
                label: task.type.name.toUpperCase(),
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
              const Icon(
                Icons.numbers_rounded,
                size: 14,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                task.quantity.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
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
                hasImage: itemImageUrl != null && itemImageUrl!.trim().isNotEmpty,
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
