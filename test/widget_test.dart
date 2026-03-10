import 'package:flutter_test/flutter_test.dart';

import 'package:putaway_app/features/dashboard/domain/entities/task_entity.dart';

void main() {
  test('TaskEntity status helpers work correctly', () {
    final task = TaskEntity(
      id: 1,
      type: TaskType.move,
      itemId: 100,
      itemName: 'Test Item',
      fromLocation: 'A01',
      toLocation: 'B02',
      quantity: 5,
      assignedTo: null,
      status: TaskStatus.pending,
      createdBy: 'system',
      zone: 'Z01',
      createdAt: DateTime.now(),
    );

    expect(task.isPending, isTrue);
    expect(task.isInProgress, isFalse);
    expect(task.isCompleted, isFalse);
  });
}
