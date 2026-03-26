import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/l10n/l10n.dart';
import '../../domain/entities/location_lookup_summary_entity.dart';
import '../controllers/location_lookup_controller.dart';

class LocationLookupResultPage extends StatefulWidget {
  const LocationLookupResultPage({
    super.key,
    required this.locationCode,
  });

  final String locationCode;

  @override
  State<LocationLookupResultPage> createState() =>
      _LocationLookupResultPageState();
}

class _LocationLookupResultPageState extends State<LocationLookupResultPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LocationLookupController>().lookup(widget.locationCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocationLookupController>();
    final state = controller.state;
    final summary = state.summary;
    final isArabic = context.isArabicLocale;
    final theme = Theme.of(context);

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
          isArabic ? 'نتيجة بحث الموقع' : 'Location Lookup Result',
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
                return _LocationStateMessage(
                  icon: Icons.hourglass_top_rounded,
                  title: isArabic
                      ? 'جارٍ تحميل تفاصيل الموقع'
                      : 'Loading location details',
                  subtitle: isArabic
                      ? 'جارٍ جلب الأصناف الموجودة في هذا الموقع...'
                      : 'Fetching items stored in this location...',
                  loading: true,
                );
              }

              if (state.errorType == LocationLookupErrorType.notFound) {
                return _LocationStateMessage(
                  icon: Icons.search_off_rounded,
                  title: isArabic ? 'الموقع غير موجود' : 'Location not found',
                );
              }

              if (state.errorType == LocationLookupErrorType.retryable) {
                return _LocationStateMessage(
                  icon: Icons.wifi_off_rounded,
                  title: state.errorMessage ??
                      (isArabic
                          ? 'تعذر تحميل تفاصيل الموقع'
                          : 'Could not load location details'),
                  action: ElevatedButton(
                    onPressed: controller.retry,
                    child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                  ),
                );
              }

              if (state.errorMessage != null) {
                return _LocationStateMessage(
                  icon: Icons.error_outline_rounded,
                  title: state.errorMessage!,
                );
              }

              if (summary == null) {
                return _LocationStateMessage(
                  icon: Icons.inventory_2_outlined,
                  title: isArabic
                      ? 'لا توجد بيانات للموقع'
                      : 'No location data available',
                );
              }

              return ListView(
                children: [
                  _LocationHeaderCard(
                    summary: summary,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 14),
                  _LocationItemsSection(
                    summary: summary,
                    isArabic: isArabic,
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

class _LocationHeaderCard extends StatelessWidget {
  const _LocationHeaderCard({
    required this.summary,
    required this.isArabic,
  });

  final LocationLookupSummaryEntity summary;
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                summary.locationCode.isEmpty ? '-' : summary.locationCode,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _LocationStatCard(
                      label: isArabic ? 'عدد الأصناف' : 'Items',
                      value: '${summary.totalItems}',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LocationStatCard(
                      label: isArabic ? 'إجمالي الكمية' : 'Total Quantity',
                      value: '${summary.totalQuantity}',
                      icon: Icons.numbers_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationStatCard extends StatelessWidget {
  const _LocationStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
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

class _LocationItemsSection extends StatelessWidget {
  const _LocationItemsSection({
    required this.summary,
    required this.isArabic,
  });

  final LocationLookupSummaryEntity summary;
  final bool isArabic;

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
                Icon(
                  Icons.inventory_rounded,
                  size: 19,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'الأصناف في الموقع' : 'Items In Location',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${summary.totalItems}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (summary.items.isEmpty)
              Text(
                isArabic
                    ? 'لا توجد أصناف في هذا الموقع'
                    : 'No items in this location',
              )
            else
              for (var index = 0; index < summary.items.length; index++) ...[
                _LocationItemCard(
                  key: Key('location-item-row-$index'),
                  item: summary.items[index],
                  isArabic: isArabic,
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _LocationItemCard extends StatelessWidget {
  const _LocationItemCard({
    super.key,
    required this.item,
    required this.isArabic,
  });

  final LocationLookupItemEntity item;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          _LocationItemImage(imageUrl: item.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName.isEmpty
                      ? (isArabic ? 'صنف غير معروف' : 'Unknown Item')
                      : item.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.barcode.isEmpty ? '-' : item.barcode,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isArabic ? 'الكمية' : 'Qty',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationItemImage extends StatelessWidget {
  const _LocationItemImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final value = imageUrl?.trim();
    final child = value == null || value.isEmpty
        ? const Icon(Icons.inventory_2_outlined, size: 24)
        : value.startsWith('assets/')
            ? Image.asset(
                value,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.inventory_2_outlined, size: 24),
              )
            : Image.network(
                value,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.inventory_2_outlined, size: 24),
              );

    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3ECF8)),
      ),
      child: child,
    );
  }
}

class _LocationStateMessage extends StatelessWidget {
  const _LocationStateMessage({
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
