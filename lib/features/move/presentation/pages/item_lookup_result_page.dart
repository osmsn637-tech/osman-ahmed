import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/l10n/l10n.dart';
import '../../../../shared/ui/location_row.dart';
import '../../domain/entities/item_location_entity.dart';
import '../controllers/item_adjustment_controller.dart';
import '../controllers/item_lookup_controller.dart';

enum ItemLookupPageMode { lookup, adjust }

class ItemLookupResultPage extends StatefulWidget {
  const ItemLookupResultPage({
    super.key,
    required this.barcode,
    this.mode = ItemLookupPageMode.lookup,
  });

  final String barcode;
  final ItemLookupPageMode mode;

  @override
  State<ItemLookupResultPage> createState() => _ItemLookupResultPageState();
}

class _ItemLookupResultPageState extends State<ItemLookupResultPage> {
  bool _showingAdjustmentSuccessDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ItemLookupController>().lookup(widget.barcode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ItemLookupController>();
    final state = controller.state;
    final isAdjustMode = widget.mode == ItemLookupPageMode.adjust;
    final adjustmentController =
        isAdjustMode ? context.watch<ItemAdjustmentController>() : null;
    final adjustmentState = adjustmentController?.state;
    final theme = Theme.of(context);
    final summary = state.summary;
    final isArabic = context.isArabicLocale;

    if (isAdjustMode &&
        adjustmentState?.success == true &&
        !_showingAdjustmentSuccessDialog) {
      _showingAdjustmentSuccessDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showAdjustmentSuccessDialog(isArabic: isArabic);
        if (!mounted) return;
        _navigateAfterAdjustmentSuccess();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            context.go('/home');
          },
        ),
        title: Text(
          isAdjustMode
              ? (isArabic ? 'تعديل الصنف' : 'Adjust Item')
              : (isArabic ? 'نتيجة البحث عن الصنف' : 'Item Lookup Result'),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return _StateMessage(
                  icon: Icons.hourglass_top_rounded,
                  title: isArabic
                      ? 'جارٍ تحميل تفاصيل الصنف'
                      : 'Loading item details',
                  subtitle: isArabic
                      ? 'جارٍ جلب أحدث بيانات المخزون...'
                      : 'Fetching latest inventory snapshot...',
                  loading: true,
                );
              }

              if (state.errorType == ItemLookupErrorType.notFound) {
                return _StateMessage(
                  icon: Icons.search_off_rounded,
                  title: isArabic ? 'الصنف غير موجود' : 'Item not found',
                );
              }

              if (state.errorType == ItemLookupErrorType.retryable) {
                return _StateMessage(
                  icon: Icons.wifi_off_rounded,
                  title: state.errorMessage ??
                      (isArabic
                          ? 'تعذر تحميل تفاصيل الصنف'
                          : 'Could not load item details'),
                  action: ElevatedButton(
                    onPressed: controller.retry,
                    child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                  ),
                );
              }

              if (state.errorMessage != null) {
                return _StateMessage(
                  icon: Icons.error_outline_rounded,
                  title: state.errorMessage!,
                );
              }

              if (summary == null) {
                return _StateMessage(
                  icon: Icons.inventory_2_outlined,
                  title: isArabic
                      ? 'لا توجد بيانات للصنف'
                      : 'No item data available',
                );
              }

              return ListView(
                children: [
                  _ItemHeaderCard(
                    itemName: summary.itemName,
                    barcode: summary.barcode,
                    itemImageUrl: summary.itemImageUrl,
                    totalQuantity: summary.totalQuantity,
                    totalLocations: summary.shelfLocations.length +
                        summary.bulkLocations.length,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 14),
                  _LocationSection(
                    title: isArabic ? 'مواقع الرفوف' : 'Shelf Locations',
                    label: isArabic ? 'رف' : 'Shelf',
                    icon: Icons.grid_view_rounded,
                    locations: summary.shelfLocations,
                    isArabic: isArabic,
                    isShelf: true,
                    selectedLocationId: adjustmentState?.selectedLocationId,
                    onLocationTap: isAdjustMode
                        ? adjustmentController!.selectLocation
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _LocationSection(
                    title: isArabic ? 'مواقع التخزين' : 'Bulk Locations',
                    label: isArabic ? 'تخزين' : 'Bulk',
                    icon: Icons.warehouse_rounded,
                    locations: summary.bulkLocations,
                    isArabic: isArabic,
                    isShelf: false,
                    selectedLocationId: adjustmentState?.selectedLocationId,
                    onLocationTap: isAdjustMode
                        ? adjustmentController!.selectLocation
                        : null,
                  ),
                  if (isAdjustMode) ...[
                    const SizedBox(height: 12),
                    _AdjustmentPanel(
                      state: adjustmentState!,
                      isArabic: isArabic,
                      onLocationCodeChanged: (value) =>
                          adjustmentController.updateSelectedLocationCode(
                        value,
                        knownLocations: summary.locations,
                      ),
                      onQuantityChanged: adjustmentController!.setQuantityText,
                      onConfirm: adjustmentState.canSubmit
                          ? () => adjustmentController.submitForItem(summary)
                          : null,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAdjustmentSuccessDialog({required bool isArabic}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        const successColor = Color(0xFF16A34A);

        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: successColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: successColor.withValues(alpha: 0.20),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 42,
                    color: successColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isArabic ? 'تم التعديل بنجاح' : 'Adjust successful',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isArabic
                      ? 'تم تعديل كمية الصنف بنجاح.'
                      : 'The item quantity was adjusted successfully.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('adjust_success_confirm_button'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(isArabic ? 'تأكيد' : 'Confirm'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateAfterAdjustmentSuccess() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('/home');
  }
}

class _ItemHeaderCard extends StatelessWidget {
  const _ItemHeaderCard({
    required this.itemName,
    required this.barcode,
    required this.itemImageUrl,
    required this.totalQuantity,
    required this.totalLocations,
    required this.isArabic,
  });

  final String itemName;
  final String barcode;
  final String? itemImageUrl;
  final int totalQuantity;
  final int totalLocations;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
          child: SizedBox(
            height: 390,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ItemImage(imageUrl: itemImageUrl),
                      const SizedBox(height: 8),
                      Text(
                        itemName.isEmpty
                            ? (isArabic ? 'صنف غير معروف' : 'Unknown Item')
                            : itemName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 14,
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    barcode.isEmpty ? '-' : barcode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 14,
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                SizedBox(
                  height: 92,
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeaderStatCard(
                          label: isArabic ? 'إجمالي الكمية' : 'Total Quantity',
                          value: '$totalQuantity',
                          icon: Icons.inventory_2_outlined,
                          isArabic: isArabic,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeaderStatCard(
                          label:
                              isArabic ? 'إجمالي المواقع' : 'Total Locations',
                          value: '$totalLocations',
                          icon: Icons.grid_view_rounded,
                          isArabic: isArabic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  const _HeaderStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isArabic,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.imageUrl});

  final String? imageUrl;
  static const double _size = 150;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(22));

  @override
  Widget build(BuildContext context) {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) {
      return _imagePlaceholder();
    }

    if (value.startsWith('assets/')) {
      return _imageFrame(
        child: Image.asset(
          value,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        ),
      );
    }

    return _imageFrame(
      child: Image.network(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      ),
    );
  }

  Widget _imageFrame({required Widget child}) {
    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: _radius,
        border: Border.all(
          color: const Color(0xFFE3ECF8),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: _radius,
        border: Border.all(
          color: const Color(0xFFE3ECF8),
        ),
      ),
      child: const Icon(Icons.inventory_2_outlined, size: 32),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.title,
    required this.label,
    required this.icon,
    required this.locations,
    required this.isArabic,
    required this.isShelf,
    this.selectedLocationId,
    this.onLocationTap,
  });

  final String title;
  final String label;
  final IconData icon;
  final List<ItemLocationEntity> locations;
  final bool isArabic;
  final bool isShelf;
  final int? selectedLocationId;
  final ValueChanged<ItemLocationEntity>? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${locations.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (locations.isEmpty)
              Text(isArabic ? 'لا توجد مواقع' : 'No locations')
            else
              for (var index = 0; index < locations.length; index++) ...[
                LocationRow(
                  key:
                      Key('location-row-${locations[index].locationId}-$index'),
                  code: locations[index].code.isEmpty
                      ? '-'
                      : locations[index].code,
                  typeLabel: label,
                  quantity: '${locations[index].quantity}',
                  isShelfOverride: isShelf,
                  selected: locations[index].locationId == selectedLocationId,
                  trailing: locations[index].locationId == selectedLocationId
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  onTap: onLocationTap == null
                      ? null
                      : () => onLocationTap!(locations[index]),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _AdjustmentPanel extends StatefulWidget {
  const _AdjustmentPanel({
    required this.state,
    required this.isArabic,
    required this.onLocationCodeChanged,
    required this.onQuantityChanged,
    required this.onConfirm,
  });

  final ItemAdjustmentState state;
  final bool isArabic;
  final ValueChanged<String> onLocationCodeChanged;
  final ValueChanged<String> onQuantityChanged;
  final VoidCallback? onConfirm;

  @override
  State<_AdjustmentPanel> createState() => _AdjustmentPanelState();
}

class _AdjustmentPanelState extends State<_AdjustmentPanel> {
  late final TextEditingController _locationController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(
      text: widget.state.selectedLocationCode ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.state.hasQuantityInput ? '${widget.state.quantity}' : '',
    );
  }

  @override
  void didUpdateWidget(covariant _AdjustmentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextLocation = widget.state.selectedLocationCode ?? '';
    if (_locationController.text != nextLocation) {
      _locationController.value = TextEditingValue(
        text: nextLocation,
        selection: TextSelection.collapsed(offset: nextLocation.length),
      );
    }

    final nextQuantity =
        widget.state.hasQuantityInput ? '${widget.state.quantity}' : '';
    if (_quantityController.text != nextQuantity) {
      _quantityController.value = TextEditingValue(
        text: nextQuantity,
        selection: TextSelection.collapsed(offset: nextQuantity.length),
      );
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceTint = theme.colorScheme.primary.withValues(alpha: 0.05);
    final outline = theme.colorScheme.outlineVariant.withValues(alpha: 0.65);
    final mutedText = theme.colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: surfaceTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: outline),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isArabic ? 'تفاصيل التعديل' : 'Adjustment Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.state.selectedLocationCode == null
                  ? (widget.isArabic
                      ? 'اختر موقعًا لإجراء التعديل.'
                      : 'Select a location to adjust.')
                  : (widget.isArabic
                      ? 'الموقع المحدد: ${widget.state.selectedLocationCode}'
                      : 'Selected location: ${widget.state.selectedLocationCode}'),
              style: TextStyle(
                color: mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isArabic ? 'الموقع' : 'Location',
              style: TextStyle(
                color: mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('adjust_location_code_field'),
              controller: _locationController,
              onChanged: widget.onLocationCodeChanged,
              decoration: InputDecoration(
                hintText: widget.isArabic
                    ? 'أدخل موقع الرف أو التخزين'
                    : 'Enter shelf or bulk location',
                filled: true,
                fillColor: surfaceTint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.4,
                  ),
                ),
                prefixIcon: const Icon(Icons.location_on_outlined),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isArabic ? 'الكمية الجديدة' : 'New Quantity',
              style: TextStyle(
                color: mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('adjust_quantity_field'),
              controller: _quantityController,
              keyboardType: TextInputType.number,
              onChanged: widget.onQuantityChanged,
              decoration: InputDecoration(
                hintText: widget.isArabic
                    ? 'أدخل الكمية المعدلة'
                    : 'Enter adjusted quantity',
                filled: true,
                fillColor: surfaceTint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.4,
                  ),
                ),
                prefixIcon: const Icon(Icons.numbers_rounded),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.state.errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.state.errorMessage!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('adjust_confirm_button'),
                onPressed: widget.onConfirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  widget.state.isSubmitting
                      ? (widget.isArabic ? 'جارٍ التأكيد...' : 'Confirming...')
                      : (widget.isArabic ? 'تأكيد' : 'Confirm'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                ] else ...[
                  Icon(icon, size: 32, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: 14),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
