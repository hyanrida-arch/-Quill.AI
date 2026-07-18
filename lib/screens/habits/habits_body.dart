// lib/screens/habits/habits_body.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/habit.dart';
import '../../widgets/habits/add_habit_sheet.dart';
import 'habit_detail_screen.dart';

/// Habits owns its own header (menu + title + add), same pattern as
/// TasksBody/CalendarBody — AppShell doesn't wrap it in the shared
/// AppHeader.
class HabitsBody extends StatefulWidget {
  final List<Habit> habits;
  final ValueChanged<Habit> onAdd;
  final ValueChanged<Habit> onUpdate;
  final ValueChanged<Habit> onDelete;
  final VoidCallback onMenuTap;

  const HabitsBody({
    super.key,
    required this.habits,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onMenuTap,
  });

  @override
  State<HabitsBody> createState() => _HabitsBodyState();
}

class _HabitsBodyState extends State<HabitsBody> {
  List<Habit> get _activeHabits => widget.habits.where((h) => !h.archived).toList();

  void _openAdd() {
    AddHabitSheet.show(context, onSave: widget.onAdd);
  }

  void _openEdit(Habit h) {
    AddHabitSheet.show(context, editing: h, onSave: widget.onUpdate);
  }

  void _openDetail(Habit h) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitDetailScreen(
          habit: h,
          onUpdate: widget.onUpdate,
          onDelete: widget.onDelete,
        ),
      ),
    );
  }

  void _checkIn(Habit h) {
    HapticFeedback.lightImpact();
    final updated = h.type == HabitType.count
        ? h.withIncrement(DateTime.now())
        : h.withToggle(DateTime.now());
    widget.onUpdate(updated);
  }

  String _subtitle(List<Habit> habits) {
    if (habits.isEmpty) return 'Build your first habit';
    final due = habits.where((h) => h.isDueToday).length;
    final done = habits.where((h) => h.isDueToday && h.isDoneToday).length;
    if (due == 0) return 'Nothing scheduled today';
    return '$done of $due done today';
  }

  @override
  Widget build(BuildContext context) {
    final habits = _activeHabits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 20, top: 12, bottom: 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: AppColors.deepNavy, size: 28),
                onPressed: widget.onMenuTap,
              ),
              const SizedBox(width: 4),
              const Text('Habits',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.deepNavy, letterSpacing: -0.5)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.deepNavy, size: 26),
                onPressed: _openAdd,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 58, bottom: 12),
          child: Text(_subtitle(habits), style: const TextStyle(fontSize: 13.5, color: AppColors.slateGray)),
        ),
        Expanded(
          child: habits.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final h = habits[index];
                    return _HabitCard(
                      habit: h,
                      onTap: () => _openDetail(h),
                      onCheckIn: () => _checkIn(h),
                      onLongPressEdit: () => _openEdit(h),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.track_changes, size: 48, color: AppColors.slateGray),
            const SizedBox(height: 16),
            const Text('No habits yet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            const Text(
              'Small, repeated actions compound into real change. Add your first habit to start building a streak.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.slateGray, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Habit', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback onCheckIn;
  final VoidCallback onLongPressEdit;

  const _HabitCard({
    required this.habit,
    required this.onTap,
    required this.onCheckIn,
    required this.onLongPressEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = habit.color;
    final doneToday = habit.isDoneToday;
    final streak = habit.currentStreak;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPressEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
              child: Icon(habit.icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavy,
                        decoration: doneToday ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.slateGray),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(habit.frequency.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                      ),
                      if (streak > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.local_fire_department, size: 13, color: AppColors.amber),
                        const SizedBox(width: 2),
                        Text('$streak',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.amber)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _checkInControl(),
          ],
        ),
      ),
    );
  }

  Widget _checkInControl() {
    final color = habit.color;
    final doneToday = habit.isDoneToday;

    if (habit.type == HabitType.yesNo) {
      return GestureDetector(
        onTap: onCheckIn,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: doneToday ? color : Colors.transparent,
            border: Border.all(color: doneToday ? color : AppColors.border, width: 1.6),
          ),
          child: doneToday ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
        ),
      );
    }

    final count = habit.todayCount;
    final target = habit.targetCount;
    return GestureDetector(
      onTap: onCheckIn,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: doneToday ? color : color.withValues(alpha: 0.15),
            ),
            child: Text('$count',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: doneToday ? AppColors.white : color)),
          ),
          const SizedBox(height: 2),
          Text('/$target', style: const TextStyle(fontSize: 10, color: AppColors.slateGray)),
        ],
      ),
    );
  }
}
