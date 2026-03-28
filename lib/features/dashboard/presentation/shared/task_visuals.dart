import 'package:flutter/material.dart';

import '../../../../shared/l10n/l10n.dart';
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

String taskTypeLabel(TaskType type, {bool isPutaway = false}) {
  switch (type) {
    case TaskType.receive:
      return isPutaway ? 'PUTAWAY' : 'RECEIVE';
    case TaskType.move:
      return 'MOVE';
    case TaskType.returnTask:
      return 'RETURN';
    case TaskType.adjustment:
      return 'ADJUSTMENT';
    case TaskType.refill:
      return 'REFILL';
    case TaskType.exception:
      return 'EXCEPTION';
    case TaskType.cycleCount:
      return 'CYCLE COUNT';
  }
}

String taskTypeLabelForContext(
  BuildContext context,
  TaskType type, {
  bool isPutaway = false,
}) {
  switch (type) {
    case TaskType.receive:
      return context.trText(
        english: isPutaway ? 'PUTAWAY' : 'RECEIVE',
        arabic: 'استلام',
        urdu: isPutaway ? 'پٹ اوے' : 'وصولی',
      );
    case TaskType.move:
      return context.trText(
        english: 'MOVE',
        arabic: 'نقل',
        urdu: 'منتقلی',
      );
    case TaskType.returnTask:
      return context.trText(
        english: 'RETURN',
        arabic: 'مرتجع',
        urdu: 'واپسی',
      );
    case TaskType.adjustment:
      return context.trText(
        english: 'ADJUSTMENT',
        arabic: 'تعديل',
        urdu: 'ایڈجسٹمنٹ',
      );
    case TaskType.refill:
      return context.trText(
        english: 'REFILL',
        arabic: 'إعادة تعبئة',
        urdu: 'ری فل',
      );
    case TaskType.exception:
      return context.trText(
        english: 'EXCEPTION',
        arabic: 'استثناء',
        urdu: 'استثناء',
      );
    case TaskType.cycleCount:
      return context.trText(
        english: 'CYCLE COUNT',
        arabic: 'جرد دوري',
        urdu: 'سائیکل کاؤنٹ',
      );
  }
}

String taskStatusLabelForContext(BuildContext context, TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return context.trText(
        english: 'PENDING',
        arabic: 'قيد الانتظار',
        urdu: 'زیر انتظار',
      );
    case TaskStatus.inProgress:
      return context.trText(
        english: 'INPROGRESS',
        arabic: 'قيد التنفيذ',
        urdu: 'جاری',
      );
    case TaskStatus.completed:
      return context.trText(
        english: 'COMPLETED',
        arabic: 'مكتملة',
        urdu: 'مکمل',
      );
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


