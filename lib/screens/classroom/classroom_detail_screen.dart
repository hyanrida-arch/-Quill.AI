// lib/screens/classroom/classroom_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/classroom.dart';
import '../../models/task.dart';
import '../../widgets/classroom/create_classroom_sheet.dart';
import '../../widgets/tasks/add_task_sheet.dart';

/// Owns a local copy of both the classroom and the task list it was pushed
/// with, mutating them directly and bubbling every change up via
/// onUpdate/onAddTask/onToggleTask — same "own a working copy, callback
/// upward" pattern as HabitDetailScreen/TaskDetailScreen. This screen is a
/// separate pushed route, not a descendant of AppShell's widget tree, so it
/// can't just read AppShell's live lists; keeping a local copy is what lets
/// the progress bar and assigned-task list update immediately instead of
/// only after popping back.
class ClassroomDetailScreen extends StatefulWidget {
  final Classroom classroom;
  final bool isTeacher;
  final String userName;
  final List<Task> tasks;
  final ValueChanged<Classroom> onUpdate;
  final ValueChanged<Classroom> onDelete;
  final ValueChanged<Task> onAddTask;
  final ValueChanged<Task> onToggleTask;

  const ClassroomDetailScreen({
    super.key,
    required this.classroom,
    required this.isTeacher,
    required this.userName,
    required this.tasks,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddTask,
    required this.onToggleTask,
  });

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  late Classroom _classroom;
  late List<Task> _localTasks;

  @override
  void initState() {
    super.initState();
    _classroom = widget.classroom;
    _localTasks = List<Task>.from(widget.tasks);
  }

  void _update(Classroom updated) {
    setState(() => _classroom = updated);
    widget.onUpdate(updated);
  }

  List<Task> get _assignedTasks {
    final result = <Task>[];
    for (final id in _classroom.assignedTaskIds) {
      final match = _localTasks.where((t) => t.id == id);
      if (match.isNotEmpty) result.add(match.first);
    }
    return result;
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Today';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = dateOnly.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return 'Overdue';
    return '${date.day}/${date.month}';
  }

  // Reuses the exact same NewTaskDraft -> Task construction shape as
  // TasksBody/CalendarBody, except the tag is forced to this classroom's
  // name/color rather than whatever (if anything) the user picked — an
  // assigned task should always visibly belong to the classroom it came
  // from.
  void _assignTask() {
    showAddTaskSheet(
      context,
      onAdd: (draft) {
        final task = Task(
          id: 'task_${DateTime.now().microsecondsSinceEpoch}',
          title: draft.title,
          subject: _classroom.name,
          estimatedMinutes: draft.estimatedMinutes,
          pomodorosPlanned: draft.pomodorosPlanned ?? (draft.estimatedMinutes / 25).ceil().clamp(1, 8),
          priority: draft.priority == TaskPriority.none ? TaskPriority.medium : draft.priority,
          dueLabel: _dateLabel(draft.dueDate),
          dueDate: draft.dueDate,
          hasTime: draft.hasTime,
          tagLabel: _classroom.name,
          tagColorValue: _classroom.colorValue,
          recurrence: draft.recurrence,
          reminderMinutesBefore: draft.reminderMinutesBefore,
        );
        setState(() => _localTasks.add(task));
        widget.onAddTask(task);
        _update(_classroom.copyWith(assignedTaskIds: [..._classroom.assignedTaskIds, task.id]));
      },
    );
  }

  void _unassignTask(Task task) {
    _update(_classroom.copyWith(
      assignedTaskIds: _classroom.assignedTaskIds.where((id) => id != task.id).toList(),
    ));
  }

  void _toggleTask(Task task) {
    HapticFeedback.selectionClick();
    setState(() {
      final i = _localTasks.indexWhere((t) => t.id == task.id);
      if (i != -1) {
        _localTasks[i] = _localTasks[i].copyWith(
          status: task.isDone ? TaskStatus.pending : TaskStatus.completed,
        );
      }
    });
    widget.onToggleTask(task);
  }

  Future<void> _addMember() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add member', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && !_classroom.roster.contains(name)) {
      _update(_classroom.copyWith(roster: [..._classroom.roster, name]));
    }
  }

  void _removeMember(String name) {
    _update(_classroom.copyWith(roster: _classroom.roster.where((n) => n != name).toList()));
  }

  Future<void> _editClassroom() async {
    await CreateClassroomSheet.show(
      context,
      editing: _classroom,
      isTeacher: widget.isTeacher,
      ownerName: _classroom.ownerName,
      onSave: _update,
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete classroom?', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
        content: Text(
          'This removes "${_classroom.name}" and its roster. Tasks already assigned to it stay in your task list.',
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
      widget.onDelete(_classroom);
      Navigator.pop(context);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _classroom.joinCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Join code copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _classroom.color;
    final assigned = _assignedTasks;
    final doneCount = assigned.where((t) => t.isDone).length;
    final progress = assigned.isEmpty ? 0.0 : doneCount / assigned.length;

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
              if (value == 'edit') _editClassroom();
              if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18, color: AppColors.deepNavy),
                  SizedBox(width: 10),
                  Text('Edit classroom'),
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
                    child: Icon(
                      _classroom.type == ClassroomType.teacherClass ? Icons.school_outlined : Icons.groups_outlined,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_classroom.name,
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                        const SizedBox(height: 4),
                        Text('${_classroom.type.label} · Owned by ${_classroom.ownerName}',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.slateGray)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _copyCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.subtleGray, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, size: 16, color: AppColors.slateGray),
                      const SizedBox(width: 8),
                      Text('Join code: ${_classroom.joinCode}',
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.deepNavy, letterSpacing: 1)),
                      const Spacer(),
                      const Icon(Icons.copy_outlined, size: 16, color: AppColors.slateGray),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                  Text('$doneCount/${assigned.length} done',
                      style: const TextStyle(fontSize: 13, color: AppColors.slateGray)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.subtleGray,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Shows only your own completion on this device — Quill.AI has no shared backend yet, so per-member progress can\'t be tracked.',
                style: TextStyle(fontSize: 11.5, color: AppColors.slateGray, height: 1.4),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Assigned Tasks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                  GestureDetector(
                    onTap: _assignTask,
                    child: const Icon(Icons.add_circle_outline, color: AppColors.deepNavy, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (assigned.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No tasks assigned yet. Tap + to broadcast one to this classroom.',
                    style: TextStyle(fontSize: 13, color: AppColors.slateGray),
                  ),
                )
              else
                ...assigned.map(_taskRow),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Members (${_classroom.roster.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                  GestureDetector(
                    onTap: _addMember,
                    child: const Icon(Icons.person_add_alt_outlined, color: AppColors.deepNavy, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_classroom.roster.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No members yet — add names, or share the join code above.',
                    style: TextStyle(fontSize: 13, color: AppColors.slateGray),
                  ),
                )
              else
                ..._classroom.roster.map(_memberRow),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskRow(Task t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleTask(t),
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.isDone ? _classroom.color : Colors.transparent,
                border: Border.all(color: t.isDone ? _classroom.color : AppColors.border, width: 1.6),
              ),
              child: t.isDone ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.deepNavy,
                decoration: t.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _unassignTask(t),
            child: const Icon(Icons.close, size: 18, color: AppColors.slateGray),
          ),
        ],
      ),
    );
  }

  Widget _memberRow(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.subtleGray, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _classroom.color.withValues(alpha: 0.2),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _classroom.color)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.deepNavy))),
          GestureDetector(
            onTap: () => _removeMember(name),
            child: const Icon(Icons.close, size: 16, color: AppColors.slateGray),
          ),
        ],
      ),
    );
  }
}
