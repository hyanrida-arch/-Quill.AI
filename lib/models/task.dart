// lib/models/task.dart
// Single source of truth for the Task model.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TaskPriority { high, medium, low, none }

enum TaskType { quick, timeBased, volume }

enum TaskStatus { pending, completed, overdue }

enum RecurrenceType { none, daily, weekly, monthly }

// ============================================================
// RECURRENCE — daily / weekly-on-specific-weekdays / monthly, with an
// optional end date. Deliberately doesn't attempt a full RRULE spec —
// this covers "every day", "every Mon/Wed/Fri", and "same date each
// month", which is what a student/teacher actually needs day to day.
// ============================================================
class RecurrenceRule {
  final RecurrenceType type;
  // 1=Mon .. 7=Sun (DateTime.weekday convention). Only used when
  // type == weekly; empty means "same weekday as the start date".
  final Set<int> weekdays;
  final DateTime? endDate;

  const RecurrenceRule({
    this.type = RecurrenceType.none,
    this.weekdays = const {},
    this.endDate,
  });

  bool get isRecurring => type != RecurrenceType.none;

  static const List<String> _weekdayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get label {
    switch (type) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.daily:
        return 'Repeats daily';
      case RecurrenceType.weekly:
        if (weekdays.isEmpty) return 'Repeats weekly';
        final sorted = weekdays.toList()..sort();
        return 'Repeats on ${sorted.map((d) => _weekdayNames[d]).join(', ')}';
      case RecurrenceType.monthly:
        return 'Repeats monthly';
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'weekdays': weekdays.toList(),
        'endDate': endDate?.toIso8601String(),
      };

  factory RecurrenceRule.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RecurrenceRule();
    return RecurrenceRule(
      type: RecurrenceType.values.byName(json['type'] as String? ?? 'none'),
      weekdays: ((json['weekdays'] as List<dynamic>?) ?? const [])
          .map((e) => e as int)
          .toSet(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    );
  }
}

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

// ============================================================
// SUBTASK — a small checklist item that lives inside a Task. Previously
// these were kept as screen-local state in TaskDetailScreen (a plain
// LocalSubtask class that was never written back to the Task or saved),
// so closing and reopening a task silently reset its checklist to empty
// every time. Making this a real field on Task fixes that.
// ============================================================
class Subtask {
  final String id;
  final String title;
  final bool isDone;

  const Subtask({required this.id, required this.title, this.isDone = false});

  Subtask copyWith({String? title, bool? isDone}) => Subtask(
        id: id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'isDone': isDone};

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'] as String,
        title: json['title'] as String,
        isDone: json['isDone'] as bool? ?? false,
      );
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
  final String description;

  // True only when the user explicitly picked a time of day (not just a
  // date) for this task. Lets the Calendar tell "due sometime today"
  // tasks apart from "due at 3pm" tasks — the former go in the all-day
  // strip, the latter get positioned in the hourly grid.
  final bool hasTime;

  // Custom tag — a user-chosen label + color, independent of priority.
  // Calendar/Task cards use this as the primary color when set, falling
  // back to the priority color otherwise.
  final String? tagLabel;
  final int? tagColorValue; // Color.toARGB32(), nullable so "no tag" is distinct from "tag with color 0"

  final RecurrenceRule recurrence;
  // Date-only entries (year/month/day, time stripped) — which occurrences
  // of a recurring task have been marked done, or deleted ("this event
  // only" rather than the whole series). Non-recurring tasks ignore both
  // and use status/completedAt directly, same as before.
  final Set<DateTime> completedOccurrences;
  final Set<DateTime> skippedOccurrences;

  // How long before dueDate to fire a local notification. Null = no
  // reminder set. 0 = right at the due time. See kReminderPresets below
  // for the values the UI actually offers.
  final int? reminderMinutesBefore;

  final List<Subtask> subtasks;

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
    this.description = '',
    this.hasTime = false,
    this.tagLabel,
    this.tagColorValue,
    this.recurrence = const RecurrenceRule(),
    this.completedOccurrences = const {},
    this.skippedOccurrences = const {},
    this.reminderMinutesBefore,
    this.subtasks = const [],
  });

  Color? get tagColor => tagColorValue != null ? Color(tagColorValue!) : null;

  /// Priority color and tag color both feed into how blocks render — a
  /// custom tag takes precedence since it's the more specific choice.
  Color get displayColor => tagColor ?? priorityColor;

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

  /// The label to actually render on screen. Unlike the stored [dueLabel]
  /// (which is frozen the moment a task is created/edited), this recomputes
  /// live from [dueDate] on every read — so a task due "Tomorrow" correctly
  /// turns into "Overdue" a few days later instead of saying "Tomorrow"
  /// forever. Falls back to the stored [dueLabel] only for the rare task
  /// that has a label but no real date attached.
  String? get displayDueLabel {
    if (dueDate == null) return dueLabel;
    return Task.dateLabelFor(dueDate);
  }

  // ============================================================
  // REMINDERS
  // ============================================================

  /// The moment a reminder counts down from — the task's own due time if
  /// one was picked, else a sensible default (9 AM) for date-only tasks so
  /// "remind me a day before" still means something.
  DateTime? get reminderAnchor {
    if (dueDate == null) return null;
    if (hasTime) return dueDate;
    return DateTime(dueDate!.year, dueDate!.month, dueDate!.day, 9, 0);
  }

  /// The exact instant a local notification should fire, or null if no
  /// reminder is set / there's nothing to anchor it to.
  DateTime? get reminderFireAt {
    if (reminderMinutesBefore == null || reminderAnchor == null) return null;
    return reminderAnchor!.subtract(Duration(minutes: reminderMinutesBefore!));
  }

  String get reminderLabel =>
      reminderMinutesBefore == null ? 'No reminder' : reminderPresetLabel(reminderMinutesBefore!);

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
    String? description,
    bool? hasTime,
    String? tagLabel,
    int? tagColorValue,
    RecurrenceRule? recurrence,
    Set<DateTime>? completedOccurrences,
    Set<DateTime>? skippedOccurrences,
    int? reminderMinutesBefore,
    bool clearReminder = false,
    List<Subtask>? subtasks,
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
      description: description ?? this.description,
      hasTime: hasTime ?? this.hasTime,
      tagLabel: tagLabel ?? this.tagLabel,
      tagColorValue: tagColorValue ?? this.tagColorValue,
      recurrence: recurrence ?? this.recurrence,
      completedOccurrences: completedOccurrences ?? this.completedOccurrences,
      skippedOccurrences: skippedOccurrences ?? this.skippedOccurrences,
      reminderMinutesBefore: clearReminder ? null : (reminderMinutesBefore ?? this.reminderMinutesBefore),
      subtasks: subtasks ?? this.subtasks,
    );
  }

  /// copyWith can't null out tagLabel/tagColorValue (its `??` pattern can't
  /// tell "not passed" from "explicitly null") — this is the dedicated way
  /// to remove a tag entirely.
  Task clearTag() => Task(
        id: id,
        title: title,
        subject: subject,
        estimatedMinutes: estimatedMinutes,
        pomodorosPlanned: pomodorosPlanned,
        priority: priority,
        type: type,
        status: status,
        dueLabel: dueLabel,
        dueDate: dueDate,
        isTeacher: isTeacher,
        completedAt: completedAt,
        description: description,
        hasTime: hasTime,
        recurrence: recurrence,
        completedOccurrences: completedOccurrences,
        skippedOccurrences: skippedOccurrences,
        reminderMinutesBefore: reminderMinutesBefore,
        subtasks: subtasks,
      );

  Task markAsDone() {
    return copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  // ============================================================
  // RECURRENCE — occurrence generation + per-occurrence completion
  // ============================================================

  static DateTime _d(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _containsDate(Set<DateTime> set, DateTime date) {
    final d = _d(date);
    return set.any((e) => e.year == d.year && e.month == d.month && e.day == d.day);
  }

  /// All the dates (within [rangeStart, rangeEnd], inclusive, date-only)
  /// this task actually falls on — a single date for a one-off task, or
  /// every matching date for a recurring one. Callers (Tasks list,
  /// Calendar) iterate this instead of trusting a single dueDate once
  /// recurrence is involved.
  List<DateTime> occurrencesBetween(DateTime rangeStart, DateTime rangeEnd) {
    if (dueDate == null) return const [];
    final base = _d(dueDate!);
    final start = _d(rangeStart);
    final end = _d(rangeEnd);

    if (!recurrence.isRecurring) {
      if (!base.isBefore(start) && !base.isAfter(end)) return [base];
      return const [];
    }

    final hardEnd = recurrence.endDate != null && _d(recurrence.endDate!).isBefore(end)
        ? _d(recurrence.endDate!)
        : end;
    if (base.isAfter(hardEnd)) return const [];

    final result = <DateTime>[];
    switch (recurrence.type) {
      case RecurrenceType.daily:
        var d = base;
        while (!d.isAfter(hardEnd)) {
          if (!d.isBefore(start) && !_containsDate(skippedOccurrences, d)) result.add(d);
          d = d.add(const Duration(days: 1));
        }
        break;
      case RecurrenceType.weekly:
        final days = recurrence.weekdays.isEmpty ? {base.weekday} : recurrence.weekdays;
        var d = base;
        while (!d.isAfter(hardEnd)) {
          if (days.contains(d.weekday) && !d.isBefore(start) && !_containsDate(skippedOccurrences, d)) {
            result.add(d);
          }
          d = d.add(const Duration(days: 1));
        }
        break;
      case RecurrenceType.monthly:
        var d = base;
        while (!d.isAfter(hardEnd)) {
          if (!d.isBefore(start) && !_containsDate(skippedOccurrences, d)) result.add(d);
          d = d.month == 12 ? DateTime(d.year + 1, 1, d.day) : DateTime(d.year, d.month + 1, d.day);
        }
        break;
      case RecurrenceType.none:
        break;
    }
    return result;
  }

  bool isOccurrenceDone(DateTime date) {
    if (!recurrence.isRecurring) return isDone;
    return _containsDate(completedOccurrences, date);
  }

  Task withOccurrenceToggled(DateTime date) {
    final d = _d(date);
    if (!recurrence.isRecurring) return isDone ? markAsPending() : markAsDone();
    final updated = Set<DateTime>.from(completedOccurrences);
    if (_containsDate(updated, d)) {
      updated.removeWhere((e) => e.year == d.year && e.month == d.month && e.day == d.day);
    } else {
      updated.add(d);
    }
    return copyWith(completedOccurrences: updated);
  }

  /// Removes just this one occurrence from a recurring series ("delete
  /// this event" rather than "delete the series" — the series itself is
  /// removed from AppShell's list the normal way).
  Task withOccurrenceSkipped(DateTime date) {
    final d = _d(date);
    final updated = Set<DateTime>.from(skippedOccurrences)..add(d);
    return copyWith(skippedOccurrences: updated);
  }

  /// Moves dueDate to this series' next occurrence after the current one.
  /// The Tasks list only ever shows a recurring task's single next instance
  /// (like Google Tasks/TickTick) — completing it advances the pointer
  /// instead of exploding one task into dozens of list rows. Returns the
  /// task unchanged if it isn't recurring, has no dueDate, or the series
  /// has ended (recurrence.endDate already passed).
  Task advanceToNextOccurrence() {
    if (!recurrence.isRecurring || dueDate == null) return this;
    final next = _nextOccurrenceAfter(dueDate!);
    if (next == null) return this;
    // Preserve whatever time-of-day the series runs at.
    final withTime = hasTime
        ? DateTime(next.year, next.month, next.day, dueDate!.hour, dueDate!.minute)
        : next;
    return copyWith(dueDate: withTime, dueLabel: Task.dateLabelFor(withTime));
  }

  DateTime? _nextOccurrenceAfter(DateTime after) {
    final base = _d(dueDate!);
    final searchLimit = _d(after).add(const Duration(days: 730));
    final hardEnd = recurrence.endDate != null && _d(recurrence.endDate!).isBefore(searchLimit)
        ? _d(recurrence.endDate!)
        : searchLimit;

    DateTime d;
    switch (recurrence.type) {
      case RecurrenceType.daily:
        d = _d(after).add(const Duration(days: 1));
        while (!d.isAfter(hardEnd)) {
          if (!_containsDate(skippedOccurrences, d)) return d;
          d = d.add(const Duration(days: 1));
        }
        return null;
      case RecurrenceType.weekly:
        final days = recurrence.weekdays.isEmpty ? {base.weekday} : recurrence.weekdays;
        d = _d(after).add(const Duration(days: 1));
        while (!d.isAfter(hardEnd)) {
          if (days.contains(d.weekday) && !_containsDate(skippedOccurrences, d)) return d;
          d = d.add(const Duration(days: 1));
        }
        return null;
      case RecurrenceType.monthly:
        d = _d(after).month == 12
            ? DateTime(_d(after).year + 1, 1, base.day)
            : DateTime(_d(after).year, _d(after).month + 1, base.day);
        while (!d.isAfter(hardEnd)) {
          if (!_containsDate(skippedOccurrences, d)) return d;
          d = d.month == 12 ? DateTime(d.year + 1, 1, d.day) : DateTime(d.year, d.month + 1, d.day);
        }
        return null;
      case RecurrenceType.none:
        return null;
    }
  }

  // ============================================================
  // JSON SERIALIZATION (local persistence)
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'estimatedMinutes': estimatedMinutes,
      'pomodorosPlanned': pomodorosPlanned,
      'priority': priority.name,
      'type': type.name,
      'status': status.name,
      'dueLabel': dueLabel,
      'dueDate': dueDate?.toIso8601String(),
      'isTeacher': isTeacher,
      'completedAt': completedAt?.toIso8601String(),
      'description': description,
      'hasTime': hasTime,
      'tagLabel': tagLabel,
      'tagColorValue': tagColorValue,
      'recurrence': recurrence.toJson(),
      'completedOccurrences': completedOccurrences.map((d) => d.toIso8601String()).toList(),
      'skippedOccurrences': skippedOccurrences.map((d) => d.toIso8601String()).toList(),
      'reminderMinutesBefore': reminderMinutesBefore,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
      pomodorosPlanned: json['pomodorosPlanned'] as int,
      priority: TaskPriority.values.byName(json['priority'] as String),
      type: TaskType.values.byName(json['type'] as String),
      status: TaskStatus.values.byName(json['status'] as String),
      dueLabel: json['dueLabel'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isTeacher: json['isTeacher'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      description: json['description'] as String? ?? '',
      hasTime: json['hasTime'] as bool? ?? false,
      tagLabel: json['tagLabel'] as String?,
      tagColorValue: json['tagColorValue'] as int?,
      recurrence: RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>?),
      completedOccurrences: ((json['completedOccurrences'] as List<dynamic>?) ?? const [])
          .map((e) => DateTime.parse(e as String))
          .toSet(),
      skippedOccurrences: ((json['skippedOccurrences'] as List<dynamic>?) ?? const [])
          .map((e) => DateTime.parse(e as String))
          .toSet(),
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
      subtasks: ((json['subtasks'] as List<dynamic>?) ?? const [])
          .map((e) => Subtask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Task markAsPending() {
    return copyWith(
      status: TaskStatus.pending,
      completedAt: null,
    );
  }

  // ============================================================
  // Helper Method: dateLabelFor (هادي هي اللي كانت ناقصة)
  // ============================================================
  static String dateLabelFor(DateTime? date) {
    if (date == null) return 'No Date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final diff = dateOnly.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Overdue · Yesterday';
    if (diff < -1) return 'Overdue · ${-diff}d ago';
    if (diff > 1 && diff <= 7) return 'In $diff days';

    return '${date.day}/${date.month}';
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

  // Real dueDate values (computed relative to "now" the moment this seed
  // runs, which only ever happens once — see LocalStorageService) instead
  // of a frozen dueLabel string. Without a real date, these would say
  // "Today"/"Tomorrow" forever, even weeks after the app was first opened.
  static List<Task> mockStudentTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      Task(
        id: 's1',
        title: 'Read Chapter 4 - Macroeconomics',
        subject: 'Economics',
        estimatedMinutes: 45,
        pomodorosPlanned: 2,
        priority: TaskPriority.high,
        dueDate: today,
      ),
      Task(
        id: 's2',
        title: 'Solve problem set #3',
        subject: 'Calculus',
        estimatedMinutes: 60,
        pomodorosPlanned: 2,
        priority: TaskPriority.high,
        dueDate: today,
      ),
      Task(
        id: 's3',
        title: 'Review lecture notes',
        subject: 'Behavioral Econ',
        estimatedMinutes: 30,
        pomodorosPlanned: 1,
        priority: TaskPriority.medium,
        dueDate: today.add(const Duration(days: 1)),
      ),
      Task(
        id: 's4',
        title: 'Finish lab report',
        subject: 'Physics',
        estimatedMinutes: 50,
        pomodorosPlanned: 2,
        priority: TaskPriority.high,
        status: TaskStatus.overdue,
        dueDate: today.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 's5',
        title: 'Read research paper',
        subject: 'Statistics',
        estimatedMinutes: 40,
        pomodorosPlanned: 2,
        priority: TaskPriority.low,
        dueDate: today.add(const Duration(days: 7)),
      ),
    ];
  }

  static List<Task> mockTeacherTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      Task(
        id: 't1',
        title: 'Grade midterm essays',
        subject: 'ECON 301',
        estimatedMinutes: 120,
        pomodorosPlanned: 5,
        priority: TaskPriority.high,
        dueDate: today,
        isTeacher: true,
      ),
      Task(
        id: 't2',
        title: 'Prepare lecture slides',
        subject: 'ECON 301',
        estimatedMinutes: 60,
        pomodorosPlanned: 2,
        priority: TaskPriority.medium,
        dueDate: today,
        isTeacher: true,
      ),
      Task(
        id: 't3',
        title: 'Review student submissions',
        subject: 'STAT 210',
        estimatedMinutes: 45,
        pomodorosPlanned: 2,
        priority: TaskPriority.medium,
        dueDate: today.add(const Duration(days: 1)),
        isTeacher: true,
      ),
      Task(
        id: 't4',
        title: 'Faculty meeting prep',
        subject: 'Department',
        estimatedMinutes: 30,
        pomodorosPlanned: 1,
        priority: TaskPriority.low,
        dueDate: today.add(const Duration(days: 7)),
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

/// Everything AddTaskSheet collects for a new task. Replaces the old
/// (title, date) callback pair, which silently dropped whatever priority
/// and duration the user picked in the sheet's own pills — only the title
/// and date ever made it onto the actual Task.
class NewTaskDraft {
  final String title;
  final DateTime? dueDate;
  final bool hasTime;
  final TaskPriority priority;
  final int estimatedMinutes;
  final String? tagLabel;
  final int? tagColorValue;
  final RecurrenceRule recurrence;
  final int? reminderMinutesBefore;
  // Explicit session count from the Focus/Pomodoro picker, when the user
  // set it directly there. Null means "not customized" — callers fall
  // back to the old ceil(estimatedMinutes / 25) default.
  final int? pomodorosPlanned;

  const NewTaskDraft({
    required this.title,
    required this.dueDate,
    required this.hasTime,
    required this.priority,
    required this.estimatedMinutes,
    this.tagLabel,
    this.tagColorValue,
    this.recurrence = const RecurrenceRule(),
    this.reminderMinutesBefore,
    this.pomodorosPlanned,
  });
}

/// Reminder offsets the UI offers, in minutes before the task's due time
/// (or 9 AM on the due date, for date-only tasks — see Task.reminderAnchor).
/// 0 means "right at the due time".
const List<int> kReminderPresets = [0, 10, 30, 60, 1440];

String reminderPresetLabel(int minutes) {
  if (minutes == 0) return 'At time of task';
  if (minutes < 60) return '$minutes minutes before';
  if (minutes == 60) return '1 hour before';
  if (minutes < 1440) return '${minutes ~/ 60} hours before';
  if (minutes == 1440) return '1 day before';
  return '${minutes ~/ 1440} days before';
}

/// A handful of preset swatches for the tag color picker — kept in the
/// model file so both AddTaskSheet and TaskDetailScreen use the exact
/// same palette instead of drifting apart.
const List<int> kTagColorPresets = [
  0xFF14B8A6, // teal (matches AppColors.teal)
  0xFF6366F1, // indigo
  0xFFEC4899, // pink
  0xFFF59E0B, // amber
  0xFF10B981, // emerald
  0xFF3B82F6, // blue
  0xFFEF4444, // red
  0xFF8B5CF6, // violet
];