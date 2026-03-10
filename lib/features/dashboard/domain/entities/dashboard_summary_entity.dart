class DashboardSummaryEntity {
  const DashboardSummaryEntity({
    required this.pendingPutawayCount,
    required this.pendingMoveCount,
    required this.exceptionCount,
    required this.cycleCountTasks,
  });

  final int pendingPutawayCount;
  final int pendingMoveCount;
  final int exceptionCount;
  final int cycleCountTasks;
}
