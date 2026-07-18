// lib/screens/classroom/classrooms_list_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/classroom.dart';
import '../../models/task.dart';
import '../../widgets/classroom/create_classroom_sheet.dart';
import '../../widgets/classroom/join_classroom_sheet.dart';
import 'classroom_detail_screen.dart';

/// Pushed via Navigator from AppShell's drawer/header "Classroom" entry
/// points — not a persistent AppSection tab, since it's a rarer,
/// deeper-nav destination than Tasks/Calendar/Habits/Pomodoro.
///
/// Keeps its own local copy of the classroom list (seeded from
/// widget.classrooms) because it's a separate pushed route: AppShell
/// rebuilding after onCreate/onUpdate/onDelete bubbles up doesn't rebuild
/// this already-constructed route with fresh constructor args. Every
/// mutation here updates the local copy AND calls the matching widget.on*
/// callback so AppShell's real, persisted list stays the source of truth.
class ClassroomsListScreen extends StatefulWidget {
  final List<Classroom> classrooms;
  final bool isTeacher;
  final String userName;
  final List<Task> tasks;
  final ValueChanged<Classroom> onCreate;
  final ValueChanged<Classroom> onUpdate;
  final ValueChanged<Classroom> onDelete;
  final ValueChanged<Task> onAddTask;
  final ValueChanged<Task> onToggleTask;

  const ClassroomsListScreen({
    super.key,
    required this.classrooms,
    required this.isTeacher,
    required this.userName,
    required this.tasks,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddTask,
    required this.onToggleTask,
  });

  @override
  State<ClassroomsListScreen> createState() => _ClassroomsListScreenState();
}

class _ClassroomsListScreenState extends State<ClassroomsListScreen> {
  late List<Classroom> _classrooms;

  @override
  void initState() {
    super.initState();
    _classrooms = List<Classroom>.from(widget.classrooms);
  }

  void _openCreate() {
    CreateClassroomSheet.show(
      context,
      isTeacher: widget.isTeacher,
      ownerName: widget.userName,
      onSave: (c) {
        setState(() => _classrooms.insert(0, c));
        widget.onCreate(c);
      },
    );
  }

  void _openJoin() {
    JoinClassroomSheet.show(
      context,
      existingClassrooms: _classrooms,
      memberName: widget.userName,
      onJoined: (updated) {
        setState(() {
          final i = _classrooms.indexWhere((c) => c.id == updated.id);
          if (i != -1) _classrooms[i] = updated;
        });
        widget.onUpdate(updated);
        _openDetail(updated);
      },
    );
  }

  void _openDetail(Classroom c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassroomDetailScreen(
          classroom: c,
          isTeacher: widget.isTeacher,
          userName: widget.userName,
          tasks: widget.tasks,
          onUpdate: (updated) {
            setState(() {
              final i = _classrooms.indexWhere((x) => x.id == updated.id);
              if (i != -1) _classrooms[i] = updated;
            });
            widget.onUpdate(updated);
          },
          onDelete: (deleted) {
            setState(() => _classrooms.removeWhere((x) => x.id == deleted.id));
            widget.onDelete(deleted);
          },
          onAddTask: widget.onAddTask,
          onToggleTask: widget.onToggleTask,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Classrooms',
            style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(child: _actionButton(icon: Icons.add, label: 'Create', onTap: _openCreate, filled: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _actionButton(icon: Icons.login, label: 'Join', onTap: _openJoin, filled: false)),
                ],
              ),
            ),
            Expanded(child: _classrooms.isEmpty ? _buildEmptyState() : _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? AppColors.deepNavy : AppColors.white,
          border: Border.all(color: filled ? AppColors.deepNavy : AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? AppColors.white : AppColors.deepNavy),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: filled ? AppColors.white : AppColors.deepNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 48, color: AppColors.slateGray),
            const SizedBox(height: 16),
            const Text('No classrooms yet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            const Text(
              'Create a study group or class to broadcast tasks to everyone in it, or join one with a code from someone on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.slateGray, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _classrooms.length,
      itemBuilder: (context, index) {
        final c = _classrooms[index];
        return GestureDetector(
          onTap: () => _openDetail(c),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.color.withValues(alpha: 0.15)),
                  child: Icon(
                    c.type == ClassroomType.teacherClass ? Icons.school_outlined : Icons.groups_outlined,
                    color: c.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      const SizedBox(height: 4),
                      Text(
                        '${c.type.label} · ${c.roster.length} member${c.roster.length == 1 ? '' : 's'} · '
                        '${c.assignedTaskIds.length} task${c.assignedTaskIds.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.slateGray),
              ],
            ),
          ),
        );
      },
    );
  }
}
