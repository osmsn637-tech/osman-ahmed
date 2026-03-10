import '../repositories/task_repository.dart';

class GetTaskSuggestionUseCase {
  GetTaskSuggestionUseCase(this._repo);

  final TaskRepository _repo;

  Future<String?> execute(int taskId) async {
    final response = await _repo.suggestTask(taskId);
    return _extractLocationCode(response);
  }

  String? _extractLocationCode(Map<String, dynamic> response) {
    final direct =
        _toString(response['locationCode']) ??
        _toString(response['location']) ??
        _toString(response['location_id']) ??
        _toString(response['toLocation']) ??
        _toString(response['zone']);
    if (direct != null) return direct;

    final alternatives = response['alternatives'];
    if (alternatives is List && alternatives.isNotEmpty) {
      final first = alternatives.first;
      if (first is Map<String, dynamic>) {
        return _toString(first['locationCode']) ??
            _toString(first['location']) ??
            _toString(first['location_id']);
      }
      if (first is Map) {
        return _toString(first['locationCode']) ??
            _toString(first['location']) ??
            _toString(first['location_id']);
      }
    }
    return null;
  }

  String? _toString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
