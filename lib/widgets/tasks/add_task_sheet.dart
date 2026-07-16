// lib/widgets/tasks/add_task_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';

import 'priority_picker.dart';
import 'advanced_date_picker.dart';
import 'focus_pomodoro_sheet.dart';
import 'tag_picker.dart';
import 'recurrence_picker.dart';
import 'reminder_picker.dart';

void showAddTaskSheet(
    BuildContext context, {
      required ValueChanged<NewTaskDraft> onAdd,
      DateTime? initialDate,
      TimeOfDay? initialTime,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddTaskSheet(
      onAdd: onAdd,
      initialDate: initialDate,
      initialTime: initialTime,
    ),
  );
}

class AddTaskSheet extends StatefulWidget {
  final ValueChanged<NewTaskDraft> onAdd;
  // Pre-fills the date/time pill — used by the Calendar's tap-empty-slot
  // quick-create so the sheet opens already pointed at the slot you tapped
  // instead of defaulting to "Today, no time".
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const AddTaskSheet({super.key, required this.onAdd, this.initialDate, this.initialTime});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  TaskPriority _priority = TaskPriority.none;
  int _estimatedMinutes = 0;
  // Set only when the user explicitly picked a session count in the Focus
  // sheet — null falls back to the old ceil(estimatedMinutes / 25) default
  // at the call site that actually builds the Task.
  int? _pomodorosPlanned;
  DateTime? _exactDate;

  String _selectedQuickDate = 'Today';
  // The time-of-day picked via the Date pill's AdvancedDatePicker. Both used
  // to be read from the picker's result and then thrown away — only the
  // date made it onto the task. Now they flow into the final NewTaskDraft.
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedEndTime;
  bool _isTyping = false;
  ParsedTaskInput? _detectedNLP;
  String? _tagLabel;
  int? _tagColorValue;
  RecurrenceRule _recurrence = const RecurrenceRule();
  int? _reminderMinutes;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTitleChanged);
    if (widget.initialDate != null) {
      _exactDate = widget.initialDate;
      _selectedQuickDate = '';
    }
    if (widget.initialTime != null) {
      _selectedTime = widget.initialTime;
    }
  }

  void _onTitleChanged() {
    final text = _titleController.text;
    setState(() {
      _isTyping = text.isNotEmpty;
      if (text.length > 3) {
        final parsed = Task.parseInput(text);
        if (parsed.dueLabel != null && parsed.title != text) {
          _detectedNLP = parsed;
          if (parsed.dueLabel == 'Today') _selectedQuickDate = 'Today';
          if (parsed.dueLabel == 'Tomorrow') _selectedQuickDate = 'Tomorrow';
          if (parsed.dueLabel == 'Next Week') _selectedQuickDate = 'Next Week';
        } else {
          _detectedNLP = null;
        }
      } else {
        _detectedNLP = null;
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime _computeFinalDate() {
    if (_exactDate != null) return _attachTimeIfNeeded(_exactDate!);
    if (_detectedNLP?.dueDate != null) {
      return _attachTimeIfNeeded(_detectedNLP!.dueDate!);
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime base;
    switch (_selectedQuickDate) {
      case 'Tomorrow':
        base = today.add(const Duration(days: 1));
        break;
      case '+7d':
      case 'Next Week':
        base = today.add(const Duration(days: 7));
        break;
      default:
        base = today;
    }
    return _attachTimeIfNeeded(base);
  }

  DateTime _attachTimeIfNeeded(DateTime base) {
    if (_selectedTime == null) return base;
    return DateTime(base.year, base.month, base.day,
        _selectedTime!.hour, _selectedTime!.minute);
  }

  void _handleAdd() {
    if (!_isTyping) return;
    HapticFeedback.mediumImpact();
    final finalTitle = _detectedNLP?.title ?? _titleController.text.trim();
    widget.onAdd(NewTaskDraft(
      title: finalTitle,
      dueDate: _computeFinalDate(),
      hasTime: _selectedTime != null,
      priority: _priority,
      estimatedMinutes: _estimatedMinutes > 0 ? _estimatedMinutes : 30,
      tagLabel: _tagLabel,
      tagColorValue: _tagColorValue,
      recurrence: _recurrence,
      reminderMinutesBefore: _reminderMinutes,
      pomodorosPlanned: _pomodorosPlanned,
    ));
    Navigator.pop(context);
  }

  String _getDatePillText() {
    if (_detectedNLP?.dueLabel != null) return _detectedNLP!.dueLabel!;
    if (_exactDate != null) return Task.dateLabelFor(_exactDate);
    return _selectedQuickDate.isEmpty ? 'Today' : _selectedQuickDate;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: AppBar().preferredSize.height),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slateGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New Task',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepNavy)),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.subtleGray,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: AppColors.deepNavy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Input
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.deepNavy),
            decoration: const InputDecoration(
              hintText: 'What needs doing?',
              hintStyle: TextStyle(
                  color: AppColors.slateGray,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.teal, width: 2)),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onSubmitted: (_) => _handleAdd(),
          ),
          const SizedBox(height: 16),

          // NLP Detection Banner (AI Suggestion)
          if (_detectedNLP != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightTeal.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightTeal),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, size: 18, color: AppColors.teal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I detected this might be a high-priority task due ${_detectedNLP!.dueLabel?.toLowerCase()}. Want me to set it up?',
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.teal,
                              height: 1.4,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildAiBtn('Yes', isPrimary: true, onTap: () {}),
                      const SizedBox(width: 8),
                      _buildAiBtn('Skip', isPrimary: false, onTap: () => setState(() => _detectedNLP = null)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ==========================================
          // Interactive Pills (Row Scrolling الجديد)
          // ==========================================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. Priority
                _buildPill(
                  icon: Icons.flag_outlined,
                  text: _priority == TaskPriority.none ? 'Priority' : _priority.label.replaceAll(' Priority', ''),
                  iconColor: _priority == TaskPriority.none ? AppColors.slateGray : _priority.color,
                  onTap: () {
                    PriorityPicker.show(
                      context,
                      currentPriority: _priority,
                      onSelected: (p) => setState(() => _priority = p),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // 2. Date
                _buildPill(
                  icon: Icons.calendar_today_outlined,
                  text: _getDatePillText(),
                  isSolid: _exactDate != null || _selectedQuickDate.isNotEmpty,
                  onTap: () async {
                    final result = await AdvancedDatePicker.show(
                      context,
                      initialDate: _exactDate ?? DateTime.now(),
                      initialStartTime: _selectedTime,
                      initialEndTime: _selectedEndTime,
                    );
                    if (result != null && result['date'] != null) {
                      final start = result['startTime'] as TimeOfDay?;
                      final end = result['endTime'] as TimeOfDay?;
                      setState(() {
                        _exactDate = result['date'];
                        _selectedQuickDate = '';
                        _selectedTime = start;
                        _selectedEndTime = end;
                        // A start+end range picked in the picker's Duration
                        // tab overrides the separate duration pill — it's a
                        // more precise signal of how long the task actually
                        // takes than the generic 30-min default.
                        if (start != null && end != null) {
                          final startMins = start.hour * 60 + start.minute;
                          var endMins = end.hour * 60 + end.minute;
                          if (endMins <= startMins) endMins += 24 * 60;
                          _estimatedMinutes = endMins - startMins;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),

                // 3. Time (30 min placeholder)
                _buildPill(
                  icon: Icons.access_time,
                  text: _estimatedMinutes == 0 ? '30 min' : '$_estimatedMinutes min',
                  isSolid: _estimatedMinutes > 0, // كيولي كحل يلا تختار
                  onTap: () async {
                    final result = await FocusPomodoroSheet.show(
                      context,
                      initialMinutes: _estimatedMinutes == 0 ? 30 : _estimatedMinutes,
                      initialPomodoroMinutes: _pomodorosPlanned != null && _pomodorosPlanned! > 0
                          ? (_estimatedMinutes / _pomodorosPlanned!).round().clamp(5, 120)
                          : 25,
                    );
                    if (result != null) {
                      setState(() {
                        _estimatedMinutes = result['minutes']!;
                        _pomodorosPlanned = result['pomodoros'];
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),

                // 4. Repeat
                _buildPill(
                  icon: Icons.repeat,
                  text: _recurrence.isRecurring ? _recurrence.label.replaceFirst('Repeats ', '') : 'Repeat',
                  isSolid: _recurrence.isRecurring,
                  onTap: () async {
                    final result = await RecurrencePicker.show(
                      context,
                      current: _recurrence,
                      baseDate: _exactDate ?? DateTime.now(),
                    );
                    if (result != null) setState(() => _recurrence = result);
                  },
                ),
                const SizedBox(width: 8),

                // 4b. Reminder
                _buildPill(
                  icon: Icons.notifications_none,
                  text: _reminderMinutes == null ? 'Remind' : reminderPresetLabel(_reminderMinutes!),
                  isSolid: _reminderMinutes != null,
                  onTap: () async {
                    final result = await ReminderPicker.show(
                      context,
                      currentMinutes: _reminderMinutes,
                      hasDueDate: true,
                    );
                    if (result == null) return;
                    setState(() {
                      _reminderMinutes = result['remove'] == true ? null : result['minutes'] as int;
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 5. Classroom
                _buildPill(
                  icon: Icons.sell_outlined,
                  text: 'Classroom',
                  onTap: () {}, // إضافة اللوجيك من بعد
                ),
                const SizedBox(width: 8),

                // 6. Tag
                _buildPill(
                  icon: Icons.label_outline,
                  text: _tagLabel ?? 'Tag',
                  iconColor: _tagLabel != null ? Color(_tagColorValue!) : null,
                  isSolid: _tagLabel != null,
                  onTap: () async {
                    final result = await TagPicker.show(
                      context,
                      currentLabel: _tagLabel,
                      currentColorValue: _tagColorValue,
                    );
                    if (result == null) return;
                    if (result['remove'] == true) {
                      setState(() {
                        _tagLabel = null;
                        _tagColorValue = null;
                      });
                    } else {
                      setState(() {
                        _tagLabel = result['label'] as String;
                        _tagColorValue = result['color'] as int;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),

                // 7. Subtasks
                _buildPill(
                  icon: Icons.auto_awesome,
                  text: 'Subtasks',
                  onTap: () {}, // إضافة اللوجيك من بعد
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ==========================================
          // Quick Date Boxes
          // ==========================================
          Row(
            children: [
              Expanded(child: _buildQuickDateBox(Icons.wb_sunny, 'Today', Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickDateBox(Icons.wb_twilight, 'Tomorrow', Colors.redAccent)),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickDateBox(Icons.calendar_month, '+7d', Colors.blueGrey)),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickDateBox(Icons.nightlight_round, 'Next Week', AppColors.amber)),
            ],
          ),
          const SizedBox(height: 20),

          // ==========================================
          // Description
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _descController,
              minLines: 3,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: AppColors.deepNavy),
              decoration: const InputDecoration(
                hintText: 'Add details...',
                hintStyle: TextStyle(color: AppColors.slateGray, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // ==========================================
          // Bottom Actions
          // ==========================================
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.attach_file, size: 20, color: AppColors.slateGray),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tap ✨ for AI assist',
                  style: TextStyle(color: AppColors.slateGray, fontSize: 13),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isTyping ? _handleAdd : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTyping ? AppColors.deepNavy : AppColors.subtleGray,
                  foregroundColor: _isTyping ? AppColors.white : AppColors.slateGray,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // Helpers
  // ------------------------------------------

  Widget _buildAiBtn(String text, {required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.teal : AppColors.white,
          border: Border.all(color: isPrimary ? AppColors.teal : AppColors.teal.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPrimary ? AppColors.white : AppColors.teal),
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSolid ? AppColors.deepNavy : AppColors.white,
          border: Border.all(
            color: isSolid ? AppColors.deepNavy : AppColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSolid ? AppColors.white : (iconColor ?? AppColors.slateGray),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSolid ? AppColors.white : AppColors.deepNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateBox(IconData icon, String label, Color iconColor) {
    final isSelected = _selectedQuickDate == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedQuickDate = label;
          _exactDate = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepNavy : AppColors.white,
          border: Border.all(color: isSelected ? AppColors.deepNavy : AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: isSelected ? AppColors.white : iconColor),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.deepNavy,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2.5,
                width: 16,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}