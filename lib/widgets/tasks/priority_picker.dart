// lib/widgets/tasks/priority_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';

class PriorityPicker {
  static Future<void> show(
    BuildContext context, {
    required TaskPriority currentPriority,
    required ValueChanged<TaskPriority> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PriorityPickerSheet(
        currentPriority: currentPriority,
        onSelected: onSelected,
      ),
    );
  }
}

class _PriorityPickerSheet extends StatelessWidget {
  final TaskPriority currentPriority;
  final ValueChanged<TaskPriority> onSelected;

  const _PriorityPickerSheet({
    required this.currentPriority,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildOption(context, TaskPriority.high, 'High Priority'),
            _buildOption(context, TaskPriority.medium, 'Medium Priority'),
            _buildOption(context, TaskPriority.low, 'Low Priority'),
            _buildOption(context, TaskPriority.none, 'No Priority'),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, TaskPriority priority, String label) {
    final isSelected = currentPriority == priority;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(priority);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: priority.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.teal : AppColors.deepNavy,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.teal, size: 20),
          ],
        ),
      ),
    );
  }
}