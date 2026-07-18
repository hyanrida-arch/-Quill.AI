// lib/screens/habits/habit_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/habit.dart';
import '../../widgets/habits/add_habit_sheet.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _weekdayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  final ValueChanged<Habit> onUpdate;
  final ValueChanged<Habit> onDelete;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late Habit _habit;
  late DateTime _focusedMonth;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    final today = _dateOnly(DateTime.now());
    _focusedMonth = DateTime(today.year, today.month);
  }

  void _update(Habit updated) {
    setState(() => _habit = updated);
    widget.onUpdate(updated);
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta));
  }

  // Tapping a day in the heatmap backfills or corrects that day's
  // check-in directly — handy for logging yesterday's habit you forgot to
  // tick off, without needing a separate "edit past day" flow.
  void _tapDay(DateTime day) {
    final today = _dateOnly(DateTime.now());
    if (day.isAfter(today)) return; // can't check in for the future
    HapticFeedback.selectionClick();
    final updated = _habit.type == HabitType.count ? _habit.withIncrement(day) : _habit.withToggle(day);
    _update(updated);
  }

  Future<void> _editHabit() async {
    await AddHabitSheet.show(context, editing: _habit, onSave: _update);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete habit?', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
        content: Text(
          'This removes "${_habit.title}" and its entire check-in history. This can\'t be undone.',
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
      widget.onDelete(_habit);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _habit.color;

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.deepNavy),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'edit') _editHabit();
              if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18, color: AppColors.deepNavy),
                  SizedBox(width: 10),
                  Text('Edit habit'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: AppColors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
                    child: Icon(_habit.icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_habit.title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                        const SizedBox(height: 4),
                        Text(_habit.frequency.label,
                            style: const TextStyle(fontSize: 13, color: AppColors.slateGray)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.subtleGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat('Current', '${_habit.currentStreak}', Icons.local_fire_department, AppColors.amber),
                    _statDivider(),
                    _stat('Best', '${_habit.bestStreak}', Icons.emoji_events_outlined, color),
                    _statDivider(),
                    _stat('30-day', '${(_habit.completionRateOver(30) * 100).round()}%', Icons.insights, AppColors.teal),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(onTap: () => _shiftMonth(-1), child: const Icon(Icons.chevron_left, color: AppColors.deepNavy)),
                  Text('${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  GestureDetector(onTap: () => _shiftMonth(1), child: const Icon(Icons.chevron_right, color: AppColors.deepNavy)),
                ],
              ),
              const SizedBox(height: 12),
              _buildHeatmap(color),
              const SizedBox(height: 12),
              Text(
                'Tap a day to log or undo a check-in for that date.',
                style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 36, color: AppColors.border);

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
      ],
    );
  }

  Widget _buildHeatmap(Color color) {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Monday-first
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final gridCount = rows * 7;
    final today = _dateOnly(DateTime.now());

    return Column(
      children: [
        Row(
          children: _weekdayShort
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slateGray)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
          itemCount: gridCount,
          itemBuilder: (context, index) {
            final dayNum = index - leadingBlanks + 1;
            if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();
            final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
            final isFuture = day.isAfter(today);
            final isToday = day == today;
            final due = _habit.isDueOn(day);
            final done = _habit.isDoneOn(day);

            Color bg;
            Color fg;
            if (done) {
              bg = color;
              fg = AppColors.white;
            } else if (!due) {
              bg = AppColors.subtleGray;
              fg = AppColors.slateGray.withValues(alpha: 0.5);
            } else if (isFuture) {
              bg = AppColors.subtleGray;
              fg = AppColors.slateGray;
            } else {
              bg = AppColors.white;
              fg = AppColors.slateGray;
            }

            return GestureDetector(
              onTap: isFuture ? null : () => _tapDay(day),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: isToday ? Border.all(color: color, width: 1.6) : (due && !done ? Border.all(color: AppColors.border) : null),
                ),
                child: Text('$dayNum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
              ),
            );
          },
        ),
      ],
    );
  }
}
