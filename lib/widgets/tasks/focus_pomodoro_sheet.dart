// lib/widgets/tasks/focus_pomodoro_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class FocusPomodoroSheet extends StatefulWidget {
  final int initialMinutes;

  const FocusPomodoroSheet({super.key, required this.initialMinutes});

  static Future<int?> show(BuildContext context, {int initialMinutes = 45}) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FocusPomodoroSheet(initialMinutes: initialMinutes),
    );
  }

  @override
  State<FocusPomodoroSheet> createState() => _FocusPomodoroSheetState();
}

class _FocusPomodoroSheetState extends State<FocusPomodoroSheet> {
  bool isPomoTab = true;
  late FixedExtentScrollController _scrollController;
  late int selectedMinutes;

  @override
  void initState() {
    super.initState();
    selectedMinutes = widget.initialMinutes;
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
              _buildStat('Estimation', '$selectedMinutes >', isHighlight: true),
              _buildStat('Focus Duration', '0s'),
              _buildStat('Pomo', '0'),
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
                Navigator.pop(context, selectedMinutes);
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
                fontSize: 24,
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
              return Center(
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