import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';

Color taskStatusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return AppTheme.warning;
    case TaskStatus.inProgress:
      return AppTheme.accent;
    case TaskStatus.completed:
      return AppTheme.success;
  }
}

IconData taskTypeIcon(TaskType type) {
  switch (type) {
    case TaskType.receive:
      return Icons.call_received_rounded;
    case TaskType.move:
      return Icons.swap_horiz_rounded;
    case TaskType.returnTask:
      return Icons.undo_rounded;
    case TaskType.adjustment:
      return Icons.tune_rounded;
    case TaskType.refill:
      return Icons.inventory_2_rounded;
    case TaskType.exception:
      return Icons.error_outline_rounded;
    case TaskType.cycleCount:
      return Icons.fact_check_rounded;
  }
}

Color taskTypeColor(TaskType type) {
  switch (type) {
    case TaskType.receive:
      return const Color(0xFF0EA5E9);
    case TaskType.move:
      return AppTheme.accent;
    case TaskType.returnTask:
      return AppTheme.warning;
    case TaskType.adjustment:
      return const Color(0xFFB45309);
    case TaskType.refill:
      return const Color(0xFF2563EB);
    case TaskType.exception:
      return AppTheme.error;
    case TaskType.cycleCount:
      return const Color(0xFF0D9488);
  }
}
