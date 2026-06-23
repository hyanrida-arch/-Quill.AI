// lib/widgets/tasks/task_card.dart
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onStartPomodoro;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onStartPomodoro,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.status == TaskStatus.overdue;
    final isCompleted = task.status == TaskStatus.completed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isOverdue ? AppColors.redBackground : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOverdue ? AppColors.red : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggleComplete,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.teal : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.teal
                        : (isOverdue ? AppColors.red : AppColors.slateGray),
                    width: 1.5,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: AppColors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildPriorityDot(task.priority),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepNavy,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.subject} · ${task.estimatedMinutes} min · ${task.pomodorosPlanned} Pomodoros',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slateGray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (task.dueLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? AppColors.red.withValues(alpha: 0.1)
                            : AppColors.subtleGray,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.calendar_today_outlined,
                            size: 11,
                            color: isOverdue
                                ? AppColors.red
                                : AppColors.slateGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.dueLabel!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOverdue
                                  ? AppColors.red
                                  : AppColors.slateGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Start button
            GestureDetector(
              onTap: onStartPomodoro,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.deepNavy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 14, color: AppColors.white),
                    SizedBox(width: 2),
                    Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDot(TaskPriority priority) {
    final color = switch (priority) {
      TaskPriority.high => AppColors.red,
      TaskPriority.medium => AppColors.amber,
      TaskPriority.low => AppColors.slateGray,
      TaskPriority.none => AppColors.slateGray,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}