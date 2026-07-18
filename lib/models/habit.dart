// lib/models/habit.dart
// Habit tracking — a TickTick-style companion to Task. Tasks are one-off
// (or recurring-but-finite) things to finish; Habits are open-ended things
// to repeat, tracked by daily/weekly check-ins and a streak instead of a
// due date and a done/pending status.

import 'package:flutter/material.dart';

enum HabitType { yesNo, count }

enum HabitFrequencyType { daily, weekdays, timesPerWeek }

// ============================================================
// FREQUENCY — every day, specific weekdays, or a flexible weekly target
// (e.g. "3 times a week", any days). Mirrors the shape of Task's
// RecurrenceRule but "timesPerWeek" has no Task equivalent — habits are
// the one place a flexible (not day-pinned) weekly goal makes sense.
// ============================================================
class HabitFrequency {
  final HabitFrequencyType type;
  // 1=Mon .. 7=Sun. Only used when type == weekdays; empty means every day.
  final Set<int> weekdays;
  // Only used when type == timesPerWeek.
  final int timesPerWeek;

  const HabitFrequency({
    this.type = HabitFrequencyType.daily,
    this.weekdays = const {},
    this.timesPerWeek = 3,
  });

  static const List<String> _weekdayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Whether this habit is "on the schedule" for [date]. For timesPerWeek
  /// habits every day counts as eligible — the constraint is the weekly
  /// total, not which specific days.
  bool isDueOn(DateTime date) {
    switch (type) {
      case HabitFrequencyType.daily:
        return true;
      case HabitFrequencyType.weekdays:
        if (weekdays.isEmpty) return true;
        return weekdays.contains(date.weekday);
      case HabitFrequencyType.timesPerWeek:
        return true;
    }
  }

  String get label {
    switch (type) {
      case HabitFrequencyType.daily:
        return 'Every day';
      case HabitFrequencyType.weekdays:
        if (weekdays.isEmpty) return 'Every day';
        final sorted = weekdays.toList()..sort();
        return sorted.map((d) => _weekdayNames[d]).join(', ');
      case HabitFrequencyType.timesPerWeek:
        return '$timesPerWeek× a week';
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'weekdays': weekdays.toList(),
        'timesPerWeek': timesPerWeek,
      };

  factory HabitFrequency.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HabitFrequency();
    return HabitFrequency(
      type: HabitFrequencyType.values.byName(json['type'] as String? ?? 'daily'),
      weekdays: ((json['weekdays'] as List<dynamic>?) ?? const []).map((e) => e as int).toSet(),
      timesPerWeek: json['timesPerWeek'] as int? ?? 3,
    );
  }
}

// ============================================================
// PRESET ICONS/COLORS — icons are stored as a String key (not a raw
// IconData) so persistence doesn't depend on Flutter's icon-font
// tree-shaking/codepoint quirks; the key is just looked up at render time.
// ============================================================
const Map<String, IconData> kHabitIconPresets = {
  'water': Icons.water_drop,
  'run': Icons.directions_run,
  'walk': Icons.directions_walk,
  'book': Icons.menu_book,
  'meditate': Icons.self_improvement,
  'sleep': Icons.bedtime,
  'gym': Icons.fitness_center,
  'food': Icons.restaurant,
  'study': Icons.school,
  'code': Icons.code,
  'music': Icons.music_note,
  'clean': Icons.cleaning_services,
  'journal': Icons.edit_note,
  'sun': Icons.wb_sunny,
  'nowifi': Icons.phonelink_erase,
  'heart': Icons.favorite,
};

IconData habitIconFor(String key) => kHabitIconPresets[key] ?? Icons.track_changes;

const List<int> kHabitColorPresets = [
  0xFF14B8A6, // teal
  0xFF6366F1, // indigo
  0xFFEC4899, // pink
  0xFFF59E0B, // amber
  0xFF10B981, // emerald
  0xFF3B82F6, // blue
  0xFFEF4444, // red
  0xFF8B5CF6, // violet
];

class Habit {
  final String id;
  final String title;
  final String iconKey;
  final int colorValue;
  final HabitType type;
  // Daily target. 1 for yes/no habits ("done" = at least 1 check-in);
  // >1 for count habits ("drink water" × 8).
  final int targetCount;
  final HabitFrequency frequency;
  // Optional daily reminder time-of-day — repeats every day regardless of
  // frequency (a reminder to log a 3x/week habit is still useful daily).
  final TimeOfDay? reminderTime;
  final DateTime createdAt;
  final bool archived;
  // Date-only key -> count logged that day. Comparing against targetCount
  // tells you whether that day counts as "done".
  final Map<DateTime, int> checkIns;

  const Habit({
    required this.id,
    required this.title,
    this.iconKey = 'water',
    this.colorValue = 0xFF14B8A6,
    this.type = HabitType.yesNo,
    this.targetCount = 1,
    this.frequency = const HabitFrequency(),
    this.reminderTime,
    required this.createdAt,
    this.archived = false,
    this.checkIns = const {},
  });

  Color get color => Color(colorValue);
  IconData get icon => habitIconFor(iconKey);

  static DateTime _d(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  static DateTime _weekStart(DateTime dt) => _d(dt).subtract(Duration(days: dt.weekday - 1));

  int countOn(DateTime date) => checkIns[_d(date)] ?? 0;
  bool isDoneOn(DateTime date) => countOn(date) >= targetCount;
  bool isDueOn(DateTime date) => frequency.isDueOn(date);

  int get todayCount => countOn(DateTime.now());
  bool get isDoneToday => isDoneOn(DateTime.now());
  bool get isDueToday => isDueOn(DateTime.now());

  Habit copyWith({
    String? id,
    String? title,
    String? iconKey,
    int? colorValue,
    HabitType? type,
    int? targetCount,
    HabitFrequency? frequency,
    TimeOfDay? reminderTime,
    bool clearReminder = false,
    DateTime? createdAt,
    bool? archived,
    Map<DateTime, int>? checkIns,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      frequency: frequency ?? this.frequency,
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
      checkIns: checkIns ?? this.checkIns,
    );
  }

  /// Sets (or clears, if count <= 0) the logged count for [date].
  Habit withCheckIn(DateTime date, int count) {
    final d = _d(date);
    final updated = Map<DateTime, int>.from(checkIns);
    if (count <= 0) {
      updated.remove(d);
    } else {
      updated[d] = count;
    }
    return copyWith(checkIns: updated);
  }

  /// Count-habit tap control: +1, cycling back to 0 once you go past the
  /// target so repeated taps don't climb forever by accident.
  Habit withIncrement(DateTime date) {
    final next = countOn(date) + 1;
    return withCheckIn(date, next > targetCount ? 0 : next);
  }

  /// Yes/no habit tap control: flips between "done" and "not done" for the
  /// day.
  Habit withToggle(DateTime date) {
    return withCheckIn(date, isDoneOn(date) ? 0 : targetCount);
  }

  int _daysMetInWeek(DateTime weekStart) {
    var count = 0;
    for (var i = 0; i < 7; i++) {
      if (isDoneOn(weekStart.add(Duration(days: i)))) count++;
    }
    return count;
  }

  /// Consecutive days (or weeks, for timesPerWeek habits) meeting the
  /// target, counting back from today. A day that's due but not yet
  /// checked into today doesn't break the streak — the day only fails once
  /// it's over, so this looks from yesterday backward in that one case.
  int get currentStreak {
    final now = DateTime.now();
    if (frequency.type == HabitFrequencyType.timesPerWeek) {
      var weekStart = _weekStart(now);
      var streak = 0;
      if (_daysMetInWeek(weekStart) >= frequency.timesPerWeek) streak++;
      weekStart = weekStart.subtract(const Duration(days: 7));
      var guard = 0;
      while (_daysMetInWeek(weekStart) >= frequency.timesPerWeek && guard < 520) {
        streak++;
        weekStart = weekStart.subtract(const Duration(days: 7));
        guard++;
      }
      return streak;
    }

    var streak = 0;
    var day = _d(now);
    if (frequency.isDueOn(day) && !isDoneOn(day)) {
      day = day.subtract(const Duration(days: 1));
    }
    var guard = 0;
    while (guard < 3650) {
      guard++;
      if (frequency.isDueOn(day)) {
        if (isDoneOn(day)) {
          streak++;
        } else {
          break;
        }
      }
      day = day.subtract(const Duration(days: 1));
      if (day.isBefore(_d(createdAt))) break;
    }
    return streak;
  }

  /// The longest streak ever achieved, scanning from creation to today.
  int get bestStreak {
    final start = _d(createdAt);
    final now = _d(DateTime.now());
    if (frequency.type == HabitFrequencyType.timesPerWeek) {
      var weekStart = _weekStart(start);
      var best = 0, running = 0;
      var guard = 0;
      while (!weekStart.isAfter(now) && guard < 1040) {
        if (_daysMetInWeek(weekStart) >= frequency.timesPerWeek) {
          running++;
          if (running > best) best = running;
        } else {
          running = 0;
        }
        weekStart = weekStart.add(const Duration(days: 7));
        guard++;
      }
      return best;
    }

    var best = 0, running = 0;
    var day = start;
    var guard = 0;
    while (!day.isAfter(now) && guard < 3650) {
      if (frequency.isDueOn(day)) {
        if (isDoneOn(day)) {
          running++;
          if (running > best) best = running;
        } else {
          running = 0;
        }
      }
      day = day.add(const Duration(days: 1));
      guard++;
    }
    return best;
  }

  /// Fraction of due days met over the last [days] days (bounded by
  /// creation date) — used for a lightweight completion-rate stat.
  double completionRateOver(int days) {
    final today = _d(DateTime.now());
    final start = _d(createdAt);
    var due = 0, done = 0;
    for (var i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.isBefore(start)) continue;
      if (!frequency.isDueOn(day)) continue;
      due++;
      if (isDoneOn(day)) done++;
    }
    if (due == 0) return 0;
    return done / due;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'type': type.name,
        'targetCount': targetCount,
        'frequency': frequency.toJson(),
        'reminderHour': reminderTime?.hour,
        'reminderMinute': reminderTime?.minute,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
        'checkIns': checkIns.entries
            .map((e) => {'date': e.key.toIso8601String(), 'count': e.value})
            .toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    TimeOfDay? reminder;
    if (json['reminderHour'] != null && json['reminderMinute'] != null) {
      reminder = TimeOfDay(hour: json['reminderHour'] as int, minute: json['reminderMinute'] as int);
    }
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      iconKey: json['iconKey'] as String? ?? 'water',
      colorValue: json['colorValue'] as int? ?? 0xFF14B8A6,
      type: HabitType.values.byName(json['type'] as String? ?? 'yesNo'),
      targetCount: json['targetCount'] as int? ?? 1,
      frequency: HabitFrequency.fromJson(json['frequency'] as Map<String, dynamic>?),
      reminderTime: reminder,
      createdAt: DateTime.parse(json['createdAt'] as String),
      archived: json['archived'] as bool? ?? false,
      checkIns: {
        for (final e in ((json['checkIns'] as List<dynamic>?) ?? const []))
          DateTime.parse((e as Map<String, dynamic>)['date'] as String):
              e['count'] as int,
      },
    );
  }
}
