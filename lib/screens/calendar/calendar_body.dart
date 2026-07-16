// lib/screens/calendar/calendar_body.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import '../tasks/task_detail_screen.dart';
import '../../widgets/tasks/add_task_sheet.dart';

enum CalendarViewType { agenda, day, week, month }

const _weekdayShort = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _weekdayFull = [
  'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
];

class CalendarBody extends StatefulWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onClassroomTap;

  // Read-only view over AppShell's single source of truth — Calendar has
  // no data of its own, it's just a timeline over the same tasks shown
  // elsewhere. Tapping into a task still needs to write edits and any
  // Pomodoro session back up, though.
  final List<Task> tasks;
  final List<FocusSession> sessions;
  final ValueChanged<Task> onUpdate;
  final ValueChanged<Task> onAdd;
  final ValueChanged<FocusSession> onSessionComplete;

  const CalendarBody({
    super.key,
    required this.onMenuTap,
    required this.onClassroomTap,
    required this.tasks,
    required this.sessions,
    required this.onUpdate,
    required this.onAdd,
    required this.onSessionComplete,
  });

  @override
  State<CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<CalendarBody> {
  CalendarViewType _currentView = CalendarViewType.agenda;
  late DateTime _selectedDate;
  late DateTime _focusedMonth;

  // Hourly grid (Day/Week) constants + the vertical scroll it shares
  // between the time-label column and every day column, so they always
  // stay lined up. Auto-scrolls to roughly the current hour once, the
  // first time a grid is built, like Google Calendar opening "at now".
  static const double _hourHeight = 64.0;
  static const double _timeColWidth = 44.0;
  final ScrollController _hourScroll = ScrollController();
  bool _hasAutoScrolled = false;

  // Drag-to-reschedule (move) and resize-by-bottom-edge state for the
  // Day/Week hourly grid. Only one task can be actively dragged/resized at
  // a time, tracked by id; the live delta feeds straight back into
  // _positionedTaskBlock's layout math so the block visibly follows the
  // finger before anything is committed to AppShell on release.
  String? _draggingTaskId;
  int _dragDeltaMinutes = 0;
  double _dragAccumPixels = 0;
  String? _resizingTaskId;
  int _resizeDeltaMinutes = 0;
  double _resizeAccumPixels = 0;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _selectedDate = today;
    _focusedMonth = DateTime(today.year, today.month);
  }

  @override
  void dispose() {
    _hourScroll.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA — derive real dates from each task's dueDate/dueLabel so
  // the calendar reflects the same tasks shown in the Tasks tab.
  // ============================================================

  DateTime? _effectiveDate(Task t) {
    if (t.dueDate != null) return _dateOnly(t.dueDate!);
    final today = _dateOnly(DateTime.now());
    switch (t.dueLabel) {
      case 'Today':
        return today;
      case 'Tomorrow':
        return today.add(const Duration(days: 1));
      case 'Yesterday':
        return today.subtract(const Duration(days: 1));
      case 'Next Week':
        return today.add(const Duration(days: 7));
      default:
        final label = t.dueLabel;
        if (label != null) {
          final match = RegExp(r'^In (\d+) days?$').firstMatch(label);
          if (match != null) {
            final n = int.tryParse(match.group(1)!) ?? 0;
            return today.add(Duration(days: n));
          }
        }
        return null;
    }
  }

  // Recurring tasks are expanded across every matching date in this window
  // instead of showing only their single current dueDate — a calendar
  // timeline needs to show "every Monday" going forward, unlike the Tasks
  // list which deliberately shows a recurring task as one row.
  static DateTime get _occurrenceRangeStart =>
      _dateOnly(DateTime.now()).subtract(const Duration(days: 90));
  static DateTime get _occurrenceRangeEnd =>
      _dateOnly(DateTime.now()).add(const Duration(days: 730));

  Map<DateTime, List<Task>> get _tasksByDay {
    final map = <DateTime, List<Task>>{};
    for (final t in widget.tasks) {
      if (t.recurrence.isRecurring) {
        for (final d in t.occurrencesBetween(_occurrenceRangeStart, _occurrenceRangeEnd)) {
          map.putIfAbsent(d, () => []).add(t);
        }
      } else {
        final d = _effectiveDate(t);
        if (d != null) map.putIfAbsent(d, () => []).add(t);
      }
    }
    return map;
  }

  List<Task> _tasksOn(DateTime day) => _tasksByDay[_dateOnly(day)] ?? const [];

  bool _isDoneOn(Task t, DateTime day) => t.recurrence.isRecurring ? t.isOccurrenceDone(day) : t.isDone;

  // Split by whether the task has a real time-of-day attached. Tasks with
  // just a due date (no time) go in the all-day strip; tasks the user gave
  // an actual time get positioned in the hourly grid.
  List<Task> _timedTasksOn(DateTime day) =>
      _tasksOn(day).where((t) => t.hasTime && t.dueDate != null).toList();

  List<Task> _allDayTasksOn(DateTime day) =>
      _tasksOn(day).where((t) => !t.hasTime).toList();

  // ============================================================
  // Reality — completed/interrupted/abandoned FocusSessions, placed on
  // the day they actually happened (not a due date).
  // ============================================================

  Map<DateTime, List<FocusSession>> get _sessionsByDay {
    final map = <DateTime, List<FocusSession>>{};
    for (final s in widget.sessions) {
      final d = _dateOnly(s.completedAt);
      map.putIfAbsent(d, () => []).add(s);
    }
    return map;
  }

  List<FocusSession> _sessionsOn(DateTime day) => _sessionsByDay[_dateOnly(day)] ?? const [];

  void _switchView(CalendarViewType view) {
    HapticFeedback.selectionClick();
    setState(() => _currentView = view);
  }

  Future<void> _openDetail(Task task) async {
    final updated = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task, onSessionComplete: widget.onSessionComplete),
      ),
    );
    if (updated != null) widget.onUpdate(updated);
  }

  void _jumpToToday() {
    final today = _dateOnly(DateTime.now());
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = today;
      _focusedMonth = DateTime(today.year, today.month);
    });
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  // Monday-first calendar week containing _selectedDate — matches how most
  // students actually think of "this week", unlike the old Day/Week view
  // which was just a rolling 7-day strip centered on whatever day was picked.
  DateTime _weekStart(DateTime date) =>
      _dateOnly(date).subtract(Duration(days: date.weekday - 1));

  List<DateTime> _weekDays(DateTime date) {
    final start = _weekStart(date);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  void _shiftWeek(int deltaWeeks) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: 7 * deltaWeeks));
    });
  }

  void _shiftDay(int deltaDays) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: deltaDays));
    });
  }

  // Swipe left = next (day/week), swipe right = previous — matches Google
  // Calendar/TickTick. A plain GestureDetector (not a PageView) so it
  // doesn't fight the grid's own vertical scrolling; horizontal drags and
  // vertical scrolls resolve to different axes in the gesture arena.
  Widget _swipeNav({required Widget child, required void Function(int) onShift}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -200) {
          onShift(1);
        } else if (v > 200) {
          onShift(-1);
        }
      },
      child: child,
    );
  }

  void _selectDay(DateTime day) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDate = _dateOnly(day));
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final isToday = _selectedDate == today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ───
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 20, top: 12, bottom: 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: AppColors.deepNavy, size: 28),
                onPressed: widget.onMenuTap,
              ),
              const SizedBox(width: 4),
              const Text(
                'Calendar',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.deepNavy, letterSpacing: -0.5),
              ),
              const Spacer(),
              if (!isToday || _currentView == CalendarViewType.month)
                IconButton(
                  tooltip: 'Jump to today',
                  icon: const Icon(Icons.today_outlined, color: AppColors.deepNavy, size: 24),
                  onPressed: _jumpToToday,
                ),
              IconButton(
                icon: const Icon(Icons.school_outlined, color: AppColors.deepNavy, size: 26),
                onPressed: widget.onClassroomTap,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _subtitle(),
                style: const TextStyle(fontSize: 15, color: AppColors.slateGray),
              ),
              const SizedBox(height: 20),

              // Segmented control
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.slateGray.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab('Agenda', CalendarViewType.agenda),
                    _buildTab('Day', CalendarViewType.day),
                    _buildTab('Week', CalendarViewType.week),
                    _buildTab('Month', CalendarViewType.month),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(child: _buildCurrentView()),
      ],
    );
  }

  String _subtitle() {
    switch (_currentView) {
      case CalendarViewType.month:
        return '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}';
      case CalendarViewType.agenda:
        return 'Your upcoming days';
      case CalendarViewType.day:
        return '${_weekdayFull[_selectedDate.weekday % 7]}, ${_monthNames[_selectedDate.month - 1]} ${_selectedDate.day}';
      case CalendarViewType.week:
        final days = _weekDays(_selectedDate);
        final start = days.first;
        final end = days.last;
        if (start.month == end.month) {
          return '${_monthNames[start.month - 1]} ${start.day} – ${end.day}, ${end.year}';
        }
        return '${_monthNames[start.month - 1]} ${start.day} – ${_monthNames[end.month - 1]} ${end.day}, ${end.year}';
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CalendarViewType.agenda:
        return _buildAgendaView();
      case CalendarViewType.month:
        return _buildMonthView();
      case CalendarViewType.day:
        return _buildDayGridView();
      case CalendarViewType.week:
        return _buildWeekGridView();
    }
  }

  // ==========================================
  // 1. AGENDA VIEW — next 14 days that actually have tasks, plus Today
  // ==========================================
  Widget _buildAgendaView() {
    final today = _dateOnly(DateTime.now());
    final tasksGrouped = _tasksByDay;
    final sessionsGrouped = _sessionsByDay;
    final days = <DateTime>[];
    for (int i = -1; i <= 14; i++) {
      final day = today.add(Duration(days: i));
      if (day == today || tasksGrouped.containsKey(day) || sessionsGrouped.containsKey(day)) {
        days.add(day);
      }
    }

    if (days.length == 1 && tasksGrouped[today] == null && sessionsGrouped[today] == null) {
      return _buildEmptyState('No upcoming events', 'Tasks with a due date will show up here.');
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        for (final day in days) ...[
          _buildAgendaDayGroup(day, today),
          const SizedBox(height: 24),
        ],
        const SizedBox(height: 56),
      ],
    );
  }

  Widget _buildAgendaDayGroup(DateTime day, DateTime today) {
    final taskEvents = _tasksOn(day);
    final sessionEvents = _sessionsOn(day);
    final dayLabel = day == today
        ? 'Today'
        : day == today.add(const Duration(days: 1))
            ? 'Tomorrow'
            : day == today.subtract(const Duration(days: 1))
                ? 'Yesterday'
                : _weekdayFull[day.weekday % 7].substring(0, 3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Column(
            children: [
              Text('${day.day}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
              Text(dayLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dayLabel == 'Today' ? AppColors.teal : AppColors.slateGray)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: (taskEvents.isEmpty && sessionEvents.isEmpty)
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('All caught up', style: TextStyle(fontSize: 13, color: AppColors.slateGray.withValues(alpha: 0.7))),
                )
              : Column(
                  children: [
                    // Plan first, then reality — matches "Calendar shows the
                    // plan, Pomodoro logs reality" underneath it.
                    ...taskEvents.map((t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildTaskEventCard(t, day))),
                    ...sessionEvents.map((s) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildSessionEventCard(s))),
                  ],
                ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. DAY VIEW — date strip + a real hourly grid for the selected day
  // ==========================================
  Widget _buildDayGridView() {
    final today = _dateOnly(DateTime.now());
    final strip = List.generate(7, (i) => _selectedDate.add(Duration(days: i - 3)));

    return Column(
      children: [
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: strip.length,
            itemBuilder: (context, index) {
              final day = strip[index];
              final isSelected = day == _selectedDate;
              return GestureDetector(
                onTap: () => _selectDay(day),
                child: Container(
                  width: 48,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.deepNavy : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_weekdayShort[day.weekday % 7], style: TextStyle(fontSize: 12, color: isSelected ? AppColors.white : AppColors.slateGray)),
                      const SizedBox(height: 4),
                      Text('${day.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isSelected ? AppColors.white : (day == today ? AppColors.teal : AppColors.deepNavy))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _swipeNav(onShift: _shiftDay, child: _buildHourGrid([_selectedDate])),
        ),
      ],
    );
  }

  // ==========================================
  // WEEK VIEW — real Monday–Sunday hourly grid, 7 columns
  // ==========================================
  Widget _buildWeekGridView() {
    final days = _weekDays(_selectedDate);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(onTap: () => _shiftWeek(-1), child: const Icon(Icons.chevron_left, color: AppColors.deepNavy)),
              const SizedBox(width: 16),
              GestureDetector(onTap: () => _shiftWeek(1), child: const Icon(Icons.chevron_right, color: AppColors.deepNavy)),
            ],
          ),
        ),
        Expanded(
          child: _swipeNav(onShift: _shiftWeek, child: _buildHourGrid(days)),
        ),
      ],
    );
  }

  // ==========================================
  // SHARED HOURLY GRID — time column + N day columns, tasks (plan) and
  // focus sessions (reality) both positioned by real time-of-day. Used by
  // both Day (1 column) and Week (7 columns).
  // ==========================================
  Widget _buildHourGrid(List<DateTime> days) {
    const totalHeight = _hourHeight * 24;
    final showAllDayRow = days.any((d) => _allDayTasksOn(d).isNotEmpty);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAutoScrolled && _hourScroll.hasClients) {
        final now = DateTime.now();
        final target = ((now.hour - 2).clamp(0, 24) * _hourHeight)
            .clamp(0.0, _hourScroll.position.maxScrollExtent);
        _hourScroll.jumpTo(target);
        _hasAutoScrolled = true;
      }
    });

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: _timeColWidth),
            for (final day in days) Expanded(child: _dayHeaderCell(day, days.length)),
          ],
        ),
        const Divider(height: 1, color: AppColors.border),
        if (showAllDayRow) ...[
          Row(
            children: [
              const SizedBox(width: _timeColWidth),
              for (final day in days) Expanded(child: _allDayCell(day)),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
        ],
        Expanded(
          child: SingleChildScrollView(
            controller: _hourScroll,
            child: SizedBox(
              height: totalHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: _timeColWidth, height: totalHeight, child: _hourLabelsColumn()),
                  for (final day in days) Expanded(child: _dayColumn(day, totalHeight)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayHeaderCell(DateTime day, int columnCount) {
    final today = _dateOnly(DateTime.now());
    final isToday = day == today;
    return GestureDetector(
      onTap: () {
        _selectDay(day);
        if (_currentView == CalendarViewType.week) _switchView(CalendarViewType.day);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_weekdayShort[day.weekday % 7],
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slateGray)),
            const SizedBox(height: 4),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? AppColors.deepNavy : Colors.transparent,
              ),
              child: Text('${day.day}',
                  style: TextStyle(
                      fontSize: columnCount > 1 ? 13 : 16,
                      fontWeight: FontWeight.w700,
                      color: isToday ? AppColors.white : AppColors.deepNavy)),
            ),
          ],
        ),
      ),
    );
  }

  // Solid pastel bar, dark readable text — matches the "All-day Task Bar"
  // look (e.g. TickTick's pale-blue "Monthly Bill" bar) instead of the
  // faint low-contrast chip this used to be.
  Widget _allDayCell(DateTime day) {
    final tasks = _allDayTasksOn(day);
    if (tasks.isEmpty) return const SizedBox(height: 30);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Column(
        children: [
          for (final t in tasks.take(2))
            Builder(builder: (context) {
              final done = _isDoneOn(t, day);
              return GestureDetector(
                onTap: () => _openDetail(t),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  decoration: BoxDecoration(
                    color: (done ? AppColors.slateGray : t.displayColor).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (t.recurrence.isRecurring) ...[
                        Icon(Icons.repeat,
                            size: 9, color: done ? AppColors.slateGray : AppColors.deepNavy),
                        const SizedBox(width: 2),
                      ],
                      Flexible(
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: done ? AppColors.slateGray : AppColors.deepNavy,
                              decoration: done ? TextDecoration.lineThrough : null),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (tasks.length > 2)
            Text('+${tasks.length - 2} more', style: const TextStyle(fontSize: 8, color: AppColors.slateGray)),
        ],
      ),
    );
  }

  Widget _hourLabelsColumn() {
    return Column(
      children: List.generate(24, (h) {
        final label = '${h.toString().padLeft(2, '0')}:00';
        return SizedBox(
          height: _hourHeight,
          child: Padding(
            padding: const EdgeInsets.only(right: 6, top: 2),
            child: Align(
              alignment: Alignment.topRight,
              child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.slateGray)),
            ),
          ),
        );
      }),
    );
  }

  Widget _dayColumn(DateTime day, double totalHeight) {
    final today = _dateOnly(DateTime.now());
    final isToday = day == today;
    final timedTasks = _timedTasksOn(day);
    final sessions = _sessionsOn(day);

    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        border: const Border(left: BorderSide(color: AppColors.border, width: 0.5)),
        color: isToday ? AppColors.lightTeal.withValues(alpha: 0.25) : null,
      ),
      child: Stack(
        children: [
          // Tapping empty grid space quick-creates a task at that time —
          // sits under the hour gridlines and task/session blocks so a tap
          // that lands on an existing block still opens that block instead.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _quickCreateAt(day, details.localPosition.dy),
            ),
          ),
          Column(
            children: List.generate(
              24,
              (h) => Container(
                height: _hourHeight,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                ),
              ),
            ),
          ),
          if (isToday) _nowIndicator(),
          for (final t in timedTasks) ..._positionedTaskBlock(t, totalHeight, day),
          for (final s in sessions) _positionedSessionBlock(s, totalHeight),
        ],
      ),
    );
  }

  // Rounds the tapped y-offset to the nearest 30 minutes and opens the same
  // Add Task sheet used elsewhere, pre-filled with that day + time — so
  // tapping 2:30 PM on Tuesday's column starts a task already due then.
  void _quickCreateAt(DateTime day, double dy) {
    final totalMinutes = (dy / _hourHeight * 60).round();
    final rounded = ((totalMinutes / 30).round() * 30).clamp(0, 24 * 60 - 30);
    final hour = rounded ~/ 60;
    final minute = rounded % 60;
    HapticFeedback.selectionClick();
    showAddTaskSheet(
      context,
      initialDate: day,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      onAdd: (draft) {
        final task = Task(
          id: 'task_${DateTime.now().microsecondsSinceEpoch}',
          title: draft.title,
          subject: 'New Task',
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
        widget.onAdd(task);
      },
    );
  }

  Widget _nowIndicator() {
    final now = DateTime.now();
    final top = (now.hour + now.minute / 60) * _hourHeight;
    return Positioned(
      top: top - 4,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
          ),
          Expanded(child: Container(height: 1.5, color: AppColors.red.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  String _fmtHM(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // Clamps a block's top/height to the grid's bounds by hand instead of
  // Duration.clamp, since a task starting at 23:50 would otherwise ask for
  // a clamp() with a lower bound above the upper bound and throw.
  //
  // Styled as a solid pastel block with the time range shown above the
  // title (matching TickTick's Week View look) instead of a thin accent
  // stripe on a near-invisible tint — much easier to actually read.
  // Clamps a live drag so the task's start time can't be dragged past
  // midnight in either direction (the grid only ever renders one day's
  // worth of hours, so wrapping into the next/previous day would just
  // make the block vanish rather than move somewhere sensible).
  int _clampDragDelta(Task t, int rawDeltaMinutes) {
    final base = t.dueDate!.hour * 60 + t.dueDate!.minute;
    final duration = t.estimatedMinutes > 0 ? t.estimatedMinutes : 30;
    final maxStart = (24 * 60 - duration).clamp(0, 24 * 60);
    final newStart = (base + rawDeltaMinutes).clamp(0, maxStart);
    return newStart - base;
  }

  // Clamps a live resize so the block can't shrink below 15 minutes or
  // stretch past midnight.
  int _clampResizeDelta(Task t, int rawDeltaMinutes) {
    final base = t.dueDate!.hour * 60 + t.dueDate!.minute;
    final duration = t.estimatedMinutes > 0 ? t.estimatedMinutes : 30;
    final maxDuration = (24 * 60 - base).clamp(15, 24 * 60);
    final newDuration = (duration + rawDeltaMinutes).clamp(15, maxDuration);
    return newDuration - duration;
  }

  static int _snap15(int minutes) => (minutes / 15).round() * 15;

  void _commitDrag(Task t) {
    final delta = _dragDeltaMinutes;
    setState(() {
      _draggingTaskId = null;
      _dragDeltaMinutes = 0;
      _dragAccumPixels = 0;
    });
    if (delta == 0 || t.dueDate == null) return;
    HapticFeedback.lightImpact();
    final newDate = t.dueDate!.add(Duration(minutes: delta));
    widget.onUpdate(t.copyWith(dueDate: newDate, dueLabel: Task.dateLabelFor(newDate), hasTime: true));
  }

  void _commitResize(Task t) {
    final delta = _resizeDeltaMinutes;
    setState(() {
      _resizingTaskId = null;
      _resizeDeltaMinutes = 0;
      _resizeAccumPixels = 0;
    });
    if (delta == 0) return;
    HapticFeedback.lightImpact();
    final base = t.estimatedMinutes > 0 ? t.estimatedMinutes : 30;
    widget.onUpdate(t.copyWith(estimatedMinutes: base + delta));
  }

  // Returns [the event block, its bottom-edge resize handle] as sibling
  // Positioned widgets in the day column's Stack — Google Calendar/TickTick
  // both let you drag a whole block to reschedule it, or just its bottom
  // edge to resize it, so both live here together. Recurring tasks opt out
  // of both (their dueDate is a rolling "next occurrence" pointer, not a
  // fixed slot — dragging it would be ambiguous about which occurrence
  // moves) but can still be tapped open as before.
  List<Widget> _positionedTaskBlock(Task t, double totalHeight, DateTime day) {
    final canDragResize = !t.recurrence.isRecurring;
    final isDragging = canDragResize && _draggingTaskId == t.id;
    final isResizing = canDragResize && _resizingTaskId == t.id;

    final baseDt = t.dueDate!;
    final dt = isDragging ? baseDt.add(Duration(minutes: _dragDeltaMinutes)) : baseDt;
    final baseDuration = t.estimatedMinutes > 0 ? t.estimatedMinutes : 30;
    final durationMinutes = isResizing ? baseDuration + _resizeDeltaMinutes : baseDuration;

    final top = (dt.hour + dt.minute / 60) * _hourHeight;
    double height = (durationMinutes / 60) * _hourHeight;
    if (height < 24) height = 24;
    final maxHeight = totalHeight - top;
    if (height > maxHeight) height = maxHeight > 4 ? maxHeight : 4;

    final done = _isDoneOn(t, day);
    final accent = done ? AppColors.slateGray : t.displayColor;
    final endDt = dt.add(Duration(minutes: durationMinutes));
    final showTime = height >= 42;
    final isActive = isDragging || isResizing;

    final block = Positioned(
      top: top,
      left: 2,
      right: 2,
      height: height,
      child: GestureDetector(
        onTap: () => _openDetail(t),
        onVerticalDragStart: !canDragResize
            ? null
            : (_) {
                HapticFeedback.selectionClick();
                setState(() {
                  _draggingTaskId = t.id;
                  _dragDeltaMinutes = 0;
                  _dragAccumPixels = 0;
                });
              },
        onVerticalDragUpdate: !canDragResize
            ? null
            : (details) {
                setState(() {
                  _dragAccumPixels += details.primaryDelta ?? 0;
                  final raw = _snap15((_dragAccumPixels / _hourHeight * 60).round());
                  _dragDeltaMinutes = _clampDragDelta(t, raw);
                });
              },
        onVerticalDragEnd: !canDragResize ? null : (_) => _commitDrag(t),
        onVerticalDragCancel: !canDragResize
            ? null
            : () => setState(() {
                  _draggingTaskId = null;
                  _dragDeltaMinutes = 0;
                  _dragAccumPixels = 0;
                }),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: done ? 0.12 : 0.24),
            borderRadius: BorderRadius.circular(8),
            border: isActive ? Border.all(color: accent, width: 1.5) : null,
            boxShadow: isActive
                ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showTime)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t.recurrence.isRecurring) ...[
                      Icon(Icons.repeat, size: 9, color: accent),
                      const SizedBox(width: 2),
                    ],
                    Flexible(
                      child: Text('${_fmtHM(dt)}–${_fmtHM(endDt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accent)),
                    ),
                  ],
                ),
              Text(
                t.title,
                maxLines: showTime && height > 58 ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                  height: 1.15,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!canDragResize) return [block];

    final handle = Positioned(
      top: top + height - 6,
      left: 2,
      right: 2,
      height: 12,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) {
          HapticFeedback.selectionClick();
          setState(() {
            _resizingTaskId = t.id;
            _resizeDeltaMinutes = 0;
            _resizeAccumPixels = 0;
          });
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            _resizeAccumPixels += details.primaryDelta ?? 0;
            final raw = _snap15((_resizeAccumPixels / _hourHeight * 60).round());
            _resizeDeltaMinutes = _clampResizeDelta(t, raw);
          });
        },
        onVerticalDragEnd: (_) => _commitResize(t),
        onVerticalDragCancel: () => setState(() {
          _resizingTaskId = null;
          _resizeDeltaMinutes = 0;
          _resizeAccumPixels = 0;
        }),
        child: Center(
          child: Container(
            width: 28,
            height: 4,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isResizing ? 1 : 0.55),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );

    return [block, handle];
  }

  Widget _positionedSessionBlock(FocusSession s, double totalHeight) {
    final dt = s.completedAt;
    final top = (dt.hour + dt.minute / 60) * _hourHeight;
    double height = (s.actualMinutes / 60) * _hourHeight;
    if (height < 30) height = 30;
    final maxHeight = totalHeight - top;
    if (height > maxHeight) height = maxHeight > 4 ? maxHeight : 4;

    final Color accent;
    switch (s.outcome) {
      case FocusOutcome.completed:
        accent = AppColors.teal;
        break;
      case FocusOutcome.interrupted:
        accent = AppColors.amber;
        break;
      case FocusOutcome.abandoned:
        accent = AppColors.red;
        break;
    }
    final endDt = dt.add(Duration(minutes: s.actualMinutes));
    final showTime = height >= 42;

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: height,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTime)
              Text('${_fmtHM(dt)}–${_fmtHM(endDt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accent)),
            Text(
              s.taskTitle,
              maxLines: showTime && height > 58 ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.deepNavy, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. MONTH VIEW — real calendar grid for _focusedMonth
  // ==========================================
  Widget _buildMonthView() {
    final today = _dateOnly(DateTime.now());
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7; // Sunday = 0
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final gridCount = rows * 7;
    final grouped = _tasksByDay;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(onTap: () => _shiftMonth(-1), child: const Icon(Icons.chevron_left, color: AppColors.deepNavy)),
                  const SizedBox(width: 16),
                  GestureDetector(onTap: () => _shiftMonth(1), child: const Icon(Icons.chevron_right, color: AppColors.deepNavy)),
                ],
              ),
              GestureDetector(
                onTap: _jumpToToday,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(100)),
                  child: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: 7 + gridCount,
            itemBuilder: (context, index) {
              if (index < 7) {
                return Center(child: Text(_weekdayShort[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slateGray)));
              }
              final cellIndex = index - 7;
              final dayNum = cellIndex - leadingBlanks + 1;
              if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();

              final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
              final isSelected = day == _selectedDate;
              final isToday = day == today;
              final dayEvents = grouped[day] ?? const [];
              final dotColors = <Color>{for (final t in dayEvents) t.displayColor}.take(2).toList();

              return GestureDetector(
                onTap: () {
                  _selectDay(day);
                  _switchView(CalendarViewType.day);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.deepNavy : Colors.transparent,
                    shape: BoxShape.circle,
                    border: (isToday && !isSelected) ? Border.all(color: AppColors.teal, width: 1.5) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: (isSelected || isToday) ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.white : AppColors.deepNavy,
                        ),
                      ),
                      if (dotColors.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < dotColors.length; i++) ...[
                              if (i > 0) const SizedBox(width: 2),
                              Container(width: 4, height: 4, decoration: BoxDecoration(color: dotColors[i], shape: BoxShape.circle)),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Shared UI Helpers ───

  Widget _buildTaskEventCard(Task t, DateTime day) {
    final done = _isDoneOn(t, day);
    final accent = done ? AppColors.slateGray : t.displayColor;
    final tag = done ? '✓ DONE' : (t.isOverdue ? 'OVERDUE' : t.priorityLabel);
    return GestureDetector(
      onTap: () => _openDetail(t),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(width: 3, height: 40, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.subject} · ${t.estimatedMinutes} min', style: const TextStyle(fontSize: 12, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (t.recurrence.isRecurring) ...[
                        const Icon(Icons.repeat, size: 12, color: AppColors.slateGray),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          t.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy, decoration: done ? TextDecoration.lineThrough : TextDecoration.none),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  // "Reality" card — a logged Pomodoro session, placed at the time it
  // actually happened rather than a due date.
  Widget _buildSessionEventCard(FocusSession s) {
    final Color accent;
    final String tag;
    switch (s.outcome) {
      case FocusOutcome.completed:
        accent = AppColors.teal;
        tag = '✓ FOCUSED';
        break;
      case FocusOutcome.interrupted:
        accent = AppColors.amber;
        tag = 'INTERRUPTED';
        break;
      case FocusOutcome.abandoned:
        accent = AppColors.red;
        tag = 'ABANDONED';
        break;
    }
    final hh = s.completedAt.hour.toString().padLeft(2, '0');
    final mm = s.completedAt.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 40, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$hh:$mm · ${s.actualMinutes} of ${s.plannedMinutes} min',
                    style: const TextStyle(fontSize: 12, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(s.taskTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ],
            ),
          ),
          Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_outlined, size: 60, color: AppColors.slateGray.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.slateGray, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, CalendarViewType type) {
    final isSel = _currentView == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchView(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.deepNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSel ? [BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
              color: isSel ? AppColors.white : AppColors.slateGray,
            ),
          ),
        ),
      ),
    );
  }
}
