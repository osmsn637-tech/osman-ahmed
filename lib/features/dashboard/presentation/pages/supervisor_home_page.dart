import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/l10n/l10n.dart';
import '../../../../shared/theme/app_theme.dart';
import '../controllers/supervisor_tasks_controller.dart';
import '../shared/dashboard_common_widgets.dart';

class SupervisorHomePage extends StatefulWidget {
  const SupervisorHomePage({super.key});

  @override
  State<SupervisorHomePage> createState() => _SupervisorHomePageState();
}

class _SupervisorHomePageState extends State<SupervisorHomePage> {
  static const _zones = [
    'Z01',
    'Z02',
    'Z03',
    'Z04',
    'Z05',
    'Z06',
    'Z07',
    'Z08',
    'Z09',
    'Z10',
    'Z11',
    'Z12'
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Consumer<SupervisorTasksController>(
      builder: (context, ctrl, _) {
        final tasks = ctrl.state.tasks;
        final loading = ctrl.state.loading;
        final selectedZone =
            ctrl.state.zone.isNotEmpty ? ctrl.state.zone : _zones.first;

        final pending = tasks.where((t) => t.isPending).length;
        final inProgress = tasks.where((t) => t.isInProgress).length;
        final completed = tasks.where((t) => t.isCompleted).length;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 20),
                const SizedBox(width: 8),
                Text(l10n.supervisorTitle),
              ],
            ),
            actions: [
              IconButton(
                onPressed: ctrl.load,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.supervisorRefresh,
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
                    stops: [0, 0.42],
                  ),
                ),
              ),
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
                child: Column(
                  children: [
                    _SupervisorOverview(
                      selectedZone: selectedZone,
                      pending: pending,
                      inProgress: inProgress,
                      completed: completed,
                      zones: _zones,
                      onZoneChanged: (z) {
                        if (z != null) ctrl.setZone(z);
                      },
                    ),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : tasks.isEmpty
                              ? Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: DashboardEmptyState(
                                      icon: Icons.inbox_outlined,
                                      message:
                                          l10n.supervisorNoTasksForZone(selectedZone),
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () async => ctrl.load(),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 100),
                                    itemCount: tasks.length,
                                    itemBuilder: (context, index) {
                                      final t = tasks[index];
                                      return Padding(
                                        padding: EdgeInsets.only(
                                            bottom: index < tasks.length - 1
                                                ? 10
                                                : 0),
                                        child: Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    DashboardTypeBadge(t.type),
                                                    const Spacer(),
                                                    DashboardStatusBadge(
                                                        t.status),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  t.itemName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(Icons.numbers,
                                                        size: 14,
                                                        color: Colors
                                                            .grey.shade500),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      l10n.workerQty(
                                                          t.quantity.toString()),
                                                      style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors
                                                              .grey.shade700,
                                                          fontWeight:
                                                              FontWeight.w700),
                                                    ),
                                                    if (t.assignedTo !=
                                                        null) ...[
                                                      const SizedBox(width: 14),
                                                      Icon(Icons.person_outline,
                                                          size: 14,
                                                          color: Colors
                                                              .grey.shade500),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        l10n.supervisorWorkerNumber(
                                                            t.assignedTo.toString()),
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey.shade700,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ] else ...[
                                                      const SizedBox(width: 14),
                                                      Icon(Icons.group_outlined,
                                                          size: 14,
                                                          color: Colors
                                                              .grey.shade400),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        l10n.supervisorUnassigned,
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey.shade500,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: null,
        );
      },
    );
  }
}

class _SupervisorOverview extends StatelessWidget {
  const _SupervisorOverview({
    required this.selectedZone,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.zones,
    required this.onZoneChanged,
  });

  final String selectedZone;
  final int pending;
  final int inProgress;
  final int completed;
  final List<String> zones;
  final ValueChanged<String?> onZoneChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
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
            l10n.supervisorOperationsOverview,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedZone,
                      dropdownColor: const Color(0xFF225B84),
                      isExpanded: true,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                      iconEnabledColor: Colors.white,
                      items: zones
                          .map((z) => DropdownMenuItem(
                              value: z, child: Text(l10n.zoneWithCode(z))))
                          .toList(),
                      onChanged: onZoneChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DashboardStatChip(
                  label: l10n.supervisorPending,
                  count: pending,
                  color: AppTheme.warning,
                  darkMode: true),
              const SizedBox(width: 8),
              DashboardStatChip(
                  label: l10n.metricActive,
                  count: inProgress,
                  color: AppTheme.accent,
                  darkMode: true),
              const SizedBox(width: 8),
              DashboardStatChip(
                  label: l10n.metricDone,
                  count: completed,
                  color: AppTheme.success,
                  darkMode: true),
            ],
          ),
        ],
      ),
    );
  }
}


