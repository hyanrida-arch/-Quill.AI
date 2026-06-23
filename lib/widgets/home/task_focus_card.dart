// lib/widgets/home/task_focus_card.dart
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';

class TaskFocusCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onStartPomodoro;

  const TaskFocusCard({
    super.key,
    required this.task,
    this.onStartPomodoro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                task.subject.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slateGray,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${task.estimatedMinutes} min · ${task.pomodorosPlanned} Pomodoros',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slateGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onStartPomodoro,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 16, color: AppColors.white),
                  SizedBox(width: 4),
                  Text(
                    'Start Pomodoro',
                    style: TextStyle(
                      fontSize: 13,
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
    );
  }
}