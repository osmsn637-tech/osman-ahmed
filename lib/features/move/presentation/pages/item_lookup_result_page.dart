import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/ui/location_row.dart';
import '../../domain/entities/item_location_entity.dart';
import '../controllers/item_lookup_controller.dart';

class ItemLookupResultPage extends StatefulWidget {
  const ItemLookupResultPage({super.key, required this.barcode});

  final String barcode;

  @override
  State<ItemLookupResultPage> createState() => _ItemLookupResultPageState();
}

class _ItemLookupResultPageState extends State<ItemLookupResultPage> {
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
    final theme = Theme.of(context);
    final summary = state.summary;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
        title: Text(isArabic ? 'نتيجة البحث عن الصنف' : 'Item Lookup Result'),
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
                  title: isArabic ? 'جارٍ تحميل تفاصيل الصنف' : 'Loading item details',
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
                      (isArabic ? 'تعذر تحميل تفاصيل الصنف' : 'Could not load item details'),
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
                  title: isArabic ? 'لا توجد بيانات للصنف' : 'No item data available',
                );
              }

              return ListView(
                children: [
                  _ItemHeaderCard(
                    itemName: summary.itemName,
                    barcode: summary.barcode,
                    itemImageUrl: summary.itemImageUrl,
                    totalQuantity: summary.totalQuantity,
                    totalLocations:
                        summary.shelfLocations.length + summary.bulkLocations.length,
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
                  ),
                  const SizedBox(height: 12),
                  _LocationSection(
                    title: isArabic ? 'مواقع التخزين' : 'Bulk Locations',
                    label: isArabic ? 'تخزين' : 'Bulk',
                    icon: Icons.warehouse_rounded,
                    locations: summary.bulkLocations,
                    isArabic: isArabic,
                    isShelf: false,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
                        itemName.isEmpty ? (isArabic ? 'صنف غير معروف' : 'Unknown Item') : itemName,
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
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                          label: isArabic ? 'إجمالي المواقع' : 'Total Locations',
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
  });

  final String title;
  final String label;
  final IconData icon;
  final List<ItemLocationEntity> locations;
  final bool isArabic;
  final bool isShelf;

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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              for (final item in locations) ...[
                LocationRow(
                  code: item.code.isEmpty ? '-' : item.code,
                  typeLabel: label,
                  quantity: '${item.quantity}',
                  isShelfOverride: isShelf,
                ),
                const SizedBox(height: 8),
              ],
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
