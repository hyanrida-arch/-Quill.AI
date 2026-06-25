// lib/screens/tasks/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';

// هادو هما الـ Imports ديال النوافذ اللي غيتحلو
import '../../widgets/tasks/priority_picker.dart';
import '../../widgets/tasks/advanced_date_picker.dart';
import '../../widgets/tasks/focus_pomodoro_sheet.dart';

class LocalSubtask {
  String title;
  bool isDone;
  LocalSubtask({required this.title, this.isDone = false});
}

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final TextEditingController _newSubtaskController = TextEditingController();

  late TaskPriority _currentPriority;
  late DateTime? _currentDate;
  late int _currentDuration;

  final List<LocalSubtask> _subtasks = [
    LocalSubtask(title: 'Read pages 80-95', isDone: true),
    LocalSubtask(title: 'Outline key concepts', isDone: false),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(
      text: 'This chapter covers supply and demand fundamentals, market equilibrium, and price elasticity.',
    );
    _currentPriority = widget.task.priority;
    _currentDate = widget.task.dueDate;
    _currentDuration = widget.task.estimatedMinutes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _addSubtask(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      _subtasks.add(LocalSubtask(title: title.trim(), isDone: false));
      _newSubtaskController.clear();
    });
  }

  void _deleteSubtask(int index) {
    setState(() => _subtasks.removeAt(index));
  }

  void _toggleSubtask(int index) {
    HapticFeedback.lightImpact();
    setState(() => _subtasks[index].isDone = !_subtasks[index].isDone);
  }

  String _getDateLabel() {
    if (_currentDate == null) return 'No Date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(_currentDate!.year, _currentDate!.month, _currentDate!.day);
    final diff = dateOnly.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${_currentDate!.day}/${_currentDate!.month}';
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _subtasks.where((s) => s.isDone).length;
    final totalCount = _subtasks.length;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.deepNavy),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Mystro Insight
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.deepNavy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.teal, size: 14),
                              SizedBox(width: 8),
                              Text('MYSTRO · INSIGHT',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.teal,
                                      letterSpacing: 1.2)),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'This is a high-cognitive task. Your peak focus is 9-11 AM tomorrow - want me to schedule it then?',
                            style: TextStyle(color: AppColors.white, fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Editable Title
                    TextField(
                      controller: _titleController,
                      maxLines: null,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepNavy,
                          height: 1.2,
                          letterSpacing: -0.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // Meta Pills (التحديث الجديد اللي كيحل النوافذ)
                    // ==========================================
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // 1. Priority Pill
                        _buildPill(
                          icon: Icons.flag_outlined,
                          text: _currentPriority == TaskPriority.none ? 'Priority' : _currentPriority.label.replaceAll(' Priority', ''),
                          iconColor: _currentPriority == TaskPriority.none ? AppColors.slateGray : _currentPriority.color,
                          onTap: () {
                            PriorityPicker.show(
                              context,
                              currentPriority: _currentPriority,
                              onSelected: (newPriority) {
                                setState(() => _currentPriority = newPriority);
                              },
                            );
                          },
                        ),

                        // 2. Date Pill
                        _buildPill(
                          icon: Icons.calendar_today_outlined,
                          text: _currentDate == null ? 'No Date' : _getDateLabel(),
                          isSolid: _currentDate != null, // كتولي كحلة يلا كاين تاريخ
                          onTap: () async {
                            final result = await AdvancedDatePicker.show(
                              context,
                              initialDate: _currentDate ?? DateTime.now(),
                            );
                            if (result != null && result['date'] != null) {
                              setState(() {
                                _currentDate = result['date'];
                              });
                            }
                          },
                        ),

                        // 3. Duration/Time Pill
                        _buildPill(
                          icon: Icons.access_time,
                          text: _currentDuration == 0 ? 'Time' : '$_currentDuration min',
                          onTap: () async {
                            final newDuration = await FocusPomodoroSheet.show(
                              context,
                              initialMinutes: _currentDuration == 0 ? 25 : _currentDuration,
                            );
                            if (newDuration != null) {
                              setState(() {
                                _currentDuration = newDuration;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    TextField(
                      controller: _descController,
                      maxLines: null,
                      style: const TextStyle(fontSize: 15, color: AppColors.slateGray, height: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Add a description...',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Subtasks
                    Text('Subtasks ($completedCount/$totalCount)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                    const SizedBox(height: 16),

                    ...List.generate(_subtasks.length, (index) {
                      final sub = _subtasks[index];
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.red.withValues(alpha: 0.1),
                          child: const Icon(Icons.delete_outline, color: AppColors.red),
                        ),
                        onDismissed: (_) => _deleteSubtask(index),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _toggleSubtask(index),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: sub.isDone ? AppColors.deepNavy : AppColors.white,
                                    border: Border.all(
                                        color: sub.isDone ? AppColors.deepNavy : AppColors.slateGray.withValues(alpha: 0.5),
                                        width: 1.5),
                                  ),
                                  child: sub.isDone ? const Icon(Icons.check, size: 14, color: AppColors.white) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    sub.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: sub.isDone ? AppColors.slateGray : AppColors.deepNavy,
                                      decoration: sub.isDone ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Add subtask input
                    Row(
                      children: [
                        const Icon(Icons.add, size: 22, color: AppColors.slateGray),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _newSubtaskController,
                            style: const TextStyle(fontSize: 15, color: AppColors.deepNavy),
                            decoration: const InputDecoration(
                              hintText: 'Add a subtask...',
                              hintStyle: TextStyle(color: AppColors.slateGray),
                              border: InputBorder.none,
                            ),
                            onSubmitted: _addSubtask,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Start Pomodoro Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pomodoro coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Pomodoro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepNavy,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // دالة _buildPill الجديدة اللي كتدعم التفاعل
  // ==========================================
  Widget _buildPill({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? iconColor,
    bool isSolid = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSolid ? AppColors.deepNavy : AppColors.white,
          border: Border.all(
            color: isSolid ? AppColors.deepNavy : AppColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSolid ? AppColors.white : (iconColor ?? AppColors.slateGray),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSolid ? AppColors.white : AppColors.deepNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}