// lib/models/task.dart
// Single source of truth for the Task model.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TaskPriority { high, medium, low, none }

enum TaskType { quick, timeBased, volume }

enum TaskStatus { pending, completed, overdue }

// ============================================================
// PRIORITY EXTENSION
// ============================================================
extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High Priority';
      case TaskPriority.medium:
        return 'Medium Priority';
      case TaskPriority.low:
        return 'Low Priority';
      case TaskPriority.none:
        return 'No Priority';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return AppColors.red;
      case TaskPriority.medium:
        return AppColors.amber;
      case TaskPriority.low:
        return AppColors.teal;
      case TaskPriority.none:
        return AppColors.slateGray;
    }
  }
}

class Task {
  final String id;
  final String title;
  final String subject;
  final int estimatedMinutes;
  final int pomodorosPlanned;
  final TaskPriority priority;
  final TaskType type;
  final TaskStatus status;
  final String? dueLabel;
  final DateTime? dueDate;
  final bool isTeacher;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.title,
    required this.subject,
    required this.estimatedMinutes,
    required this.pomodorosPlanned,
    this.priority = TaskPriority.medium,
    this.type = TaskType.timeBased,
    this.status = TaskStatus.pending,
    this.dueLabel,
    this.dueDate,
    this.isTeacher = false,
    this.completedAt,
  });

  // ============================================================
  // STATE GETTERS
  // ============================================================

  bool get isDone => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;
  bool get isOverdue {
    if (isDone) return false;
    if (status == TaskStatus.overdue) return true;
    if (dueDate == null) return false;
    final today = DateTime.now();
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final now = DateTime(today.year, today.month, today.day);
    return due.isBefore(now);
  }

  bool get isToday {
    if (dueLabel == 'Today') return true;
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isUpcoming {
    if (isDone) return false;
    if (isOverdue) return false;
    if (isToday) return false;
    if (dueDate == null && (dueLabel == null || dueLabel!.isEmpty)) {
      return false;
    }
    return true;
  }

  // ============================================================
  // PRIORITY HELPERS
  // ============================================================

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.red;
      case TaskPriority.medium:
        return AppColors.amber;
      case TaskPriority.low:
        return AppColors.teal;
      case TaskPriority.none:
        return AppColors.slateGray;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.high:
        return 'HIGH';
      case TaskPriority.medium:
        return 'MED';
      case TaskPriority.low:
        return 'LOW';
      case TaskPriority.none:
        return 'NONE';
    }
  }

  // ============================================================
  // STATE MUTATIONS (copyWith pattern)
  // ============================================================

  Task copyWith({
    String? id,
    String? title,
    String? subject,
    int? estimatedMinutes,
    int? pomodorosPlanned,
    TaskPriority? priority,
    TaskType? type,
    TaskStatus? status,
    String? dueLabel,
    DateTime? dueDate,
    bool? isTeacher,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      pomodorosPlanned: pomodorosPlanned ?? this.pomodorosPlanned,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      status: status ?? this.status,
      dueLabel: dueLabel ?? this.dueLabel,
      dueDate: dueDate ?? this.dueDate,
      isTeacher: isTeacher ?? this.isTeacher,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Task markAsDone() {
    return copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  Task markAsPending() {
    return copyWith(
      status: TaskStatus.pending,
      completedAt: null,
    );
  }

  // ============================================================
  // SIMPLE NLP — parse "tomorrow", "today", "next week" from text
  // ============================================================

  static ParsedTaskInput parseInput(String input) {
    String cleaned = input.trim();
    String? dueLabel;
    DateTime? dueDate;
    final now = DateTime.now();

    final patterns = <RegExp, ({String label, DateTime date})>{
      RegExp(r'\btoday\b', caseSensitive: false): (
        label: 'Today',
        date: DateTime(now.year, now.month, now.day),
      ),
      RegExp(r'\btomorrow\b', caseSensitive: false): (
        label: 'Tomorrow',
        date:
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      ),
      RegExp(r'\bnext week\b', caseSensitive: false): (
        label: 'Next Week',
        date:
            DateTime(now.year, now.month, now.day).add(const Duration(days: 7)),
      ),
      RegExp(r'\bin (\d+) days?\b', caseSensitive: false): (
        label: '',
        date: now,
      ),
    };

    for (final entry in patterns.entries) {
      final match = entry.key.firstMatch(cleaned);
      if (match != null) {
        if (entry.key.pattern.contains(r'\d')) {
          final daysStr = match.group(1);
          if (daysStr != null) {
            final days = int.tryParse(daysStr) ?? 0;
            dueDate = DateTime(now.year, now.month, now.day)
                .add(Duration(days: days));
            dueLabel = 'In $days days';
          }
        } else {
          dueLabel = entry.value.label;
          dueDate = entry.value.date;
        }
        cleaned = cleaned.replaceAll(entry.key, '').trim();
        cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
        break;
      }
    }

    return ParsedTaskInput(
      title: cleaned.isEmpty ? input : cleaned,
      dueLabel: dueLabel,
      dueDate: dueDate,
    );
  }

  // ============================================================
  // MOCK DATA
  // ============================================================

  static List<Task> mockTasks(bool isTeacher) =>
      isTeacher ? mockTeacherTasks() : mockStudentTasks();

  static List<Task> mockStudentTasks() {
    return const [
      Task(
        id: 's1',
        title: 'Read Chapter 4 - Macroeconomics',
        subject: 'Economics',
        estimatedMinutes: 45,
        pomodorosPlanned: 2,
        priority: TaskPriority.high,
        dueLabel: 'Today',
      ),
      Task(
        id: 's2',
        title: 'Solve problem set #3',
        subject: 'Calculus',
        estimatedMinutes: 60,
        pomodorosPlanned: 2,
        priority: TaskPriority.high,
        dueLabel: 'Today',
      ),
      Task(
        id: 's3',
        title: 'Review lecture notes',
        subject: 'Behavioral Econ',
        estimatedMinutes: 30,
        pomodorosPlanned: 1,
        priority: TaskPriority.medium,
        dueLabel: 'Tomorrow',
      ),
      Task(
        id: 's4',
        title: 'Finish lab report',
        subject: 'Physics',
        estimatedMinutes: 50,
        pomodorosPlanned: 2,
        priority: TaskPriority.high,
        status: TaskStatus.overdue,
        dueLabel: 'Yesterday',
      ),
      Task(
        id: 's5',
        title: 'Read research paper',
        subject: 'Statistics',
        estimatedMinutes: 40,
        pomodorosPlanned: 2,
        priority: TaskPriority.low,
        dueLabel: 'Next Week',
      ),
    ];
  }

  static List<Task> mockTeacherTasks() {
    return const [
      Task(
        id: 't1',
        title: 'Grade midterm essays',
        subject: 'ECON 301',
        estimatedMinutes: 120,
        pomodorosPlanned: 5,
        priority: TaskPriority.high,
        dueLabel: 'Today',
        isTeacher: true,
      ),
      Task(
        id: 't2',
        title: 'Prepare lecture slides',
        subject: 'ECON 301',
        estimatedMinutes: 60,
        pomodorosPlanned: 2,
        priority: TaskPriority.medium,
        dueLabel: 'Today',
        isTeacher: true,
      ),
      Task(
        id: 't3',
        title: 'Review student submissions',
        subject: 'STAT 210',
        estimatedMinutes: 45,
        pomodorosPlanned: 2,
        priority: TaskPriority.medium,
        dueLabel: 'Tomorrow',
        isTeacher: true,
      ),
      Task(
        id: 't4',
        title: 'Faculty meeting prep',
        subject: 'Department',
        estimatedMinutes: 30,
        pomodorosPlanned: 1,
        priority: TaskPriority.low,
        dueLabel: 'Next Week',
        isTeacher: true,
      ),
    ];
  }
}

/// Result of parsing user input via simple NLP.
class ParsedTaskInput {
  final String title;
  final String? dueLabel;
  final DateTime? dueDate;

  const ParsedTaskInput({
    required this.title,
    this.dueLabel,
    this.dueDate,
  });
}