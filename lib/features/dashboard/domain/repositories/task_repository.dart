import '../entities/dashboard_summary_entity.dart';
import '../entities/exception_entity.dart';
import '../entities/ai_alert_entity.dart';
import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<DashboardSummaryEntity> getDashboardSummary();
  Future<List<ExceptionEntity>> getExceptions();
  Future<void> resolveException({required int id, required String action});
  Future<List<AiAlertEntity>> getAiAlerts();

  Future<List<TaskEntity>> getTasksForZone(String zone);
  Future<List<TaskEntity>> getTasksForWorker(String workerId);
  Future<TaskEntity?> findBySourceEventId(String sourceEventId);
  Future<TaskEntity> createTask(TaskEntity task);
  Future<TaskEntity> completeTask(
    int taskId, {
    int? quantity,
    String? locationId,
  });
  Future<TaskEntity> claimTask({required int taskId, required String workerId});
  Future<Map<String, dynamic>> suggestTask(int taskId);
  Future<Map<String, dynamic>> validateTaskLocation({
    required int taskId,
    required String barcode,
  });
}
