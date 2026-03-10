import '../../domain/entities/dashboard_summary_entity.dart';

class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.pendingPutaway,
    required this.pendingMove,
    required this.exceptions,
    required this.cycleCounts,
  });

  final int pendingPutaway;
  final int pendingMove;
  final int exceptions;
  final int cycleCounts;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      pendingPutaway: json['pending_putaway'] as int? ?? 0,
      pendingMove: json['pending_move'] as int? ?? 0,
      exceptions: json['exceptions'] as int? ?? 0,
      cycleCounts: json['cycle_counts'] as int? ?? 0,
    );
  }

  DashboardSummaryEntity toEntity() => DashboardSummaryEntity(
        pendingPutawayCount: pendingPutaway,
        pendingMoveCount: pendingMove,
        exceptionCount: exceptions,
        cycleCountTasks: cycleCounts,
      );
}
