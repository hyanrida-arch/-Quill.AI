// lib/screens/focus/pomodoro_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import 'focus_history_screen.dart';

enum TimerMode { pomodoro, stopwatch }

class PomodoroDashboard extends StatefulWidget {
  /// Optional pre-selected task (when launched from Home/Tasks).
  final Task? initialTask;
  final VoidCallback? onMenuTap;
  final VoidCallback? onClassroomTap;

  // Read-only view over AppShell's single source of truth — the task
  // picker binds a session to one of these instead of its own mock list.
  final List<Task> tasks;

  // Read here too, so "Daily Goal" reflects real sessions logged today
  // instead of a number that never changes.
  final List<FocusSession> sessions;

  // Reality gets written back here whenever a focus segment ends (natural
  // completion, or the user resets mid-session/mid-stopwatch).
  final ValueChanged<FocusSession> onSessionComplete;

  const PomodoroDashboard({
    super.key,
    this.initialTask,
    this.onMenuTap,
    this.onClassroomTap,
    required this.tasks,
    required this.sessions,
    required this.onSessionComplete,
  });

  @override
  State<PomodoroDashboard> createState() => _PomodoroDashboardState();
}

class _PomodoroDashboardState extends State<PomodoroDashboard> {
  TimerMode _mode = TimerMode.pomodoro;
  Task? _selectedTask;
  String _selectedNoise = 'Silence 🤫';

  // Timer States
  Timer? _timer;
  bool _isRunning = false;
  bool _isBreak = false;
  int _pomodoroMinutes = 25;
  late int _secondsLeft;
  int _stopwatchSeconds = 0;
  int _sessionsCompleted = 0;
  int _pauseCount = 0;

  // Daily goal target is still a fixed number (no settings screen to
  // configure it yet), but how many count toward it is real now — pulled
  // from AppShell's session ledger instead of a number frozen at 3 forever.
  final int _dailyGoal = 6;
  int get _completedToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.sessions.where((s) {
      final d = DateTime(s.completedAt.year, s.completedAt.month, s.completedAt.day);
      return d == today && s.isSuccessful;
    }).length;
  }

  final List<String> _noises = [
    'Silence 🤫',
    'Rain 🌧️',
    'Cafe ☕',
    'Forest 🌲',
    'Clock ⏱️'
  ];

  @override
  void initState() {
    super.initState();
    _selectedTask = widget.initialTask;
    if (_selectedTask != null && _selectedTask!.estimatedMinutes > 0) {
      _pomodoroMinutes = _selectedTask!.estimatedMinutes;
    }
    _secondsLeft = _pomodoroMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.lightImpact();
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
        if (_mode == TimerMode.pomodoro && !_isBreak) _pauseCount++;
      });
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_mode == TimerMode.pomodoro) {
            if (_secondsLeft > 0) {
              _secondsLeft--;
            } else {
              _timer?.cancel();
              _handlePomodoroDone();
            }
          } else {
            _stopwatchSeconds++;
          }
        });
      });
    }
  }

  void _handlePomodoroDone() {
    HapticFeedback.heavyImpact();
    final wasFocusSegment = !_isBreak;
    final justFinishedMinutes = _pomodoroMinutes;

    setState(() {
      _isRunning = false;
      if (!_isBreak) _sessionsCompleted++;
      _isBreak = !_isBreak;
      _secondsLeft = (_isBreak ? 5 : _pomodoroMinutes) * 60;
    });

    // A focus segment (not a break) that ran all the way down is a
    // completed FocusSession — logged against whatever task was bound.
    if (wasFocusSegment && _selectedTask != null) {
      widget.onSessionComplete(FocusSession(
        id: 'session_${DateTime.now().microsecondsSinceEpoch}',
        taskId: _selectedTask!.id,
        taskTitle: _selectedTask!.title,
        plannedMinutes: justFinishedMinutes,
        actualSeconds: justFinishedMinutes * 60,
        pauseCount: _pauseCount,
        outcome: FocusOutcome.completed,
        completedAt: DateTime.now(),
      ));
      _pauseCount = 0;
    }

    // Show completion toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBreak
            ? '✅ Focus done! Take a 5min break.'
            : '☕ Break done! Ready to focus?'),
        backgroundColor: AppColors.deepNavy,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetTimer() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();

    // Bailing out mid-segment is still reality worth logging, same as the
    // full-screen Pomodoro flow does when you back out early.
    if (_selectedTask != null) {
      if (_mode == TimerMode.pomodoro && !_isBreak && _secondsLeft < _pomodoroMinutes * 60) {
        widget.onSessionComplete(FocusSession(
          id: 'session_${DateTime.now().microsecondsSinceEpoch}',
          taskId: _selectedTask!.id,
          taskTitle: _selectedTask!.title,
          plannedMinutes: _pomodoroMinutes,
          actualSeconds: (_pomodoroMinutes * 60) - _secondsLeft,
          pauseCount: _pauseCount,
          outcome: FocusOutcome.abandoned,
          completedAt: DateTime.now(),
        ));
      } else if (_mode == TimerMode.stopwatch && _stopwatchSeconds > 0) {
        widget.onSessionComplete(FocusSession(
          id: 'session_${DateTime.now().microsecondsSinceEpoch}',
          taskId: _selectedTask!.id,
          taskTitle: _selectedTask!.title,
          plannedMinutes: 0,
          actualSeconds: _stopwatchSeconds,
          pauseCount: _pauseCount,
          outcome: FocusOutcome.completed,
          completedAt: DateTime.now(),
        ));
      }
    }

    setState(() {
      _isRunning = false;
      _isBreak = false;
      _pauseCount = 0;
      if (_mode == TimerMode.pomodoro) {
        _secondsLeft = _pomodoroMinutes * 60;
      } else {
        _stopwatchSeconds = 0;
      }
    });
  }

  void _pickTask() {
    final tasks = widget.tasks.where((t) => !t.isDone).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select Task to Focus On',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepNavy),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedTask != null)
                ListTile(
                  leading: const Icon(Icons.close,
                      color: AppColors.slateGray),
                  title: const Text('Unbind task',
                      style: TextStyle(
                          color: AppColors.slateGray,
                          fontStyle: FontStyle.italic)),
                  onTap: () {
                    setState(() => _selectedTask = null);
                    Navigator.pop(context);
                  },
                ),
              ...tasks.map((t) => ListTile(
                leading:
                Icon(Icons.adjust, color: t.priorityColor),
                title: Text(t.title,
                    style: const TextStyle(
                        color: AppColors.deepNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${t.subject} · ${t.estimatedMinutes} min',
                    style: const TextStyle(
                        color: AppColors.slateGray, fontSize: 12)),
                trailing: _selectedTask?.id == t.id
                    ? const Icon(Icons.check_circle,
                    color: AppColors.teal)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedTask = t;
                    if (!_isRunning) {
                      _pomodoroMinutes = t.estimatedMinutes;
                      _secondsLeft = _pomodoroMinutes * 60;
                    }
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _cycleNoise() {
    HapticFeedback.selectionClick();
    final nextIndex = (_noises.indexOf(_selectedNoise) + 1) % _noises.length;
    setState(() => _selectedNoise = _noises[nextIndex]);
  }

  String get _formattedTime {
    int totalSecs = _mode == TimerMode.pomodoro ? _secondsLeft : _stopwatchSeconds;
    int m = (totalSecs / 60).floor();
    int s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _showResetButton {
    if (_mode == TimerMode.pomodoro) {
      return _secondsLeft < (_pomodoroMinutes * 60);
    }
    return _stopwatchSeconds > 0;
  }

  @override
  Widget build(BuildContext context) {
    final primaryAccent = _isBreak ? AppColors.amber : AppColors.teal;
    final progress = _mode == TimerMode.pomodoro
        ? (1 - (_secondsLeft / (_pomodoroMinutes * 60)))
        : 1.0;

    return Container(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 0. Header (menu + title + history + classroom)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 20, top: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.deepNavy, size: 28),
                    onPressed: widget.onMenuTap,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Pomodoro',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.deepNavy, letterSpacing: -0.5),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Focus history',
                    icon: const Icon(Icons.bar_chart_outlined, color: AppColors.deepNavy, size: 24),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FocusHistoryScreen(sessions: widget.sessions)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.school_outlined, color: AppColors.deepNavy, size: 26),
                    onPressed: widget.onClassroomTap,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 1. Mode Switcher
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isRunning ? 0.3 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.subtleGray,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModePill('Pomodoro', TimerMode.pomodoro),
                    _buildModePill('Stopwatch', TimerMode.stopwatch),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Task Selector
            GestureDetector(
              onTap: _isRunning ? null : _pickTask,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _selectedTask != null
                          ? primaryAccent
                          : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                        color:
                        AppColors.deepNavy.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedTask != null
                          ? Icons.task_alt
                          : Icons.adjust,
                      size: 16,
                      color: _selectedTask != null
                          ? primaryAccent
                          : AppColors.slateGray,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _selectedTask?.title ?? 'Click to bind a task...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedTask != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _selectedTask != null
                              ? AppColors.deepNavy
                              : AppColors.slateGray,
                        ),
                      ),
                    ),
                    if (!_isRunning) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: AppColors.slateGray),
                    ]
                  ],
                ),
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 3. Timer Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: _mode == TimerMode.pomodoro
                              ? progress
                              : null,
                          strokeWidth: 8,
                          backgroundColor: AppColors.subtleGray,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(primaryAccent),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formattedTime,
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w200,
                              color: AppColors.deepNavy,
                              fontFeatures: [
                                FontFeature.tabularFigures()
                              ],
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _mode == TimerMode.stopwatch
                                ? 'COUNT-UP MODE'
                                : (_isBreak
                                ? 'SHORT BREAK'
                                : 'FOCUS SESSION'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primaryAccent,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (_sessionsCompleted > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Session ${_sessionsCompleted + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.slateGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 4. Noise Selector
                  GestureDetector(
                    onTap: _cycleNoise,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.subtleGray
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.headphones,
                              size: 14, color: AppColors.slateGray),
                          const SizedBox(width: 6),
                          Text(
                            _selectedNoise,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.deepNavy),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Controls
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_showResetButton) ...[
                    IconButton(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.stop_circle_outlined,
                          size: 32, color: AppColors.slateGray),
                    ),
                    const SizedBox(width: 24),
                  ],

                  GestureDetector(
                    onTap: _toggleTimer,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 140,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isRunning
                            ? AppColors.white
                            : primaryAccent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _isRunning
                                ? AppColors.border
                                : primaryAccent,
                            width: 2),
                        boxShadow: _isRunning
                            ? []
                            : [
                          BoxShadow(
                              color: primaryAccent.withValues(
                                  alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Text(
                        _isRunning
                            ? 'Pause'
                            : (_isBreak ? 'Start Break' : 'Start Focus'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _isRunning
                              ? AppColors.deepNavy
                              : AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 6. Daily Goal Tracker
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isRunning ? 0 : 90,
              curve: Curves.easeInOut,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(24, 10, 24, 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.subtleGray
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Daily Goal',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slateGray)),
                            Text(
                                '$_completedToday / $_dailyGoal Pomodoros',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepNavy)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _completedToday / _dailyGoal,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                AppColors.teal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill(String title, TimerMode mode) {
    final isSel = _mode == mode;
    return GestureDetector(
      onTap: _isRunning
          ? null
          : () {
        HapticFeedback.selectionClick();
        setState(() {
          _mode = mode;
          _isBreak = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSel
              ? [
            BoxShadow(
                color: AppColors.deepNavy.withValues(alpha: 0.06),
                blurRadius: 8)
          ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? AppColors.deepNavy : AppColors.slateGray,
          ),
        ),
      ),
    );
  }
}