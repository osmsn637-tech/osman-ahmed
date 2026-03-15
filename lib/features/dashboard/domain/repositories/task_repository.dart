import '../entities/dashboard_summary_entity.dart';
import '../entities/exception_entity.dart';
import '../entities/ai_alert_entity.dart';
import '../entities/adjustment_task_entities.dart';
import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<DashboardSummaryEntity> getDashboardSummary();
  Future<List<ExceptionEntity>> getExceptions();
  Future<void> resolveException({required int id, required String action});
  Future<List<AiAlertEntity>> getAiAlerts();

  Future<List<TaskEntity>> getTasksForZone(String zone);
  Future<List<TaskEntity>> getTasksForWorker(String workerId);
  Future<TaskEntity?> findBySourceEventId(String sourceEventId);
  Future<TaskEntity> completeTask(
    int taskId, {
    int? quantity,
    String? locationId,
  });
  Future<TaskEntity> saveCycleCountProgress(
    int taskId, {
    required Map<String, Object?> progress,
  });
  Future<TaskEntity> claimTask({required int taskId, required String workerId});
  Future<Map<String, dynamic>> suggestTask(int taskId);
  Future<Map<String, dynamic>> validateTaskLocation({
    required int taskId,
    required String barcode,
  });
  Future<AdjustmentTaskLocationScan> scanAdjustmentLocation({
    required int taskId,
    required String barcode,
  });
  Future<void> submitAdjustmentCount({
    required int taskId,
    required String adjustmentItemId,
    required int actualQuantity,
    String? notes,
  });

  Future<QuickAdjustmentResult> createQuickAdjustment({
    required String warehouseId,
    required int productId,
    required String locationId,
    required int systemQuantity,
    required int actualQuantity,
    String? reason,
    String? notes,
    String? batchNumber,
    String? expiryDate,
  });
}

class QuickAdjustmentResult {
  final bool success;
  final String message;
  final String? adjustmentId;
  final String? adjustmentNumber;
  final String? status;

  QuickAdjustmentResult({
    required this.success,
    required this.message,
    this.adjustmentId,
    this.adjustmentNumber,
    this.status,
  });

  factory QuickAdjustmentResult.fromJson(Map<String, dynamic> json) {
    return QuickAdjustmentResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      adjustmentId: json['adjustmentId']?.toString(),
      adjustmentNumber: json['adjustmentNumber']?.toString(),
      status: json['status']?.toString(),
    );
  }
}
