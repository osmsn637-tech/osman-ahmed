import '../entities/dashboard_summary_entity.dart';
import '../entities/exception_entity.dart';
import '../repositories/task_repository.dart';

class DashboardTasksResult {
  const DashboardTasksResult({
    required this.summary,
    required this.exceptions,
  });

  final DashboardSummaryEntity summary;
  final List<ExceptionEntity> exceptions;
}

class GetDashboardTasksUseCase {
  const GetDashboardTasksUseCase(this._repository);

  final TaskRepository _repository;

  Future<DashboardTasksResult> call() async {
    final summary = await _repository.getDashboardSummary();
    final exceptions = await _repository.getExceptions();
    return DashboardTasksResult(summary: summary, exceptions: exceptions);
  }
}
