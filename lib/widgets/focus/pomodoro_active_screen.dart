// lib/widgets/focus/pomodoro_active_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';

class PomodoroActiveScreen extends StatefulWidget {
  final Task task;
  final int durationMinutes;

  // Reality gets written back here — a FocusSession is emitted whenever this
  // session ends, however it ends (naturally, skipped, or backed out of).
  final ValueChanged<FocusSession> onSessionComplete;

  const PomodoroActiveScreen({
    super.key,
    required this.task,
    required this.durationMinutes,
    required this.onSessionComplete,
  });

  @override
  State<PomodoroActiveScreen> createState() => _PomodoroActiveScreenState();
}

class _PomodoroActiveScreenState extends State<PomodoroActiveScreen> {
  Timer? _timer;
  late int _totalSeconds;
  late int _remainingSeconds;
  bool _isPaused = false;
  bool _isCompleted = false;
  int _pauseCount = 0;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _onTimerComplete();
      }
    });
  }

  FocusSession _buildSession(FocusOutcome outcome) {
    return FocusSession(
      id: 'session_${DateTime.now().microsecondsSinceEpoch}',
      taskId: widget.task.id,
      taskTitle: widget.task.title,
      plannedMinutes: widget.durationMinutes,
      actualSeconds: _totalSeconds - _remainingSeconds,
      pauseCount: _pauseCount,
      outcome: outcome,
      completedAt: DateTime.now(),
    );
  }

  void _onTimerComplete() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() => _isCompleted = true);
    widget.onSessionComplete(_buildSession(FocusOutcome.completed));
  }

  void _togglePause() {
    HapticFeedback.mediumImpact();
    if (_isPaused) {
      _startTimer();
      setState(() => _isPaused = false);
    } else {
      _timer?.cancel();
      setState(() {
        _isPaused = true;
        _pauseCount++;
      });
    }
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isPaused = false;
      _isCompleted = false;
      _pauseCount = 0;
    });
    _startTimer();
  }

  void _skipSession() {
    if (_isCompleted) return;
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() => _isCompleted = true);
    widget.onSessionComplete(_buildSession(FocusOutcome.interrupted));
  }

  // Backing out before the timer naturally finishes or gets skipped still
  // counts as reality — an abandoned session, logged only if any time was
  // actually spent.
  void _handleClose() {
    _timer?.cancel();
    if (!_isCompleted && _remainingSeconds < _totalSeconds) {
      widget.onSessionComplete(_buildSession(FocusOutcome.abandoned));
    }
    Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  double get _progress {
    if (_totalSeconds == 0) return 0;
    return _remainingSeconds / _totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.deepNavy),
          onPressed: _handleClose,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              _isCompleted ? 'COMPLETED' : 'WORKING ON',
              style: TextStyle(
                color: _isCompleted ? AppColors.teal : AppColors.slateGray,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.task.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.deepNavy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Session 1 of ${widget.task.pomodorosPlanned}',
              style:
              const TextStyle(color: AppColors.slateGray, fontSize: 14),
            ),
            const Spacer(),

            // Animated Circular Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 12,
                    backgroundColor:
                    AppColors.border.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isCompleted ? AppColors.teal : AppColors.deepNavy,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepNavy,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      _isCompleted
                          ? 'Done!'
                          : (_isPaused ? 'paused' : 'remaining'),
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.slateGray),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                      border:
                      Border.all(color: AppColors.border, width: 2),
                      shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.refresh,
                        color: AppColors.deepNavy),
                    onPressed: _resetTimer,
                  ),
                ),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: _isCompleted ? null : _togglePause,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: AppColors.white,
                  ),
                  label: Text(
                    _isCompleted ? 'Done' : (_isPaused ? 'Resume' : 'Pause'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCompleted
                        ? AppColors.teal
                        : AppColors.deepNavy,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.teal,
                    disabledForegroundColor: AppColors.white,
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  decoration: BoxDecoration(
                      border:
                      Border.all(color: AppColors.border, width: 2),
                      shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.skip_next,
                        color: AppColors.deepNavy),
                    onPressed: _skipSession,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Session will be logged on your calendar at ${TimeOfDay.now().format(context)}',
              style: const TextStyle(
                  color: AppColors.slateGray, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}