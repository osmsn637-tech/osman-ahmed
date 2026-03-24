import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import 'task_visuals.dart';

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceAlt),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.verticalPadding = 28,
  });

  final IconData icon;
  final String message;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceAlt),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}

class DashboardTypeBadge extends StatelessWidget {
  const DashboardTypeBadge(
    this.type, {
    this.isPutaway = false,
    super.key,
  });

  final TaskType type;
  final bool isPutaway;

  @override
  Widget build(BuildContext context) {
    final color = taskTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(taskTypeIcon(type), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
          taskTypeLabelForContext(
            context,
            type,
            isPutaway: isPutaway,
          ),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class DashboardStatusBadge extends StatelessWidget {
  const DashboardStatusBadge(this.status, {super.key});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final color = taskStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        taskStatusLabelForContext(context, status),
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class DashboardStatChip extends StatelessWidget {
  const DashboardStatChip({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    this.darkMode = false,
  });

  final String label;
  final int count;
  final Color color;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: darkMode
              ? Colors.white.withValues(alpha: 0.22)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: darkMode
                ? Colors.white.withValues(alpha: 0.34)
                : color.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: darkMode ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: darkMode
                    ? Colors.white.withValues(alpha: 0.88)
                    : color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
