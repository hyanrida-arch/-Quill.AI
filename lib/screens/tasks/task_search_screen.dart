// lib/screens/tasks/task_search_screen.dart
//
// Full-text search across every task (title, subject, tag, description) —
// not scoped to whatever tab happens to be selected in TasksBody. Opens
// straight into TaskDetailScreen on tap, same as the regular list.

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import 'task_detail_screen.dart';

class TaskSearchScreen extends StatefulWidget {
  final List<Task> tasks;
  final ValueChanged<Task> onUpdate;
  final ValueChanged<Task> onToggleDone;
  final ValueChanged<FocusSession> onSessionComplete;

  const TaskSearchScreen({
    super.key,
    required this.tasks,
    required this.onUpdate,
    required this.onToggleDone,
    required this.onSessionComplete,
  });

  @override
  State<TaskSearchScreen> createState() => _TaskSearchScreenState();
}

class _TaskSearchScreenState extends State<TaskSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Task> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return widget.tasks.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.subject.toLowerCase().contains(q) ||
          (t.tagLabel?.toLowerCase().contains(q) ?? false) ||
          t.description.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openDetail(Task task) async {
    final updated = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task, onSessionComplete: widget.onSessionComplete),
      ),
    );
    if (updated == null || !mounted) return;
    widget.onUpdate(updated);
    setState(() {}); // reflect the edit in the still-open results list
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final hasQuery = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(fontSize: 16, color: AppColors.deepNavy),
          decoration: const InputDecoration(
            hintText: 'Search tasks, subjects, tags...',
            hintStyle: TextStyle(color: AppColors.slateGray, fontSize: 16),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.slateGray, size: 20),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: SafeArea(
        child: !hasQuery
            ? const _SearchEmptyState(message: 'Search across every task by title, subject, tag, or description.')
            : results.isEmpty
                ? const _SearchEmptyState(message: 'No tasks match that search.')
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final t = results[index];
                      return _SearchResultRow(
                        task: t,
                        onTap: () => _openDetail(t),
                        onToggleDone: () => widget.onToggleDone(t),
                      );
                    },
                  ),
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;

  const _SearchResultRow({required this.task, required this.onTap, required this.onToggleDone});

  @override
  Widget build(BuildContext context) {
    final isDone = task.recurrence.isRecurring
        ? (task.dueDate != null ? task.isOccurrenceDone(task.dueDate!) : task.isDone)
        : task.isDone;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onToggleDone,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2, right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppColors.deepNavy : Colors.transparent,
                  border: Border.all(color: isDone ? AppColors.deepNavy : AppColors.slateGray, width: 1.5),
                ),
                child: isDone ? const Icon(Icons.check, size: 14, color: AppColors.white) : null,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (task.recurrence.isRecurring) ...[
                        const Icon(Icons.repeat, size: 13, color: AppColors.slateGray),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavy,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.subtleGray, borderRadius: BorderRadius.circular(6)),
                        child: Text(task.subject, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slateGray)),
                      ),
                      if (task.tagLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: task.displayColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(task.tagLabel!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: task.displayColor)),
                        ),
                      if (task.displayDueLabel != null)
                        Text(task.displayDueLabel!, style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final String message;
  const _SearchEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 40, color: AppColors.slateGray),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.slateGray)),
          ],
        ),
      ),
    );
  }
}
