import '../repositories/task_repository.dart';

class ReportTaskIssueUseCase {
  ReportTaskIssueUseCase(this._repo);

  final TaskRepository _repo;

  Future<void> execute({
    required int taskId,
    required String note,
    String? photoPath,
  }) {
    return _repo.reportTaskIssue(
      taskId: taskId,
      note: note,
      photoPath: photoPath,
    );
  }
}
