// lib/services/achievements_service.dart
//
// Real, explainable achievement scoring — replaces the Account screen's
// old hardcoded Badges / Achievement Score (356, "Lv.3 Hardworker", 13
// badges with counts 5/4/3/3/3/2 — every one of those was a static number
// with zero data model behind it). Every value here is computed directly
// from the app's real Task / FocusSession / Habit / Flashcard lists.
//
// Same "explainable in one sentence" principle as the Leitner spaced-
// repetition system: one disclosed threshold per badge, one disclosed
// weighted sum for the score — no hidden/black-box weighting.
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/focus_session.dart';
import '../models/habit.dart';
import '../models/flashcard.dart';

/// One badge = one real signal, tiered 0..5. A tier is only reached at a
/// disclosed threshold (see AchievementsService.compute) — there is no
/// tier the user can't explain by pointing at their own real data.
class AchievementBadge {
  final String label;
  final IconData icon;
  final Color color;
  final int tier; // 0..5, 0 = not started

  const AchievementBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.tier,
  });
}

class AchievementSummary {
  final int score;
  final int level; // 1..5
  final String levelTitle;
  final List<AchievementBadge> badges;

  const AchievementSummary({
    required this.score,
    required this.level,
    required this.levelTitle,
    required this.badges,
  });
}

class AchievementsService {
  static int _tierFor(num value, num perTier) {
    if (perTier <= 0) return 0;
    final t = (value / perTier).floor();
    if (t > 5) return 5;
    if (t < 0) return 0;
    return t;
  }

  static AchievementSummary compute({
    required List<Task> tasks,
    required List<FocusSession> sessions,
    required List<Habit> habits,
    required List<Flashcard> flashcards,
  }) {
    final completedTasks = tasks.where((t) => t.isDone).length;
    final successfulSessions = sessions.where((s) => s.isSuccessful).toList();
    final totalFocusHours =
        successfulSessions.fold<int>(0, (sum, s) => sum + s.actualSeconds) / 3600.0;
    final bestHabitStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.bestStreak).reduce((a, b) => b > a ? b : a);
    final masteredCards = flashcards.where((c) => c.isMastered).length;
    final dayStreak = focusDayStreak(sessions);

    final badges = [
      AchievementBadge(
        label: 'Focus',
        icon: Icons.local_fire_department,
        color: const Color(0xFFEF4444),
        tier: _tierFor(totalFocusHours, 5), // 1 tier per 5 hours actually focused
      ),
      AchievementBadge(
        label: 'Tasks',
        icon: Icons.check_circle,
        color: const Color(0xFFF59E0B),
        tier: _tierFor(completedTasks, 15), // 1 tier per 15 tasks completed
      ),
      AchievementBadge(
        label: 'Sessions',
        icon: Icons.emoji_events,
        color: const Color(0xFF6B7280),
        tier: _tierFor(successfulSessions.length, 15), // 1 tier per 15 successful Pomodoros
      ),
      AchievementBadge(
        label: 'Habits',
        icon: Icons.stars_rounded,
        color: const Color(0xFF14B8A6),
        tier: _tierFor(bestHabitStreak, 7), // 1 tier per 7-day best habit streak
      ),
      AchievementBadge(
        label: 'Flashcards',
        icon: Icons.style_outlined,
        color: const Color(0xFFF59E0B),
        tier: _tierFor(masteredCards, 10), // 1 tier per 10 cards reaching box 5 (mastered)
      ),
      AchievementBadge(
        label: 'Streak',
        icon: Icons.military_tech,
        color: const Color(0xFF6B7280),
        tier: _tierFor(dayStreak, 5), // 1 tier per 5 consecutive days with a real session
      ),
    ];

    // Disclosed weighted sum — tasks and focus hours weigh most since
    // they're the app's two core loops (plan vs reality); habits,
    // flashcards and day-streak weigh less since they're secondary.
    final score = (completedTasks * 2) +
        (totalFocusHours * 5).round() +
        (bestHabitStreak * 3) +
        (masteredCards * 2) +
        (dayStreak * 4);

    final level = _levelFor(score);

    return AchievementSummary(
      score: score,
      level: level.$1,
      levelTitle: level.$2,
      badges: badges,
    );
  }

  static (int, String) _levelFor(int score) {
    if (score >= 700) return (5, 'Master');
    if (score >= 350) return (4, 'Dedicated');
    if (score >= 150) return (3, 'Hardworker');
    if (score >= 50) return (2, 'Building Momentum');
    return (1, 'Getting Started');
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Consecutive days (counting back from today) with at least one
  /// successful focus session — same definition FocusHistoryScreen already
  /// uses, duplicated here rather than imported so this service stays free
  /// of any screen-layer dependency.
  static int focusDayStreak(List<FocusSession> sessions) {
    final doneDays =
        sessions.where((s) => s.isSuccessful).map((s) => _dateOnly(s.completedAt)).toSet();
    var day = _dateOnly(DateTime.now());
    var streak = 0;
    var guard = 0;
    while (doneDays.contains(day) && guard < 3650) {
      streak++;
      day = day.subtract(const Duration(days: 1));
      guard++;
    }
    return streak;
  }
}
