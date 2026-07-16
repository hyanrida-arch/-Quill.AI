import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/home/mystro_insight_card.dart';
import '../../widgets/home/task_focus_card.dart';
import '../../widgets/tasks/add_task_sheet.dart';

/// Mystro owns nothing — it reads Task (the plan) and FocusSession (the
/// reality) and reports the gap between them. This is deliberately the
/// first and only computed signal for now; everything else Mystro shows
/// is still a static stub (chat, other insight buttons).
class MystroInsight {
  final String message;
  final String primaryLabel;

  const MystroInsight(this.message, this.primaryLabel);
}

MystroInsight computeMystroInsight(List<Task> tasks, List<FocusSession> sessions) {
  if (sessions.isEmpty) {
    final pending = tasks.where((t) => !t.isDone).length;
    if (pending == 0) {
      return const MystroInsight(
        "You're all caught up. Log a focus session and I'll start spotting patterns in how you actually work.",
        'View tasks',
      );
    }
    return MystroInsight(
      "You have $pending open task${pending == 1 ? '' : 's'} and no focus sessions logged yet. "
      "Start one and I'll learn your real pace instead of guessing.",
      'View tasks',
    );
  }

  final completed = sessions.where((s) => s.isSuccessful && s.plannedMinutes > 0).toList();
  if (completed.isNotEmpty) {
    final avgRatio = completed.map((s) => s.durationRatio).reduce((a, b) => a + b) / completed.length;
    if (avgRatio > 1.15) {
      final pct = ((avgRatio - 1) * 100).round();
      return MystroInsight(
        "Your focus sessions are running about $pct% longer than you estimate. "
        "Want me to pad your next few task estimates to match reality?",
        'View tasks',
      );
    }
    if (avgRatio < 0.85) {
      final pct = ((1 - avgRatio) * 100).round();
      return MystroInsight(
        "You're finishing focus sessions about $pct% faster than planned — "
        "your estimates might be padded more than they need to be.",
        'View tasks',
      );
    }
  }

  final neverStarted = tasks.where((t) => !t.isDone && !sessions.any((s) => s.taskId == t.id)).length;
  if (neverStarted > 0) {
    return MystroInsight(
      "$neverStarted of your open tasks ${neverStarted == 1 ? 'has' : 'have'} no focus session logged yet. "
      "Want to start with one of those?",
      'View tasks',
    );
  }

  final abandoned = sessions.where((s) => s.outcome == FocusOutcome.abandoned).length;
  if (abandoned > 0) {
    return MystroInsight(
      "You've abandoned $abandoned focus session${abandoned == 1 ? '' : 's'} recently. "
      "Want to try shorter sessions instead?",
      'View tasks',
    );
  }

  return const MystroInsight(
    "Your estimates and actual focus time are lining up well — keep going.",
    'View tasks',
  );
}

/// Content-only Home body. The AppShell provides the Scaffold, AppHeader,
/// Drawer and Mystro FAB. Stateful so "Today's Focus" updates when a task is
/// added via the Add Task sheet.
class HomeBody extends StatefulWidget {
  final String userName;
  final bool isTeacher;
  final VoidCallback onSeeAllTasks;
  final ValueChanged<Task> onStartPomodoro;

  // Task is the single source of truth, owned by AppShell. "Today's Focus"
  // is just a filtered view over it, and adding a task here writes back
  // through onAddTask instead of a local copy — so it also shows up in
  // Tasks and Calendar immediately.
  final List<Task> tasks;
  final ValueChanged<Task> onAddTask;

  // The other half of the "plan vs reality" loop — read here to compute
  // Mystro's insight for the student view.
  final List<FocusSession> sessions;

  const HomeBody({
    super.key,
    required this.userName,
    required this.isTeacher,
    required this.onSeeAllTasks,
    required this.onStartPomodoro,
    required this.tasks,
    required this.onAddTask,
    required this.sessions,
  });

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  List<Task> get _todaysFocus {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = widget.tasks.where((t) {
      if (t.isDone) return false;
      if (t.dueDate == null) {
        return t.dueLabel == 'Today' || t.dueLabel == 'Yesterday';
      }
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDay.isBefore(today) || dueDay.isAtSameMomentAs(today);
    }).toList();
    return due.take(2).toList();
  }

  void _openAddTask() {
    showAddTaskSheet(
      context,
      onAdd: (draft) {
        final task = Task(
          id: 'task_${DateTime.now().microsecondsSinceEpoch}',
          title: draft.title,
          subject: 'General',
          estimatedMinutes: draft.estimatedMinutes,
          pomodorosPlanned: draft.pomodorosPlanned ?? (draft.estimatedMinutes / 25).ceil().clamp(1, 8),
          priority: draft.priority == TaskPriority.none ? TaskPriority.medium : draft.priority,
          dueDate: draft.dueDate,
          dueLabel: draft.dueDate != null ? Task.dateLabelFor(draft.dueDate) : 'Today',
          hasTime: draft.hasTime,
          tagLabel: draft.tagLabel,
          tagColorValue: draft.tagColorValue,
          recurrence: draft.recurrence,
          reminderMinutesBefore: draft.reminderMinutesBefore,
        );
        widget.onAddTask(task);
      },
    );
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
    final insight = computeMystroInsight(widget.tasks, widget.sessions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _greeting(
          '${_partOfDay()}, $name.',
          'You have 2 hours of focus time scheduled tonight.',
        ),
        const SizedBox(height: 24),
        MystroInsightCard(
          message: insight.message,
          primaryButtonLabel: insight.primaryLabel,
          secondaryButtonLabel: 'Dismiss',
          onPrimaryTap: widget.onSeeAllTasks,
          onSecondaryTap: () {},
        ),
        const SizedBox(height: 28),
        _sectionHeader("Today's Focus"),
        const SizedBox(height: 12),
        ..._todaysFocus.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskFocusCard(
              task: t,
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
              "quality tends to drop after 90 minutes — want me to schedule a "
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
          title: 'ECON 301 · Lecture',
          meta: '10:30 AM · Hall B · 64 students',
          actionLabel: 'Open',
        ),
        const SizedBox(height: 12),
        const _PriorityItem(
          tag: 'GRADING',
          title: 'Midterm essays',
          meta: '22 of 47 graded · ~2h remaining',
          actionLabel: 'Resume',
        ),
      ],
    );
  }

  Widget _greeting(String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                  height: 1.2)),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.slateGray, height: 1.5)),
        ],
      );

  Widget _sectionHeader(String title) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy)),
          GestureDetector(
            onTap: widget.onSeeAllTasks,
            child: const Text('See all',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slateGray)),
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
              Text('Add task',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slateGray)),
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
                Text(tag,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slateGray,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavy)),
                const SizedBox(height: 4),
                Text(meta,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.slateGray)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.circular(20)),
            child: Text(actionLabel,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}
