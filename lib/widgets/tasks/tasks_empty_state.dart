// lib/widgets/tasks/tasks_empty_state.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TasksEmptyState extends StatelessWidget {
  final VoidCallback? onAskMystro;

  const TasksEmptyState({super.key, this.onAskMystro});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.lightTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 28,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Let Mystro help you plan your day.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.slateGray,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAskMystro,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.deepNavy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 16, color: AppColors.teal),
                    SizedBox(width: 8),
                    Text(
                      'Ask Mystro',
                      style: TextStyle(
                        fontSize: 14,
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
}