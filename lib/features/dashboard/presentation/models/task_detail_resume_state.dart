import '../../domain/entities/task_entity.dart';

class TaskDetailResumeState {
  const TaskDetailResumeState({
    required this.page,
    this.locationValue,
    this.locationValidated = false,
    this.cycleCountItemKey,
    this.cycleCountDetailOpenedManually = false,
    this.cycleCountDetailBarcodeValidated = false,
  });

  const TaskDetailResumeState.initial() : this(page: 0);

  final int page;
  final String? locationValue;
  final bool locationValidated;
  final String? cycleCountItemKey;
  final bool cycleCountDetailOpenedManually;
  final bool cycleCountDetailBarcodeValidated;

  bool get isInitial =>
      page <= 0 &&
      (locationValue == null || locationValue!.trim().isEmpty) &&
      !locationValidated &&
      (cycleCountItemKey == null || cycleCountItemKey!.trim().isEmpty) &&
      !cycleCountDetailOpenedManually &&
      !cycleCountDetailBarcodeValidated;

  bool supports(TaskType type) {
    return switch (type) {
      TaskType.receive ||
      TaskType.refill ||
      TaskType.returnTask =>
        page == 0 || page == 1,
      TaskType.cycleCount => page == 0 ||
          (page == 1 &&
              cycleCountItemKey != null &&
              cycleCountItemKey!.trim().isNotEmpty),
      _ => false,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskDetailResumeState &&
        other.page == page &&
        other.locationValue == locationValue &&
        other.locationValidated == locationValidated &&
        other.cycleCountItemKey == cycleCountItemKey &&
        other.cycleCountDetailOpenedManually ==
            cycleCountDetailOpenedManually &&
        other.cycleCountDetailBarcodeValidated ==
            cycleCountDetailBarcodeValidated;
  }

  @override
  int get hashCode => Object.hash(
        page,
        locationValue,
        locationValidated,
        cycleCountItemKey,
        cycleCountDetailOpenedManually,
        cycleCountDetailBarcodeValidated,
      );
}
