// lib/widgets/tasks/reminder_picker.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';

/// Lets the user set (or clear) a reminder offset on a task. Returns null
/// if cancelled/unchanged, {'remove': true} to clear the reminder, or
/// {'minutes': int} to set one of the kReminderPresets values.
class ReminderPicker {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    int? currentMinutes,
    required bool hasDueDate,
  }) {
    return showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderPickerSheet(
        currentMinutes: currentMinutes,
        hasDueDate: hasDueDate,
      ),
    );
  }
}

class _ReminderPickerSheet extends StatelessWidget {
  final int? currentMinutes;
  final bool hasDueDate;

  const _ReminderPickerSheet({required this.currentMinutes, required this.hasDueDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Remind me', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          const SizedBox(height: 4),
          if (!hasDueDate)
            const Text(
              'Set a due date first — reminders count down from it.',
              style: TextStyle(fontSize: 13, color: AppColors.slateGray),
            ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              currentMinutes == null ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: currentMinutes == null ? AppColors.teal : AppColors.slateGray,
            ),
            title: const Text('No reminder', style: TextStyle(fontSize: 15, color: AppColors.deepNavy)),
            onTap: () => Navigator.pop(context, {'remove': true}),
          ),
          for (final minutes in kReminderPresets)
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: hasDueDate,
              leading: Icon(
                currentMinutes == minutes ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: currentMinutes == minutes ? AppColors.teal : AppColors.slateGray,
              ),
              title: Text(
                reminderPresetLabel(minutes),
                style: TextStyle(fontSize: 15, color: hasDueDate ? AppColors.deepNavy : AppColors.slateGray),
              ),
              onTap: hasDueDate ? () => Navigator.pop(context, {'minutes': minutes}) : null,
            ),
        ],
      ),
    );
  }
}
