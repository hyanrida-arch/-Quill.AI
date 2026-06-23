// lib/widgets/tasks/add_task_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';

/// Show the Add Task bottom sheet.
void showAddTaskSheet(
  BuildContext context, {
  required Function(String, DateTime?) onAdd,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddTaskSheet(onAdd: onAdd),
  );
}

class AddTaskSheet extends StatefulWidget {
  final Function(String, DateTime?) onAdd;

  const AddTaskSheet({super.key, required this.onAdd});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _selectedQuickDate = 'Today';
  TimeOfDay? _selectedTime;
  bool _isTyping = false;
  ParsedTaskInput? _detectedNLP;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTitleChanged);
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
    widget.onAdd(finalTitle, _computeFinalDate());
    Navigator.pop(context);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      HapticFeedback.selectionClick();
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: AppBar().preferredSize.height),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New Task',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepNavy)),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.subtleGray,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.slateGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Input
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.deepNavy),
            decoration: const InputDecoration(
              hintText: 'Try: "Read chapter 4 tomorrow"',
              hintStyle: TextStyle(
                  color: AppColors.slateGray,
                  fontSize: 17,
                  fontWeight: FontWeight.w400),
              enabledBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.teal, width: 2)),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (_) => _handleAdd(),
          ),

          // NLP Detection Banner
          if (_detectedNLP != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightTeal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 16, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.deepNavy,
                            fontFamily: 'Inter'),
                        children: [
                          const TextSpan(text: 'Detected: '),
                          TextSpan(
                            text: _detectedNLP!.dueLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Pills (Priority, Date, Time)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSmallPill(Icons.flag_outlined, 'Priority'),
                const SizedBox(width: 8),
                _buildSmallPill(Icons.calendar_today, _selectedQuickDate,
                    isDark: true),
                const SizedBox(width: 8),
                _buildTimePill(),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickDateBox(Icons.wb_sunny, 'Today', Colors.orange),
              _buildQuickDateBox(
                  Icons.wb_twilight, 'Tomorrow', Colors.redAccent),
              _buildQuickDateBox(
                  Icons.calendar_month, '+7d', Colors.blueAccent),
              _buildQuickDateBox(
                  Icons.nightlight_round, 'Next Week', AppColors.amber),
            ],
          ),
          const SizedBox(height: 20),

          // Description
          TextField(
            controller: _descController,
            style: const TextStyle(
                fontSize: 14, color: AppColors.deepNavy),
            decoration: const InputDecoration(
              hintText: 'Add description...',
              hintStyle:
                  TextStyle(color: AppColors.slateGray, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.attach_file,
                    size: 20, color: AppColors.slateGray),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tap ✨ for AI assist',
                  style:
                      TextStyle(color: AppColors.slateGray, fontSize: 13),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isTyping ? _handleAdd : null,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Add',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isTyping ? AppColors.deepNavy : AppColors.border,
                  foregroundColor: _isTyping
                      ? AppColors.white
                      : AppColors.slateGray,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePill() {
    final hasTime = _selectedTime != null;
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: hasTime ? AppColors.lightTeal : AppColors.white,
          border: Border.all(
              color: hasTime ? AppColors.teal : AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time,
                size: 14,
                color: hasTime ? AppColors.teal : AppColors.slateGray),
            const SizedBox(width: 6),
            Text(
              hasTime ? _formatTime(_selectedTime!) : 'Time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasTime ? AppColors.teal : AppColors.deepNavy,
              ),
            ),
            if (hasTime) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _selectedTime = null),
                child: const Icon(Icons.close,
                    size: 12, color: AppColors.teal),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmallPill(IconData icon, String label,
      {bool isDark = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: label.isEmpty ? 12 : 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepNavy : AppColors.white,
        border: Border.all(
            color: isDark ? AppColors.deepNavy : AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isDark ? AppColors.white : AppColors.slateGray),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.deepNavy,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildQuickDateBox(
      IconData icon, String label, Color iconColor) {
    final isSelected = _selectedQuickDate == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedQuickDate = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepNavy : AppColors.white,
          border: Border.all(
              color:
                  isSelected ? AppColors.deepNavy : AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 22,
                color: isSelected ? AppColors.white : iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppColors.white : AppColors.deepNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}