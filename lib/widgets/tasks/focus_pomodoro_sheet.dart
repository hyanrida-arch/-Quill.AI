// lib/widgets/tasks/focus_pomodoro_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

// Common Pomodoro session lengths people actually use — classic 25, plus
// the usual variants (short 15/20, "deep work" 45/50/60).
const List<int> kPomodoroLengthPresets = [15, 20, 25, 30, 45, 50, 60];

class FocusPomodoroSheet extends StatefulWidget {
  final int initialMinutes;
  // Length of a single Pomodoro session, in minutes — previously baked in
  // as a hardcoded "/25" everywhere Pomo count was computed, with no way
  // to change it. Defaults to the classic 25 if the caller doesn't know
  // what was used last (e.g. a brand new task).
  final int initialPomodoroMinutes;

  const FocusPomodoroSheet({
    super.key,
    required this.initialMinutes,
    this.initialPomodoroMinutes = 25,
  });

  /// Returns null if cancelled, otherwise {'minutes': totalEstimateMinutes,
  /// 'pomodoros': sessionCount} — both now independently editable instead
  /// of "pomodoros" being a fixed, un-settable /25 of "minutes".
  static Future<Map<String, int>?> show(
    BuildContext context, {
    int initialMinutes = 45,
    int initialPomodoroMinutes = 25,
  }) {
    return showModalBottomSheet<Map<String, int>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FocusPomodoroSheet(
        initialMinutes: initialMinutes,
        initialPomodoroMinutes: initialPomodoroMinutes,
      ),
    );
  }

  @override
  State<FocusPomodoroSheet> createState() => _FocusPomodoroSheetState();
}

class _FocusPomodoroSheetState extends State<FocusPomodoroSheet> {
  bool isPomoTab = true;
  late FixedExtentScrollController _scrollController;
  late int selectedMinutes;
  late int _pomodoroLength;

  int get _pomodoroCount => (selectedMinutes / _pomodoroLength).ceil().clamp(1, 20);

  @override
  void initState() {
    super.initState();
    selectedMinutes = widget.initialMinutes;
    _pomodoroLength = widget.initialPomodoroMinutes.clamp(5, 120);
    _scrollController =
        FixedExtentScrollController(initialItem: selectedMinutes - 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('Focus',
              style: TextStyle(
                  color: AppColors.deepNavy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Estimation — total time for the task. Editable directly, or
              // via the wheel below.
              GestureDetector(
                onTap: _editEstimationDirectly,
                child: _buildStat('Estimation', '$selectedMinutes >', isHighlight: true),
              ),
              // Focus Duration — the length of ONE Pomodoro session. This
              // used to just mirror Estimation (both showed the same
              // number), which was redundant and un-editable. Now it's its
              // own setting with presets.
              GestureDetector(
                onTap: _editPomodoroLength,
                child: _buildStat('Focus Duration', '${_formatDuration(_pomodoroLength)} >'),
              ),
              // Pomo — how many sessions Estimation breaks into at the
              // current Focus Duration. Previously a frozen, un-tappable
              // '0' / a fixed ceil(minutes/25). Now tappable to set the
              // session count directly, which adjusts Estimation to match.
              GestureDetector(
                onTap: _editPomodoroCount,
                child: _buildStat('Pomo', '$_pomodoroCount >'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => isPomoTab = true);
                },
                child: Column(
                  children: [
                    Text('POMO',
                        style: TextStyle(
                            color: isPomoTab
                                ? AppColors.teal
                                : AppColors.slateGray,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Container(
                        height: 2,
                        width: 40,
                        color: isPomoTab
                            ? AppColors.teal
                            : Colors.transparent),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => isPomoTab = false);
                },
                child: Column(
                  children: [
                    Text('STOPWATCH',
                        style: TextStyle(
                            color: !isPomoTab
                                ? AppColors.teal
                                : AppColors.slateGray,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Container(
                        height: 2,
                        width: 80,
                        color: !isPomoTab
                            ? AppColors.teal
                            : Colors.transparent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
              height: 180,
              child: isPomoTab ? _buildPomoPicker() : _buildStopwatch()),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, {
                  'minutes': selectedMinutes,
                  'pomodoros': _pomodoroCount,
                });
              },
              child: const Text('Start',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  // The "Estimation 30 >" stat used to just be a Text with no tap handler
  // at all — the "›" implied it was tappable but nothing happened. This
  // opens a direct numeric entry so picking, say, 95 minutes doesn't mean
  // scrolling the wheel 95 times.
  Future<void> _editEstimationDirectly() async {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(text: selectedMinutes.toString());
    final entered = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set estimation', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.deepNavy, fontSize: 18),
          decoration: const InputDecoration(suffixText: 'minutes'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (entered == null || entered < 1) return;
    final clamped = entered > 120 ? 120 : entered;
    setState(() => selectedMinutes = clamped);
    if (_scrollController.hasClients) {
      _scrollController.animateToItem(
        clamped - 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // Lets you change how long a single Pomodoro session runs — a fixed 25
  // was previously assumed everywhere with no way to override it.
  Future<void> _editPomodoroLength() async {
    HapticFeedback.selectionClick();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pomodoro length', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kPomodoroLengthPresets.map((mins) {
            final isSelected = mins == _pomodoroLength;
            return GestureDetector(
              onTap: () => Navigator.pop(context, mins),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.deepNavy : AppColors.subtleGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${mins}m',
                    style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.deepNavy,
                        fontWeight: FontWeight.w700)),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
    if (result == null) return;
    // Estimation stays put; the number of sessions it breaks into changes
    // to match the new per-session length.
    setState(() => _pomodoroLength = result);
  }

  // Lets you set the number of Pomodoro sessions directly instead of only
  // ever seeing it as a read-only ceil(minutes / 25).
  Future<void> _editPomodoroCount() async {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(text: _pomodoroCount.toString());
    final entered = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Number of Pomodoros', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.deepNavy, fontSize: 18),
          decoration: const InputDecoration(suffixText: 'sessions'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (entered == null || entered < 1) return;
    final clampedCount = entered > 20 ? 20 : entered;
    // Setting the count directly re-derives Estimation to match (count ×
    // per-session length) rather than the other way around.
    final newMinutes = (clampedCount * _pomodoroLength).clamp(1, 120);
    setState(() => selectedMinutes = newMinutes);
    if (_scrollController.hasClients) {
      _scrollController.animateToItem(
        newMinutes - 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.slateGray,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: AppColors.deepNavy,
                fontSize: 20,
                fontWeight:
                    isHighlight ? FontWeight.w800 : FontWeight.w700)),
      ],
    );
  }

  Widget _buildPomoPicker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ListWheelScrollView.useDelegate(
          controller: _scrollController,
          itemExtent: 50,
          physics: const FixedExtentScrollPhysics(),
          perspective: 0.005,
          onSelectedItemChanged: (index) {
            HapticFeedback.selectionClick();
            setState(() => selectedMinutes = index + 1);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final val = index + 1;
              final isSelected = val == selectedMinutes;
              // Tapping any visible number (not just scrolling to it) jumps
              // straight there — a second, guaranteed-to-work way to change
              // the value if the scroll gesture itself feels unresponsive
              // inside a modal bottom sheet.
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _scrollController.animateToItem(
                    index,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                },
                child: Center(
                  child: Text(
                    val.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.deepNavy
                          : AppColors.slateGray.withValues(alpha: 0.4),
                      fontSize: isSelected ? 32 : 22,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
            childCount: 120,
          ),
        ),
        const Positioned(
          right: 70,
          child: Text('Minutes',
              style: TextStyle(
                  color: AppColors.slateGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStopwatch() {
    return const Center(
        child: Text('00 : 00',
            style: TextStyle(
                color: AppColors.deepNavy,
                fontSize: 36,
                fontWeight: FontWeight.w800)));
  }
}
