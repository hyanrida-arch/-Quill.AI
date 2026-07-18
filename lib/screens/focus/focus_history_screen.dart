// lib/screens/focus/focus_history_screen.dart
//
// Was a fully hardcoded mockup (fake dates, a fabricated "78% completion"
// AI insight) — rewritten to read the app's real FocusSession list.
// Deliberately does NOT show any AI-generated insight: Mystro doesn't
// actually read tasks/sessions yet (see the "points de vigilance" section
// of the project report), so a real insight box will come once that's
// true, not before.
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/focus_session.dart';

class FocusHistoryScreen extends StatelessWidget {
  final List<FocusSession> sessions;

  const FocusHistoryScreen({super.key, required this.sessions});

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<FocusSession> get _sorted {
    final list = List<FocusSession>.from(sessions);
    list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return list;
  }

  List<FocusSession> get _todaySessions {
    final today = _dateOnly(DateTime.now());
    return sessions.where((s) => _dateOnly(s.completedAt) == today).toList();
  }

  int get _pomosToday => _todaySessions.where((s) => s.isSuccessful).length;

  Duration get _focusedTodayDuration {
    final totalSeconds = _todaySessions.fold<int>(0, (sum, s) => sum + s.actualSeconds);
    return Duration(seconds: totalSeconds);
  }

  /// Consecutive days (counting back from today) with at least one
  /// successful session — same "streak" definition used by Habits.
  int get _dayStreak {
    final doneDays = sessions.where((s) => s.isSuccessful).map((s) => _dateOnly(s.completedAt)).toSet();
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

  Map<DateTime, List<FocusSession>> get _groupedByDay {
    final map = <DateTime, List<FocusSession>>{};
    for (final s in _sorted) {
      final day = _dateOnly(s.completedAt);
      map.putIfAbsent(day, () => []).add(s);
    }
    return map;
  }

  String _dayLabel(DateTime day) {
    final today = _dateOnly(DateTime.now());
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[day.month - 1]} ${day.day}';
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedByDay;
    final focused = _focusedTodayDuration;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Focus History',
          style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepNavy.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildStatColumn('$_pomosToday', 'POMOS TODAY'),
                  _buildDivider(),
                  _buildMainStatColumn('${focused.inHours}h', '${focused.inMinutes % 60}m', 'FOCUSED TODAY'),
                  _buildDivider(),
                  _buildStatColumn('$_dayStreak', 'DAY STREAK'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (grouped.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.timer_outlined, size: 40, color: AppColors.slateGray),
                      const SizedBox(height: 12),
                      const Text('No focus sessions yet',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                      const SizedBox(height: 6),
                      Text('Finish a Pomodoro session and it will show up here.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.slateGray.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              )
            else
              ...grouped.entries.expand((entry) {
                final day = entry.key;
                final daySessions = entry.value;
                return [
                  Text(_dayLabel(day),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                  const SizedBox(height: 12),
                  ...daySessions.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildSessionCard(s),
                      )),
                  const SizedBox(height: 22),
                ];
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildMainStatColumn(String hrs, String mins, String label) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(hrs, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.white, height: 1)),
            const SizedBox(width: 4),
            Text(mins, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.white, height: 1)),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.slateGray.withValues(alpha: 0.3),
    );
  }

  Widget _buildSessionCard(FocusSession s) {
    final badgeColor = s.isSuccessful ? AppColors.teal : AppColors.amber;
    final badgeIcon = s.isSuccessful ? Icons.check : Icons.warning_amber_rounded;
    final endTime = s.completedAt;
    final startTime = endTime.subtract(Duration(seconds: s.actualSeconds));
    final subtitle = s.pauseCount == 0 ? '0 pauses' : '${s.pauseCount} pause${s.pauseCount == 1 ? '' : 's'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_timeLabel(startTime)} — ${_timeLabel(endTime)}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(s.taskTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, color: badgeColor.withValues(alpha: 0.15)),
                child: Icon(badgeIcon, size: 14, color: badgeColor),
              ),
              const SizedBox(height: 4),
              Text('${s.actualMinutes}m', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            ],
          ),
        ],
      ),
    );
  }
}
