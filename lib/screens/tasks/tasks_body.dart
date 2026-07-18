// lib/screens/tasks/tasks_body.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import '../../widgets/tasks/add_task_sheet.dart';
import '../chat/mystro_chat_screen.dart';
import 'task_detail_screen.dart';
import 'task_search_screen.dart';

enum TaskTab { all, today, upcoming, completed }

class TasksBody extends StatefulWidget {
  final bool isTeacher;
  final VoidCallback onMenuTap;
  final VoidCallback onClassroomTap;
  final String userName;

  // Task is the single source of truth, owned by AppShell. TasksBody just
  // renders a view over it and writes back through these callbacks instead
  // of keeping its own mock copy.
  final List<Task> tasks;
  final ValueChanged<Task> onAdd;
  final ValueChanged<Task> onToggleDone;
  final ValueChanged<Task> onDelete;
  final ValueChanged<Task> onUpdate;
  final ValueChanged<FocusSession> onSessionComplete;

  const TasksBody({
    super.key,
    required this.isTeacher,
    required this.onMenuTap,
    required this.onClassroomTap,
    required this.userName,
    required this.tasks,
    required this.onAdd,
    required this.onToggleDone,
    required this.onDelete,
    required this.onUpdate,
    required this.onSessionComplete,
  });

  @override
  State<TasksBody> createState() => _TasksBodyState();
}

class _TasksBodyState extends State<TasksBody> {
  TaskTab _selectedTab = TaskTab.today;
  bool _showCompleted = true;

  String _generateTaskId() => 'task_${DateTime.now().microsecondsSinceEpoch}';

  // ============================================================
  // FILTERED TASKS PER TAB
  // ============================================================

  List<Task> get _allList {
    return widget.tasks.where((t) => _showCompleted || !t.isDone).toList();
  }

  List<Task> get _todayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.tasks.where((t) {
      if (!_showCompleted && t.isDone) return false;
      if (t.dueDate == null) {
        return t.dueLabel == 'Today' || t.dueLabel == 'Yesterday';
      }
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDay.isBefore(today) || dueDay.isAtSameMomentAs(today);
    }).toList();
  }

  List<Task> get _upcomingTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.tasks.where((t) {
      if (!_showCompleted && t.isDone) return false;
      if (t.dueDate == null) {
        return t.dueLabel == 'Tomorrow' ||
            t.dueLabel == 'Next Week' ||
            (t.dueLabel?.startsWith('In ') ?? false);
      }
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDay.isAfter(today);
    }).toList();
  }

  List<Task> get _completedTasks {
    return widget.tasks.where((t) => t.isDone).toList();
  }

  List<Task> get _visibleTasks {
    switch (_selectedTab) {
      case TaskTab.all:
        return _allList;
      case TaskTab.today:
        return _todayTasks;
      case TaskTab.upcoming:
        return _upcomingTasks;
      case TaskTab.completed:
        return _completedTasks;
    }
  }

  String get _subtitle {
    final count = _visibleTasks.length;
    switch (_selectedTab) {
      case TaskTab.all:
        return count == 0 ? 'No tasks' : '$count total task${count == 1 ? '' : 's'}';
      case TaskTab.today:
        return count == 0 ? 'All caught up' : '$count task${count == 1 ? '' : 's'} for today';
      case TaskTab.upcoming:
        return count == 0 ? 'Nothing planned ahead' : '$count upcoming task${count == 1 ? '' : 's'}';
      case TaskTab.completed:
        return count == 0 ? 'No completed tasks yet' : '$count completed';
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================

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

  void _openAddTask() {
    showAddTaskSheet(
      context,
      onAdd: (draft) {
        final newTask = Task(
          id: _generateTaskId(),
          title: draft.title,
          subject: 'New Task',
          estimatedMinutes: draft.estimatedMinutes,
          pomodorosPlanned: draft.pomodorosPlanned ?? (draft.estimatedMinutes / 25).ceil().clamp(1, 8),
          priority: draft.priority == TaskPriority.none ? TaskPriority.medium : draft.priority,
          dueLabel: _dateLabel(draft.dueDate),
          dueDate: draft.dueDate,
          hasTime: draft.hasTime,
          tagLabel: draft.tagLabel,
          tagColorValue: draft.tagColorValue,
          recurrence: draft.recurrence,
          reminderMinutesBefore: draft.reminderMinutesBefore,
        );
        widget.onAdd(newTask);
      },
    );
  }

  // Recurring tasks stay a single list row (like Google Tasks/TickTick)
  // instead of exploding into one row per future date — completing one
  // just advances its dueDate to the series' next occurrence, while the
  // completed date itself is kept in completedOccurrences so Calendar can
  // still show history correctly.
  void _toggleDone(Task task) {
    HapticFeedback.lightImpact();
    if (task.recurrence.isRecurring && task.dueDate != null) {
      final wasDone = task.isOccurrenceDone(task.dueDate!);
      var updated = task.withOccurrenceToggled(task.dueDate!);
      if (!wasDone) updated = updated.advanceToNextOccurrence();
      widget.onUpdate(updated);
      return;
    }
    widget.onToggleDone(task);
  }

  void _skipOccurrence(Task task) {
    if (task.dueDate == null) return;
    final updated = task.withOccurrenceSkipped(task.dueDate!).advanceToNextOccurrence();
    widget.onUpdate(updated);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skipped this occurrence of "${task.title}"'),
        backgroundColor: AppColors.deepNavy,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _deleteTask(Task task) {
    widget.onDelete(task);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${task.title}" deleted'),
        backgroundColor: AppColors.deepNavy,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.teal,
          // Re-adding puts it back at the top of the list rather than its
          // exact original position — a minor trade-off of no longer owning
          // the list locally.
          onPressed: () => widget.onAdd(task),
        ),
      ),
    );
  }

  Future<void> _openDetail(Task task) async {
    final updated = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          task: task,
          onSessionComplete: widget.onSessionComplete,
          onDelete: widget.onDelete,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _visibleTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= الهيدر المترتب الجديد =================
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 20, top: 12, bottom: 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: AppColors.deepNavy, size: 28),
                onPressed: widget.onMenuTap,
              ),
              const SizedBox(width: 4),
              const Text(
                'Tasks',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.deepNavy, letterSpacing: -0.5),
              ),
              const Spacer(),

              // Search across every task, independent of the selected tab.
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.deepNavy, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskSearchScreen(
                        tasks: widget.tasks,
                        onUpdate: widget.onUpdate,
                        onToggleDone: _toggleDone,
                        onSessionComplete: widget.onSessionComplete,
                      ),
                    ),
                  );
                },
              ),

              // 1. أيكون الكلاسروم (جا هو الأول مورا الفراغ)
              IconButton(
                icon: const Icon(Icons.school_outlined, color: AppColors.deepNavy, size: 26),
                onPressed: widget.onClassroomTap,
              ),

              // 2. الثلاث نقط (جات مورا الكلاسروم، ومسحنا الأفاتار)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.deepNavy, size: 26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: AppColors.white,
                position: PopupMenuPosition.under,
                onSelected: (value) {
                  if (value == 'toggle_completed') {
                    setState(() => _showCompleted = !_showCompleted);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$value section coming soon')));
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_completed',
                    child: Row(
                      children: [
                        Icon(_showCompleted ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.deepNavy),
                        const SizedBox(width: 12),
                        Text(_showCompleted ? 'Hide completed' : 'Show completed', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.deepNavy)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'Filter',
                    child: Row(children: [Icon(Icons.filter_list_outlined, size: 20, color: AppColors.deepNavy), SizedBox(width: 12), Text('Filter', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.deepNavy))]),
                  ),
                  const PopupMenuItem(
                    value: 'Collaborate',
                    child: Row(children: [Icon(Icons.group_add_outlined, size: 20, color: AppColors.deepNavy), SizedBox(width: 12), Text('Collaborate', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.deepNavy))]),
                  ),
                  const PopupMenuItem(
                    value: 'Share',
                    child: Row(children: [Icon(Icons.share_outlined, size: 20, color: AppColors.deepNavy), SizedBox(width: 12), Text('Share', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.deepNavy))]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'Trash',
                    child: Row(children: [Icon(Icons.delete_outline, size: 20, color: AppColors.red), SizedBox(width: 12), Text('Trash', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.red))]),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Subtitle
        Padding(
          padding: const EdgeInsets.only(left: 58, bottom: 12),
          child: Text(_subtitle, style: const TextStyle(fontSize: 13.5, color: AppColors.slateGray)),
        ),

        // التبويبات الأربعة
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              _buildTab('All', TaskTab.all, _allList.length),
              const SizedBox(width: 20),
              _buildTab('Today', TaskTab.today, _todayTasks.length),
              const SizedBox(width: 20),
              _buildTab('Upcoming', TaskTab.upcoming, _upcomingTasks.length),
              const SizedBox(width: 20),
              _buildTab('Completed', TaskTab.completed, _completedTasks.length),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 16),

        // اللائحة
        Expanded(
          child: tasks.isEmpty
              ? _buildEmptyState()
              : AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: ListView.builder(
              key: ValueKey(_selectedTab),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              itemCount: tasks.isEmpty ? 1 : tasks.length + 1,
              itemBuilder: (context, index) {
                if (index == tasks.length || tasks.isEmpty) {
                  return _selectedTab != TaskTab.completed ? _buildInlineAddButton() : const SizedBox.shrink();
                }
                final task = tasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SwipeableTaskCard(
                    key: ValueKey(task.id),
                    task: task,
                    onToggleDone: () => _toggleDone(task),
                    onDelete: () => _deleteTask(task),
                    onSkipOccurrence: () => _skipOccurrence(task),
                    onTap: () => _openDetail(task),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineAddButton() {
    return GestureDetector(
      onTap: _openAddTask,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 24),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(color: AppColors.subtleGray, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: const Row(children: [Icon(Icons.add, color: AppColors.teal, size: 20), SizedBox(width: 12), Text('Add new task...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.teal))]),
      ),
    );
  }

  Widget _buildTab(String label, TaskTab tab, int count) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTab = tab);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.deepNavy : AppColors.slateGray)),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: isSelected ? AppColors.deepNavy : AppColors.subtleGray, borderRadius: BorderRadius.circular(8)),
                  child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? AppColors.white : AppColors.slateGray)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 2, width: 32, decoration: BoxDecoration(color: isSelected ? AppColors.deepNavy : Colors.transparent, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isCompleted = _selectedTab == TaskTab.completed;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(isCompleted ? Icons.task_alt_outlined : Icons.inbox_outlined, size: 70, color: AppColors.slateGray.withValues(alpha: 0.3)),
                if (!isCompleted) Positioned(top: 15, child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle))),
              ],
            ),
            const SizedBox(height: 24),
            Text(isCompleted ? 'No completed tasks' : 'No tasks yet', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            Text(isCompleted ? 'Tasks you finish will appear here.' : 'Let Mystro help you plan your day.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.slateGray, height: 1.5)),
            if (!isCompleted) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _openAddTask,
                icon: const Icon(Icons.add, size: 18, color: AppColors.white),
                label: const Text('Add task', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepNavy, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MystroChatScreen())),
                icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.teal),
                label: const Text('Ask Mystro', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.teal)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _SwipeableTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;
  final VoidCallback onSkipOccurrence;
  final VoidCallback onTap;

  const _SwipeableTaskCard({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onDelete,
    required this.onSkipOccurrence,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      background: Container(padding: const EdgeInsets.symmetric(horizontal: 24), decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(16)), alignment: Alignment.centerLeft, child: Row(children: [Icon(task.isDone ? Icons.undo : Icons.check, color: AppColors.white, size: 24), const SizedBox(width: 8), Text(task.isDone ? 'Undo' : 'Done', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14))])),
      secondaryBackground: Container(padding: const EdgeInsets.symmetric(horizontal: 24), decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(16)), alignment: Alignment.centerRight, child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Delete', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14)), SizedBox(width: 8), Icon(Icons.delete_outline, color: AppColors.white, size: 24)])),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggleDone();
          return false;
        }
        // Recurring tasks need to ask "this occurrence or the whole
        // series?" — matches Google Calendar/TickTick's own delete prompt.
        if (task.recurrence.isRecurring) {
          final choice = await _showRecurringDeleteSheet(context);
          if (choice == 'series') {
            return true;
          } else if (choice == 'occurrence') {
            onSkipOccurrence();
          }
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) onDelete();
      },
      child: _TaskCard(task: task, onToggleDone: onToggleDone, onTap: onTap),
    );
  }
}

/// Returns 'series', 'occurrence', or null (cancelled/tapped outside).
Future<String?> _showRecurringDeleteSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('This is a repeating task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          ),
          ListTile(
            leading: const Icon(Icons.event_busy_outlined, color: AppColors.deepNavy),
            title: const Text('Delete this occurrence', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(ctx, 'occurrence'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.red),
            title: const Text('Delete entire series', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(ctx, 'series'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleDone;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onToggleDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    final isDone = task.isDone;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDone ? AppColors.subtleGray : AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isOverdue ? AppColors.red.withValues(alpha: 0.6) : AppColors.border, width: isOverdue ? 1.5 : 1)),
        child: Opacity(
          opacity: isDone ? 0.55 : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onToggleDone,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 1, right: 12),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: isDone ? AppColors.deepNavy : Colors.transparent, border: Border.all(color: isDone ? AppColors.deepNavy : (isOverdue ? AppColors.red : AppColors.slateGray), width: 1.5)), child: isDone ? const Icon(Icons.check, size: 16, color: AppColors.white) : null),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.recurrence.isRecurring) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 3, right: 4),
                            child: Icon(Icons.repeat, size: 14, color: AppColors.slateGray),
                          ),
                        ],
                        Expanded(child: AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 200), style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.deepNavy, decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none, decorationColor: AppColors.slateGray, decorationThickness: 2, height: 1.3), child: Text(task.title))),
                        if (!isDone) ...[const SizedBox(width: 8), _PriorityPill(task: task, isOverdue: isOverdue)],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.subtleGray, borderRadius: BorderRadius.circular(6)), child: Text(task.subject, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slateGray))),
                        if (task.tagLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: task.displayColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text(task.tagLabel!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: task.displayColor)),
                          ),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.access_time, size: 12, color: AppColors.slateGray),
                          const SizedBox(width: 4),
                          Text('${task.estimatedMinutes} min', style: const TextStyle(fontSize: 12, color: AppColors.slateGray, fontWeight: FontWeight.w500)),
                        ]),
                        if (task.displayDueLabel != null)
                          Text(task.displayDueLabel!, style: TextStyle(fontSize: 12, color: isOverdue ? AppColors.red : AppColors.slateGray, fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500)),
                        if (task.reminderMinutesBefore != null)
                          const Icon(Icons.notifications, size: 13, color: AppColors.slateGray),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isDone) ...[const SizedBox(width: 8), Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.chevron_right, size: 20, color: AppColors.slateGray.withValues(alpha: 0.4)))],
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final Task task;
  final bool isOverdue;

  const _PriorityPill({required this.task, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    if (isOverdue) {
      return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.red.withValues(alpha: 0.3), width: 1)), child: const Text('OVERDUE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.red, letterSpacing: 0.5)));
    }
    Color color;
    String label;
    switch (task.priority) {
      case TaskPriority.high: color = AppColors.red; label = 'HIGH'; break;
      case TaskPriority.medium: color = AppColors.amber; label = 'MED'; break;
      case TaskPriority.low: color = AppColors.teal; label = 'LOW'; break;
      case TaskPriority.none: color = AppColors.slateGray; label = 'NONE'; break;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3), width: 1)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5))]));
  }
}