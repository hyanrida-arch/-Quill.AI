// lib/screens/tasks/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';

// هادو هما الـ Imports ديال النوافذ اللي غيتحلو
import '../../widgets/tasks/priority_picker.dart';
import '../../widgets/tasks/advanced_date_picker.dart';
import '../../widgets/tasks/focus_pomodoro_sheet.dart';
import '../../widgets/tasks/tag_picker.dart';
import '../../widgets/tasks/recurrence_picker.dart';
import '../../widgets/tasks/reminder_picker.dart';
import '../../widgets/focus/pomodoro_active_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final ValueChanged<FocusSession> onSessionComplete;
  // Optional: only TasksBody currently has a delete callback to hand down
  // (CalendarBody/TaskSearchScreen don't support deleting yet). The 3-dot
  // menu only appears when this is provided, rather than showing an empty
  // popup from the screens that can't act on it.
  final ValueChanged<Task>? onDelete;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.onSessionComplete,
    this.onDelete,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final TextEditingController _newSubtaskController = TextEditingController();

  late TaskPriority _currentPriority;
  late DateTime? _currentDate;
  late bool _currentHasTime;
  late int _currentDuration;
  late String? _currentTagLabel;
  late int? _currentTagColorValue;
  late RecurrenceRule _currentRecurrence;
  late int? _currentReminderMinutes;
  late int _currentPomodorosPlanned;

  // Real, persisted subtasks now — Subtask is a field on Task, saved via
  // AppShell the same way title/priority/etc. are. Previously this was a
  // screen-local LocalSubtask list that was never written back to the
  // Task, so every close-and-reopen silently wiped the checklist.
  late List<Subtask> _subtasks;
  int _subtaskCounter = 0;
  String _generateSubtaskId() =>
      'subtask_${DateTime.now().microsecondsSinceEpoch}_${_subtaskCounter++}';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _currentPriority = widget.task.priority;
    _currentDate = widget.task.dueDate;
    _currentHasTime = widget.task.hasTime;
    _currentDuration = widget.task.estimatedMinutes;
    _currentTagLabel = widget.task.tagLabel;
    _currentTagColorValue = widget.task.tagColorValue;
    _currentRecurrence = widget.task.recurrence;
    _currentReminderMinutes = widget.task.reminderMinutesBefore;
    _currentPomodorosPlanned = widget.task.pomodorosPlanned;
    _subtasks = List<Subtask>.from(widget.task.subtasks);
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
      _subtasks.add(Subtask(id: _generateSubtaskId(), title: title.trim()));
      _newSubtaskController.clear();
    });
  }

  void _deleteSubtask(int index) {
    setState(() => _subtasks.removeAt(index));
  }

  void _toggleSubtask(int index) {
    HapticFeedback.lightImpact();
    setState(() => _subtasks[index] = _subtasks[index].copyWith(isDone: !_subtasks[index].isDone));
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete task?', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
        content: Text(
          'This removes "${widget.task.title}". This can\'t be undone.',
          style: const TextStyle(color: AppColors.slateGray),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.onDelete?.call(widget.task);
      Navigator.pop(context);
    }
  }

  Future<void> _openTagPicker() async {
    final result = await TagPicker.show(
      context,
      currentLabel: _currentTagLabel,
      currentColorValue: _currentTagColorValue,
    );
    if (result == null) return;
    if (result['remove'] == true) {
      setState(() {
        _currentTagLabel = null;
        _currentTagColorValue = null;
      });
    } else {
      setState(() {
        _currentTagLabel = result['label'] as String;
        _currentTagColorValue = result['color'] as int;
      });
    }
  }

  // The screen edits everything locally (title, priority, date, duration).
  // This getter folds those local edits back onto the original Task so
  // callers can persist them — without it, every edit made here was
  // silently discarded the moment this screen was popped.
  Task get _editedTask {
    final title = _titleController.text.trim();
    // copyWith's `??` pattern can't null out a field that was previously
    // set, so when the tag was removed in this screen, start from a
    // cleared copy first — otherwise a removed tag would silently come
    // back the moment this screen closes.
    final base = _currentTagLabel == null ? widget.task.clearTag() : widget.task;
    return base.copyWith(
      title: title.isEmpty ? widget.task.title : title,
      priority: _currentPriority,
      dueDate: _currentDate,
      dueLabel: _currentDate == null ? widget.task.dueLabel : Task.dateLabelFor(_currentDate),
      estimatedMinutes: _currentDuration,
      description: _descController.text.trim(),
      hasTime: _currentHasTime,
      tagLabel: _currentTagLabel,
      tagColorValue: _currentTagColorValue,
      recurrence: _currentRecurrence,
      reminderMinutesBefore: _currentReminderMinutes,
      clearReminder: _currentReminderMinutes == null,
      subtasks: _subtasks,
      pomodorosPlanned: _currentPomodorosPlanned,
    );
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
          onPressed: () => Navigator.pop(context, _editedTask),
        ),
        actions: [
          if (widget.onDelete != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.deepNavy),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (value) {
                if (value == 'delete') _confirmDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                    SizedBox(width: 10),
                    Text('Delete Task', style: TextStyle(color: AppColors.red)),
                  ]),
                ),
              ],
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
                            'Start a focus session on this task and Mystro will start spotting real patterns — best times, typical pace, where it tends to stall.',
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
                              initialStartTime: _currentHasTime && _currentDate != null
                                  ? TimeOfDay.fromDateTime(_currentDate!)
                                  : null,
                            );
                            if (result != null && result['date'] != null) {
                              final pickedDate = result['date'] as DateTime;
                              final start = result['startTime'] as TimeOfDay?;
                              final end = result['endTime'] as TimeOfDay?;
                              setState(() {
                                if (start != null) {
                                  _currentDate = DateTime(pickedDate.year,
                                      pickedDate.month, pickedDate.day, start.hour, start.minute);
                                  _currentHasTime = true;
                                  if (end != null) {
                                    final startMins = start.hour * 60 + start.minute;
                                    var endMins = end.hour * 60 + end.minute;
                                    if (endMins <= startMins) endMins += 24 * 60;
                                    _currentDuration = endMins - startMins;
                                  }
                                } else {
                                  _currentDate = pickedDate;
                                  _currentHasTime = false;
                                }
                              });
                            }
                          },
                        ),

                        // 3. Duration/Time Pill
                        _buildPill(
                          icon: Icons.access_time,
                          text: _currentDuration == 0 ? 'Time' : '$_currentDuration min',
                          onTap: () async {
                            final result = await FocusPomodoroSheet.show(
                              context,
                              initialMinutes: _currentDuration == 0 ? 25 : _currentDuration,
                              initialPomodoroMinutes: _currentPomodorosPlanned > 0
                                  ? (_currentDuration / _currentPomodorosPlanned).round().clamp(5, 120)
                                  : 25,
                            );
                            if (result != null) {
                              setState(() {
                                _currentDuration = result['minutes']!;
                                _currentPomodorosPlanned = result['pomodoros']!;
                              });
                            }
                          },
                        ),

                        // 4. Repeat Pill
                        _buildPill(
                          icon: Icons.repeat,
                          text: _currentRecurrence.isRecurring
                              ? _currentRecurrence.label.replaceFirst('Repeats ', '')
                              : 'Repeat',
                          isSolid: _currentRecurrence.isRecurring,
                          onTap: () async {
                            final result = await RecurrencePicker.show(
                              context,
                              current: _currentRecurrence,
                              baseDate: _currentDate ?? DateTime.now(),
                            );
                            if (result != null) setState(() => _currentRecurrence = result);
                          },
                        ),

                        // 5. Reminder Pill
                        _buildPill(
                          icon: Icons.notifications_none,
                          text: _currentReminderMinutes == null
                              ? 'Remind'
                              : reminderPresetLabel(_currentReminderMinutes!),
                          isSolid: _currentReminderMinutes != null,
                          onTap: () async {
                            final result = await ReminderPicker.show(
                              context,
                              currentMinutes: _currentReminderMinutes,
                              hasDueDate: _currentDate != null,
                            );
                            if (result == null) return;
                            setState(() {
                              _currentReminderMinutes =
                                  result['remove'] == true ? null : result['minutes'] as int;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // Tags — pulled out of the meta pills row into its own
                    // labeled section with a bigger, icon-led chip, closer
                    // to the reference design's dedicated "Tags" block.
                    // Still one tag per task under the hood; the chip
                    // itself is tappable to change it, and the dashed
                    // circle adds one when there isn't one yet.
                    // ==========================================
                    const Text('Tags',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_currentTagLabel != null)
                          GestureDetector(
                            onTap: _openTagPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: Color(_currentTagColorValue!).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.label, size: 15, color: Color(_currentTagColorValue!)),
                                  const SizedBox(width: 6),
                                  Text(_currentTagLabel!,
                                      style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(_currentTagColorValue!))),
                                ],
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: _openTagPicker,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border, width: 1.4),
                            ),
                            child: const Icon(Icons.add, size: 17, color: AppColors.slateGray),
                          ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PomodoroActiveScreen(
                          task: _editedTask,
                          durationMinutes: _currentDuration > 0 ? _currentDuration : 25,
                          onSessionComplete: widget.onSessionComplete,
                        ),
                      ),
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