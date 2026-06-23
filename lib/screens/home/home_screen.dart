// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../widgets/home/mystro_insight_card.dart';
import '../../widgets/tasks/add_task_sheet.dart';

/// Content-only Home body. The AppShell provides the Scaffold, AppHeader,
/// Drawer and Mystro FAB.
class HomeBody extends StatefulWidget {
  final String userName;
  final bool isTeacher;
  final VoidCallback onSeeAllTasks;
  final ValueChanged<Task> onStartPomodoro;

  const HomeBody({
    super.key,
    required this.userName,
    required this.isTeacher,
    required this.onSeeAllTasks,
    required this.onStartPomodoro,
  });

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late List<Task> _focus;
  int _localCounter = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the focus list with first 2 mock student tasks
    _focus = Task.mockStudentTasks().take(2).toList();
  }

  /// Generates a guaranteed-unique ID using timestamp + counter.
  /// Survives hot reloads and avoids collisions across screens.
  String _generateTaskId() {
    return 'home_${DateTime.now().millisecondsSinceEpoch}_${_localCounter++}';
  }

  void _openAddTask() {
    showAddTaskSheet(
      context,
      onAdd: (title, date) {
        final newTask = Task(
          id: _generateTaskId(),
          title: title,
          subject: 'Quick Add',
          estimatedMinutes: 30,
          pomodorosPlanned: 1,
          priority: TaskPriority.medium,
          dueLabel: _dateLabel(date),
          dueDate: date,
        );
        setState(() => _focus.insert(0, newTask));
      },
    );
  }

  /// Convert a DateTime to a human-readable label.
  String _dateLabel(DateTime? date) {
    if (date == null) return 'Today';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final diff = dateOnly.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff <= 7) return 'In $diff days';
    if (diff > 7) return 'Next Week';
    if (diff < -1) return 'Overdue';
    return 'Today';
  }

  void _toggleTaskDone(Task task) {
    HapticFeedback.lightImpact();
    setState(() {
      final index = _focus.indexWhere((t) => t.id == task.id);
      if (index == -1) return;
      _focus[index] = _focus[index].copyWith(
        status: task.isDone ? TaskStatus.pending : TaskStatus.completed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      child: widget.isTeacher ? _teacher() : _student(),
    );
  }

  Widget _student() {
    final name = _firstName().isEmpty ? 'there' : _firstName();
    final pendingCount = _focus.where((t) => !t.isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _greeting(
          '${_partOfDay()}, $name.',
          pendingCount == 0
              ? 'All clear for today. Nice work.'
              : 'You have $pendingCount task${pendingCount == 1 ? '' : 's'} to focus on today.',
        ),
        const SizedBox(height: 24),
        MystroInsightCard(
          message:
              'Based on your calibration, your peak focus window is 9-11 AM. '
              'Want me to schedule your hardest task there tomorrow?',
          onPrimaryTap: () {},
          onSecondaryTap: () {},
        ),
        const SizedBox(height: 28),
        _sectionHeader("Today's Focus"),
        const SizedBox(height: 12),
        ..._focus.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InteractiveFocusCard(
              task: t,
              onToggleDone: () => _toggleTaskDone(t),
              onStartPomodoro: () => widget.onStartPomodoro(t),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _addTaskButton(),
      ],
    );
  }

  Widget _teacher() {
    final name = widget.userName.trim().isEmpty
        ? 'Professor'
        : widget.userName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _greeting(
          '${_partOfDay()},\n$name.',
          'You have 47 assignments awaiting feedback.',
        ),
        const SizedBox(height: 24),
        MystroInsightCard(
          message:
              "I noticed you've been grading for 3 days straight. Your feedback "
              "quality tends to drop after 90 minutes - want me to schedule a "
              "Grading Sprint for tomorrow morning?",
          primaryButtonLabel: 'Schedule sprint',
          secondaryButtonLabel: 'Not today',
          onPrimaryTap: () {},
          onSecondaryTap: () {},
        ),
        const SizedBox(height: 28),
        _sectionHeader("Today's Priorities"),
        const SizedBox(height: 12),
        const _PriorityItem(
          tag: 'LESSON',
          title: 'ECON 301 - Lecture',
          meta: '10:30 AM - Hall B - 64 students',
          actionLabel: 'Open',
        ),
        const SizedBox(height: 12),
        const _PriorityItem(
          tag: 'GRADING',
          title: 'Midterm essays',
          meta: '22 of 47 graded - ~2h remaining',
          actionLabel: 'Resume',
        ),
      ],
    );
  }

  Widget _greeting(String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slateGray,
              height: 1.5,
            ),
          ),
        ],
      );

  Widget _sectionHeader(String title) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
            ),
          ),
          GestureDetector(
            onTap: widget.onSeeAllTasks,
            child: const Text(
              'See all',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.slateGray,
              ),
            ),
          ),
        ],
      );

  Widget _addTaskButton() => GestureDetector(
        onTap: _openAddTask,
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.add, size: 18, color: AppColors.slateGray),
              SizedBox(width: 8),
              Text(
                'Add task',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slateGray,
                ),
              ),
            ],
          ),
        ),
      );

  String _firstName() {
    final n = widget.userName.trim();
    return n.isEmpty ? '' : n.split(' ').first;
  }

  String _partOfDay() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

// ============================================================
// INTERACTIVE FOCUS CARD
// ============================================================

class _InteractiveFocusCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleDone;
  final VoidCallback onStartPomodoro;

  const _InteractiveFocusCard({
    required this.task,
    required this.onToggleDone,
    required this.onStartPomodoro,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.isDone;
    final isOverdue = task.isOverdue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? AppColors.subtleGray : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? AppColors.red.withValues(alpha: 0.5)
              : AppColors.border,
          width: isOverdue ? 1.5 : 1,
        ),
      ),
      child: Opacity(
        opacity: isDone ? 0.55 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Isolated Checkbox
                GestureDetector(
                  onTap: onToggleDone,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, right: 12),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? AppColors.deepNavy
                                : Colors.transparent,
                            border: Border.all(
                              color: isDone
                                  ? AppColors.deepNavy
                                  : (isOverdue
                                      ? AppColors.red
                                      : AppColors.slateGray),
                              width: 1.5,
                            ),
                          ),
                          child: isDone
                              ? const Icon(Icons.check,
                                  size: 14, color: AppColors.white)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppColors.slateGray,
                          decorationThickness: 2,
                          height: 1.3,
                        ),
                        child: Text(task.title),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            task.subject,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slateGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppColors.slateGray,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${task.estimatedMinutes} min',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slateGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!isDone) ...[
                  const SizedBox(width: 8),
                  _PriorityDot(task: task, isOverdue: isOverdue),
                ],
              ],
            ),

            if (!isDone) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: onStartPomodoro,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.deepNavy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow,
                          size: 16, color: AppColors.white),
                      SizedBox(width: 6),
                      Text(
                        'Start Pomodoro',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRIORITY DOT (Student Focus Cards)
// ============================================================

class _PriorityDot extends StatelessWidget {
  final Task task;
  final bool isOverdue;

  const _PriorityDot({required this.task, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    if (isOverdue) {
      color = AppColors.red;
      label = 'OVERDUE';
    } else if (task.priority == TaskPriority.high) {
      color = AppColors.red;
      label = 'HIGH';
    } else if (task.priority == TaskPriority.medium) {
      color = AppColors.amber;
      label = 'MED';
    } else if (task.priority == TaskPriority.low) {
      color = AppColors.teal;
      label = 'LOW';
    } else {
      color = AppColors.slateGray;
      label = 'NONE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRIORITY ITEM (Teacher mode)
// ============================================================

class _PriorityItem extends StatelessWidget {
  final String tag;
  final String title;
  final String meta;
  final String actionLabel;

  const _PriorityItem({
    required this.tag,
    required this.title,
    required this.meta,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slateGray,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slateGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.deepNavy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}