import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/l10n/l10n.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../move/domain/usecases/lookup_item_by_barcode_usecase.dart';
import '../../../move/presentation/pages/item_lookup_scan_dialog.dart';
import '../../domain/entities/task_entity.dart';
import '../controllers/worker_tasks_controller.dart';
import 'worker_task_details_page.dart';
import '../shared/dashboard_common_widgets.dart';
import '../shared/task_visuals.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Consumer2<WorkerTasksController, SessionController>(
      builder: (context, ctrl, session, _) {
        final user = session.state.user;
        final currentTasks = ctrl.state.current;
        final completedTasks = ctrl.state.completed;
        final loading = ctrl.state.loading;
        final availableCount =
            currentTasks.where((t) => t.assignedTo == null && t.isPending).length;
        final activeCount =
            currentTasks.where((t) => t.assignedTo != null && !t.isCompleted).length;
        final completedCount = completedTasks.length;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warehouse_outlined, size: 20),
                const SizedBox(width: 8),
                Text(l10n.zoneWithCode(user?.zone ?? '--')),
              ],
            ),
            actions: [
              IconButton(
                onPressed: ctrl.refresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.workerRefreshTasks,
              ),
            ],
          ),
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE6EEF8), AppTheme.surface],
                    stops: [0, 0.38],
                  ),
                ),
              ),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else
                TweenAnimationBuilder<double>(
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  tween: Tween<double>(begin: 0.98, end: 1),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: scale, child: child),
                  ),
                  child: RefreshIndicator(
                    onRefresh: ctrl.refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: _OverviewPanel(
                              workerName: user?.name ?? 'Worker',
                              availableCount: availableCount,
                              activeCount: activeCount,
                              completedCount: completedCount,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final barcode =
                                      await showItemLookupScanDialog(
                                    context,
                                    showKeyboard: false,
                                  );
                                  final normalized = barcode?.trim() ?? '';
                                  if (!context.mounted ||
                                      normalized.isEmpty) {
                                    return;
                                  }
                                  context.push(
                                    '/item-lookup/result/${Uri.encodeComponent(normalized)}',
                                  );
                                },
                                icon: const Icon(Icons.search_rounded),
                                label: Text(l10n.workerLookup),
                                style: ElevatedButton.styleFrom(
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: DashboardSectionHeader(
                              icon: Icons.inbox_rounded,
                              title: 'Tasks',
                              count: currentTasks.length,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 10)),
                        if (currentTasks.isEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverToBoxAdapter(
                              child: DashboardEmptyState(
                                icon: Icons.check_circle_outline,
                                message: l10n.workerNoAvailableTasks,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList.separated(
                              itemBuilder: (context, index) {
                                final task = currentTasks[index];
                                final canStart =
                                    task.status == TaskStatus.pending &&
                                    task.assignedTo == null;
                                return _TaskCard(
                                  task: task,
                                  actionLabel: canStart ? l10n.workerStart : 'Open',
                                  actionColor:
                                      canStart ? AppTheme.accent : AppTheme.primary,
                                  actionIcon: canStart
                                      ? Icons.play_arrow_rounded
                                      : null,
                                  onAction: () => canStart
                                      ? _startTaskFromHome(task)
                                      : _openTaskDetails(context, task),
                                  onTap: () => _openTaskDetails(
                                    context,
                                    task,
                                    onStartTask: canStart
                                        ? () async {
                                            await ctrl.claim(task.id);
                                          }
                                        : null,
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemCount: currentTasks.length,
                            ),
                          ),
                        if (completedTasks.isNotEmpty) ...[
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverToBoxAdapter(
                              child: DashboardSectionHeader(
                                icon: Icons.check_circle_rounded,
                                title: 'Completed Tasks',
                                count: completedTasks.length,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList.separated(
                              itemBuilder: (context, index) {
                                final task = completedTasks[index];
                                return _TaskCard(
                                  task: task,
                                  completed: true,
                                  onAction: null,
                                  onTap: () => _openTaskDetails(context, task),
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemCount: completedTasks.length,
                            ),
                          ),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openTaskDetails(
    BuildContext context,
    TaskEntity task, {
    Future<void> Function()? onStartTask,
  }) {
    final controller = context.read<WorkerTasksController>();
    final lookupItem = context.read<LookupItemByBarcodeUseCase>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkerTaskDetailsPage(
          task: task,
          onStartTask: onStartTask,
          onCompleteTask: (taskId, {int? quantity, String? locationId}) =>
              controller.complete(
                taskId,
                quantity: quantity,
                locationId: locationId,
              ),
          onGetSuggestion: () => controller.getSuggestion(task.id),
          onValidateLocation: (barcode) =>
              controller.validateLocation(task.id, barcode),
          onLookupItem: (barcode) async {
            final result = await lookupItem(barcode);
            return result.when(
              success: (data) => data,
              failure: (error) => throw error,
            );
          },
        ),
      ),
    );
  }

  Future<void> _startTaskFromHome(TaskEntity task) async {
    final controller = context.read<WorkerTasksController>();
    final claimedTask = await controller.claim(task.id);
    if (!mounted || claimedTask == null) return;
    await _openTaskDetails(context, claimedTask);
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.workerName,
    required this.availableCount,
    required this.activeCount,
    required this.completedCount,
  });

  final String workerName;
  final int availableCount;
  final int activeCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, Color(0xFF184E77)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E0D3B66),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.workerWelcomeBack(workerName),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.workerTrackQueue,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MetricPill(
                  label: l10n.metricAvailable,
                  value: availableCount.toString()),
              const SizedBox(width: 8),
              _MetricPill(
                  label: l10n.metricActive, value: activeCount.toString()),
              const SizedBox(width: 8),
              _MetricPill(
                  label: l10n.metricDone, value: completedCount.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.84)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    this.actionLabel,
    this.actionColor,
    this.actionIcon,
    this.onAction,
    this.onTap,
    this.completed = false,
  });

  final TaskEntity task;
  final String? actionLabel;
  final Color? actionColor;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typeColor = taskTypeColor(task.type);
    final imageUrl = task.itemImageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return RepaintBoundary(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: completed ? 0.55 : 1.0,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DashboardTypeBadge(task.type),
                      const Spacer(),
                      if (completed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                size: 16, color: AppTheme.success),
                            const SizedBox(width: 4),
                            Text(l10n.workerDone,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TaskImageThumb(imageUrl: imageUrl, hasImage: hasImage),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.itemName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(Icons.numbers,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(l10n.workerQty(task.quantity.toString()),
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 16),
                      if (task.fromLocation != null) ...[
                        Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(task.fromLocation!,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                      ],
                      if (task.toLocation != null)
                        Text(task.toLocation!,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (!completed && onAction != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: actionIcon == null
                          ? ElevatedButton(
                              onPressed: onAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: actionColor ?? typeColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14),
                                minimumSize: Size.zero,
                                elevation: 0,
                              ),
                              child: Text(actionLabel ?? ''),
                            )
                          : ElevatedButton.icon(
                              onPressed: onAction,
                              icon: Icon(actionIcon, size: 18),
                              label: Text(actionLabel ?? ''),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: actionColor ?? typeColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14),
                                minimumSize: Size.zero,
                                elevation: 0,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskImageThumb extends StatelessWidget {
  const _TaskImageThumb({
    required this.imageUrl,
    required this.hasImage,
  });

  final String? imageUrl;
  final bool hasImage;

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

    if (!hasImage) return placeholder;

    final trimmed = imageUrl!;
    final image = trimmed.startsWith('assets/')
        ? Image.asset(
            trimmed,
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          )
        : Image.network(
            trimmed,
            width: 56,
            height: 56,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => placeholder,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: image,
    );
  }
}
