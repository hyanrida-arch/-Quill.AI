// lib/models/focus_session.dart
//
// The "reality" ledger. A Task is the plan (title, due date, estimated
// minutes) and is never mutated by a session finishing. Every completed
// or abandoned Pomodoro run produces one FocusSession instead. Calendar
// and Mystro both read _tasks + _sessions together to reconstruct
// plan-vs-reality — neither owns its own copy of either list.
enum FocusOutcome { completed, interrupted, abandoned }

extension FocusOutcomeLabel on FocusOutcome {
  String get label {
    switch (this) {
      case FocusOutcome.completed:
        return 'Completed';
      case FocusOutcome.interrupted:
        return 'Interrupted';
      case FocusOutcome.abandoned:
        return 'Abandoned';
    }
  }
}

class FocusSession {
  final String id;
  final String taskId;

  // Denormalized snapshot of the task's title at session time, so history
  // still reads correctly even if the task is later renamed or deleted.
  final String taskTitle;

  final int plannedMinutes;
  final int actualSeconds;
  final int pauseCount;
  final FocusOutcome outcome;
  final DateTime completedAt;

  const FocusSession({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.plannedMinutes,
    required this.actualSeconds,
    required this.pauseCount,
    required this.outcome,
    required this.completedAt,
  });

  int get actualMinutes => (actualSeconds / 60).round();

  bool get isSuccessful => outcome == FocusOutcome.completed;

  /// Actual/planned ratio. >1 means the session ran longer than estimated,
  /// <1 means it wrapped up early or was cut short. 0 if there was nothing
  /// to compare against.
  double get durationRatio {
    if (plannedMinutes <= 0) return 0;
    return actualMinutes / plannedMinutes;
  }

  // ============================================================
  // JSON SERIALIZATION (local persistence)
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'plannedMinutes': plannedMinutes,
      'actualSeconds': actualSeconds,
      'pauseCount': pauseCount,
      'outcome': outcome.name,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      taskTitle: json['taskTitle'] as String,
      plannedMinutes: json['plannedMinutes'] as int,
      actualSeconds: json['actualSeconds'] as int,
      pauseCount: json['pauseCount'] as int,
      outcome: FocusOutcome.values.byName(json['outcome'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}
